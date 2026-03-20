/**
 * appspawn-x ART runtime wrapper.
 *
 * Manages the Android Runtime (ART) virtual machine lifecycle within
 * the appspawn-x daemon. Handles VM creation, framework class preloading
 * (analogous to Zygote), and per-child post-fork initialization.
 */

#pragma once

#include <jni.h>
#include <string>

namespace appspawnx {

class AppSpawnXRuntime {
public:
    AppSpawnXRuntime();
    ~AppSpawnXRuntime();

    // Phase 1: Create ART VM and register JNI methods
    // Returns 0 on success
    int startVm();

    // Phase 2: Call Java-side preload (classes, resources, libs, adapter)
    // Returns 0 on success
    int preload();

    // Called in child process after fork
    // For Option A: initialize OH IPC (no Android Binder)
    // For Option B: start Android Binder thread pool
    void onChildInit();

    JavaVM* getJavaVM() const { return javaVm_; }
    JNIEnv* getJNIEnv() const { return env_; }

private:
    JavaVM* javaVm_;
    JNIEnv* env_;

    // Cached Java class/method references for preload
    jclass appSpawnXInitClass_;
    jmethodID preloadMethod_;
    jmethodID initChildMethod_;

    int registerNativeMethods();
    int cacheJavaReferences();
};

} // namespace appspawnx
