/**
 * appspawn-x child process implementation.
 *
 * Handles the complete child process lifecycle after fork():
 * 1. Apply OH DAC credentials (UID/GID/groups)
 * 2. Set up filesystem sandbox (mount namespace, bind mounts)
 * 3. Set SELinux security context
 * 4. Configure OH AccessToken for permission enforcement
 * 5. Initialize the Android-OH adapter layer
 * 6. Launch ActivityThread.main() to start the Android app
 */

#include "child_main.h"
#include "appspawnx_runtime.h"

#include <cerrno>
#include <cstdlib>
#include <cstring>
#include <grp.h>
#include <sys/prctl.h>
#include <sys/types.h>
#include <unistd.h>

namespace appspawnx {

// ---------------------------------------------------------------------------
// run  –  child process main entry point (does not return)
// ---------------------------------------------------------------------------
[[noreturn]] void ChildMain::run(const SpawnMsg& msg, AppSpawnXRuntime* runtime) {
    pid_t myPid = getpid();
    LOGI("Child process started, pid=%d uid=%d bundle=%s",
         myPid, msg.uid, msg.bundleName.c_str());

    // Step 1: Apply DAC credentials (must be done early, before sandbox)
    int ret = applyDac(msg);
    if (ret != 0) {
        LOGE("applyDac failed, ret=%d – aborting child", ret);
        _exit(10);
    }

    // Step 2: Set up filesystem sandbox
    ret = applySandbox(msg);
    if (ret != 0) {
        LOGE("applySandbox failed, ret=%d – aborting child", ret);
        _exit(11);
    }

    // Step 3: Set SELinux context
    ret = applySELinux(msg);
    if (ret != 0) {
        LOGE("applySELinux failed, ret=%d – aborting child", ret);
        _exit(12);
    }

    // Step 4: Apply OH AccessToken
    ret = applyAccessToken(msg);
    if (ret != 0) {
        LOGE("applyAccessToken failed, ret=%d – aborting child", ret);
        _exit(13);
    }

    // Step 5: Post-fork runtime initialization (OH IPC setup)
    runtime->onChildInit();

    // Step 6: Initialize adapter layer (OHEnvironment.initialize)
    JNIEnv* env = runtime->getJNIEnv();
    if (!env) {
        LOGE("JNIEnv is null after onChildInit – aborting child");
        _exit(14);
    }

    ret = initAdapterLayer(env);
    if (ret != 0) {
        LOGW("initAdapterLayer failed, ret=%d – continuing anyway", ret);
        // Non-fatal: the app may work without the adapter in some cases
    }

    // Step 7: Set process name for debugging (shows in ps output)
    if (!msg.procName.empty()) {
        prctl(PR_SET_NAME, msg.procName.c_str(), 0, 0, 0);
    }

    // Step 8: Launch the Android ActivityThread event loop
    LOGI("Launching ActivityThread for %s", msg.procName.c_str());
    launchActivityThread(env, msg);

    // Should never reach here – launchActivityThread enters an infinite loop
    LOGE("launchActivityThread returned unexpectedly – exiting");
    _exit(1);
}

// ---------------------------------------------------------------------------
// applyDac  –  set UID, GID, and supplementary groups
// ---------------------------------------------------------------------------
int ChildMain::applyDac(const SpawnMsg& msg) {
    LOGI("Applying DAC: uid=%d gid=%d gids_count=%zu",
         msg.uid, msg.gid, msg.gids.size());

    // Set supplementary groups first (requires root)
    if (!msg.gids.empty()) {
        // Convert int32_t vector to gid_t array
        std::vector<gid_t> gidArray(msg.gids.begin(), msg.gids.end());
        if (setgroups(gidArray.size(), gidArray.data()) < 0) {
            LOGE("setgroups(%zu groups) failed: %s",
                 gidArray.size(), strerror(errno));
            return -1;
        }
        LOGD("Set %zu supplementary groups", gidArray.size());
    } else {
        // Clear supplementary groups if none specified
        if (setgroups(0, nullptr) < 0) {
            LOGW("setgroups(0) failed: %s", strerror(errno));
            // Non-fatal on some configurations
        }
    }

    // Set primary GID (must be done before setuid to avoid permission issues)
    if (msg.gid >= 0) {
        if (setresgid(msg.gid, msg.gid, msg.gid) < 0) {
            LOGE("setresgid(%d) failed: %s", msg.gid, strerror(errno));
            return -1;
        }
        LOGD("Set GID to %d", msg.gid);
    }

    // Set UID (this drops root privileges – do this last)
    if (msg.uid >= 0) {
        if (setresuid(msg.uid, msg.uid, msg.uid) < 0) {
            LOGE("setresuid(%d) failed: %s", msg.uid, strerror(errno));
            return -1;
        }
        LOGD("Set UID to %d", msg.uid);
    }

    // Verify we actually dropped root
    if (msg.uid > 0 && getuid() == 0) {
        LOGE("Failed to drop root – uid is still 0");
        return -1;
    }

    // Disable ability to regain root via setuid binaries
    if (msg.uid > 0) {
        if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0) < 0) {
            LOGW("prctl(PR_SET_NO_NEW_PRIVS) failed: %s", strerror(errno));
            // Non-fatal
        }
    }

    LOGI("DAC applied: running as uid=%d gid=%d", getuid(), getgid());
    return 0;
}

