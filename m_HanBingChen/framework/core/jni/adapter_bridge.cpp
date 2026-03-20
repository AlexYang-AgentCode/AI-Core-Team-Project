/*
 * adapter_bridge.cpp
 *
 * JNI Bridge implementation.
 * Connects Android Java layer with OpenHarmony C++ IPC framework.
 *
 * Provides JNI native methods for:
 *   - OHEnvironment: initialization, service connection, shutdown
 *   - ActivityManagerAdapter / ActivityTaskManagerAdapter: ability start/connect
 *   - WindowManagerAdapter / WindowSessionAdapter: window creation, layout, surface
 */
#include "adapter_bridge.h"
#include "oh_ability_manager_client.h"
#include "oh_app_mgr_client.h"
#include "oh_callback_handler.h"
#include "oh_window_manager_client.h"
#include "oh_input_bridge.h"
#include "oh_surface_bridge.h"
#include "oh_graphic_buffer_producer.h"
#include "oh_common_event_client.h"
#include "oh_datashare_client.h"
#include "common_event_subscriber_adapter.h"
#include "intent_want_converter.h"

#include <android/log.h>
#include <string>
#include <mutex>
#include <unistd.h>
#include <cerrno>
#include <cstring>

#define LOG_TAG "OH_JNI_Bridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

using namespace oh_adapter;

// ==================== AdapterBridge Implementation ====================

AdapterBridge& AdapterBridge::getInstance() {
    static AdapterBridge instance;
    return instance;
}

bool AdapterBridge::initialize(JNIEnv* env) {
    LOGI("AdapterBridge::initialize()");

    // Cache LifecycleAdapter JNI method IDs
    jclass clazz = env->FindClass("adapter/LifecycleAdapter");
    if (clazz == nullptr) {
        LOGE("Failed to find LifecycleAdapter class");
        return false;
    }
    lifecycle_adapter_class_ = (jclass)env->NewGlobalRef(clazz);
    on_oh_lifecycle_callback_ = env->GetMethodID(clazz, "onOHLifecycleCallback", "(II)V");
    if (on_oh_lifecycle_callback_ == nullptr) {
        LOGE("Failed to find onOHLifecycleCallback method");
        return false;
    }

    // Initialize DataShare JNI cache (MatrixCursor class/method IDs)
    if (!initDataShareJniCache(env)) {
        LOGE("Failed to initialize DataShare JNI cache");
        // Non-fatal: ContentProvider bridge won't work, but other bridges are fine
    }

    return true;
}

void AdapterBridge::shutdown() {
    LOGI("AdapterBridge::shutdown()");
    JNIEnv* env = getEnv();
    if (env && lifecycle_adapter_ref_) {
        env->DeleteGlobalRef(lifecycle_adapter_ref_);
        lifecycle_adapter_ref_ = nullptr;
    }
    if (env && lifecycle_adapter_class_) {
        env->DeleteGlobalRef(lifecycle_adapter_class_);
        lifecycle_adapter_class_ = nullptr;
    }
}

void AdapterBridge::setLifecycleAdapterRef(JNIEnv* env, jobject obj) {
    if (lifecycle_adapter_ref_) {
        env->DeleteGlobalRef(lifecycle_adapter_ref_);
    }
    lifecycle_adapter_ref_ = env->NewGlobalRef(obj);
}

JNIEnv* AdapterBridge::getEnv() {
    JNIEnv* env = nullptr;
    if (jvm_) {
        int status = jvm_->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
        if (status == JNI_EDETACHED) {
            jvm_->AttachCurrentThread(&env, nullptr);
        }
    }
    return env;
}

void AdapterBridge::callbackLifecycleChange(int abilityToken, int ohState) {
    JNIEnv* env = getEnv();
    if (!env || !lifecycle_adapter_ref_) {
        LOGE("Cannot callback: JNI env or LifecycleAdapter ref is null");
        return;
    }

    // Call LifecycleAdapter directly using the stored singleton reference
    env->CallVoidMethod(lifecycle_adapter_ref_, on_oh_lifecycle_callback_,
                        abilityToken, ohState);
}

