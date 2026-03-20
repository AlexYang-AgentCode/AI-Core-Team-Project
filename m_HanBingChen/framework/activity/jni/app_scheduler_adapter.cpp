/*
 * app_scheduler_adapter.cpp
 *
 * Reverse callback adapter implementation.
 * Receives OH AppMgrService callbacks via Binder and bridges them
 * to the Android IApplicationThread via JNI.
 *
 * Thread safety: All callbacks arrive on OH Binder threads.
 * JNIEnv is obtained via JavaVM->AttachCurrentThread for each call.
 */

#include "app_scheduler_adapter.h"

#include <android/log.h>
#include <cstdarg>

#define LOG_TAG "OH_AppSchedulerAdapter"
#define ALOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define ALOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN,  LOG_TAG, __VA_ARGS__)
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// Android process state constants
static constexpr int PROCESS_STATE_TOP = 2;
static constexpr int PROCESS_STATE_CACHED_EMPTY = 16;

namespace oh_adapter {

// ================================================================
// Construction / Destruction
// ================================================================

AppSchedulerAdapter::AppSchedulerAdapter(JavaVM* vm, jobject appThread)
    : jvm_(vm)
{
    ALOGI("AppSchedulerAdapter created");
    if (jvm_ == nullptr) {
        ALOGE("JavaVM is null, JNI bridging will not work");
        return;
    }
    JNIEnv* env = nullptr;
    bool needDetach = getJNIEnv(&env);
    if (env == nullptr) {
        ALOGE("Failed to obtain JNIEnv in constructor");
        return;
    }

    // Create global references so they survive across threads
    app_thread_ = env->NewGlobalRef(appThread);
    if (app_thread_ == nullptr) {
        ALOGE("Failed to create global ref for IApplicationThread");
    } else {
        jclass clazz = env->GetObjectClass(app_thread_);
        app_thread_class_ = static_cast<jclass>(env->NewGlobalRef(clazz));
        env->DeleteLocalRef(clazz);
        ALOGI("IApplicationThread global ref created successfully");
    }

    if (needDetach) {
        jvm_->DetachCurrentThread();
    }
}

AppSchedulerAdapter::~AppSchedulerAdapter()
{
    ALOGI("AppSchedulerAdapter destroyed");
    if (jvm_ == nullptr) {
        return;
    }
    JNIEnv* env = nullptr;
    bool needDetach = getJNIEnv(&env);
    if (env != nullptr) {
        if (app_thread_ != nullptr) {
            env->DeleteGlobalRef(app_thread_);
            app_thread_ = nullptr;
        }
        if (app_thread_class_ != nullptr) {
            env->DeleteGlobalRef(app_thread_class_);
            app_thread_class_ = nullptr;
        }
    }
    if (needDetach) {
        jvm_->DetachCurrentThread();
    }
}

// ================================================================
// JNI Helpers
// ================================================================

bool AppSchedulerAdapter::getJNIEnv(JNIEnv** env)
{
    *env = nullptr;
    if (jvm_ == nullptr) {
        return false;
    }

    // Check if current thread is already attached
    jint result = jvm_->GetEnv(reinterpret_cast<void**>(env), JNI_VERSION_1_6);
    if (result == JNI_OK) {
        return false; // Already attached, no need to detach
    }

    // Attach current thread (OH Binder thread) to JVM
    JavaVMAttachArgs args;
    args.version = JNI_VERSION_1_6;
    args.name = "OH_BinderThread";
    args.group = nullptr;

    result = jvm_->AttachCurrentThread(env, &args);
    if (result != JNI_OK) {
        ALOGE("AttachCurrentThread failed with error %d", result);
        *env = nullptr;
        return false;
    }
    return true; // Newly attached, caller should detach
}

void AppSchedulerAdapter::callJavaMethod(const char* methodName, const char* signature, ...)
{
    std::lock_guard<std::mutex> lock(jni_mutex_);

    if (app_thread_ == nullptr || app_thread_class_ == nullptr) {
        ALOGW("callJavaMethod(%s): IApplicationThread ref is null, skipping", methodName);
        return;
    }

    JNIEnv* env = nullptr;
    bool needDetach = getJNIEnv(&env);
    if (env == nullptr) {
        ALOGE("callJavaMethod(%s): Failed to obtain JNIEnv", methodName);
        return;
    }

    jmethodID method = env->GetMethodID(app_thread_class_, methodName, signature);
    if (method == nullptr) {
        ALOGW("callJavaMethod(%s): Method not found with signature %s", methodName, signature);
        env->ExceptionClear();
        if (needDetach) jvm_->DetachCurrentThread();
        return;
    }

    va_list args;
    va_start(args, signature);
    env->CallVoidMethodV(app_thread_, method, args);
    va_end(args);

    if (env->ExceptionCheck()) {
        ALOGE("callJavaMethod(%s): Java exception occurred", methodName);
        env->ExceptionDescribe();
        env->ExceptionClear();
    }

    if (needDetach) {
        jvm_->DetachCurrentThread();
    }
}

int AppSchedulerAdapter::mapMemoryLevel(int ohLevel)
{
    // OH memory levels -> Android TRIM_MEMORY_* constants
    // OH: 0=normal, 1=low, 2=critical
    switch (ohLevel) {
        case 0:  return 5;   // TRIM_MEMORY_RUNNING_MODERATE
        case 1:  return 10;  // TRIM_MEMORY_RUNNING_LOW
        case 2:  return 15;  // TRIM_MEMORY_RUNNING_CRITICAL
        default: return 5;   // Default to moderate
    }
}

// ================================================================
// Category 1: App Lifecycle
// ================================================================

bool AppSchedulerAdapter::ScheduleForegroundApplication()
{
    ALOGI("[BRIDGED] ScheduleForegroundApplication -> setProcessState(PROCESS_STATE_TOP)");
    callJavaMethod("setProcessState", "(I)V", static_cast<jint>(PROCESS_STATE_TOP));
    return true;
}

void AppSchedulerAdapter::ScheduleBackgroundApplication()
{
    ALOGI("[BRIDGED] ScheduleBackgroundApplication -> setProcessState(PROCESS_STATE_CACHED_EMPTY)");
    callJavaMethod("setProcessState", "(I)V", static_cast<jint>(PROCESS_STATE_CACHED_EMPTY));
}

void AppSchedulerAdapter::ScheduleTerminateApplication(bool isLastProcess)
{
    ALOGI("[BRIDGED] ScheduleTerminateApplication(isLastProcess=%d) -> scheduleExit/scheduleSuicide",
          isLastProcess);
    if (isLastProcess) {
        callJavaMethod("scheduleSuicide", "()V");
    } else {
        callJavaMethod("scheduleExit", "()V");
    }
}

void AppSchedulerAdapter::ScheduleProcessSecurityExit()
{
    ALOGI("[BRIDGED] ScheduleProcessSecurityExit -> scheduleSuicide");
    callJavaMethod("scheduleSuicide", "()V");
}

// ================================================================
// Category 2: Memory Management
// ================================================================

void AppSchedulerAdapter::ScheduleLowMemory()
{
    ALOGI("[BRIDGED] ScheduleLowMemory -> scheduleLowMemory");
    callJavaMethod("scheduleLowMemory", "()V");
}

void AppSchedulerAdapter::ScheduleShrinkMemory(const int level)
{
    int androidLevel = mapMemoryLevel(level);
    ALOGI("[BRIDGED] ScheduleShrinkMemory(oh=%d) -> scheduleTrimMemory(%d)", level, androidLevel);
    callJavaMethod("scheduleTrimMemory", "(I)V", static_cast<jint>(androidLevel));
}

void AppSchedulerAdapter::ScheduleMemoryLevel(int32_t level, bool isShellCall)
{
    int androidLevel = mapMemoryLevel(level);
    ALOGI("[BRIDGED] ScheduleMemoryLevel(oh=%d, shell=%d) -> scheduleTrimMemory(%d)",
          level, isShellCall, androidLevel);
    callJavaMethod("scheduleTrimMemory", "(I)V", static_cast<jint>(androidLevel));
}

void AppSchedulerAdapter::ScheduleHeapMemory(const int32_t pid,
                                              OHOS::AppExecFwk::MallocInfo &mallocInfo)
{
    ALOGD("[OH_ONLY] ScheduleHeapMemory(pid=%d) - OH malloc diagnostics, no direct Android equivalent",
          pid);
    // No Android equivalent - OH expects MallocInfo struct output
}

void AppSchedulerAdapter::ScheduleJsHeapMemory(OHOS::AppExecFwk::JsHeapDumpInfo &info)
{
    ALOGD("[OH_ONLY] ScheduleJsHeapMemory - ArkTS JS engine specific, no Android equivalent");
}

void AppSchedulerAdapter::ScheduleCjHeapMemory(OHOS::AppExecFwk::CjHeapDumpInfo &info)
{
    ALOGD("[OH_ONLY] ScheduleCjHeapMemory - CJ language specific, no Android equivalent");
}

// ================================================================
// Category 3: Application Launch
// ================================================================

void AppSchedulerAdapter::ScheduleLaunchApplication(const OHOS::AppExecFwk::AppLaunchData &data,
                                                     const OHOS::AppExecFwk::Configuration &config)
{
    ALOGI("[BRIDGED] ScheduleLaunchApplication -> bindApplication");

    // Extract bundle name and process info from OH launch data for logging
    // In Phase 1, the actual Android app binding is handled by the Android framework.
    // We synchronize the OH app state by setting the process state to foreground.
    std::lock_guard<std::mutex> lock(jni_mutex_);

    if (app_thread_ == nullptr || app_thread_class_ == nullptr) {
        ALOGW("ScheduleLaunchApplication: IApplicationThread ref is null");
        return;
    }

    JNIEnv* env = nullptr;
    bool needDetach = getJNIEnv(&env);
    if (env == nullptr) {
        ALOGE("ScheduleLaunchApplication: Failed to obtain JNIEnv");
        return;
    }

    // Set process state to TOP to indicate active app
    jmethodID setProcessState = env->GetMethodID(app_thread_class_, "setProcessState", "(I)V");
    if (setProcessState != nullptr) {
        env->CallVoidMethod(app_thread_, setProcessState, static_cast<jint>(PROCESS_STATE_TOP));
        if (env->ExceptionCheck()) {
            ALOGE("ScheduleLaunchApplication: Exception in setProcessState");
            env->ExceptionDescribe();
            env->ExceptionClear();
        }
    } else {
        ALOGW("ScheduleLaunchApplication: setProcessState method not found");
        env->ExceptionClear();
    }

    if (needDetach) {
        jvm_->DetachCurrentThread();
    }
}

void AppSchedulerAdapter::ScheduleUpdateApplicationInfoInstalled(
    const OHOS::AppExecFwk::ApplicationInfo &appInfo, const std::string &bundleName)
{
    ALOGD("[OH_ONLY] ScheduleUpdateApplicationInfoInstalled(bundle=%s) "
          "- logged, no direct bridge in Phase 1", bundleName.c_str());
}

void AppSchedulerAdapter::ScheduleAbilityStage(const OHOS::AppExecFwk::HapModuleInfo &hapModuleInfo)
{
    ALOGD("[OH_ONLY] ScheduleAbilityStage - OH module-level lifecycle, "
          "no direct Android AbilityStage concept");
}

// ================================================================
// Category 4: Ability Lifecycle
// ================================================================

void AppSchedulerAdapter::ScheduleLaunchAbility(const OHOS::AppExecFwk::AbilityInfo &info,
                                                 const OHOS::sptr<OHOS::IRemoteObject> &token,
                                                 const std::shared_ptr<OHOS::AAFwk::Want> &want,
                                                 int32_t abilityRecordId)
{
    ALOGI("[BRIDGED] ScheduleLaunchAbility(recordId=%d) "
          "-> scheduleTransaction(LaunchActivityItem)", abilityRecordId);

    // Bridge to Android IApplicationThread.scheduleTransaction with LaunchActivityItem.
    // The actual Activity launch transaction construction requires Android-side
    // ClientTransaction building which is done in the Java bridge layer.
    std::lock_guard<std::mutex> lock(jni_mutex_);

    if (app_thread_ == nullptr || app_thread_class_ == nullptr) {
        ALOGW("ScheduleLaunchAbility: IApplicationThread ref is null");
        return;
    }

    JNIEnv* env = nullptr;
    bool needDetach = getJNIEnv(&env);
    if (env == nullptr) {
        ALOGE("ScheduleLaunchAbility: Failed to obtain JNIEnv");
        return;
    }

    // Find the AppSchedulerBridge Java helper to construct the launch transaction
    jclass bridgeClass = env->FindClass("adapter/bridge/callback/AppSchedulerBridge");
    if (bridgeClass != nullptr) {
        jmethodID onLaunch = env->GetStaticMethodID(bridgeClass,
            "nativeOnScheduleLaunchAbility", "(Ljava/lang/Object;Ljava/lang/String;I)V");
        if (onLaunch != nullptr) {
            // Extract ability name for the Java bridge
            jstring abilityName = env->NewStringUTF(info.name.c_str());
            env->CallStaticVoidMethod(bridgeClass, onLaunch, app_thread_,
                                      abilityName, static_cast<jint>(abilityRecordId));
            env->DeleteLocalRef(abilityName);
            if (env->ExceptionCheck()) {
                ALOGE("ScheduleLaunchAbility: Java exception");
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
        } else {
            ALOGW("ScheduleLaunchAbility: nativeOnScheduleLaunchAbility not found, "
                  "falling back to log-only");
            env->ExceptionClear();
        }
        env->DeleteLocalRef(bridgeClass);
    } else {
        ALOGW("ScheduleLaunchAbility: AppSchedulerBridge class not found");
        env->ExceptionClear();
    }

    if (needDetach) {
        jvm_->DetachCurrentThread();
    }
}

void AppSchedulerAdapter::ScheduleCleanAbility(const OHOS::sptr<OHOS::IRemoteObject> &token,
                                                bool isCacheProcess)
{
    ALOGI("[BRIDGED] ScheduleCleanAbility(cache=%d) "
          "-> scheduleTransaction(DestroyActivityItem)", isCacheProcess);

    // Bridge to Android IApplicationThread.scheduleTransaction with DestroyActivityItem.
    // Similar to ScheduleLaunchAbility, the actual transaction construction is
    // delegated to the Java bridge layer.
    std::lock_guard<std::mutex> lock(jni_mutex_);

    if (app_thread_ == nullptr || app_thread_class_ == nullptr) {
        ALOGW("ScheduleCleanAbility: IApplicationThread ref is null");
        return;
    }

    JNIEnv* env = nullptr;
    bool needDetach = getJNIEnv(&env);
    if (env == nullptr) {
        ALOGE("ScheduleCleanAbility: Failed to obtain JNIEnv");
        return;
    }

    jclass bridgeClass = env->FindClass("adapter/bridge/callback/AppSchedulerBridge");
    if (bridgeClass != nullptr) {
        jmethodID onClean = env->GetStaticMethodID(bridgeClass,
            "nativeOnScheduleCleanAbility", "(Ljava/lang/Object;Z)V");
        if (onClean != nullptr) {
            env->CallStaticVoidMethod(bridgeClass, onClean, app_thread_,
                                      static_cast<jboolean>(isCacheProcess));
            if (env->ExceptionCheck()) {
                ALOGE("ScheduleCleanAbility: Java exception");
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
        } else {
            ALOGW("ScheduleCleanAbility: nativeOnScheduleCleanAbility not found");
            env->ExceptionClear();
        }
        env->DeleteLocalRef(bridgeClass);
    } else {
        ALOGW("ScheduleCleanAbility: AppSchedulerBridge class not found");
        env->ExceptionClear();
    }

    if (needDetach) {
        jvm_->DetachCurrentThread();
    }
}

// ================================================================
// Category 5: Configuration / Profile
// ================================================================

void AppSchedulerAdapter::ScheduleConfigurationUpdated(
    const OHOS::AppExecFwk::Configuration &config,
    OHOS::AppExecFwk::ConfigUpdateReason reason)
{
    ALOGI("[BRIDGED] ScheduleConfigurationUpdated(reason=%d) "
          "-> scheduleConfigurationChanged", static_cast<int>(reason));

    // Bridge to IApplicationThread.scheduleConfigurationChanged.
    // OH Configuration fields are converted to Android Configuration in the Java layer.
    std::lock_guard<std::mutex> lock(jni_mutex_);

    if (app_thread_ == nullptr || app_thread_class_ == nullptr) {
        ALOGW("ScheduleConfigurationUpdated: IApplicationThread ref is null");
        return;
    }

    JNIEnv* env = nullptr;
    bool needDetach = getJNIEnv(&env);
    if (env == nullptr) {
        ALOGE("ScheduleConfigurationUpdated: Failed to obtain JNIEnv");
        return;
    }

    jclass bridgeClass = env->FindClass("adapter/bridge/callback/AppSchedulerBridge");
    if (bridgeClass != nullptr) {
        jmethodID onConfig = env->GetStaticMethodID(bridgeClass,
            "nativeOnScheduleConfigurationUpdated", "(Ljava/lang/Object;Ljava/lang/String;)V");
        if (onConfig != nullptr) {
            // Serialize config to string for Java-side parsing
            std::string configStr = config.GetName();
            jstring jConfigStr = env->NewStringUTF(configStr.c_str());
            env->CallStaticVoidMethod(bridgeClass, onConfig, app_thread_, jConfigStr);
            env->DeleteLocalRef(jConfigStr);
            if (env->ExceptionCheck()) {
                ALOGE("ScheduleConfigurationUpdated: Java exception");
                env->ExceptionDescribe();
                env->ExceptionClear();
            }
        } else {
            ALOGW("ScheduleConfigurationUpdated: native method not found");
            env->ExceptionClear();
        }
        env->DeleteLocalRef(bridgeClass);
    } else {
        ALOGW("ScheduleConfigurationUpdated: AppSchedulerBridge class not found");
        env->ExceptionClear();
    }

    if (needDetach) {
        jvm_->DetachCurrentThread();
    }
}

void AppSchedulerAdapter::ScheduleProfileChanged(const OHOS::AppExecFwk::Profile &profile)
{
    ALOGD("[OH_ONLY] ScheduleProfileChanged - OH Profile, partial Configuration mapping");
}

// ================================================================
// Category 6: Service / Process
// ================================================================

void AppSchedulerAdapter::ScheduleAcceptWant(const OHOS::AAFwk::Want &want,
                                              const std::string &moduleName)
{
    ALOGD("[OH_ONLY] ScheduleAcceptWant(module=%s) - OH specified process, "
          "approximate bindService mapping", moduleName.c_str());
}

void AppSchedulerAdapter::SchedulePrepareTerminate(const std::string &moduleName)
{
    ALOGD("[OH_ONLY] SchedulePrepareTerminate(module=%s) - "
          "OH module terminate, Android uses onDestroy", moduleName.c_str());
}

void AppSchedulerAdapter::ScheduleNewProcessRequest(const OHOS::AAFwk::Want &want,
                                                     const std::string &moduleName)
{
    ALOGD("[OH_ONLY] ScheduleNewProcessRequest(module=%s) - "
          "OH new process request, logged only", moduleName.c_str());
}

// ================================================================
// Category 7: Hot Fix / Quick Fix (OH_ONLY)
// ================================================================

int32_t AppSchedulerAdapter::ScheduleNotifyLoadRepairPatch(
    const std::string &bundleName,
    const OHOS::sptr<OHOS::AppExecFwk::IQuickFixCallback> &callback,
    const int32_t recordId)
{
    ALOGD("[OH_ONLY] ScheduleNotifyLoadRepairPatch(bundle=%s, record=%d) - "
          "OH hot-fix, no Android equivalent", bundleName.c_str(), recordId);
    return 0;
}

int32_t AppSchedulerAdapter::ScheduleNotifyHotReloadPage(
    const OHOS::sptr<OHOS::AppExecFwk::IQuickFixCallback> &callback,
    const int32_t recordId)
{
    ALOGD("[OH_ONLY] ScheduleNotifyHotReloadPage(record=%d) - "
          "OH hot reload, no Android equivalent", recordId);
    return 0;
}

int32_t AppSchedulerAdapter::ScheduleNotifyUnLoadRepairPatch(
    const std::string &bundleName,
    const OHOS::sptr<OHOS::AppExecFwk::IQuickFixCallback> &callback,
    const int32_t recordId)
{
    ALOGD("[OH_ONLY] ScheduleNotifyUnLoadRepairPatch(bundle=%s, record=%d) - "
          "OH hot-fix, no Android equivalent", bundleName.c_str(), recordId);
    return 0;
}

// ================================================================
// Category 8: Fault / Debug
// ================================================================

int32_t AppSchedulerAdapter::ScheduleNotifyAppFault(const OHOS::AppExecFwk::FaultData &faultData)
{
    ALOGD("[OH_ONLY] ScheduleNotifyAppFault - OH fault notification, logged only");
    return 0;
}

int32_t AppSchedulerAdapter::ScheduleChangeAppGcState(int32_t state, uint64_t tid)
{
    ALOGD("[OH_ONLY] ScheduleChangeAppGcState(state=%d, tid=%llu) - "
          "OH NativeEngine GC, Android uses ART GC",
          state, static_cast<unsigned long long>(tid));
    return 0;
}

void AppSchedulerAdapter::AttachAppDebug(bool isDebugFromLocal)
{
    ALOGD("[OH_ONLY] AttachAppDebug(local=%d) - OH debug attach, mechanism differs from Android",
          isDebugFromLocal);
}

void AppSchedulerAdapter::DetachAppDebug()
{
    ALOGD("[OH_ONLY] DetachAppDebug - no Android detach equivalent");
}

// ================================================================
// Category 9: IPC / FFRT / ArkWeb Dump (OH_ONLY)
// ================================================================

int32_t AppSchedulerAdapter::ScheduleDumpIpcStart(std::string &result)
{
    ALOGD("[OH_ONLY] ScheduleDumpIpcStart - OH IPC diagnostics, no Android equivalent");
    result = "Not supported in adapter mode";
    return 0;
}

int32_t AppSchedulerAdapter::ScheduleDumpIpcStop(std::string &result)
{
    ALOGD("[OH_ONLY] ScheduleDumpIpcStop - OH IPC diagnostics, no Android equivalent");
    result = "Not supported in adapter mode";
    return 0;
}

int32_t AppSchedulerAdapter::ScheduleDumpIpcStat(std::string &result)
{
    ALOGD("[OH_ONLY] ScheduleDumpIpcStat - OH IPC diagnostics, no Android equivalent");
    result = "Not supported in adapter mode";
    return 0;
}

void AppSchedulerAdapter::ScheduleCacheProcess()
{
    ALOGD("[OH_ONLY] ScheduleCacheProcess - OH process cache, Android uses oom_adj");
}

int32_t AppSchedulerAdapter::ScheduleDumpFfrt(std::string &result)
{
    ALOGD("[OH_ONLY] ScheduleDumpFfrt - OH FFRT diagnostics, no Android equivalent");
    result = "Not supported in adapter mode";
    return 0;
}

int32_t AppSchedulerAdapter::ScheduleDumpArkWeb(const std::string &customArgs, std::string &result)
{
    ALOGD("[OH_ONLY] ScheduleDumpArkWeb - OH ArkWeb diagnostics, no Android equivalent");
    result = "Not supported in adapter mode";
    return 0;
}

void AppSchedulerAdapter::ScheduleClearPageStack()
{
    ALOGD("[OH_ONLY] ScheduleClearPageStack - OH recovery specific");
}

void AppSchedulerAdapter::SetWatchdogBackgroundStatus(bool status)
{
    ALOGD("[OH_ONLY] SetWatchdogBackgroundStatus(status=%d) - "
          "OH watchdog, Android uses ANR mechanism", status);
}

void AppSchedulerAdapter::OnLoadAbilityFinished(uint64_t callbackId, int32_t pid)
{
    ALOGD("[OH_ONLY] OnLoadAbilityFinished(callbackId=%llu, pid=%d) - "
          "OH ability load completion callback",
          static_cast<unsigned long long>(callbackId), pid);
}

}  // namespace oh_adapter
