/*
 * session_stage_adapter.cpp
 *
 * Implementation of SessionStageAdapter.
 * Bridges OH ISessionStage callbacks to Android IWindow via JNI.
 */

#include "session_stage_adapter.h"
#include "adapter_bridge.h"

#include <android/log.h>
#include <cstdarg>

#define LOG_TAG "OH_SessionStageAdapter"
#define ALOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define ALOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN,  LOG_TAG, __VA_ARGS__)
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

using namespace OHOS::Rosen;
using WSError = OHOS::Rosen::WSError;
using WSErrorCode = OHOS::Rosen::WSErrorCode;
using WMError = OHOS::Rosen::WMError;

namespace oh_adapter {

// ================================================================
// Construction / Destruction
// ================================================================

SessionStageAdapter::SessionStageAdapter(JavaVM* jvm, jobject androidWindow)
    : jvm_(jvm)
{
    ALOGI("SessionStageAdapter created");

    JNIEnv* env = nullptr;
    bool needsDetach = false;
    env = getJNIEnv(needsDetach);
    if (!env) {
        ALOGE("Failed to get JNIEnv in constructor");
        return;
    }

    // Store Android IWindow as a global reference
    androidWindow_ = env->NewGlobalRef(androidWindow);

    // Create the Java-side SessionStageBridge instance
    jclass localBridgeClass = env->FindClass(
        "adapter/bridge/callback/SessionStageBridge");
    if (!localBridgeClass) {
        ALOGE("Failed to find SessionStageBridge class");
        detachIfNeeded(needsDetach);
        return;
    }
    bridgeClass_ = reinterpret_cast<jclass>(env->NewGlobalRef(localBridgeClass));
    env->DeleteLocalRef(localBridgeClass);

    // Construct SessionStageBridge(Object androidWindow)
    jmethodID ctor = env->GetMethodID(bridgeClass_, "<init>",
        "(Ljava/lang/Object;)V");
    if (!ctor) {
        ALOGE("Failed to find SessionStageBridge constructor");
        detachIfNeeded(needsDetach);
        return;
    }

    jobject localBridgeObj = env->NewObject(bridgeClass_, ctor,
        androidWindow_);
    if (!localBridgeObj) {
        ALOGE("Failed to create SessionStageBridge instance");
        detachIfNeeded(needsDetach);
        return;
    }
    bridgeObj_ = env->NewGlobalRef(localBridgeObj);
    env->DeleteLocalRef(localBridgeObj);

    detachIfNeeded(needsDetach);
    ALOGI("SessionStageAdapter initialized successfully");
}

SessionStageAdapter::~SessionStageAdapter()
{
    ALOGI("SessionStageAdapter destroyed");

    JNIEnv* env = nullptr;
    bool needsDetach = false;
    env = getJNIEnv(needsDetach);
    if (env) {
        if (androidWindow_) {
            env->DeleteGlobalRef(androidWindow_);
            androidWindow_ = nullptr;
        }
        if (bridgeObj_) {
            env->DeleteGlobalRef(bridgeObj_);
            bridgeObj_ = nullptr;
        }
        if (bridgeClass_) {
            env->DeleteGlobalRef(bridgeClass_);
            bridgeClass_ = nullptr;
        }
        detachIfNeeded(needsDetach);
    }
}

// ================================================================
// Category 1: Session Lifecycle
// ================================================================

WSError SessionStageAdapter::SetActive(bool active)
{
    ALOGD("[BRIDGED] SetActive(%d) -> IWindow.dispatchAppVisibility(%d)",
          static_cast<int>(active), static_cast<int>(active));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onSetActive", "(Z)V", static_cast<jboolean>(active));

    return WSError::WS_OK;
}

void SessionStageAdapter::NotifySessionForeground(uint32_t reason, bool withAnimation)
{
    ALOGD("[BRIDGED] NotifySessionForeground(reason=%u, anim=%d) -> IWindow.dispatchAppVisibility(true)",
          reason, static_cast<int>(withAnimation));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onNotifySessionForeground", "(IZ)V",
        static_cast<jint>(reason), static_cast<jboolean>(withAnimation));
}