// ---------------------------------------------------------------------------
// applySandbox  –  create mount namespace and set up filesystem isolation
// ---------------------------------------------------------------------------
int ChildMain::applySandbox(const SpawnMsg& msg) {
    // Skip sandbox if NO_SANDBOX flag is set (for debugging)
    if (msg.hasFlag(StartFlags::NO_SANDBOX)) {
        LOGW("Sandbox disabled by NO_SANDBOX flag");
        return 0;
    }

    LOGI("Setting up sandbox for %s", msg.bundleName.c_str());

    // TODO: Implement Android-specific sandbox mounts:
    //
    // 1. Create new mount namespace:
    //    unshare(CLONE_NEWNS)
    //
    // 2. Make root mount private to prevent propagation:
    //    mount("", "/", NULL, MS_REC | MS_PRIVATE, NULL)
    //
    // 3. Bind mount APK directory for app code access:
    //    mount("/data/app/<bundleName>/", "<sandbox>/app/", NULL, MS_BIND, NULL)
    //
    // 4. Bind mount app data directory:
    //    mount("/data/data/<bundleName>/", "<sandbox>/data/", NULL, MS_BIND, NULL)
    //
    // 5. Mount tmpfs for /dev and create minimal device nodes
    //
    // 6. Bind mount shared libraries:
    //    mount("/system/lib64/", "<sandbox>/system/lib64/", NULL, MS_BIND | MS_RDONLY, NULL)
    //
    // 7. Apply OH sandbox profile from JSON config
    //
    // In production, this links against OH appspawn sandbox library:
    //   - SetAppSandboxProperty(msg)
    //   - AppSpawnSandboxCfg_Parse(configPath)

    LOGD("Sandbox setup: TODO – filesystem isolation not yet implemented");
    LOGD("  APK path: %s", msg.apkPath.c_str());
    LOGD("  Native libs: %s", msg.nativeLibPaths.c_str());
    LOGD("  Bundle data: /data/data/%s/", msg.bundleName.c_str());

    return 0;
}

