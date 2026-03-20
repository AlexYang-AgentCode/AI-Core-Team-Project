/*
 * ability_scheduler_adapter.cpp
 *
 * Reverse callback adapter implementation.
 * Bridges OH AbilitySchedulerStub virtual calls to Java IApplicationThread via JNI.
 */

#include "ability_scheduler_adapter.h"

#include <android/log.h>
#include <cstdarg>

#define LOG_TAG "OH_AbilitySchedAdapter"
#define ALOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace oh_adapter {

// ============================================================
// Construction / Destruction
// ============================================================

AbilitySchedulerAdapter::AbilitySchedulerAdapter(JavaVM* jvm, jobject appThread)
    : jvm_(jvm)
{
    JNIEnv* env = getJNIEnv();
    if (!env) {
        ALOGE("Failed to get JNIEnv in constructor");
        return;
    }

    // Store a global reference to the Android IApplicationThread.Stub
    mApplicationThread_ = env->NewGlobalRef(appThread);

    // Create the Java-side AbilitySchedulerBridge and cache a global ref.
    // AbilitySchedulerBridge(Object applicationThread)
    // The native-only path uses reflection-based dispatch on the Java side.
    jclass bridgeCls = env->FindClass(
        "adapter/bridge/callback/AbilitySchedulerBridge");
    if (bridgeCls) {
        bridgeClass_ = reinterpret_cast<jclass>(env->NewGlobalRef(bridgeCls));
        jmethodID ctor = env->GetMethodID(bridgeCls, "<init>",
            "(Ljava/lang/Object;)V");
        if (ctor) {
            jobject local = env->NewObject(bridgeCls, ctor, mApplicationThread_);
            if (local) {
                bridgeObj_ = env->NewGlobalRef(local);
                env->DeleteLocalRef(local);
            }
        }
        env->DeleteLocalRef(bridgeCls);
    }

    if (!bridgeObj_) {
        ALOGW("AbilitySchedulerBridge Java object could not be created; "
              "JNI calls will go directly to IApplicationThread");
    }

    ALOGI("AbilitySchedulerAdapter created");
}

AbilitySchedulerAdapter::~AbilitySchedulerAdapter()
{
    JNIEnv* env = getJNIEnv();
    if (env) {
        if (mApplicationThread_) {
            env->DeleteGlobalRef(mApplicationThread_);
        }
        if (bridgeObj_) {
            env->DeleteGlobalRef(bridgeObj_);
        }
        if (bridgeClass_) {
            env->DeleteGlobalRef(bridgeClass_);
        }
    }
    mApplicationThread_ = nullptr;
    bridgeObj_ = nullptr;
    bridgeClass_ = nullptr;

    ALOGI("AbilitySchedulerAdapter destroyed");
}

// ============================================================
// JNI Helpers
// ============================================================

JNIEnv* AbilitySchedulerAdapter::getJNIEnv()
{
    if (!jvm_) {
        ALOGE("JavaVM is null");
        return nullptr;
    }

    JNIEnv* env = nullptr;
    jint status = jvm_->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    if (status == JNI_EDETACHED) {
        JavaVMAttachArgs args;
        args.version = JNI_VERSION_1_6;
        args.name = "OH_AbilitySchedAdapter";
        args.group = nullptr;
        if (jvm_->AttachCurrentThread(&env, &args) != JNI_OK) {
            ALOGE("AttachCurrentThread failed");
            return nullptr;
        }
    } else if (status != JNI_OK) {
        ALOGE("GetEnv failed with status %d", status);
        return nullptr;
    }
    return env;
}

void AbilitySchedulerAdapter::callJavaVoidMethod(const char* methodName,
                                                  const char* sig, ...)
{
    std::lock_guard<std::mutex> lock(jniMutex_);
    JNIEnv* env = getJNIEnv();
    if (!env || !bridgeObj_ || !bridgeClass_) {
        ALOGW("callJavaVoidMethod(%s): JNI not ready, skipping", methodName);
        return;
    }

    jmethodID mid = env->GetMethodID(bridgeClass_, methodName, sig);
    if (!mid) {
        ALOGE("Method not found: %s %s", methodName, sig);
        env->ExceptionClear();
        return;
    }

    va_list args;
    va_start(args, sig);
    env->CallVoidMethodV(bridgeObj_, mid, args);
    va_end(args);

    if (env->ExceptionCheck()) {
        ALOGE("Java exception in %s", methodName);
        env->ExceptionDescribe();
        env->ExceptionClear();
    }
}