void SessionStageAdapter::NotifySessionBackground(
    uint32_t reason, bool withAnimation, bool /*isFromInnerkits*/)
{
    ALOGD("[BRIDGED] NotifySessionBackground(reason=%u, anim=%d) -> IWindow.dispatchAppVisibility(false)",
          reason, static_cast<int>(withAnimation));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onNotifySessionBackground", "(IZ)V",
        static_cast<jint>(reason), static_cast<jboolean>(withAnimation));
}

WSError SessionStageAdapter::NotifyDestroy()
{
    ALOGD("[BRIDGED] NotifyDestroy -> lifecycle handling (Activity.onDestroy path)");

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onNotifyDestroy", "()V");

    return WSError::WS_OK;
}

WSError SessionStageAdapter::NotifyWindowVisibility(bool isVisible)
{
    ALOGD("[BRIDGED] NotifyWindowVisibility(%d) -> IWindow.dispatchAppVisibility(%d)",
          static_cast<int>(isVisible), static_cast<int>(isVisible));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onNotifyWindowVisibility", "(Z)V",
        static_cast<jboolean>(isVisible));

    return WSError::WS_OK;
}

WSError SessionStageAdapter::NotifyWindowOcclusionState(const WindowVisibilityState state)
{
    ALOGD("[OH_ONLY] NotifyWindowOcclusionState(state=%d) - Android infers occlusion from lifecycle",
          static_cast<int>(state));
    return WSError::WS_OK;
}

void SessionStageAdapter::NotifyForegroundInteractiveStatus(bool interactive)
{
    ALOGD("[BRIDGED] NotifyForegroundInteractiveStatus(%d) -> IWindow.dispatchAppVisibility",
          static_cast<int>(interactive));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onNotifyForegroundInteractiveStatus", "(Z)V",
        static_cast<jboolean>(interactive));
}

void SessionStageAdapter::NotifyLifecyclePausedStatus()
{
    ALOGD("[OH_ONLY] NotifyLifecyclePausedStatus - OH specific, Android uses Activity.onPause");
}

// ================================================================
// Category 2: Window Geometry
// ================================================================

WSError SessionStageAdapter::UpdateRect(const WSRect& rect, SizeChangeReason reason,
    const SceneAnimationConfig& /*config*/,
    const std::map<AvoidAreaType, AvoidArea>& /*avoidAreas*/)
{
    ALOGD("[BRIDGED] UpdateRect([%d,%d,%d,%d], reason=%d) -> IWindow.resized",
          rect.posX_, rect.posY_, rect.width_, rect.height_, static_cast<int>(reason));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateRect", "(IIIII)V",
        static_cast<jint>(rect.posX_),
        static_cast<jint>(rect.posY_),
        static_cast<jint>(rect.width_),
        static_cast<jint>(rect.height_),
        static_cast<jint>(reason));

    return WSError::WS_OK;
}

WSError SessionStageAdapter::UpdateGlobalDisplayRectFromServer(
    const WSRect& rect, SizeChangeReason reason)
{
    ALOGD("[BRIDGED] UpdateGlobalDisplayRectFromServer([%d,%d,%d,%d]) -> IWindow.resized",
          rect.posX_, rect.posY_, rect.width_, rect.height_);

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateGlobalDisplayRectFromServer", "(IIIII)V",
        static_cast<jint>(rect.posX_),
        static_cast<jint>(rect.posY_),
        static_cast<jint>(rect.width_),
        static_cast<jint>(rect.height_),
        static_cast<jint>(reason));

    return WSError::WS_OK;
}

// ================================================================
// Category 3: Window Mode
// ================================================================

WSError SessionStageAdapter::UpdateWindowMode(WindowMode mode)
{
    ALOGD("[BRIDGED] UpdateWindowMode(mode=%d) -> IWindow.resized (windowing mode in config)",
          static_cast<int>(mode));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateWindowMode", "(I)V", static_cast<jint>(mode));

    return WSError::WS_OK;
}

WSError SessionStageAdapter::UpdateMaximizeMode(MaximizeMode mode)
{
    ALOGD("[OH_ONLY] UpdateMaximizeMode(mode=%d) - map to Android FULLSCREEN",
          static_cast<int>(mode));
    return WSError::WS_OK;
}