// ==================== Static Helpers ====================

// Guard to ensure single initialization
static std::once_flag g_initFlag;
static bool g_initialized = false;

// Helper: extract a jstring to std::string safely
static std::string jstringToString(JNIEnv* env, jstring jstr) {
    if (!jstr) return "";
    const char* raw = env->GetStringUTFChars(jstr, nullptr);
    std::string result(raw);
    env->ReleaseStringUTFChars(jstr, raw);
    return result;
}

// Shared startAbility implementation used by per-Adapter JNI methods
static jint bridgeStartAbility(JNIEnv* env, jstring bundleName, jstring abilityName,
                                jstring action, jstring uri, jstring extraJson) {
    std::string bundle = jstringToString(env, bundleName);
    std::string ability = jstringToString(env, abilityName);
    std::string act = jstringToString(env, action);
    std::string u = jstringToString(env, uri);
    std::string extra = jstringToString(env, extraJson);

    LOGI("bridgeStartAbility: bundle=%s, ability=%s, action=%s",
         bundle.c_str(), ability.c_str(), act.c_str());

    WantParams want;
    want.bundleName = bundle;
    want.abilityName = ability;
    want.action = act;
    want.uri = u;
    want.parametersJson = extra;

    return OHAbilityManagerClient::getInstance().startAbility(want);
}

// Shared connectAbility implementation
static jint bridgeConnectAbility(JNIEnv* env, jstring bundleName,
                                  jstring abilityName, jint connectionId) {
    std::string bundle = jstringToString(env, bundleName);
    std::string ability = jstringToString(env, abilityName);

    LOGI("bridgeConnectAbility: bundle=%s, ability=%s, connId=%d",
         bundle.c_str(), ability.c_str(), connectionId);

    WantParams want;
    want.bundleName = bundle;
    want.abilityName = ability;

    return OHAbilityManagerClient::getInstance().connectAbility(want, connectionId);
}

// Shared disconnectAbility implementation
static jint bridgeDisconnectAbility(jint connectionId) {
    LOGI("bridgeDisconnectAbility: connectionId=%d", connectionId);
    return OHAbilityManagerClient::getInstance().disconnectAbility(connectionId);
}

// Shared stopServiceAbility implementation
static jint bridgeStopServiceAbility(JNIEnv* env, jstring bundleName, jstring abilityName) {
    std::string bundle = jstringToString(env, bundleName);
    std::string ability = jstringToString(env, abilityName);

    LOGI("bridgeStopServiceAbility: bundle=%s, ability=%s", bundle.c_str(), ability.c_str());

    WantParams want;
    want.bundleName = bundle;
    want.abilityName = ability;

    return OHAbilityManagerClient::getInstance().stopServiceAbility(want);
}

// ==================== JNI Method Implementations ====================

