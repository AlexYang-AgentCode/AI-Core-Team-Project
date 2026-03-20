/*
 * ability_connection_adapter.cpp
 *
 * OH IAbilityConnection stub implementation.
 * Routes connection/disconnection callbacks to Java ServiceConnectionRegistry.
 */
#include "ability_connection_adapter.h"

#include <android/log.h>

#define LOG_TAG "OH_AbilityConnAdapter"
#define ALOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace oh_adapter {

// Cached JNI references for ServiceConnectionRegistry
static jclass sRegistryClass = nullptr;
static jmethodID sGetInstanceMethod = nullptr;
static jmethodID sOnConnectedMethod = nullptr;
static jmethodID sOnDisconnectedMethod = nullptr;
static bool sJniInitialized = false;

static bool initJniCache(JNIEnv* env) {
    if (sJniInitialized) return true;

    jclass cls = env->FindClass("adapter/client/ServiceConnectionRegistry");
    if (!cls) {
        ALOGE("ServiceConnectionRegistry class not found");
        env->ExceptionClear();
        return false;
    }
    sRegistryClass = reinterpret_cast<jclass>(env->NewGlobalRef(cls));
    env->DeleteLocalRef(cls);

    sGetInstanceMethod = env->GetStaticMethodID(sRegistryClass, "getInstance",
            "()Ladapter/client/ServiceConnectionRegistry;");
    sOnConnectedMethod = env->GetMethodID(sRegistryClass, "onServiceConnected",
            "(ILjava/lang/String;Ljava/lang/String;Landroid/os/IBinder;)V");
    sOnDisconnectedMethod = env->GetMethodID(sRegistryClass, "onServiceDisconnected",
            "(ILjava/lang/String;Ljava/lang/String;)V");

    if (!sGetInstanceMethod || !sOnConnectedMethod || !sOnDisconnectedMethod) {
        ALOGE("Failed to find ServiceConnectionRegistry methods");
        env->ExceptionClear();
        return false;
    }

    sJniInitialized = true;
    return true;
}

AbilityConnectionAdapter::AbilityConnectionAdapter(JavaVM* jvm, int connectionId)
    : jvm_(jvm), connectionId_(connectionId)
{
    ALOGI("AbilityConnectionAdapter created: connectionId=%d", connectionId);
}

AbilityConnectionAdapter::~AbilityConnectionAdapter()
{
    ALOGI("AbilityConnectionAdapter destroyed: connectionId=%d", connectionId_);
}

JNIEnv* AbilityConnectionAdapter::getJNIEnv()
{
    if (!jvm_) return nullptr;

    JNIEnv* env = nullptr;
    jint status = jvm_->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    if (status == JNI_EDETACHED) {
        JavaVMAttachArgs args;
        args.version = JNI_VERSION_1_6;
        args.name = "OH_AbilityConnAdapter";
        args.group = nullptr;
        if (jvm_->AttachCurrentThread(&env, &args) != JNI_OK) {
            ALOGE("AttachCurrentThread failed");
            return nullptr;
        }
    } else if (status != JNI_OK) {
        ALOGE("GetEnv failed: %d", status);
        return nullptr;
    }
    return env;
}

void AbilityConnectionAdapter::OnAbilityConnectDone(
    const OHOS::AppExecFwk::ElementName& element,
    const OHOS::sptr<OHOS::IRemoteObject>& remoteObject,
    int resultCode)
{
    std::string bundleName = element.GetBundleName();
    std::string abilityName = element.GetAbilityName();

    ALOGI("[BRIDGED] OnAbilityConnectDone: connId=%d, bundle=%s, ability=%s, result=%d",
          connectionId_, bundleName.c_str(), abilityName.c_str(), resultCode);

    JNIEnv* env = getJNIEnv();
    if (!env) return;

    if (!initJniCache(env)) return;

    jobject registry = env->CallStaticObjectMethod(sRegistryClass, sGetInstanceMethod);
    if (!registry) {
        ALOGE("Failed to get ServiceConnectionRegistry instance");
        return;
    }

    jstring jBundle = env->NewStringUTF(bundleName.c_str());
    jstring jAbility = env->NewStringUTF(abilityName.c_str());

    // TODO: Wrap OH IRemoteObject as Android IBinder
    // For now, pass null. Full implementation requires OH-to-Android Binder bridge.
    env->CallVoidMethod(registry, sOnConnectedMethod,
                        static_cast<jint>(connectionId_),
                        jBundle, jAbility,
                        static_cast<jobject>(nullptr));

    if (env->ExceptionCheck()) {
        ALOGE("Java exception in onServiceConnected");
        env->ExceptionDescribe();
        env->ExceptionClear();
    }

    env->DeleteLocalRef(jBundle);
    env->DeleteLocalRef(jAbility);
    env->DeleteLocalRef(registry);
}

void AbilityConnectionAdapter::OnAbilityDisconnectDone(
    const OHOS::AppExecFwk::ElementName& element,
    int resultCode)
{
    std::string bundleName = element.GetBundleName();
    std::string abilityName = element.GetAbilityName();

    ALOGI("[BRIDGED] OnAbilityDisconnectDone: connId=%d, bundle=%s, ability=%s, result=%d",
          connectionId_, bundleName.c_str(), abilityName.c_str(), resultCode);

    JNIEnv* env = getJNIEnv();
    if (!env) return;

    if (!initJniCache(env)) return;

    jobject registry = env->CallStaticObjectMethod(sRegistryClass, sGetInstanceMethod);
    if (!registry) {
        ALOGE("Failed to get ServiceConnectionRegistry instance");
        return;
    }

    jstring jBundle = env->NewStringUTF(bundleName.c_str());
    jstring jAbility = env->NewStringUTF(abilityName.c_str());

    env->CallVoidMethod(registry, sOnDisconnectedMethod,
                        static_cast<jint>(connectionId_),
                        jBundle, jAbility);

    if (env->ExceptionCheck()) {
        ALOGE("Java exception in onServiceDisconnected");
        env->ExceptionDescribe();
        env->ExceptionClear();
    }

    env->DeleteLocalRef(jBundle);
    env->DeleteLocalRef(jAbility);
    env->DeleteLocalRef(registry);
}

}  // namespace oh_adapter