WSError SessionStageAdapter::NotifyLayoutFinishAfterWindowModeChange(WindowMode mode)
{
    ALOGD("[OH_ONLY] NotifyLayoutFinishAfterWindowModeChange(mode=%d) - handled internally",
          static_cast<int>(mode));
    return WSError::WS_OK;
}

WSError SessionStageAdapter::SwitchFreeMultiWindow(bool enable)
{
    ALOGD("[OH_ONLY] SwitchFreeMultiWindow(%d) - OH free multi-window",
          static_cast<int>(enable));
    return WSError::WS_OK;
}

// ================================================================
// Category 4: Focus
// ================================================================

WSError SessionStageAdapter::UpdateFocus(
    const OHOS::sptr<FocusNotifyInfo>& /*focusNotifyInfo*/, bool isFocused)
{
    ALOGD("[BRIDGED] UpdateFocus(focused=%d) -> IWindow.windowFocusChanged",
          static_cast<int>(isFocused));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateFocus", "(Z)V", static_cast<jboolean>(isFocused));

    return WSError::WS_OK;
}

WSError SessionStageAdapter::NotifyHighlightChange(
    const OHOS::sptr<HighlightNotifyInfo>& /*highlightNotifyInfo*/, bool isHighlight)
{
    ALOGD("[OH_ONLY] NotifyHighlightChange(%d) - visual feedback only",
          static_cast<int>(isHighlight));
    return WSError::WS_OK;
}

// ================================================================
// Category 5: Avoid Area / Insets
// ================================================================

WSError SessionStageAdapter::UpdateAvoidArea(
    const OHOS::sptr<AvoidArea>& avoidArea, AvoidAreaType type)
{
    ALOGD("[BRIDGED] UpdateAvoidArea(type=%d) -> IWindow.insetsControlChanged",
          static_cast<int>(type));

    if (!avoidArea) {
        ALOGW("UpdateAvoidArea: avoidArea is null");
        return WSError::WS_ERROR_NULLPTR;
    }

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateAvoidArea", "(IIIII)V",
        static_cast<jint>(type),
        static_cast<jint>(avoidArea->topRect_.posX_),
        static_cast<jint>(avoidArea->topRect_.posY_),
        static_cast<jint>(avoidArea->bottomRect_.posX_ + avoidArea->bottomRect_.width_),
        static_cast<jint>(avoidArea->bottomRect_.posY_ + avoidArea->bottomRect_.height_));

    return WSError::WS_OK;
}

void SessionStageAdapter::NotifyOccupiedAreaChangeInfo(
    OHOS::sptr<OccupiedAreaChangeInfo> info,
    const std::shared_ptr<RSTransaction>& /*rsTransaction*/,
    const Rect& /*callingSessionRect*/,
    const std::map<AvoidAreaType, AvoidArea>& /*avoidAreas*/)
{
    int occupiedHeight = 0;
    if (info) {
        occupiedHeight = info->rect_.height_;
    }
    ALOGD("[BRIDGED] NotifyOccupiedAreaChangeInfo -> IWindow.insetsControlChanged (IME height=%d)",
          occupiedHeight);

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onNotifyOccupiedAreaChangeInfo", "(I)V",
        static_cast<jint>(occupiedHeight));
}

// ================================================================
// Category 6: Back Event
// ================================================================

WSError SessionStageAdapter::HandleBackEvent()
{
    ALOGD("[BRIDGED] HandleBackEvent -> inject KEYCODE_BACK via input channel");

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onHandleBackEvent", "()V");

    return WSError::WS_OK;
}

// ================================================================
// Category 7: Input Events
// ================================================================

WSError SessionStageAdapter::MarkProcessed(int32_t eventId)
{
    ALOGD("[OH_ONLY] MarkProcessed(eventId=%d) - Android uses InputChannel.finishInputEvent",
          eventId);
    return WSError::WS_OK;
}

WSError SessionStageAdapter::NotifyTouchOutside()
{
    ALOGD("[OH_ONLY] NotifyTouchOutside - Android uses ACTION_OUTSIDE via input channel");
    return WSError::WS_OK;
}

// ================================================================
// Category 8: Display / Density / Orientation
// ================================================================

void SessionStageAdapter::UpdateDensity()
{
    ALOGD("[BRIDGED] UpdateDensity -> IWindow.resized (density in MergedConfiguration)");

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateDensity", "()V");
}