extern "C" {

JNIEXPORT jint JNI_OnLoad(JavaVM* vm, void* reserved) {
    LOGI("JNI_OnLoad: oh_adapter_bridge");
    AdapterBridge::getInstance().setJavaVM(vm);

    JNIEnv* env;
    if (vm->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        return JNI_ERR;
    }
    return JNI_VERSION_1_6;
}

// ==================== OHEnvironment JNI Methods ====================

/*
 * Class:     adapter_OHEnvironment
 * Method:    nativeInitialize
 */
JNIEXPORT jboolean JNICALL
Java_adapter_OHEnvironment_nativeInitialize(JNIEnv* env, jclass clazz) {
    LOGI("nativeInitialize()");

    jboolean result = JNI_FALSE;
    std::call_once(g_initFlag, [&]() {
        AdapterBridge& bridge = AdapterBridge::getInstance();

        if (!bridge.initialize(env)) {
            LOGE("AdapterBridge initialization failed");
            return;
        }

        // Initialize OH IPC framework
        OHOS::IPCSkeleton::SetCallingIdentity("");
        LOGI("OH IPC framework initialized");

        // Initialize input event bridge
        OHInputBridge::getInstance().setJavaVM(vm);
        LOGI("Input event bridge initialized");

        // Initialize CommonEvent JNI callbacks
        if (!initCommonEventJNI(env)) {
            LOGE("CommonEvent JNI initialization failed (non-fatal)");
        }

        g_initialized = true;
        result = JNI_TRUE;
    });

    if (g_initialized) {
        result = JNI_TRUE;
    }

    return result;
}

/*
 * Class:     adapter_OHEnvironment
 * Method:    nativeConnectToOHServices
 */
JNIEXPORT jboolean JNICALL
Java_adapter_OHEnvironment_nativeConnectToOHServices(JNIEnv* env, jclass clazz) {
    LOGI("nativeConnectToOHServices()");

    // Connect to all OH system services
    bool abilityMgrOk = OHAbilityManagerClient::getInstance().connect();
    bool appMgrOk = OHAppMgrClient::getInstance().connect();
    bool windowMgrOk = OHWindowManagerClient::getInstance().connect();

    // Register callback stubs
    JavaVM* jvm = AdapterBridge::getInstance().getJavaVM();
    bool callbackOk = OHCallbackHandler::getInstance().registerCallbacks();

    LOGI("Service connections: AbilityMgr=%d, AppMgr=%d, WindowMgr=%d, Callbacks=%d",
         abilityMgrOk, appMgrOk, windowMgrOk, callbackOk);

    return (jboolean)(abilityMgrOk && appMgrOk);
}

/*
 * Class:     adapter_OHEnvironment
 * Method:    nativeAttachApplication
 */
JNIEXPORT jboolean JNICALL
Java_adapter_OHEnvironment_nativeAttachApplication(
        JNIEnv* env, jclass clazz, jint pid, jint uid, jstring packageName) {
    const char* pkgName = env->GetStringUTFChars(packageName, nullptr);
    LOGI("nativeAttachApplication: pid=%d, uid=%d, pkg=%s", pid, uid, pkgName);

    bool result = OHAppMgrClient::getInstance().attachApplication(pid, uid, pkgName);

    env->ReleaseStringUTFChars(packageName, pkgName);
    return (jboolean)result;
}

/*
 * Class:     adapter_OHEnvironment
 * Method:    nativeNotifyAppState
 */
JNIEXPORT void JNICALL
Java_adapter_OHEnvironment_nativeNotifyAppState(
        JNIEnv* env, jclass clazz, jint state) {
    LOGI("nativeNotifyAppState: state=%d", state);
    OHAppMgrClient::getInstance().notifyAppState(state);
}

/*
 * Class:     adapter_OHEnvironment
 * Method:    nativeShutdown
 */
JNIEXPORT void JNICALL
Java_adapter_OHEnvironment_nativeShutdown(JNIEnv* env, jclass clazz) {
    LOGI("nativeShutdown()");
    OHCallbackHandler::getInstance().unregisterCallbacks();
    OHWindowManagerClient::getInstance().disconnect();
    OHAbilityManagerClient::getInstance().disconnect();
    OHAppMgrClient::getInstance().disconnect();
    AdapterBridge::getInstance().shutdown();
}

/*
 * Class:     adapter_OHEnvironment
 * Method:    nativeIsOHEnvironment
 */
JNIEXPORT jboolean JNICALL
Java_adapter_OHEnvironment_nativeIsOHEnvironment(JNIEnv* env, jclass clazz) {
    // Returns true when running in an OH-compatible environment
    return (jboolean)g_initialized;
}

// ==================== Per-Adapter JNI Methods ====================

/*
 * Class:     adapter_bridge_ActivityManagerAdapter
 * Method:    nativeGetOHAbilityManagerService
 */
JNIEXPORT jlong JNICALL
Java_adapter_bridge_ActivityManagerAdapter_nativeGetOHAbilityManagerService(
        JNIEnv* env, jclass clazz) {
    return (jlong)&OHAbilityManagerClient::getInstance();
}

/*
 * Class:     adapter_bridge_ActivityTaskManagerAdapter
 * Method:    nativeGetOHAbilityManagerService
 */
JNIEXPORT jlong JNICALL
Java_adapter_bridge_ActivityTaskManagerAdapter_nativeGetOHAbilityManagerService(
        JNIEnv* env, jclass clazz) {
    return (jlong)&OHAbilityManagerClient::getInstance();
}

/*
 * Class:     adapter_bridge_ActivityManagerAdapter
 * Method:    nativeStartAbility
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityManagerAdapter_nativeStartAbility(
        JNIEnv* env, jclass clazz,
        jstring bundleName, jstring abilityName,
        jstring action, jstring uri, jstring extraJson) {
    return bridgeStartAbility(env, bundleName, abilityName, action, uri, extraJson);
}

/*
 * Class:     adapter_bridge_ActivityTaskManagerAdapter
 * Method:    nativeStartAbility
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityTaskManagerAdapter_nativeStartAbility(
        JNIEnv* env, jclass clazz,
        jstring bundleName, jstring abilityName,
        jstring action, jstring uri, jstring extraJson) {
    return bridgeStartAbility(env, bundleName, abilityName, action, uri, extraJson);
}

/*
 * Class:     adapter_client_ActivityManagerAdapter
 * Method:    nativeConnectAbility
 */
JNIEXPORT jint JNICALL
Java_adapter_client_ActivityManagerAdapter_nativeConnectAbility(
        JNIEnv* env, jclass clazz,
        jstring bundleName, jstring abilityName, jint connectionId) {
    return bridgeConnectAbility(env, bundleName, abilityName, connectionId);
}

// Legacy symbol for adapter_bridge_ package prefix (JNI RegisterNatives fallback)
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityManagerAdapter_nativeConnectAbility(
        JNIEnv* env, jclass clazz,
        jstring bundleName, jstring abilityName, jint connectionId) {
    return bridgeConnectAbility(env, bundleName, abilityName, connectionId);
}

/*
 * Class:     adapter_client_ActivityManagerAdapter
 * Method:    nativeDisconnectAbility
 */
JNIEXPORT jint JNICALL
Java_adapter_client_ActivityManagerAdapter_nativeDisconnectAbility(
        JNIEnv* env, jclass clazz, jint connectionId) {
    return bridgeDisconnectAbility(connectionId);
}

// Legacy symbol
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityManagerAdapter_nativeDisconnectAbility(
        JNIEnv* env, jclass clazz, jint connectionId) {
    return bridgeDisconnectAbility(connectionId);
}

/*
 * Class:     adapter_client_ActivityManagerAdapter
 * Method:    nativeStopServiceAbility
 */
JNIEXPORT jint JNICALL
Java_adapter_client_ActivityManagerAdapter_nativeStopServiceAbility(
        JNIEnv* env, jclass clazz,
        jstring bundleName, jstring abilityName) {
    return bridgeStopServiceAbility(env, bundleName, abilityName);
}

// Legacy symbol
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityManagerAdapter_nativeStopServiceAbility(
        JNIEnv* env, jclass clazz,
        jstring bundleName, jstring abilityName) {
    return bridgeStopServiceAbility(env, bundleName, abilityName);
}

/*
 * Class:     adapter_bridge_WindowManagerAdapter
 * Method:    nativeGetOHWindowManagerService
 */
JNIEXPORT jlong JNICALL
Java_adapter_bridge_WindowManagerAdapter_nativeGetOHWindowManagerService(
        JNIEnv* env, jclass clazz) {
    return (jlong)&OHWindowManagerClient::getInstance();
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeGetOHSessionService
 */
JNIEXPORT jlong JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeGetOHSessionService(
        JNIEnv* env, jclass clazz) {
    return (jlong)&OHWindowManagerClient::getInstance();
}

// ==================== Window Session JNI Methods ====================

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeCreateSession
 *
 * Creates an OH window session and returns the session info as an int array:
 *   [0] = sessionId, [1] = surfaceNodeId, [2] = displayId, [3] = width, [4] = height
 */
JNIEXPORT jintArray JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeCreateSession(
        JNIEnv* env, jclass clazz,
        jobject androidWindow, jstring windowName,
        jint windowType, jint displayId,
        jint requestedWidth, jint requestedHeight) {

    const char* name = env->GetStringUTFChars(windowName, nullptr);
    JavaVM* jvm = AdapterBridge::getInstance().getJavaVM();

    OHWindowSession session = OHWindowManagerClient::getInstance().createSession(
        jvm, androidWindow, name, windowType, displayId,
        requestedWidth, requestedHeight);

    env->ReleaseStringUTFChars(windowName, name);

    // Return session info as int array
    jintArray result = env->NewIntArray(5);
    jint info[5] = {
        session.sessionId,
        session.surfaceNodeId,
        session.displayId,
        session.width,
        session.height
    };
    env->SetIntArrayRegion(result, 0, 5, info);
    return result;
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeUpdateSessionRect
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeUpdateSessionRect(
        JNIEnv* env, jclass clazz,
        jint sessionId, jint x, jint y, jint width, jint height) {
    return OHWindowManagerClient::getInstance().updateSessionRect(
        sessionId, x, y, width, height);
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeNotifyDrawingCompleted
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeNotifyDrawingCompleted(
        JNIEnv* env, jclass clazz, jint sessionId) {
    return OHWindowManagerClient::getInstance().notifyDrawingCompleted(sessionId);
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeDestroySession
 */
JNIEXPORT void JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeDestroySession(
        JNIEnv* env, jclass clazz, jint sessionId) {
    OHWindowManagerClient::getInstance().destroySession(sessionId);
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeGetSurfaceNodeId
 */
JNIEXPORT jlong JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeGetSurfaceNodeId(
        JNIEnv* env, jclass clazz, jint sessionId) {
    return OHWindowManagerClient::getInstance().getSurfaceNodeId(sessionId);
}

// ==================== Input Event Bridge JNI Methods ====================

/*
 * Class:     adapter_InputEventBridge
 * Method:    nativeRegisterInputChannel
 *
 * Registers the server-side InputChannel fd with the native InputPublisher.
 * The fd is extracted from the Java InputChannel object.
 */
JNIEXPORT void JNICALL
Java_adapter_InputEventBridge_nativeRegisterInputChannel(
        JNIEnv* env, jclass clazz, jint sessionId, jobject inputChannel) {

    // Extract the fd from the Java InputChannel object
    // InputChannel stores its fd internally; we access it via reflection
    jclass channelClass = env->GetObjectClass(inputChannel);
    jmethodID getFdMethod = env->GetMethodID(channelClass, "getFd", "()I");
    if (getFdMethod == nullptr) {
        // Try alternative: dup the fd from the InputChannel's native handle
        LOGE("Cannot get fd from InputChannel, trying native method");
        return;
    }

    int fd = env->CallIntMethod(inputChannel, getFdMethod);
    LOGI("nativeRegisterInputChannel: session=%d, fd=%d", sessionId, fd);

    // Dup the fd so we have our own copy (Java may close the original)
    int dupFd = dup(fd);
    if (dupFd < 0) {
        LOGE("Failed to dup InputChannel fd: %s", strerror(errno));
        return;
    }

    OHInputBridge::getInstance().registerInputChannel(sessionId, dupFd);
}

/*
 * Class:     adapter_InputEventBridge
 * Method:    nativeUnregisterInputChannel
 */
JNIEXPORT void JNICALL
Java_adapter_InputEventBridge_nativeUnregisterInputChannel(
        JNIEnv* env, jclass clazz, jint sessionId) {
    LOGI("nativeUnregisterInputChannel: session=%d", sessionId);
    OHInputBridge::getInstance().unregisterInputChannel(sessionId);
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeInjectTouchEvent
 *
 * Injects a single-pointer touch event into the Android InputChannel
 * for the specified session. Used for testing and for forwarding
 * OH-origin touch events.
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeInjectTouchEvent(
        JNIEnv* env, jclass clazz,
        jint sessionId, jint action, jfloat x, jfloat y,
        jlong downTime, jlong eventTime) {
    return OHInputBridge::getInstance().injectTouchEvent(
        sessionId, action, x, y, downTime, eventTime);
}

// ==================== Mission / Task Management JNI Methods ====================

/*
 * Class:     adapter_bridge_ActivityTaskManagerAdapter
 * Method:    nativeStartAbilityInMission
 *
 * Starts a new Ability within an existing Mission (pushes onto Ability stack).
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityTaskManagerAdapter_nativeStartAbilityInMission(
        JNIEnv* env, jclass clazz,
        jstring bundleName, jstring abilityName,
        jstring action, jstring uri, jstring extraJson,
        jint missionId) {
    std::string bundle = jstringToString(env, bundleName);
    std::string ability = jstringToString(env, abilityName);
    std::string act = jstringToString(env, action);
    std::string u = jstringToString(env, uri);
    std::string extra = jstringToString(env, extraJson);

    LOGI("nativeStartAbilityInMission: bundle=%s, ability=%s, missionId=%d",
         bundle.c_str(), ability.c_str(), missionId);

    WantParams want;
    want.bundleName = bundle;
    want.abilityName = ability;
    want.action = act;
    want.uri = u;
    want.parametersJson = extra;

    return OHAbilityManagerClient::getInstance().startAbilityInMission(want, missionId);
}

/*
 * Class:     adapter_bridge_ActivityTaskManagerAdapter
 * Method:    nativeCleanMission
 *
 * Removes a Mission and all its stacked Abilities.
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityTaskManagerAdapter_nativeCleanMission(
        JNIEnv* env, jclass clazz, jint missionId) {
    return OHAbilityManagerClient::getInstance().cleanMission(missionId);
}

/*
 * Class:     adapter_bridge_ActivityTaskManagerAdapter
 * Method:    nativeMoveMissionToFront
 *
 * Moves a Mission's top Ability to the foreground.
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityTaskManagerAdapter_nativeMoveMissionToFront(
        JNIEnv* env, jclass clazz, jint missionId) {
    return OHAbilityManagerClient::getInstance().moveMissionToFront(missionId);
}

/*
 * Class:     adapter_bridge_ActivityTaskManagerAdapter
 * Method:    nativeIsTopAbility
 *
 * Checks if the top Ability in a Mission matches the given name.
 */
JNIEXPORT jboolean JNICALL
Java_adapter_bridge_ActivityTaskManagerAdapter_nativeIsTopAbility(
        JNIEnv* env, jclass clazz,
        jint missionId, jstring abilityName) {
    const char* name = env->GetStringUTFChars(abilityName, nullptr);
    bool result = OHAbilityManagerClient::getInstance().isTopAbility(missionId, name);
    env->ReleaseStringUTFChars(abilityName, name);
    return (jboolean)result;
}

/*
 * Class:     adapter_bridge_ActivityTaskManagerAdapter
 * Method:    nativeClearAbilitiesAbove
 *
 * Clears all Abilities above the named one in a Mission's stack (FLAG_ACTIVITY_CLEAR_TOP).
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityTaskManagerAdapter_nativeClearAbilitiesAbove(
        JNIEnv* env, jclass clazz,
        jint missionId, jstring abilityName) {
    std::string name = jstringToString(env, abilityName);
    return OHAbilityManagerClient::getInstance().clearAbilitiesAbove(missionId, name);
}

/*
 * Class:     adapter_bridge_ActivityTaskManagerAdapter
 * Method:    nativeGetMissionIdForBundle
 *
 * Queries OH MissionInfos to find the Mission ID for a given bundle name.
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityTaskManagerAdapter_nativeGetMissionIdForBundle(
        JNIEnv* env, jclass clazz,
        jstring bundleName) {
    std::string bundle = jstringToString(env, bundleName);
    return OHAbilityManagerClient::getInstance().getMissionIdForBundle(bundle);
}

// ==================== Surface Bridge JNI Methods ====================

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeCreateOHSurface
 *
 * Creates OH RSSurfaceNode + RSUIDirector + Surface for a window session.
 */
JNIEXPORT jboolean JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeCreateOHSurface(
        JNIEnv* env, jclass clazz,
        jint sessionId, jstring windowName,
        jint width, jint height, jint format) {
    const char* name = env->GetStringUTFChars(windowName, nullptr);
    bool result = OHSurfaceBridge::getInstance().createSurface(
        sessionId, name, width, height, format);
    env->ReleaseStringUTFChars(windowName, name);
    return (jboolean)result;
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeGetSurfaceHandle
 *
 * Returns opaque native pointer to OHGraphicBufferProducer for Android SurfaceControl.
 */
JNIEXPORT jlong JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeGetSurfaceHandle(
        JNIEnv* env, jclass clazz,
        jint sessionId, jint width, jint height, jint format) {
    return OHSurfaceBridge::getInstance().getSurfaceHandle(
        sessionId, width, height, format);
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeNotifySurfaceDrawingCompleted
 *
 * Flushes RSUIDirector::SendMessages() and RSTransaction for a session.
 */
JNIEXPORT void JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeNotifySurfaceDrawingCompleted(
        JNIEnv* env, jclass clazz, jint sessionId) {
    OHSurfaceBridge::getInstance().notifyDrawingCompleted(sessionId);
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeUpdateSurfaceSize
 *
 * Updates RSSurfaceNode bounds when window is resized.
 */
JNIEXPORT void JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeUpdateSurfaceSize(
        JNIEnv* env, jclass clazz,
        jint sessionId, jint width, jint height) {
    OHSurfaceBridge::getInstance().updateSurfaceSize(sessionId, width, height);
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeDestroyOHSurface
 *
 * Releases all OH surface resources for a session.
 */
JNIEXPORT void JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeDestroyOHSurface(
        JNIEnv* env, jclass clazz, jint sessionId) {
    OHSurfaceBridge::getInstance().destroySurface(sessionId);
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeDequeueBuffer
 *
 * Dequeues a buffer from OH Surface for rendering.
 * Returns int[]: [slot, fenceFd, dmabufFd, width, height, stride]
 */
JNIEXPORT jintArray JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeDequeueBuffer(
        JNIEnv* env, jclass clazz,
        jlong producerHandle, jint width, jint height,
        jint format, jlong usage) {
    auto* producer = reinterpret_cast<OHGraphicBufferProducer*>(producerHandle);
    if (!producer) {
        LOGE("nativeDequeueBuffer: null producer handle");
        return nullptr;
    }

    int slot = -1;
    int fenceFd = -1;
    int ret = producer->dequeueBuffer(&slot, &fenceFd, width, height, format, usage);
    if (ret != 0) {
        LOGE("nativeDequeueBuffer: dequeueBuffer failed (ret=%d)", ret);
        return nullptr;
    }

    // Get buffer info
    int32_t bufWidth = 0, bufHeight = 0, stride = 0, bufFormat = 0;
    producer->getBufferInfo(slot, &bufWidth, &bufHeight, &stride, &bufFormat);

    int dmabufFd = producer->getBufferFd(slot);

    jintArray result = env->NewIntArray(6);
    jint info[6] = { slot, fenceFd, dmabufFd, bufWidth, bufHeight, stride };
    env->SetIntArrayRegion(result, 0, 6, info);
    return result;
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeQueueBuffer
 *
 * Queues a rendered buffer to OH Surface for composition.
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeQueueBuffer(
        JNIEnv* env, jclass clazz,
        jlong producerHandle, jint slot, jint fenceFd,
        jlong timestamp, jint cropLeft, jint cropTop,
        jint cropRight, jint cropBottom) {
    auto* producer = reinterpret_cast<OHGraphicBufferProducer*>(producerHandle);
    if (!producer) {
        LOGE("nativeQueueBuffer: null producer handle");
        return -1;
    }

    return producer->queueBuffer(slot, fenceFd, timestamp,
                                  cropLeft, cropTop, cropRight, cropBottom);
}

/*
 * Class:     adapter_bridge_WindowSessionAdapter
 * Method:    nativeCancelBuffer
 *
 * Cancels a previously dequeued buffer.
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_WindowSessionAdapter_nativeCancelBuffer(
        JNIEnv* env, jclass clazz,
        jlong producerHandle, jint slot, jint fenceFd) {
    auto* producer = reinterpret_cast<OHGraphicBufferProducer*>(producerHandle);
    if (!producer) {
        LOGE("nativeCancelBuffer: null producer handle");
        return -1;
    }

    return producer->cancelBuffer(slot, fenceFd);
}

// ==================== Broadcast / CommonEvent JNI Methods ====================

/*
 * Class:     adapter_bridge_ActivityManagerAdapter
 * Method:    nativeSubscribeCommonEvent
 *
 * Subscribes to OH CommonEvents matching the given event names.
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityManagerAdapter_nativeSubscribeCommonEvent(
        JNIEnv* env, jclass clazz,
        jint subscriptionId, jobjectArray ohEventNames,
        jint priority, jstring permission) {

    // Extract event names from Java string array
    std::vector<std::string> events;
    if (ohEventNames) {
        int count = env->GetArrayLength(ohEventNames);
        for (int i = 0; i < count; i++) {
            jstring jstr = (jstring)env->GetObjectArrayElement(ohEventNames, i);
            events.push_back(jstringToString(env, jstr));
            if (jstr) env->DeleteLocalRef(jstr);
        }
    }

    std::string perm = jstringToString(env, permission);

    return OHCommonEventClient::getInstance().subscribe(subscriptionId, events, priority, perm);
}

/*
 * Class:     adapter_bridge_ActivityManagerAdapter
 * Method:    nativeUnsubscribeCommonEvent
 *
 * Unsubscribes from OH CommonEvents.
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityManagerAdapter_nativeUnsubscribeCommonEvent(
        JNIEnv* env, jclass clazz, jint subscriptionId) {
    return OHCommonEventClient::getInstance().unsubscribe(subscriptionId);
}

/*
 * Class:     adapter_bridge_ActivityManagerAdapter
 * Method:    nativePublishCommonEvent
 *
 * Publishes an OH CommonEvent.
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityManagerAdapter_nativePublishCommonEvent(
        JNIEnv* env, jclass clazz,
        jstring ohAction, jstring extrasJson, jstring uri,
        jint code, jstring data,
        jboolean ordered, jboolean sticky,
        jobjectArray subscriberPermissions) {

    std::string action = jstringToString(env, ohAction);
    std::string extras = jstringToString(env, extrasJson);
    std::string uriStr = jstringToString(env, uri);
    std::string dataStr = jstringToString(env, data);

    std::vector<std::string> permissions;
    if (subscriberPermissions) {
        int count = env->GetArrayLength(subscriberPermissions);
        for (int i = 0; i < count; i++) {
            jstring jstr = (jstring)env->GetObjectArrayElement(subscriberPermissions, i);
            permissions.push_back(jstringToString(env, jstr));
            if (jstr) env->DeleteLocalRef(jstr);
        }
    }

    return OHCommonEventClient::getInstance().publish(
            action, extras, uriStr, code, dataStr, ordered, sticky, permissions);
}

/*
 * Class:     adapter_bridge_ActivityManagerAdapter
 * Method:    nativeFinishCommonEvent
 *
 * Finishes processing an ordered CommonEvent (bridges Android finishReceiver).
 */
JNIEXPORT jint JNICALL
Java_adapter_bridge_ActivityManagerAdapter_nativeFinishCommonEvent(
        JNIEnv* env, jclass clazz,
        jint subscriptionId, jint resultCode, jstring resultData,
        jboolean abortEvent) {

    std::string data = jstringToString(env, resultData);
    return OHCommonEventClient::getInstance().finishReceiver(
            subscriptionId, resultCode, data, abortEvent);
}

/*
 * Class:     adapter_bridge_ActivityManagerAdapter
 * Method:    nativeGetStickyCommonEvent
 *
 * Queries a sticky CommonEvent.
 */
JNIEXPORT jstring JNICALL
Java_adapter_bridge_ActivityManagerAdapter_nativeGetStickyCommonEvent(
        JNIEnv* env, jclass clazz, jstring ohEventName) {

    std::string event = jstringToString(env, ohEventName);
    std::string result = OHCommonEventClient::getInstance().getStickyEvent(event);
    if (result.empty()) {
        return nullptr;
    }
    return env->NewStringUTF(result.c_str());
}

}  // extern "C"
