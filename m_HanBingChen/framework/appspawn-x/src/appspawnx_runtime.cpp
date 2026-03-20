/**
 * appspawn-x ART runtime implementation.
 *
 * Creates and configures the ART virtual machine, preloads Android framework
 * classes and resources for fast fork-based app spawning, and handles
 * per-child post-fork initialization including OH IPC setup.
 */

#include "appspawnx_runtime.h"
#include "spawn_msg.h"

#include <cstdlib>
#include <cstring>
#include <dlfcn.h>
#include <string>
#include <vector>

// JniInvocation provides the abstraction to load libart.so at runtime
#include "nativehelper/JniInvocation.h"

namespace appspawnx {

// ---------------------------------------------------------------------------
// JNI_CreateJavaVM function pointer type (loaded from libart.so)
// ---------------------------------------------------------------------------
using JNI_CreateJavaVM_t = jint (*)(JavaVM**, JNIEnv**, void*);

// ---------------------------------------------------------------------------
// Helper: build a VM option entry
// ---------------------------------------------------------------------------
static JavaVMOption makeOption(const char* str) {
    JavaVMOption opt;
    opt.optionString = const_cast<char*>(str);
    opt.extraInfo = nullptr;
    return opt;
}

// ---------------------------------------------------------------------------
// AppSpawnXRuntime
// ---------------------------------------------------------------------------

AppSpawnXRuntime::AppSpawnXRuntime()
    : javaVm_(nullptr),
      env_(nullptr),
      appSpawnXInitClass_(nullptr),
      preloadMethod_(nullptr),
      initChildMethod_(nullptr) {
}

AppSpawnXRuntime::~AppSpawnXRuntime() {
    if (javaVm_) {
        LOGI("Destroying ART VM");
        javaVm_->DestroyJavaVM();
        javaVm_ = nullptr;
        env_ = nullptr;
    }
}

// ---------------------------------------------------------------------------
// startVm  –  create ART VM and register JNI natives
// ---------------------------------------------------------------------------
int AppSpawnXRuntime::startVm() {
    LOGI("Starting ART VM initialization");

    // Step 1: Use JniInvocation to locate and load libart.so
    JniInvocation jniInvocation;
    if (!jniInvocation.Init(nullptr /* default: libart.so */)) {
        LOGE("JniInvocation::Init failed – cannot load ART runtime library");
        return -1;
    }
    LOGI("libart.so loaded via JniInvocation");

    // Step 2: Collect VM options
    std::vector<JavaVMOption> options;

    // Heap sizing – suitable for a Zygote-like preload process
    options.push_back(makeOption("-Xms64m"));
    options.push_back(makeOption("-Xmx512m"));

    // Enable JIT compilation
    options.push_back(makeOption("-Xusejit:true"));

    // DEX2OAT thread configuration (match core count, cap at 4)
    options.push_back(makeOption("-Xdex2oat-threads:4"));

    // Boot classpath: read from environment variable set by init.rc
    const char* bootClassPath = getenv("BOOTCLASSPATH");
    std::string bootClassPathOpt;
    if (bootClassPath && bootClassPath[0] != '\0') {
        bootClassPathOpt = std::string("-Xbootclasspath:") + bootClassPath;
        options.push_back(makeOption(bootClassPathOpt.c_str()));
        LOGI("BOOTCLASSPATH set (%zu chars)", strlen(bootClassPath));
    } else {
        LOGW("BOOTCLASSPATH not set – VM may fail to find core classes");
    }

    // Image location for pre-compiled boot image
    const char* bootImage = getenv("DEX2OATBOOTCLASSPATH");
    std::string imageOpt;
    if (bootImage && bootImage[0] != '\0') {
        imageOpt = std::string("-Ximage:") + "/system/framework/boot.art";
        options.push_back(makeOption(imageOpt.c_str()));
    }

    // Disable verify for faster startup in development builds
    // Remove this in production
    const char* fastDev = getenv("APPSPAWNX_FAST_DEV");
    if (fastDev && strcmp(fastDev, "1") == 0) {
        options.push_back(makeOption("-Xverify:none"));
        LOGW("DEX verification disabled (dev mode)");
    }

    // GC tuning
    options.push_back(makeOption("-XX:HeapGrowthLimit=256m"));
    options.push_back(makeOption("-XX:HeapMinFree=512k"));
    options.push_back(makeOption("-XX:HeapMaxFree=8m"));
    options.push_back(makeOption("-XX:HeapTargetUtilization=0.75"));

    // Step 3: Fill in JavaVMInitArgs
    JavaVMInitArgs initArgs;
    initArgs.version = JNI_VERSION_1_6;
    initArgs.nOptions = static_cast<jint>(options.size());
    initArgs.options = options.data();
    initArgs.ignoreUnrecognized = JNI_TRUE;

    LOGI("Creating JavaVM with %d options", initArgs.nOptions);

    // Step 4: Create the VM
    jint rc = JNI_CreateJavaVM(&javaVm_, &env_, &initArgs);
    if (rc != JNI_OK) {
        LOGE("JNI_CreateJavaVM failed, rc=%d", rc);
        javaVm_ = nullptr;
        env_ = nullptr;
        return -1;
    }
    LOGI("JavaVM created successfully");

    // Step 5: Register native methods (framework JNI bindings)
    int ret = registerNativeMethods();
    if (ret != 0) {
        LOGE("registerNativeMethods failed, ret=%d", ret);
        return ret;
    }

    // Step 6: Cache Java class/method references for preload and child init
    ret = cacheJavaReferences();
    if (ret != 0) {
        LOGE("cacheJavaReferences failed, ret=%d", ret);
        return ret;
    }

    LOGI("ART VM initialization complete");
    return 0;
}

// ---------------------------------------------------------------------------
// registerNativeMethods  –  link framework JNI methods into the VM
// ---------------------------------------------------------------------------
int AppSpawnXRuntime::registerNativeMethods() {
    LOGI("Registering framework JNI native methods");

    // In a full build, libandroid_runtime.so provides AndroidRuntime::startReg()
    // which registers all framework JNI methods (Binder, Parcel, Canvas, etc.).
    //
    // Strategy: dlopen libandroid_runtime.so and call its registration entry point.
    void* libRuntime = dlopen("libandroid_runtime.so", RTLD_NOW);
    if (!libRuntime) {
        LOGW("Cannot load libandroid_runtime.so: %s", dlerror());
        LOGW("Framework JNI methods will not be available – "
             "only basic VM functionality");
        // Non-fatal: preload will catch missing classes
        return 0;
    }

    // The registration entry point used by AndroidRuntime
    // Signature: int register_jni_procs(const RegJNIRec array[], size_t count, JNIEnv* env)
    // We look for the exported AndroidRuntime::startReg instead
    using StartReg_t = int (*)(JNIEnv*);
    auto startReg = reinterpret_cast<StartReg_t>(
        dlsym(libRuntime, "_ZN7android14AndroidRuntime8startRegEP7_JNIEnv"));

    if (startReg) {
        int rc = startReg(env_);
        if (rc < 0) {
            LOGE("AndroidRuntime::startReg returned %d", rc);
            dlclose(libRuntime);
            return -1;
        }
        LOGI("Framework JNI methods registered via AndroidRuntime::startReg");
    } else {
        LOGW("AndroidRuntime::startReg symbol not found: %s", dlerror());
        LOGW("Attempting manual registration of essential JNI methods");

        // Manually register the minimum set of JNI methods needed for boot.
        // These are the registration functions exported by libandroid_runtime.
        struct RegEntry {
            const char* symbol;
            const char* name;
        };
        static const RegEntry essentials[] = {
            {"register_android_os_Binder",         "Binder"},
            {"register_android_os_Parcel",         "Parcel"},
            {"register_android_util_Log",          "Log"},
            {"register_android_content_res_AssetManager", "AssetManager"},
        };

        for (const auto& entry : essentials) {
            using RegFunc_t = int (*)(JNIEnv*);
            auto fn = reinterpret_cast<RegFunc_t>(dlsym(libRuntime, entry.symbol));
            if (fn) {
                int rc = fn(env_);
                if (rc < 0) {
                    LOGW("Failed to register %s JNI methods, rc=%d",
                         entry.name, rc);
                } else {
                    LOGD("Registered %s JNI methods", entry.name);
                }
            } else {
                LOGD("Symbol %s not found, skipping", entry.symbol);
            }
        }
    }

    // Keep libandroid_runtime loaded for the lifetime of the process
    // (do not dlclose – the JNI methods reference its code)
    LOGI("JNI registration complete");
    return 0;
}

// ---------------------------------------------------------------------------
// cacheJavaReferences  –  locate AppSpawnXInit class and preload/init methods
// ---------------------------------------------------------------------------
int AppSpawnXRuntime::cacheJavaReferences() {
    LOGI("Caching Java class/method references");

    // Find the AppSpawnXInit class that provides preload() and initChild()
    static const char* kClassName = "com/android/internal/os/AppSpawnXInit";

    jclass localClass = env_->FindClass(kClassName);
    if (!localClass) {
        LOGE("Cannot find class %s", kClassName);
        if (env_->ExceptionCheck()) {
            env_->ExceptionDescribe();
            env_->ExceptionClear();
        }
        // This is non-fatal during early development when the Java class
        // may not yet be compiled into the boot image
        LOGW("AppSpawnXInit not found – preload and initChild will be no-ops");
        appSpawnXInitClass_ = nullptr;
        preloadMethod_ = nullptr;
        initChildMethod_ = nullptr;
        return 0;
    }

    // Create a global reference so it survives across JNI frames
    appSpawnXInitClass_ = reinterpret_cast<jclass>(
        env_->NewGlobalRef(localClass));
    env_->DeleteLocalRef(localClass);

    if (!appSpawnXInitClass_) {
        LOGE("Failed to create global reference for %s", kClassName);
        return -1;
    }

    // Cache preload() – static void preload()
    preloadMethod_ = env_->GetStaticMethodID(
        appSpawnXInitClass_, "preload", "()V");
    if (!preloadMethod_) {
        LOGW("Method preload()V not found in %s", kClassName);
        if (env_->ExceptionCheck()) {
            env_->ExceptionDescribe();
            env_->ExceptionClear();
        }
    }

    // Cache initChild() – static void initChild(String procName, String targetClass, int sdkVersion)
    initChildMethod_ = env_->GetStaticMethodID(
        appSpawnXInitClass_, "initChild",
        "(Ljava/lang/String;Ljava/lang/String;I)V");
    if (!initChildMethod_) {
        LOGW("Method initChild(String,String,int)V not found in %s", kClassName);
        if (env_->ExceptionCheck()) {
            env_->ExceptionDescribe();
            env_->ExceptionClear();
        }
    }

    LOGI("Java references cached successfully");
    return 0;
}

// ---------------------------------------------------------------------------
// preload  –  invoke AppSpawnXInit.preload() to warm up the VM
// ---------------------------------------------------------------------------
int AppSpawnXRuntime::preload() {
    if (!appSpawnXInitClass_ || !preloadMethod_) {
        LOGW("Preload skipped – AppSpawnXInit class or preload method not available");
        return -1;
    }

    LOGI("Calling AppSpawnXInit.preload()...");
    env_->CallStaticVoidMethod(appSpawnXInitClass_, preloadMethod_);

    if (env_->ExceptionCheck()) {
        LOGE("Exception during preload:");
        env_->ExceptionDescribe();
        env_->ExceptionClear();
        return -1;
    }

    LOGI("Preload completed successfully");
    return 0;
}

// ---------------------------------------------------------------------------
// onChildInit  –  post-fork initialization in child process
// ---------------------------------------------------------------------------
void AppSpawnXRuntime::onChildInit() {
    LOGI("Child post-fork initialization starting");

    // Re-attach current thread to the VM if needed.
    // After fork(), only the forking thread exists in the child.
    // The JNIEnv from the parent is still valid for this thread.
    JNIEnv* childEnv = nullptr;
    jint rc = javaVm_->GetEnv(reinterpret_cast<void**>(&childEnv), JNI_VERSION_1_6);
    if (rc == JNI_EDETACHED) {
        rc = javaVm_->AttachCurrentThread(&childEnv, nullptr);
        if (rc != JNI_OK) {
            LOGE("Failed to re-attach thread to VM in child, rc=%d", rc);
            return;
        }
        env_ = childEnv;
        LOGD("Thread re-attached to VM in child process");
    } else if (rc == JNI_OK) {
        env_ = childEnv;
        LOGD("Thread already attached to VM in child process");
    } else {
        LOGE("GetEnv failed in child process, rc=%d", rc);
        return;
    }

    // Option A (default): Initialize OH IPC connection.
    // The child process communicates with OH system services via OH IPC
    // (samgr/softbus) rather than Android Binder. The adapter layer
    // (OHEnvironment.initialize) handles this setup later in initAdapterLayer().
    //
    // Option B (alternative): Start Android Binder thread pool.
    // This would be needed if the child must also serve as an Android Binder
    // server. Currently not required since all IPC goes through OH.

    LOGI("Child post-fork initialization complete (OH IPC mode)");
}

} // namespace appspawnx