WSError SessionStageAdapter::UpdateOrientation()
{
    ALOGD("[BRIDGED] UpdateOrientation -> IWindow.resized (orientation in config)");

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateOrientation", "()V");

    return WSError::WS_OK;
}

WSError SessionStageAdapter::UpdateDisplayId(uint64_t displayId)
{
    ALOGD("[BRIDGED] UpdateDisplayId(%llu) -> IWindow.resized (displayId)",
          static_cast<unsigned long long>(displayId));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateDisplayId", "(J)V", static_cast<jlong>(displayId));

    return WSError::WS_OK;
}

void SessionStageAdapter::NotifyDisplayMove(DisplayId from, DisplayId to)
{
    ALOGD("[OH_ONLY] NotifyDisplayMove(from=%llu, to=%llu)",
          static_cast<unsigned long long>(from), static_cast<unsigned long long>(to));
}

WSError SessionStageAdapter::UpdateSessionViewportConfig(const SessionViewportConfig& /*config*/)
{
    ALOGD("[OH_ONLY] UpdateSessionViewportConfig - viewport config update");
    return WSError::WS_OK;
}

// ================================================================
// Category 9: PiP
// ================================================================

WSError SessionStageAdapter::SetPipActionEvent(const std::string& action, int32_t status)
{
    ALOGD("[OH_ONLY] SetPipActionEvent(action=%s, status=%d)", action.c_str(), status);
    return WSError::WS_OK;
}

WSError SessionStageAdapter::NotifyPipWindowSizeChange(double width, double height, double scale)
{
    ALOGD("[OH_ONLY] NotifyPipWindowSizeChange(w=%f, h=%f, s=%f)", width, height, scale);
    return WSError::WS_OK;
}

WSError SessionStageAdapter::NotifyPiPActiveStatusChange(bool status)
{
    ALOGD("[OH_ONLY] NotifyPiPActiveStatusChange(%d)", static_cast<int>(status));
    return WSError::WS_OK;
}

WSError SessionStageAdapter::SetPiPControlEvent(
    WsPiPControlType controlType, WsPiPControlStatus status)
{
    ALOGD("[OH_ONLY] SetPiPControlEvent(type=%d, status=%d)",
          static_cast<int>(controlType), static_cast<int>(status));
    return WSError::WS_OK;
}

WSError SessionStageAdapter::NotifyCloseExistPipWindow()
{
    ALOGD("[OH_ONLY] NotifyCloseExistPipWindow");
    return WSError::WS_OK;
}

// ================================================================
// Category 10: Rotation
// ================================================================

WSError SessionStageAdapter::SetCurrentRotation(int32_t currentRotation)
{
    ALOGD("[OH_ONLY] SetCurrentRotation(%d)", currentRotation);
    return WSError::WS_OK;
}

// ================================================================
// Category 11: Screenshot
// ================================================================

void SessionStageAdapter::NotifyScreenshot()
{
    ALOGD("[OH_ONLY] NotifyScreenshot - Android uses file observer or Activity callback");
}

WSError SessionStageAdapter::NotifyScreenshotAppEvent(ScreenshotEventType type)
{
    ALOGD("[OH_ONLY] NotifyScreenshotAppEvent(type=%d)", static_cast<int>(type));
    return WSError::WS_OK;
}

// ================================================================
// Category 12: Extension / Component Data
// ================================================================

WSError SessionStageAdapter::NotifyTransferComponentData(
    const OHOS::AAFwk::WantParams& /*wantParams*/)
{
    ALOGD("[OH_ONLY] NotifyTransferComponentData - OH component data transfer");
    return WSError::WS_OK;
}

WSErrorCode SessionStageAdapter::NotifyTransferComponentDataSync(
    const OHOS::AAFwk::WantParams& /*wantParams*/,
    OHOS::AAFwk::WantParams& /*reWantParams*/)
{
    ALOGD("[OH_ONLY] NotifyTransferComponentDataSync - OH component data transfer");
    return WSErrorCode::WS_OK;
}

WSError SessionStageAdapter::NotifyExtensionSecureLimitChange(bool isLimit)
{
    ALOGD("[OH_ONLY] NotifyExtensionSecureLimitChange(%d)", static_cast<int>(isLimit));
    return WSError::WS_OK;
}