// ---------------------------------------------------------------------------
// applySELinux  –  set the SELinux security context for the process
// ---------------------------------------------------------------------------
int ChildMain::applySELinux(const SpawnMsg& msg) {
    // Determine the target SELinux context
    std::string context = msg.selinuxContext;
    if (context.empty()) {
        // Default context for Android app processes
        context = "u:r:android_app:s0";
    }

    LOGI("Setting SELinux context: %s", context.c_str());

    // TODO: Implement SELinux context transition:
    //
    // Option A: Write to /proc/self/attr/current (requires libselinux)
    //   int rc = setcon(context.c_str());
    //
    // Option B: Direct write to procfs
    //   int fd = open("/proc/self/attr/current", O_WRONLY);
    //   write(fd, context.c_str(), context.size());
    //   close(fd);
    //
    // The context string format is:
    //   user:role:type:sensitivity[:categories]
    //
    // For Android apps running on OH:
    //   - system_app: "u:r:system_app:s0"
    //   - platform_app: "u:r:platform_app:s0"
    //   - untrusted_app: "u:r:untrusted_app:s0:c<uid>,c<uid+256>"
    //
    // In production, link against libselinux:
    //   #include <selinux/selinux.h>
    //   setcon(context.c_str());

    LOGD("SELinux context: stub – transition to '%s' not yet implemented",
         context.c_str());

    return 0;
}

// ---------------------------------------------------------------------------
// applyAccessToken  –  set OH AccessToken for permission enforcement
// ---------------------------------------------------------------------------
int ChildMain::applyAccessToken(const SpawnMsg& msg) {
    if (msg.accessTokenIdEx == 0) {
        LOGD("No AccessToken specified, skipping");
        return 0;
    }

    LOGI("Setting AccessToken: id=0x%llx apl=%s",
         static_cast<unsigned long long>(msg.accessTokenIdEx),
         msg.apl.c_str());

    // TODO: Implement AccessToken setup:
    //
    // The OH AccessToken system provides per-process permission tokens.
    // Each app process receives a token ID from foundation during install.
    //
    // In production, link against libaccesstoken_sdk:
    //   #include "accesstoken_kit.h"
    //   #include "token_setproc.h"
    //
    //   // Set the access token for this process
    //   int ret = SetSelfTokenID(msg.accessTokenIdEx);
    //   if (ret != 0) {
    //       LOGE("SetSelfTokenID failed: %d", ret);
    //       return -1;
    //   }
    //
    // The APL (Application Permission Level) determines which permissions
    // the app can request:
    //   - "system_core": highest privilege (system services)
    //   - "system_basic": moderate privilege (system apps)
    //   - "normal": standard app permissions

    LOGD("AccessToken: stub – token 0x%llx not yet applied",
         static_cast<unsigned long long>(msg.accessTokenIdEx));

    return 0;
}

// ---------------------------------------------------------------------------
// initAdapterLayer  –  initialize the Android-OH adapter bridge
// ---------------------------------------------------------------------------
int ChildMain::initAdapterLayer(JNIEnv* env) {
    LOGI("Initializing adapter layer (OHEnvironment)");

    // Find the OHEnvironment class that provides the adapter initialization
    jclass ohEnvClass = env->FindClass("adapter/core/OHEnvironment");
    if (!ohEnvClass) {
        LOGW("OHEnvironment class not found – adapter layer not in classpath");
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        return -1;
    }

    // Get the static initialize() method
    jmethodID initMethod = env->GetStaticMethodID(
        ohEnvClass, "initialize", "()V");
    if (!initMethod) {
        LOGE("OHEnvironment.initialize() method not found");
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        env->DeleteLocalRef(ohEnvClass);
        return -1;
    }

    // Call OHEnvironment.initialize()
    // This loads liboh_adapter_bridge.so, sets up the OH service connections,
    // and registers the adapter service stubs
    env->CallStaticVoidMethod(ohEnvClass, initMethod);

    if (env->ExceptionCheck()) {
        LOGE("Exception during OHEnvironment.initialize():");
        env->ExceptionDescribe();
        env->ExceptionClear();
        env->DeleteLocalRef(ohEnvClass);
        return -1;
    }

    env->DeleteLocalRef(ohEnvClass);
    LOGI("Adapter layer initialized successfully");
    return 0;
}

