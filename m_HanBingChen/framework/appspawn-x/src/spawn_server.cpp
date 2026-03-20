/**
 * appspawn-x spawn server implementation.
 *
 * Manages the Unix domain socket lifecycle, accepts connections from
 * foundation's AppSpawnClient, parses spawn request messages, and
 * dispatches them to the registered SpawnHandler. Also handles SIGCHLD
 * to reap forked child processes.
 */

#include "spawn_server.h"

#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <poll.h>
#include <signal.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/wait.h>
#include <unistd.h>

namespace appspawnx {

// ---------------------------------------------------------------------------
// SIGCHLD handler – reap zombie child processes
// ---------------------------------------------------------------------------
static void sigchldHandler(int /*sig*/) {
    // Reap all terminated children without blocking
    int savedErrno = errno;
    while (waitpid(-1, nullptr, WNOHANG) > 0) {
        // Continue reaping
    }
    errno = savedErrno;
}

// ---------------------------------------------------------------------------
// Install SIGCHLD handler with SA_RESTART so accept()/poll() auto-restart
// ---------------------------------------------------------------------------
static int installSigchldHandler() {
    struct sigaction sa;
    memset(&sa, 0, sizeof(sa));
    sa.sa_handler = sigchldHandler;
    sigemptyset(&sa.sa_mask);
    sa.sa_flags = SA_RESTART | SA_NOCLDSTOP;

    if (sigaction(SIGCHLD, &sa, nullptr) < 0) {
        LOGE("sigaction(SIGCHLD) failed: %s", strerror(errno));
        return -1;
    }
    return 0;
}

// ---------------------------------------------------------------------------
// Maximum message size we accept from a client (256 KB should be plenty)
// ---------------------------------------------------------------------------
static constexpr size_t kMaxMessageSize = 256 * 1024;

// Maximum number of pending connections on the listen socket
static constexpr int kListenBacklog = 8;

// ---------------------------------------------------------------------------
// SpawnServer
// ---------------------------------------------------------------------------

SpawnServer::SpawnServer(const std::string& socketName)
    : socketName_(socketName),
      listenFd_(-1) {
    // Build the socket filesystem path.
    // On OH, appspawn sockets live under /dev/unix/socket/
    socketPath_ = std::string("/dev/unix/socket/") + socketName_;
}

SpawnServer::~SpawnServer() {
    closeSocket();
}

// ---------------------------------------------------------------------------
// initSecurity  –  initialize OH sandbox, SELinux, AccessToken modules
// ---------------------------------------------------------------------------
int SpawnServer::initSecurity(const std::string& sandboxConfigPath) {
    LOGI("Initializing security modules");

    // Step 1: Load sandbox configuration
    // In production, this reads the JSON sandbox profile that defines
    // mount namespaces, bind mounts, and filesystem restrictions per APL.
    LOGI("Loading sandbox config from: %s", sandboxConfigPath.c_str());
    // TODO: Parse sandboxConfigPath JSON using OH sandbox APIs
    //   - LoadAppSandboxConfig(sandboxConfigPath)
    //   - Validate required mount points exist
    if (access(sandboxConfigPath.c_str(), R_OK) != 0) {
        LOGW("Sandbox config not readable: %s (errno=%d: %s)",
             sandboxConfigPath.c_str(), errno, strerror(errno));
        LOGW("Continuing without sandbox config – "
             "apps will run without filesystem isolation");
    } else {
        LOGI("Sandbox config file found");
    }

    // Step 2: Initialize SELinux labeling
    // Load file_contexts and seapp_contexts for Android app domain mapping
    LOGI("Initializing SELinux labeling");
    // TODO: Link against libselinux and call:
    //   - selinux_android_setcontext()
    //   - selabel_open() for file labeling
    // For now, log the intent
    LOGD("SELinux labeling: stub initialized");

    // Step 3: Initialize AccessToken management
    // OH AccessToken provides fine-grained permission control.
    // We need to set the correct token for each spawned app process.
    LOGI("Initializing AccessToken management");
    // TODO: Link against libaccesstoken_sdk and call:
    //   - AccessTokenKit::Init()
    LOGD("AccessToken management: stub initialized");

    // Step 4: Install SIGCHLD handler for child reaping
    if (installSigchldHandler() != 0) {
        LOGE("Failed to install SIGCHLD handler");
        return -1;
    }
    LOGI("SIGCHLD handler installed");

    LOGI("Security modules initialized successfully");
    return 0;
}

// ---------------------------------------------------------------------------
// createListenSocket  –  create, bind, and listen on Unix domain socket
// ---------------------------------------------------------------------------
int SpawnServer::createListenSocket() {
    LOGI("Creating listen socket: %s", socketPath_.c_str());

    // Create the Unix domain socket
    listenFd_ = socket(AF_UNIX, SOCK_STREAM, 0);
    if (listenFd_ < 0) {
        LOGE("socket(AF_UNIX) failed: %s", strerror(errno));
        return -1;
    }

    // Remove any stale socket file from a previous run
    unlink(socketPath_.c_str());

    // Bind to the socket path
    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;

    if (socketPath_.size() >= sizeof(addr.sun_path)) {
        LOGE("Socket path too long (%zu >= %zu): %s",
             socketPath_.size(), sizeof(addr.sun_path), socketPath_.c_str());
        close(listenFd_);
        listenFd_ = -1;
        return -1;
    }
    strncpy(addr.sun_path, socketPath_.c_str(), sizeof(addr.sun_path) - 1);

    socklen_t addrLen = offsetof(struct sockaddr_un, sun_path) +
                        strlen(addr.sun_path) + 1;

    if (bind(listenFd_, reinterpret_cast<struct sockaddr*>(&addr), addrLen) < 0) {
        LOGE("bind(%s) failed: %s", socketPath_.c_str(), strerror(errno));
        close(listenFd_);
        listenFd_ = -1;
        return -1;
    }

    // Set socket permissions: only system (root + system group) can connect
    if (chmod(socketPath_.c_str(), 0660) < 0) {
        LOGW("chmod(%s, 0660) failed: %s", socketPath_.c_str(), strerror(errno));
        // Non-fatal, continue
    }

    // Start listening
    if (listen(listenFd_, kListenBacklog) < 0) {
        LOGE("listen() failed: %s", strerror(errno));
        close(listenFd_);
        listenFd_ = -1;
        return -1;
    }

    LOGI("Listen socket ready: fd=%d path=%s", listenFd_, socketPath_.c_str());
    return 0;
}

// ---------------------------------------------------------------------------
// setSpawnHandler
// ---------------------------------------------------------------------------
void SpawnServer::setSpawnHandler(SpawnHandler handler) {
    spawnHandler_ = std::move(handler);
}

// ---------------------------------------------------------------------------
// run  –  main event loop
// ---------------------------------------------------------------------------
void SpawnServer::run() {
    LOGI("Entering event loop on %s", socketPath_.c_str());

    if (listenFd_ < 0) {
        LOGE("Cannot run – listen socket not created");
        return;
    }

    struct pollfd pfd;
    pfd.fd = listenFd_;
    pfd.events = POLLIN;

    while (true) {
        // Wait for incoming connections
        int nready = poll(&pfd, 1, -1 /* block indefinitely */);

        if (nready < 0) {
            if (errno == EINTR) {
                // Interrupted by signal (e.g. SIGCHLD) – restart poll
                continue;
            }
            LOGE("poll() failed: %s", strerror(errno));
            break;
        }

        if (nready == 0) {
            // Timeout (shouldn't happen with -1 timeout)
            continue;
        }

        if (pfd.revents & POLLIN) {
            // Accept the incoming connection
            struct sockaddr_un clientAddr;
            socklen_t clientLen = sizeof(clientAddr);
            int clientFd = accept(listenFd_,
                                  reinterpret_cast<struct sockaddr*>(&clientAddr),
                                  &clientLen);
            if (clientFd < 0) {
                if (errno == EINTR) {
                    continue;
                }
                LOGE("accept() failed: %s", strerror(errno));
                continue;
            }

            LOGD("Accepted connection, clientFd=%d", clientFd);

            // Handle the spawn request synchronously.
            // This is acceptable because fork() is fast and the parent
            // returns quickly after spawning the child.
            handleConnection(clientFd);

            close(clientFd);
        }

        if (pfd.revents & (POLLERR | POLLHUP | POLLNVAL)) {
            LOGE("Listen socket error (revents=0x%x)", pfd.revents);
            break;
        }
    }

    LOGE("Event loop terminated");
}

// ---------------------------------------------------------------------------
// closeSocket  –  close the listen fd (used in child after fork)
// ---------------------------------------------------------------------------
void SpawnServer::closeSocket() {
    if (listenFd_ >= 0) {
        close(listenFd_);
        listenFd_ = -1;
    }
}

// ---------------------------------------------------------------------------
// handleConnection  –  read request, dispatch to handler, send result
// ---------------------------------------------------------------------------
void SpawnServer::handleConnection(int clientFd) {
    // Protocol: first 4 bytes are the total payload length (network byte order),
    // followed by the payload bytes.
    uint32_t payloadLen = 0;
    ssize_t n = recv(clientFd, &payloadLen, sizeof(payloadLen), MSG_WAITALL);
    if (n != sizeof(payloadLen)) {
        LOGE("Failed to read message length: n=%zd errno=%s",
             n, strerror(errno));
        SpawnResult err = {-1, -1};
        sendResult(clientFd, err);
        return;
    }

    // Convert from network byte order to host byte order
    // (OH appspawn uses little-endian on ARM, but we handle both)
    // For simplicity, assume native byte order matches the sender
    if (payloadLen == 0 || payloadLen > kMaxMessageSize) {
        LOGE("Invalid message length: %u", payloadLen);
        SpawnResult err = {-1, -1};
        sendResult(clientFd, err);
        return;
    }

    // Read the payload
    std::vector<uint8_t> buffer(payloadLen);
    size_t totalRead = 0;
    while (totalRead < payloadLen) {
        n = recv(clientFd, buffer.data() + totalRead,
                 payloadLen - totalRead, 0);
        if (n <= 0) {
            if (n < 0 && errno == EINTR) continue;
            LOGE("Failed to read message payload: n=%zd total=%zu/%u",
                 n, totalRead, payloadLen);
            SpawnResult err = {-1, -1};
            sendResult(clientFd, err);
            return;
        }
        totalRead += static_cast<size_t>(n);
    }

    // Parse the message
    SpawnMsg msg;
    if (!parseMessage(buffer.data(), buffer.size(), msg)) {
        LOGE("Failed to parse spawn message");
        SpawnResult err = {-1, -1};
        sendResult(clientFd, err);
        return;
    }

    LOGI("Parsed spawn request: code=%d proc=%s bundle=%s uid=%d",
         msg.code, msg.procName.c_str(), msg.bundleName.c_str(), msg.uid);

    // Dispatch to the spawn handler
    SpawnResult result;
    if (spawnHandler_) {
        int pid = spawnHandler_(msg);
        result.pid = pid;
        result.result = (pid > 0) ? 0 : -1;
    } else {
        LOGE("No spawn handler registered");
        result.pid = -1;
        result.result = -1;
    }

    sendResult(clientFd, result);
}

// ---------------------------------------------------------------------------
// parseMessage  –  simplified JSON-based protocol for development
// ---------------------------------------------------------------------------
//
// In production, this would use the OH appspawn binary protocol by linking
// against appspawn libraries (appspawn_msg_parse). For development and
// testing, we use a simple text-based key=value format, one field per line:
//
//   code=0
//   procName=com.example.app
//   bundleName=com.example.app
//   uid=10042
//   gid=10042
//   gids=1003,1004,3003
//   accessTokenIdEx=123456
//   hapFlags=0
//   apl=normal
//   flags=0
//   apkPath=/data/app/com.example.app/base.apk
//   dexPaths=/data/app/com.example.app/base.apk
//   nativeLibPaths=/data/app/com.example.app/lib/arm64
//   targetClass=android.app.ActivityThread
//   targetSdkVersion=34
//   selinuxContext=u:r:android_app:s0
//
bool SpawnServer::parseMessage(const uint8_t* data, size_t len, SpawnMsg& msg) {
    // Convert to string for line-by-line parsing
    std::string text(reinterpret_cast<const char*>(data), len);

    // Helper lambda: extract value for a given key from text
    auto getValue = [&text](const std::string& key) -> std::string {
        std::string prefix = key + "=";
        size_t pos = text.find(prefix);
        if (pos == std::string::npos) return "";

        size_t start = pos + prefix.size();
        size_t end = text.find('\n', start);
        if (end == std::string::npos) end = text.size();

        // Trim trailing \r if present
        if (end > start && text[end - 1] == '\r') end--;

        return text.substr(start, end - start);
    };

    // Helper lambda: parse integer with default value
    auto getInt = [&getValue](const std::string& key, int32_t def) -> int32_t {
        std::string val = getValue(key);
        if (val.empty()) return def;
        return static_cast<int32_t>(strtol(val.c_str(), nullptr, 10));
    };

    // Helper lambda: parse uint64 with default value
    auto getUint64 = [&getValue](const std::string& key, uint64_t def) -> uint64_t {
        std::string val = getValue(key);
        if (val.empty()) return def;
        return static_cast<uint64_t>(strtoull(val.c_str(), nullptr, 10));
    };

    // Parse all fields
    msg.code = getInt("code", MSG_APP_SPAWN);
    msg.procName = getValue("procName");
    msg.bundleName = getValue("bundleName");
    msg.uid = getInt("uid", -1);
    msg.gid = getInt("gid", -1);
    msg.accessTokenIdEx = getUint64("accessTokenIdEx", 0);
    msg.hapFlags = static_cast<uint32_t>(getInt("hapFlags", 0));
    msg.apl = getValue("apl");
    msg.flags = getUint64("flags", 0);
    msg.apkPath = getValue("apkPath");
    msg.dexPaths = getValue("dexPaths");
    msg.nativeLibPaths = getValue("nativeLibPaths");
    msg.targetClass = getValue("targetClass");
    msg.targetSdkVersion = getInt("targetSdkVersion", 0);
    msg.selinuxContext = getValue("selinuxContext");

    // Parse supplementary GIDs (comma-separated)
    std::string gidsStr = getValue("gids");
    if (!gidsStr.empty()) {
        size_t pos = 0;
        while (pos < gidsStr.size()) {
            size_t comma = gidsStr.find(',', pos);
            if (comma == std::string::npos) comma = gidsStr.size();
            std::string gidVal = gidsStr.substr(pos, comma - pos);
            if (!gidVal.empty()) {
                msg.gids.push_back(
                    static_cast<int32_t>(strtol(gidVal.c_str(), nullptr, 10)));
            }
            pos = comma + 1;
        }
    }

    // Validate required fields
    if (msg.procName.empty()) {
        LOGE("parseMessage: procName is empty");
        return false;
    }
    if (msg.uid < 0) {
        LOGE("parseMessage: uid is invalid (%d)", msg.uid);
        return false;
    }

    return true;
}

// ---------------------------------------------------------------------------
// sendResult  –  write the spawn result back to the client
// ---------------------------------------------------------------------------
void SpawnServer::sendResult(int clientFd, const SpawnResult& result) {
    ssize_t n = send(clientFd, &result, sizeof(result), MSG_NOSIGNAL);
    if (n != sizeof(result)) {
        LOGE("Failed to send spawn result: n=%zd errno=%s",
             n, strerror(errno));
    } else {
        LOGD("Sent spawn result: pid=%d result=%d", result.pid, result.result);
    }
}

} // namespace appspawnx