// ================================================================
// Category 13: Debug / Diagnostic
// ================================================================

void SessionStageAdapter::DumpSessionElementInfo(const std::vector<std::string>& params)
{
    ALOGD("[OH_ONLY] DumpSessionElementInfo (%zu params)", params.size());
}

WMError SessionStageAdapter::GetRouterStackInfo(std::string& routerStackInfo)
{
    ALOGD("[OH_ONLY] GetRouterStackInfo - OH navigation stack");
    routerStackInfo = "{}";
    return WMError::WM_OK;
}

WSError SessionStageAdapter::GetTopNavDestinationName(std::string& topNavDestName)
{
    ALOGD("[OH_ONLY] GetTopNavDestinationName - OH navigation");
    topNavDestName = "";
    return WSError::WS_OK;
}

// ================================================================
// Category 14: Transform / UI
// ================================================================

void SessionStageAdapter::NotifyTransformChange(const Transform& /*transform*/)
{
    ALOGD("[OH_ONLY] NotifyTransformChange - OH window transform");
}

void SessionStageAdapter::NotifySingleHandTransformChange(
    const SingleHandTransform& /*singleHandTransform*/)
{
    ALOGD("[OH_ONLY] NotifySingleHandTransformChange - OH single-hand mode");
}

WSError SessionStageAdapter::NotifyDialogStateChange(bool isForeground)
{
    ALOGD("[OH_ONLY] NotifyDialogStateChange(foreground=%d)", static_cast<int>(isForeground));
    return WSError::WS_OK;
}

WSError SessionStageAdapter::UpdateTitleInTargetPos(bool isShow, int32_t height)
{
    ALOGD("[OH_ONLY] UpdateTitleInTargetPos(show=%d, height=%d)",
          static_cast<int>(isShow), height);
    return WSError::WS_OK;
}

// ================================================================
// Category 15: Remaining OH_ONLY methods
// ================================================================

WSError SessionStageAdapter::NotifyAppForceLandscapeConfigUpdated()
{
    ALOGD("[OH_ONLY] NotifyAppForceLandscapeConfigUpdated");
    return WSError::WS_OK;
}

WSError SessionStageAdapter::NotifyAppForceLandscapeConfigEnableUpdated(bool /*needUpdateViewport*/)
{
    ALOGD("[OH_ONLY] NotifyAppForceLandscapeConfigEnableUpdated");
    return WSError::WS_OK;
}

WSError SessionStageAdapter::NotifyAppHookWindowInfoUpdated()
{
    ALOGD("[OH_ONLY] NotifyAppHookWindowInfoUpdated");
    return WSError::WS_OK;
}

void SessionStageAdapter::NotifyAppUseControlStatus(bool isUseControl)
{
    ALOGD("[OH_ONLY] NotifyAppUseControlStatus(%d)", static_cast<int>(isUseControl));
}

void SessionStageAdapter::SetUniqueVirtualPixelRatio(bool useUniqueDensity, float virtualPixelRatio)
{
    ALOGD("[OH_ONLY] SetUniqueVirtualPixelRatio(unique=%d, ratio=%f)",
          static_cast<int>(useUniqueDensity), virtualPixelRatio);
}

void SessionStageAdapter::UpdateAnimationSpeed(float speed)
{
    ALOGD("[OH_ONLY] UpdateAnimationSpeed(%f)", speed);
}

WSError SessionStageAdapter::GetUIContentRemoteObj(
    OHOS::sptr<OHOS::IRemoteObject>& uiContentRemoteObj)
{
    ALOGD("[OH_ONLY] GetUIContentRemoteObj");
    uiContentRemoteObj = nullptr;
    return WSError::WS_OK;
}

WSError SessionStageAdapter::LinkKeyFrameNode()
{
    ALOGD("[OH_ONLY] LinkKeyFrameNode - OH render engine feature");
    return WSError::WS_OK;
}

WSError SessionStageAdapter::SetStageKeyFramePolicy(const KeyFramePolicy& /*keyFramePolicy*/)
{
    ALOGD("[OH_ONLY] SetStageKeyFramePolicy");
    return WSError::WS_OK;
}

WSError SessionStageAdapter::SetSplitButtonVisible(bool isVisible)
{
    ALOGD("[OH_ONLY] SetSplitButtonVisible(%d)", static_cast<int>(isVisible));
    return WSError::WS_OK;
}