jboolean AbilitySchedulerAdapter::callJavaBooleanMethod(const char* methodName,
                                                         const char* sig, ...)
{
    std::lock_guard<std::mutex> lock(jniMutex_);
    JNIEnv* env = getJNIEnv();
    if (!env || !bridgeObj_ || !bridgeClass_) {
        ALOGW("callJavaBooleanMethod(%s): JNI not ready", methodName);
        return JNI_FALSE;
    }

    jmethodID mid = env->GetMethodID(bridgeClass_, methodName, sig);
    if (!mid) {
        ALOGE("Method not found: %s %s", methodName, sig);
        env->ExceptionClear();
        return JNI_FALSE;
    }

    va_list args;
    va_start(args, sig);
    jboolean result = env->CallBooleanMethodV(bridgeObj_, mid, args);
    va_end(args);

    if (env->ExceptionCheck()) {
        ALOGE("Java exception in %s", methodName);
        env->ExceptionDescribe();
        env->ExceptionClear();
        return JNI_FALSE;
    }
    return result;
}

jint AbilitySchedulerAdapter::callJavaIntMethod(const char* methodName,
                                                 const char* sig, ...)
{
    std::lock_guard<std::mutex> lock(jniMutex_);
    JNIEnv* env = getJNIEnv();
    if (!env || !bridgeObj_ || !bridgeClass_) {
        ALOGW("callJavaIntMethod(%s): JNI not ready", methodName);
        return -1;
    }

    jmethodID mid = env->GetMethodID(bridgeClass_, methodName, sig);
    if (!mid) {
        ALOGE("Method not found: %s %s", methodName, sig);
        env->ExceptionClear();
        return -1;
    }

    va_list args;
    va_start(args, sig);
    jint result = env->CallIntMethodV(bridgeObj_, mid, args);
    va_end(args);

    if (env->ExceptionCheck()) {
        ALOGE("Java exception in %s", methodName);
        env->ExceptionDescribe();
        env->ExceptionClear();
        return -1;
    }
    return result;
}

std::string AbilitySchedulerAdapter::wantToJson(const OHOS::AAFwk::Want& want)
{
    // Serialize OH Want to JSON for passing through JNI.
    // Full implementation would use Want::ToJson() or manual serialization
    // of action, entity, uri, bundle, etc.
    // Placeholder: use Want::ToString() which gives a parseable representation.
    return want.ToString();
}

std::string AbilitySchedulerAdapter::pacMapToJson(const OHOS::AppExecFwk::PacMap& pacMap)
{
    // Serialize OH PacMap to JSON for passing through JNI.
    // Full implementation would iterate PacMap entries and build JSON.
    return "{}";
}

// ============================================================
// Category 1: Ability Lifecycle  [BRIDGED]
// ============================================================

bool AbilitySchedulerAdapter::ScheduleAbilityTransaction(
    const OHOS::AAFwk::Want& want,
    const OHOS::AAFwk::LifeCycleStateInfo& targetState,
    sptr<OHOS::AAFwk::SessionInfo> sessionInfo)
{
    // [BRIDGED] ScheduleAbilityTransaction -> scheduleTransaction(LifecycleItem)
    // OH lifecycle states: INITIAL(0), INACTIVE(2), BACKGROUND_NEW(4), FOREGROUND_NEW(5)
    // Maps to Android: LaunchActivityItem, PauseActivityItem, StopActivityItem, ResumeActivityItem
    ALOGI("[BRIDGED] ScheduleAbilityTransaction: targetState=%d, isNewWant=%d",
          targetState.state, targetState.isNewWant);

    std::string wantJson = wantToJson(want);
    JNIEnv* env = getJNIEnv();
    if (!env) return false;

    jstring jWantJson = env->NewStringUTF(wantJson.c_str());
    callJavaVoidMethod("onScheduleAbilityTransaction",
                       "(Ljava/lang/String;IZ)V",
                       jWantJson,
                       static_cast<jint>(targetState.state),
                       static_cast<jboolean>(targetState.isNewWant));
    env->DeleteLocalRef(jWantJson);
    return true;
}