// ---------------------------------------------------------------------------
// launchActivityThread  –  enter the Android app event loop
// ---------------------------------------------------------------------------
void ChildMain::launchActivityThread(JNIEnv* env, const SpawnMsg& msg) {
    // Determine the target class to launch
    std::string targetClass = msg.targetClass;
    if (targetClass.empty()) {
        targetClass = "android.app.ActivityThread";
    }

    LOGI("Launching target class: %s (proc=%s, sdkVersion=%d)",
         targetClass.c_str(), msg.procName.c_str(), msg.targetSdkVersion);

    // Call AppSpawnXInit.initChild(procName, targetClass, targetSdkVersion)
    // This Java method performs:
    //   1. Set the process name (Process.setArgV0)
    //   2. Call RuntimeInit.commonInit() for thread handlers, timezone, etc.
    //   3. Find the target class and invoke its main() method
    //   4. For ActivityThread, this enters Looper.loop() which blocks forever

    jclass initClass = env->FindClass("com/android/internal/os/AppSpawnXInit");
    if (!initClass) {
        LOGE("AppSpawnXInit class not found – cannot launch ActivityThread");
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }

        // Fallback: try to launch ActivityThread.main() directly
        LOGW("Attempting direct ActivityThread.main() launch as fallback");

        // Convert dotted class name to JNI format (replace . with /)
        std::string jniClassName = targetClass;
        for (char& c : jniClassName) {
            if (c == '.') c = '/';
        }

        jclass targetJniClass = env->FindClass(jniClassName.c_str());
        if (!targetJniClass) {
            LOGE("Cannot find class %s", jniClassName.c_str());
            if (env->ExceptionCheck()) {
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
            return;
        }

        jmethodID mainMethod = env->GetStaticMethodID(
            targetJniClass, "main", "([Ljava/lang/String;)V");
        if (!mainMethod) {
            LOGE("Cannot find main([String) in %s", jniClassName.c_str());
            if (env->ExceptionCheck()) {
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
            env->DeleteLocalRef(targetJniClass);
            return;
        }

        // Create empty String[] for main() argument
        jclass stringClass = env->FindClass("java/lang/String");
        jobjectArray emptyArgs = env->NewObjectArray(0, stringClass, nullptr);

        LOGI("Calling %s.main() directly", targetClass.c_str());
        env->CallStaticVoidMethod(targetJniClass, mainMethod, emptyArgs);

        if (env->ExceptionCheck()) {
            LOGE("Exception in %s.main():", targetClass.c_str());
            env->ExceptionDescribe();
            env->ExceptionClear();
        }

        env->DeleteLocalRef(emptyArgs);
        env->DeleteLocalRef(stringClass);
        env->DeleteLocalRef(targetJniClass);
        return;
    }

    // Use AppSpawnXInit.initChild for proper initialization
    jmethodID initChildMethod = env->GetStaticMethodID(
        initClass, "initChild",
        "(Ljava/lang/String;Ljava/lang/String;I)V");
    if (!initChildMethod) {
        LOGE("AppSpawnXInit.initChild() method not found");
        if (env->ExceptionCheck()) {
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
        env->DeleteLocalRef(initClass);
        return;
    }

    // Convert arguments to Java strings
    jstring jProcName = env->NewStringUTF(msg.procName.c_str());
    jstring jTargetClass = env->NewStringUTF(targetClass.c_str());

    LOGI("Calling AppSpawnXInit.initChild(\"%s\", \"%s\", %d)",
         msg.procName.c_str(), targetClass.c_str(), msg.targetSdkVersion);

    env->CallStaticVoidMethod(initClass, initChildMethod,
                              jProcName, jTargetClass,
                              static_cast<jint>(msg.targetSdkVersion));

    // If we get here, the event loop exited (unexpected)
    if (env->ExceptionCheck()) {
        LOGE("Exception in AppSpawnXInit.initChild():");
        env->ExceptionDescribe();
        env->ExceptionClear();
    } else {
        LOGE("AppSpawnXInit.initChild() returned without exception – "
             "event loop exited unexpectedly");
    }

    env->DeleteLocalRef(jProcName);
    env->DeleteLocalRef(jTargetClass);
    env->DeleteLocalRef(initClass);
}

} // namespace appspawnx