WSError SessionStageAdapter::SetEnableDragBySystem(bool dragEnable)
{
    ALOGD("[OH_ONLY] SetEnableDragBySystem(%d)", static_cast<int>(dragEnable));
    return WSError::WS_OK;
}

WSError SessionStageAdapter::SetDragActivated(bool dragActivated)
{
    ALOGD("[OH_ONLY] SetDragActivated(%d)", static_cast<int>(dragActivated));
    return WSError::WS_OK;
}

WSError SessionStageAdapter::SendContainerModalEvent(
    const std::string& eventName, const std::string& eventValue)
{
    ALOGD("[OH_ONLY] SendContainerModalEvent(%s, %s)", eventName.c_str(), eventValue.c_str());
    return WSError::WS_OK;
}

void SessionStageAdapter::NotifyWindowCrossAxisChange(CrossAxisState state)
{
    ALOGD("[OH_ONLY] NotifyWindowCrossAxisChange(state=%d)", static_cast<int>(state));
}

WSError SessionStageAdapter::SendFbActionEvent(const std::string& action)
{
    ALOGD("[OH_ONLY] SendFbActionEvent(%s)", action.c_str());
    return WSError::WS_OK;
}

WSError SessionStageAdapter::UpdateIsShowDecorInFreeMultiWindow(bool isShow)
{
    ALOGD("[OH_ONLY] UpdateIsShowDecorInFreeMultiWindow(%d)", static_cast<int>(isShow));
    return WSError::WS_OK;
}

WSError SessionStageAdapter::UpdateBrightness(float brightness)
{
    ALOGD("[OH_ONLY] UpdateBrightness(%f)", brightness);
    return WSError::WS_OK;
}

WMError SessionStageAdapter::UpdateWindowModeForUITest(int32_t updateMode)
{
    ALOGD("[OH_ONLY] UpdateWindowModeForUITest(%d)", updateMode);
    return WMError::WM_OK;
}

// ================================================================
// JNI Helpers
// ================================================================

JNIEnv* SessionStageAdapter::getJNIEnv(bool& needsDetach)
{
    needsDetach = false;
    if (!jvm_) {
        ALOGE("getJNIEnv: JavaVM is null");
        return nullptr;
    }

    JNIEnv* env = nullptr;
    jint result = jvm_->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6);
    if (result == JNI_OK) {
        return env;
    }

    if (result == JNI_EDETACHED) {
        JavaVMAttachArgs args;
        args.version = JNI_VERSION_1_6;
        args.name = "OH_SessionStageAdapter";
        args.group = nullptr;
        result = jvm_->AttachCurrentThread(&env, &args);
        if (result == JNI_OK) {
            needsDetach = true;
            return env;
        }
        ALOGE("getJNIEnv: AttachCurrentThread failed (result=%d)", result);
    }

    return nullptr;
}

void SessionStageAdapter::detachIfNeeded(bool needsDetach)
{
    if (needsDetach && jvm_) {
        jvm_->DetachCurrentThread();
    }
}

void SessionStageAdapter::callBridgeVoidMethod(
    const char* methodName, const char* signature, ...)
{
    if (!bridgeObj_ || !bridgeClass_) {
        ALOGW("callBridgeVoidMethod(%s): bridge not initialized", methodName);
        return;
    }

    bool needsDetach = false;
    JNIEnv* env = getJNIEnv(needsDetach);
    if (!env) {
        ALOGE("callBridgeVoidMethod(%s): failed to get JNIEnv", methodName);
        return;
    }

    jmethodID method = env->GetMethodID(bridgeClass_, methodName, signature);
    if (!method) {
        ALOGE("callBridgeVoidMethod: method %s%s not found", methodName, signature);
        env->ExceptionClear();
        detachIfNeeded(needsDetach);
        return;
    }

    va_list args;
    va_start(args, signature);
    env->CallVoidMethodV(bridgeObj_, method, args);
    va_end(args);

    if (env->ExceptionCheck()) {
        ALOGE("callBridgeVoidMethod(%s): Java exception occurred", methodName);
        env->ExceptionDescribe();
        env->ExceptionClear();
    }

    detachIfNeeded(needsDetach);
}

}  // namespace oh_adapter