void AbilitySchedulerAdapter::ScheduleShareData(const int32_t& uniqueId)
{
    // [BRIDGED] ScheduleShareData -> Activity result mechanism
    ALOGI("[BRIDGED] ScheduleShareData: uniqueId=%d", uniqueId);
    callJavaVoidMethod("onScheduleShareData", "(I)V",
                       static_cast<jint>(uniqueId));
}

void AbilitySchedulerAdapter::SendResult(int requestCode, int resultCode,
                                          const OHOS::AAFwk::Want& resultWant)
{
    // [BRIDGED] SendResult -> IApplicationThread.scheduleTransaction(ActivityResultItem)
    ALOGI("[BRIDGED] SendResult: requestCode=%d, resultCode=%d", requestCode, resultCode);

    std::string wantJson = wantToJson(resultWant);
    JNIEnv* env = getJNIEnv();
    if (!env) return;

    jstring jWantJson = env->NewStringUTF(wantJson.c_str());
    callJavaVoidMethod("onSendResult", "(IILjava/lang/String;)V",
                       static_cast<jint>(requestCode),
                       static_cast<jint>(resultCode),
                       jWantJson);
    env->DeleteLocalRef(jWantJson);
}

bool AbilitySchedulerAdapter::SchedulePrepareTerminateAbility()
{
    // [PARTIAL] No direct Android equivalent; allow termination by default.
    ALOGI("[PARTIAL] SchedulePrepareTerminateAbility");
    return callJavaBooleanMethod("onSchedulePrepareTerminateAbility", "()Z");
}

void AbilitySchedulerAdapter::ScheduleSaveAbilityState()
{
    // [BRIDGED] ScheduleSaveAbilityState -> scheduleTransaction(SaveStateItem)
    ALOGI("[BRIDGED] ScheduleSaveAbilityState");
    callJavaVoidMethod("onScheduleSaveAbilityState", "()V");
}

void AbilitySchedulerAdapter::ScheduleRestoreAbilityState(
    const OHOS::AppExecFwk::PacMap& inState)
{
    // [BRIDGED] ScheduleRestoreAbilityState -> LaunchActivityItem with savedInstanceState
    ALOGI("[BRIDGED] ScheduleRestoreAbilityState");

    std::string stateJson = pacMapToJson(inState);
    JNIEnv* env = getJNIEnv();
    if (!env) return;

    jstring jStateJson = env->NewStringUTF(stateJson.c_str());
    callJavaVoidMethod("onScheduleRestoreAbilityState",
                       "(Ljava/lang/String;)V", jStateJson);
    env->DeleteLocalRef(jStateJson);
}

// ============================================================
// Category 2: Service Connection  [BRIDGED]
// ============================================================

void AbilitySchedulerAdapter::ScheduleConnectAbility(const OHOS::AAFwk::Want& want)
{
    // [BRIDGED] ScheduleConnectAbility -> IApplicationThread.scheduleBindService
    ALOGI("[BRIDGED] ScheduleConnectAbility");

    std::string wantJson = wantToJson(want);
    JNIEnv* env = getJNIEnv();
    if (!env) return;

    jstring jWantJson = env->NewStringUTF(wantJson.c_str());
    callJavaVoidMethod("onScheduleConnectAbility",
                       "(Ljava/lang/String;)V", jWantJson);
    env->DeleteLocalRef(jWantJson);
}

void AbilitySchedulerAdapter::ScheduleDisconnectAbility(const OHOS::AAFwk::Want& want)
{
    // [BRIDGED] ScheduleDisconnectAbility -> IApplicationThread.scheduleUnbindService
    ALOGI("[BRIDGED] ScheduleDisconnectAbility");

    std::string wantJson = wantToJson(want);
    JNIEnv* env = getJNIEnv();
    if (!env) return;

    jstring jWantJson = env->NewStringUTF(wantJson.c_str());
    callJavaVoidMethod("onScheduleDisconnectAbility",
                       "(Ljava/lang/String;)V", jWantJson);
    env->DeleteLocalRef(jWantJson);
}

