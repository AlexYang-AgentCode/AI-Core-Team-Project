/**
 * appspawn-x spawn message definitions.
 *
 * Defines the message structures used for communication between
 * foundation's AppSpawnClient and the appspawn-x daemon over Unix socket.
 * Message codes and StartFlags must match OH appspawn protocol definitions.
 */

#pragma once

#include <cstdint>
#include <cstdio>
#include <string>
#include <vector>

// ---------- Logging macros (portable, switch to hilog for OH build) ----------
#define APPSPAWNX_LOG_TAG "AppSpawnX"
#define LOGI(fmt, ...) fprintf(stdout, "[%s] " fmt "\n", APPSPAWNX_LOG_TAG, ##__VA_ARGS__)
#define LOGD(fmt, ...) fprintf(stdout, "[%s][D] " fmt "\n", APPSPAWNX_LOG_TAG, ##__VA_ARGS__)
#define LOGE(fmt, ...) fprintf(stderr, "[%s][E] " fmt "\n", APPSPAWNX_LOG_TAG, ##__VA_ARGS__)
#define LOGW(fmt, ...) fprintf(stderr, "[%s][W] " fmt "\n", APPSPAWNX_LOG_TAG, ##__VA_ARGS__)

namespace appspawnx {

// AppSpawn message codes (must match OH appspawn protocol)
constexpr int MSG_APP_SPAWN = 0;
constexpr int MSG_SPAWN_NATIVE_PROCESS = 1;
constexpr int MSG_GET_RENDER_TERMINATION_STATUS = 2;

// StartFlags bit positions (must match OH AppSpawnStartMsg::StartFlags)
struct StartFlags {
    static constexpr int COLD_START = 0;
    static constexpr int DEBUGGABLE = 3;
    static constexpr int ASANENABLED = 4;
    static constexpr int NATIVEDEBUG = 6;
    static constexpr int NO_SANDBOX = 7;
};

// Parsed spawn request message
struct SpawnMsg {
    int32_t code;
    std::string procName;
    std::string bundleName;
    int32_t uid;
    int32_t gid;
    std::vector<int32_t> gids;
    uint64_t accessTokenIdEx;
    uint32_t hapFlags;
    std::string apl;              // "system_core", "system_basic", "normal"
    uint64_t flags;               // StartFlags bitmask

    // Android-specific extensions
    std::string apkPath;          // APK file path
    std::string dexPaths;         // DEX search paths
    std::string nativeLibPaths;   // Native library paths
    std::string targetClass;      // Entry class (default: "android.app.ActivityThread")
    int32_t targetSdkVersion;

    // SELinux
    std::string selinuxContext;   // e.g. "u:r:android_app:s0"

    SpawnMsg() : code(0), uid(-1), gid(-1), accessTokenIdEx(0),
                 hapFlags(0), flags(0), targetSdkVersion(0) {}

    bool hasFlag(int bit) const { return (flags >> bit) & 1; }
};

// Spawn result sent back to foundation
struct SpawnResult {
    int32_t pid;
    int32_t result;  // 0 = success
};

} // namespace appspawnx
