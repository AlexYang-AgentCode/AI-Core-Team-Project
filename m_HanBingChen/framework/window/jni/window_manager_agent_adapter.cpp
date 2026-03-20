/*
 * window_manager_agent_adapter.cpp
 *
 * Reverse callback adapter: OH IWindowManagerAgent -> Android internal handling.
 *
 * Most OH IWindowManagerAgent callbacks have no direct Android counterpart.
 * The few PARTIAL callbacks are routed to internal Android mechanisms.
 */
#include "window_manager_agent_adapter.h"
#include <android/log.h>

#define LOG_TAG "OH_WMAgentAdapter"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)

namespace oh_adapter {

WindowManagerAgentAdapter::WindowManagerAgentAdapter(JavaVM* jvm)
    : jvm_(jvm) {
    LOGI("WindowManagerAgentAdapter created");
}

WindowManagerAgentAdapter::~WindowManagerAgentAdapter() {
    LOGI("WindowManagerAgentAdapter destroyed");
}

JNIEnv* WindowManagerAgentAdapter::getJNIEnv() {
    JNIEnv* env = nullptr;
    if (jvm_->GetEnv(reinterpret_cast<void**>(&env), JNI_VERSION_1_6) != JNI_OK) {
        jvm_->AttachCurrentThread(&env, nullptr);
    }
    return env;
}

// ============================================================
// Category 1: Focus
// ============================================================

void WindowManagerAgentAdapter::UpdateFocusChangeInfo(
        const sptr<OHOS::Rosen::FocusChangeInfo>& focusChangeInfo, bool focused) {
    logPartial("UpdateFocusChangeInfo",
               "Route to ViewRootImpl.windowFocusChanged internally");
    // TODO: Phase 2 - Look up Android window by OH window ID,
    // call ViewRootImpl.windowFocusChanged(focused) via JNI
}

// ============================================================
// Category 2: Window Visibility
// ============================================================

void WindowManagerAgentAdapter::UpdateWindowVisibilityInfo(
        const std::vector<sptr<OHOS::Rosen::WindowVisibilityInfo>>& visibilityInfos) {
    logPartial("UpdateWindowVisibilityInfo",
               "Route to IWindow.dispatchAppVisibility per window");
    // TODO: Phase 2 - For each visibility change, find corresponding
    // Android IWindow and call dispatchAppVisibility(visible) via JNI
}

void WindowManagerAgentAdapter::UpdateVisibleWindowNum(
        const std::vector<OHOS::Rosen::VisibleWindowNumInfo>& visibleWindowNumInfo) {
    logOhOnly("UpdateVisibleWindowNum",
              "Android doesn't expose window count to apps");
}

void WindowManagerAgentAdapter::NotifyWindowPidVisibilityChanged(
        const sptr<OHOS::Rosen::WindowPidVisibilityInfo>& info) {
    logOhOnly("NotifyWindowPidVisibilityChanged",
              "Android doesn't track per-PID visibility this way");
}

// ============================================================
// Category 3: Window Mode
// ============================================================

void WindowManagerAgentAdapter::UpdateWindowModeTypeInfo(OHOS::Rosen::WindowModeType type) {
    logPartial("UpdateWindowModeTypeInfo",
               "Trigger Configuration.windowConfiguration change");
    // TODO: Phase 2 - Trigger configuration change via ActivityManagerService
}

// ============================================================
// Category 4: System Bar
// ============================================================

void WindowManagerAgentAdapter::UpdateSystemBarRegionTints(
        OHOS::Rosen::DisplayId displayId,
        const OHOS::Rosen::SystemBarRegionTints& tints) {
    logPartial("UpdateSystemBarRegionTints",
               "Android uses Window.setStatusBarColor/setNavigationBarColor");
}

void WindowManagerAgentAdapter::NotifyWindowSystemBarPropertyChange(
        OHOS::Rosen::WindowType type,
        const OHOS::Rosen::SystemBarProperty& systemBarProperty) {
    logOhOnly("NotifyWindowSystemBarPropertyChange",
              "OH system bar property, Android uses DecorView");
}

// ============================================================
// Category 5: Accessibility
// ============================================================

void WindowManagerAgentAdapter::NotifyAccessibilityWindowInfo(
        const std::vector<sptr<OHOS::Rosen::AccessibilityWindowInfo>>& infos,
        OHOS::Rosen::WindowUpdateType type) {
    logPartial("NotifyAccessibilityWindowInfo",
               "-> AccessibilityManagerService (conversion needed)");
    // TODO: Phase 2 - Convert OH AccessibilityWindowInfo to Android format
    // and forward to AccessibilityManagerService
}

// ============================================================
// Category 6: Display Group (OH_ONLY)
// ============================================================

void WindowManagerAgentAdapter::UpdateDisplayGroupInfo(
        OHOS::Rosen::DisplayGroupId displayGroupId,
        OHOS::Rosen::DisplayId displayId, bool isAdd) {
    logOhOnly("UpdateDisplayGroupInfo",
              "Android uses DisplayManagerService for multi-display");
}

// ============================================================
// Category 7: Camera / Float Window (OH_ONLY)
// ============================================================

void WindowManagerAgentAdapter::UpdateCameraFloatWindowStatus(
        uint32_t accessTokenId, bool isShowing) {
    logOhOnly("UpdateCameraFloatWindowStatus",
              "Android uses StatusBar camera indicator");
}

void WindowManagerAgentAdapter::UpdateCameraWindowStatus(
        uint32_t accessTokenId, bool isShowing) {
    logOhOnly("UpdateCameraWindowStatus", "OH camera window state");
}

// ============================================================
// Category 8: Window Drawing Content (OH_ONLY)
// ============================================================

void WindowManagerAgentAdapter::UpdateWindowDrawingContentInfo(
        const std::vector<sptr<OHOS::Rosen::WindowDrawingContentInfo>>& infos) {
    logOhOnly("UpdateWindowDrawingContentInfo",
              "Android rendering handled internally");
}

// ============================================================
// Category 9: Gesture / Style / PiP (OH_ONLY)
// ============================================================

void WindowManagerAgentAdapter::NotifyGestureNavigationEnabledResult(bool enable) {
    logOhOnly("NotifyGestureNavigationEnabledResult",
              "Android manages gesture nav via SystemUI");
}

void WindowManagerAgentAdapter::NotifyWaterMarkFlagChangedResult(bool isShowing) {
    logOhOnly("NotifyWaterMarkFlagChangedResult", "OH watermark feature");
}

void WindowManagerAgentAdapter::NotifyWindowStyleChange(OHOS::Rosen::WindowStyleType type) {
    logOhOnly("NotifyWindowStyleChange", "OH window style");
}

void WindowManagerAgentAdapter::NotifyCallingWindowDisplayChanged(
        const OHOS::Rosen::CallingWindowInfo& callingWindowInfo) {
    logOhOnly("NotifyCallingWindowDisplayChanged", "OH calling window display");
}

void WindowManagerAgentAdapter::UpdatePiPWindowStateChanged(
        const std::string& bundleName, bool isForeground) {
    logOhOnly("UpdatePiPWindowStateChanged",
              "Android handles PiP at Activity level");
}

void WindowManagerAgentAdapter::NotifyWindowPropertyChange(
        uint32_t propertyDirtyFlags,
        const OHOS::Rosen::WindowInfoList& windowInfoList) {
    logOhOnly("NotifyWindowPropertyChange", "OH window property update");
}

void WindowManagerAgentAdapter::NotifySupportRotationChange(
        const OHOS::Rosen::SupportRotationInfo& supportRotationInfo) {
    logOhOnly("NotifySupportRotationChange", "OH rotation support info");
}

// ============================================================
// Utility
// ============================================================

void WindowManagerAgentAdapter::logPartial(const char* method, const char* reason) {
    LOGD("[PARTIAL] %s - %s", method, reason);
}

void WindowManagerAgentAdapter::logOhOnly(const char* method, const char* reason) {
    LOGD("[OH_ONLY] %s - %s", method, reason);
}

}  // namespace oh_adapter