void AbilitySchedulerAdapter::ScheduleCommandAbility(const OHOS::AAFwk::Want& want,
                                                      bool restart, int startId)
{
    // [BRIDGED] ScheduleCommandAbility -> IApplicationThread.scheduleServiceArgs
    ALOGI("[BRIDGED] ScheduleCommandAbility: restart=%d, startId=%d", restart, startId);

    std::string wantJson = wantToJson(want);
    JNIEnv* env = getJNIEnv();
    if (!env) return;

    jstring jWantJson = env->NewStringUTF(wantJson.c_str());
    callJavaVoidMethod("onScheduleCommandAbility",
                       "(Ljava/lang/String;ZI)V",
                       jWantJson,
                       static_cast<jboolean>(restart),
                       static_cast<jint>(startId));
    env->DeleteLocalRef(jWantJson);
}

void AbilitySchedulerAdapter::ScheduleCommandAbilityWindow(
    const OHOS::AAFwk::Want& want,
    const sptr<OHOS::AAFwk::SessionInfo>& sessionInfo,
    OHOS::AAFwk::WindowCommand winCmd)
{
    // [PARTIAL] ScheduleCommandAbilityWindow -> scheduleServiceArgs + window handling
    ALOGI("[PARTIAL] ScheduleCommandAbilityWindow: winCmd=%d",
          static_cast<int>(winCmd));

    std::string wantJson = wantToJson(want);
    JNIEnv* env = getJNIEnv();
    if (!env) return;

    jstring jWantJson = env->NewStringUTF(wantJson.c_str());
    callJavaVoidMethod("onScheduleCommandAbilityWindow",
                       "(Ljava/lang/String;I)V",
                       jWantJson,
                       static_cast<jint>(winCmd));
    env->DeleteLocalRef(jWantJson);
}

// ============================================================
// Category 3: Data Operations  [BRIDGED -> ContentProvider]
// ============================================================

std::vector<std::string> AbilitySchedulerAdapter::GetFileTypes(
    const OHOS::Uri& uri, const std::string& mimeTypeFilter)
{
    // [PARTIAL] GetFileTypes -> ContentProvider.getStreamTypes
    ALOGI("[PARTIAL] GetFileTypes: uri=%s, filter=%s",
          uri.ToString().c_str(), mimeTypeFilter.c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return {};

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    jstring jFilter = env->NewStringUTF(mimeTypeFilter.c_str());
    callJavaVoidMethod("onGetFileTypes",
                       "(Ljava/lang/String;Ljava/lang/String;)V",
                       jUri, jFilter);
    env->DeleteLocalRef(jUri);
    env->DeleteLocalRef(jFilter);

    // TODO: Parse Java return value into vector<string>
    return {};
}

int AbilitySchedulerAdapter::OpenFile(const OHOS::Uri& uri, const std::string& mode)
{
    // [PARTIAL] OpenFile -> ContentProvider.openFile
    ALOGI("[PARTIAL] OpenFile: uri=%s, mode=%s", uri.ToString().c_str(), mode.c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return -1;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    jstring jMode = env->NewStringUTF(mode.c_str());
    callJavaVoidMethod("onOpenFile",
                       "(Ljava/lang/String;Ljava/lang/String;)V",
                       jUri, jMode);
    env->DeleteLocalRef(jUri);
    env->DeleteLocalRef(jMode);

    // TODO: Return actual file descriptor from Java side
    return -1;
}

int AbilitySchedulerAdapter::OpenRawFile(const OHOS::Uri& uri, const std::string& mode)
{
    // [PARTIAL] OpenRawFile -> ContentProvider.openFile (raw variant)
    ALOGI("[PARTIAL] OpenRawFile: uri=%s, mode=%s", uri.ToString().c_str(), mode.c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return -1;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    jstring jMode = env->NewStringUTF(mode.c_str());
    callJavaVoidMethod("onOpenFile",
                       "(Ljava/lang/String;Ljava/lang/String;)V",
                       jUri, jMode);
    env->DeleteLocalRef(jUri);
    env->DeleteLocalRef(jMode);

    return -1;
}

int AbilitySchedulerAdapter::Insert(const OHOS::Uri& uri,
                                     const OHOS::NativeRdb::ValuesBucket& value)
{
    // [PARTIAL] Insert -> ContentProvider.insert
    ALOGI("[PARTIAL] Insert: uri=%s", uri.ToString().c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return -1;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onInsert", "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    // TODO: Return actual inserted row index from Java
    return -1;
}

int AbilitySchedulerAdapter::Update(const OHOS::Uri& uri,
                                     const OHOS::NativeRdb::ValuesBucket& value,
                                     const OHOS::NativeRdb::DataAbilityPredicates& predicates)
{
    // [PARTIAL] Update -> ContentProvider.update
    ALOGI("[PARTIAL] Update: uri=%s", uri.ToString().c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return -1;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onUpdate", "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    return 0;
}

int AbilitySchedulerAdapter::Delete(const OHOS::Uri& uri,
                                     const OHOS::NativeRdb::DataAbilityPredicates& predicates)
{
    // [PARTIAL] Delete -> ContentProvider.delete
    ALOGI("[PARTIAL] Delete: uri=%s", uri.ToString().c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return -1;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onDelete", "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    return 0;
}

std::shared_ptr<OHOS::NativeRdb::AbsSharedResultSet> AbilitySchedulerAdapter::Query(
    const OHOS::Uri& uri,
    std::vector<std::string>& columns,
    const OHOS::NativeRdb::DataAbilityPredicates& predicates)
{
    // [PARTIAL] Query -> ContentProvider.query
    ALOGI("[PARTIAL] Query: uri=%s", uri.ToString().c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return nullptr;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onQuery", "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    // TODO: Convert Android Cursor to OH AbsSharedResultSet
    return nullptr;
}

std::string AbilitySchedulerAdapter::GetType(const OHOS::Uri& uri)
{
    // [PARTIAL] GetType -> ContentProvider.getType
    ALOGI("[PARTIAL] GetType: uri=%s", uri.ToString().c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return "";

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onGetType", "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    // TODO: Return actual MIME type from Java
    return "";
}

bool AbilitySchedulerAdapter::Reload(const OHOS::Uri& uri,
                                      const OHOS::AppExecFwk::PacMap& extras)
{
    // [PARTIAL] Reload -> ContentResolver.notifyChange (no direct equivalent)
    ALOGI("[PARTIAL] Reload: uri=%s", uri.ToString().c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return false;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onReload", "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    return true;
}

int AbilitySchedulerAdapter::BatchInsert(
    const OHOS::Uri& uri,
    const std::vector<OHOS::NativeRdb::ValuesBucket>& values)
{
    // [PARTIAL] BatchInsert -> ContentProvider.bulkInsert
    ALOGI("[PARTIAL] BatchInsert: uri=%s, count=%zu",
          uri.ToString().c_str(), values.size());

    JNIEnv* env = getJNIEnv();
    if (!env) return -1;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onBatchInsert", "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    return 0;
}

std::shared_ptr<OHOS::AppExecFwk::PacMap> AbilitySchedulerAdapter::Call(
    const OHOS::Uri& uri, const std::string& method,
    const std::string& arg, const OHOS::AppExecFwk::PacMap& pacMap)
{
    // [PARTIAL] Call -> ContentProvider.call
    ALOGI("[PARTIAL] Call: uri=%s, method=%s", uri.ToString().c_str(), method.c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return nullptr;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    jstring jMethod = env->NewStringUTF(method.c_str());
    jstring jArg = env->NewStringUTF(arg.c_str());
    callJavaVoidMethod("onCall",
                       "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)V",
                       jUri, jMethod, jArg);
    env->DeleteLocalRef(jUri);
    env->DeleteLocalRef(jMethod);
    env->DeleteLocalRef(jArg);

    // TODO: Convert Android Bundle return to OH PacMap
    return nullptr;
}

OHOS::Uri AbilitySchedulerAdapter::NormalizeUri(const OHOS::Uri& uri)
{
    // [PARTIAL] NormalizeUri -> ContentProvider.canonicalize
    ALOGI("[PARTIAL] NormalizeUri: uri=%s", uri.ToString().c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return uri;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onNormalizeUri", "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    // TODO: Return normalized URI from Java
    return uri;
}

OHOS::Uri AbilitySchedulerAdapter::DenormalizeUri(const OHOS::Uri& uri)
{
    // [PARTIAL] DenormalizeUri -> ContentProvider.uncanonicalize
    ALOGI("[PARTIAL] DenormalizeUri: uri=%s", uri.ToString().c_str());

    // No Java-side method; return original URI
    return uri;
}

std::vector<std::shared_ptr<OHOS::AppExecFwk::DataAbilityResult>>
AbilitySchedulerAdapter::ExecuteBatch(
    const std::vector<std::shared_ptr<OHOS::AppExecFwk::DataAbilityOperation>>& operations)
{
    // [PARTIAL] ExecuteBatch -> ContentProvider.applyBatch
    ALOGI("[PARTIAL] ExecuteBatch: operations=%zu", operations.size());

    callJavaVoidMethod("onExecuteBatch", "()V");

    // TODO: Convert Android ProviderResult[] to OH DataAbilityResult[]
    return {};
}

// ============================================================
// Category 4: Data Observer  [BRIDGED]
// ============================================================

bool AbilitySchedulerAdapter::ScheduleRegisterObserver(
    const OHOS::Uri& uri,
    const sptr<OHOS::AAFwk::IDataAbilityObserver>& dataObserver)
{
    // [PARTIAL] ScheduleRegisterObserver -> ContentResolver.registerContentObserver
    ALOGI("[PARTIAL] ScheduleRegisterObserver: uri=%s", uri.ToString().c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return false;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onScheduleRegisterObserver",
                       "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    return true;
}

bool AbilitySchedulerAdapter::ScheduleUnregisterObserver(
    const OHOS::Uri& uri,
    const sptr<OHOS::AAFwk::IDataAbilityObserver>& dataObserver)
{
    // [PARTIAL] ScheduleUnregisterObserver -> ContentResolver.unregisterContentObserver
    ALOGI("[PARTIAL] ScheduleUnregisterObserver: uri=%s", uri.ToString().c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return false;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onScheduleUnregisterObserver",
                       "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    return true;
}

bool AbilitySchedulerAdapter::ScheduleNotifyChange(const OHOS::Uri& uri)
{
    // [PARTIAL] ScheduleNotifyChange -> ContentResolver.notifyChange
    ALOGI("[PARTIAL] ScheduleNotifyChange: uri=%s", uri.ToString().c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return false;

    jstring jUri = env->NewStringUTF(uri.ToString().c_str());
    callJavaVoidMethod("onScheduleNotifyChange",
                       "(Ljava/lang/String;)V", jUri);
    env->DeleteLocalRef(jUri);

    return true;
}

// ============================================================
// Category 5: Continuation  [OH_ONLY]
// ============================================================

void AbilitySchedulerAdapter::ContinueAbility(const std::string& deviceId,
                                               uint32_t versionCode)
{
    // [OH_ONLY] ContinueAbility - OH distributed continuation, no Android equivalent
    ALOGI("[OH_ONLY] ContinueAbility: deviceId=%s, versionCode=%u",
          deviceId.c_str(), versionCode);
}

void AbilitySchedulerAdapter::NotifyContinuationResult(int32_t result)
{
    // [OH_ONLY] NotifyContinuationResult - OH distributed continuation result
    ALOGI("[OH_ONLY] NotifyContinuationResult: result=%d", result);
}

// ============================================================
// Category 6: Misc
// ============================================================

void AbilitySchedulerAdapter::DumpAbilityInfo(
    const std::vector<std::string>& params,
    std::vector<std::string>& info)
{
    // [PARTIAL] DumpAbilityInfo -> IApplicationThread.dumpActivity
    ALOGI("[PARTIAL] DumpAbilityInfo");

    callJavaVoidMethod("onDumpAbilityInfo", "()V");

    info.push_back("AbilitySchedulerAdapter: bridge active");
}

int AbilitySchedulerAdapter::CreateModalUIExtension(const OHOS::AAFwk::Want& want)
{
    // [OH_ONLY] CreateModalUIExtension - OH UIExtension, no direct Android equivalent
    ALOGI("[OH_ONLY] CreateModalUIExtension");

    std::string wantJson = wantToJson(want);
    JNIEnv* env = getJNIEnv();
    if (!env) return -1;

    jstring jWantJson = env->NewStringUTF(wantJson.c_str());
    callJavaVoidMethod("onCreateModalUIExtension",
                       "(Ljava/lang/String;)V", jWantJson);
    env->DeleteLocalRef(jWantJson);

    return 0;
}

void AbilitySchedulerAdapter::OnExecuteIntent(const OHOS::AAFwk::Want& want)
{
    // [PARTIAL] OnExecuteIntent -> scheduleTransaction with new intent delivery
    ALOGI("[PARTIAL] OnExecuteIntent");

    std::string wantJson = wantToJson(want);
    JNIEnv* env = getJNIEnv();
    if (!env) return;

    jstring jWantJson = env->NewStringUTF(wantJson.c_str());
    callJavaVoidMethod("onExecuteIntent",
                       "(Ljava/lang/String;)V", jWantJson);
    env->DeleteLocalRef(jWantJson);
}

void AbilitySchedulerAdapter::CallRequest()
{
    // [PARTIAL] CallRequest - OH call mode, no Android equivalent
    ALOGI("[PARTIAL] CallRequest");
    callJavaVoidMethod("onCallRequest", "()V");
}

void AbilitySchedulerAdapter::UpdateSessionToken(sptr<OHOS::IRemoteObject> sessionToken)
{
    // [OH_ONLY] UpdateSessionToken - OH session management
    ALOGI("[OH_ONLY] UpdateSessionToken");
    callJavaVoidMethod("onUpdateSessionToken", "()V");
}

void AbilitySchedulerAdapter::ScheduleCollaborate(const OHOS::AAFwk::Want& want)
{
    // [OH_ONLY] ScheduleCollaborate - OH collaboration, no Android equivalent
    ALOGI("[OH_ONLY] ScheduleCollaborate");

    std::string wantJson = wantToJson(want);
    JNIEnv* env = getJNIEnv();
    if (!env) return;

    jstring jWantJson = env->NewStringUTF(wantJson.c_str());
    callJavaVoidMethod("onScheduleCollaborate",
                       "(Ljava/lang/String;)V", jWantJson);
    env->DeleteLocalRef(jWantJson);
}

void AbilitySchedulerAdapter::ScheduleAbilityRequestFailure(
    const std::string& requestId,
    const OHOS::AppExecFwk::ElementName& element,
    const std::string& message,
    int32_t resultCode)
{
    // [OH_ONLY] ScheduleAbilityRequestFailure - OH ability request result
    ALOGI("[OH_ONLY] ScheduleAbilityRequestFailure: requestId=%s, msg=%s, code=%d",
          requestId.c_str(), message.c_str(), resultCode);

    JNIEnv* env = getJNIEnv();
    if (!env) return;

    jstring jReqId = env->NewStringUTF(requestId.c_str());
    callJavaVoidMethod("onScheduleAbilityRequestResult",
                       "(Ljava/lang/String;Z)V",
                       jReqId, static_cast<jboolean>(false));
    env->DeleteLocalRef(jReqId);
}

void AbilitySchedulerAdapter::ScheduleAbilityRequestSuccess(
    const std::string& requestId,
    const OHOS::AppExecFwk::ElementName& element)
{
    // [OH_ONLY] ScheduleAbilityRequestSuccess - OH ability request result
    ALOGI("[OH_ONLY] ScheduleAbilityRequestSuccess: requestId=%s",
          requestId.c_str());

    JNIEnv* env = getJNIEnv();
    if (!env) return;

    jstring jReqId = env->NewStringUTF(requestId.c_str());
    callJavaVoidMethod("onScheduleAbilityRequestResult",
                       "(Ljava/lang/String;Z)V",
                       jReqId, static_cast<jboolean>(true));
    env->DeleteLocalRef(jReqId);
}

void AbilitySchedulerAdapter::ScheduleAbilitiesRequestDone(
    const std::string& requestKey,
    int32_t resultCode)
{
    // [OH_ONLY] ScheduleAbilitiesRequestDone - OH batch ability request done
    ALOGI("[OH_ONLY] ScheduleAbilitiesRequestDone: requestKey=%s, resultCode=%d",
          requestKey.c_str(), resultCode);
}

}  // namespace oh_adapter
