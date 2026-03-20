/*
 * window_callback_adapter.cpp
 *
 * Implementation of WindowCallbackAdapter.
 * Bridges OH IWindow callbacks to Android IWindow via JNI.
 */

#include "window_callback_adapter.h"
#include "adapter_bridge.h"

#include <android/log.h>
#include <cstdarg>

#define LOG_TAG "OH_WindowAdapter"
#define ALOGD(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define ALOGI(...) __android_log_print(ANDROID_LOG_INFO,  LOG_TAG, __VA_ARGS__)
#define ALOGW(...) __android_log_print(ANDROID_LOG_WARN,  LOG_TAG, __VA_ARGS__)
#define ALOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace oh_adapter {

// ================================================================
// Construction / Destruction
// ================================================================

WindowCallbackAdapter::WindowCallbackAdapter(JavaVM* jvm, jobject androidWindow)
    : jvm_(jvm)
{
    ALOGI("WindowCallbackAdapter created");

    JNIEnv* env = nullptr;
    bool needsDetach = false;
    env = getJNIEnv(needsDetach);
    if (!env) {
        ALOGE("Failed to get JNIEnv in constructor");
        return;
    }

    // Store Android IWindow as a global reference
    androidWindow_ = env->NewGlobalRef(androidWindow);

    // Create the Java-side WindowCallbackBridge instance
    jclass localBridgeClass = env->FindClass(
        "adapter/bridge/callback/WindowCallbackBridge");
    if (!localBridgeClass) {
        ALOGE("Failed to find WindowCallbackBridge class");
        detachIfNeeded(needsDetach);
        return;
    }
    bridgeClass_ = reinterpret_cast<jclass>(env->NewGlobalRef(localBridgeClass));
    env->DeleteLocalRef(localBridgeClass);

    // Construct WindowCallbackBridge(Object androidWindow)
    jmethodID ctor = env->GetMethodID(bridgeClass_, "<init>",
        "(Ljava/lang/Object;)V");
    if (!ctor) {
        ALOGE("Failed to find WindowCallbackBridge constructor");
        detachIfNeeded(needsDetach);
        return;
    }

    jobject localBridgeObj = env->NewObject(bridgeClass_, ctor,
        androidWindow_);
    if (!localBridgeObj) {
        ALOGE("Failed to create WindowCallbackBridge instance");
        detachIfNeeded(needsDetach);
        return;
    }
    bridgeObj_ = env->NewGlobalRef(localBridgeObj);
    env->DeleteLocalRef(localBridgeObj);

    detachIfNeeded(needsDetach);
    ALOGI("WindowCallbackAdapter initialized successfully");
}

WindowCallbackAdapter::~WindowCallbackAdapter()
{
    ALOGI("WindowCallbackAdapter destroyed");

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
// Category 1: Window Geometry
// ================================================================

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateWindowRect(
    const struct OHOS::Rosen::Rect& rect, bool decoStatus,
    OHOS::Rosen::WindowSizeChangeReason reason,
    const std::shared_ptr<OHOS::Rosen::RSTransaction>& /*rsTransaction*/)
{
    ALOGD("[BRIDGED] UpdateWindowRect -> IWindow.resized (rect=[%d,%d,%d,%d], decoStatus=%d, reason=%d)",
          rect.posX_, rect.posY_, rect.width_, rect.height_,
          static_cast<int>(decoStatus), static_cast<int>(reason));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateWindowRect", "(IIIIZI)V",
        rect.posX_, rect.posY_,
        rect.posX_ + rect.width_,
        rect.posY_ + rect.height_,
        static_cast<jboolean>(decoStatus),
        static_cast<jint>(reason));

    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateWindowMode(OHOS::Rosen::WindowMode mode)
{
    ALOGD("[BRIDGED] UpdateWindowMode -> IWindow.resized (mode=%d)", static_cast<int>(mode));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateWindowMode", "(I)V", static_cast<jint>(mode));

    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateWindowModeSupportType(uint32_t windowModeSupportType)
{
    ALOGD("[OH_ONLY] UpdateWindowModeSupportType (supportType=%u) - Android WMS manages mode support internally",
          windowModeSupportType);

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateWindowModeSupportType", "(I)V",
        static_cast<jint>(windowModeSupportType));

    return OHOS::Rosen::WMError::WM_OK;
}

// ================================================================
// Category 2: Focus
// ================================================================

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateFocusStatus(bool focused)
{
    ALOGD("[BRIDGED] UpdateFocusStatus -> IWindow.windowFocusChanged(focused=%d)",
          static_cast<int>(focused));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateFocusStatus", "(Z)V", static_cast<jboolean>(focused));

    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateActiveStatus(bool isActive)
{
    ALOGD("[OH_ONLY] UpdateActiveStatus (isActive=%d) - Android handles active state internally",
          static_cast<int>(isActive));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateActiveStatus", "(Z)V", static_cast<jboolean>(isActive));

    return OHOS::Rosen::WMError::WM_OK;
}

// ================================================================
// Category 3: Avoid Area / Insets
// ================================================================

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateAvoidArea(
    const OHOS::sptr<OHOS::Rosen::AvoidArea>& avoidArea, OHOS::Rosen::AvoidAreaType type)
{
    ALOGD("[BRIDGED] UpdateAvoidArea -> IWindow.insetsChanged (type=%d)", static_cast<int>(type));

    if (!avoidArea) {
        ALOGW("UpdateAvoidArea: avoidArea is null");
        return OHOS::Rosen::WMError::WM_ERROR_NULLPTR;
    }

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateAvoidArea", "(IIIII)V",
        static_cast<jint>(type),
        static_cast<jint>(avoidArea->topRect_.posX_),
        static_cast<jint>(avoidArea->topRect_.posY_),
        static_cast<jint>(avoidArea->bottomRect_.posX_ + avoidArea->bottomRect_.width_),
        static_cast<jint>(avoidArea->bottomRect_.posY_ + avoidArea->bottomRect_.height_));

    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateOccupiedAreaChangeInfo(
    const OHOS::sptr<OHOS::Rosen::OccupiedAreaChangeInfo>& info,
    const std::map<OHOS::Rosen::AvoidAreaType, OHOS::Rosen::AvoidArea>& /*avoidAreas*/,
    const std::shared_ptr<OHOS::Rosen::RSTransaction>& /*rsTransaction*/)
{
    ALOGD("[BRIDGED] UpdateOccupiedAreaChangeInfo -> IWindow.insetsControlChanged (IME)");

    int occupiedHeight = 0;
    if (info) {
        occupiedHeight = info->rect_.height_;
    }

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateOccupiedAreaChangeInfo", "(I)V",
        static_cast<jint>(occupiedHeight));

    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateOccupiedAreaAndRect(
    const OHOS::sptr<OHOS::Rosen::OccupiedAreaChangeInfo>& /*info*/,
    const OHOS::Rosen::Rect& /*rect*/,
    const std::map<OHOS::Rosen::AvoidAreaType, OHOS::Rosen::AvoidArea>& /*avoidAreas*/,
    const std::shared_ptr<OHOS::Rosen::RSTransaction>& /*rsTransaction*/)
{
    ALOGD("[BRIDGED] UpdateOccupiedAreaAndRect -> IWindow.resized (combined insets + rect)");

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateOccupiedAreaAndRect", "()V");

    return OHOS::Rosen::WMError::WM_OK;
}

// ================================================================
// Category 4: Visibility / Lifecycle
// ================================================================

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateWindowState(OHOS::Rosen::WindowState state)
{
    ALOGD("[BRIDGED] UpdateWindowState -> IWindow.dispatchAppVisibility (state=%d)",
          static_cast<int>(state));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateWindowState", "(I)V", static_cast<jint>(state));

    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::NotifyForeground(void)
{
    ALOGD("[BRIDGED] NotifyForeground -> IWindow.dispatchAppVisibility(true)");

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onNotifyForeground", "()V");

    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::NotifyBackground(void)
{
    ALOGD("[BRIDGED] NotifyBackground -> IWindow.dispatchAppVisibility(false)");

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onNotifyBackground", "()V");

    return OHOS::Rosen::WMError::WM_OK;
}

void WindowCallbackAdapter::NotifyForegroundInteractiveStatus(bool interactive)
{
    ALOGD("[BRIDGED] NotifyForegroundInteractiveStatus -> IWindow.dispatchAppVisibility(%d)",
          static_cast<int>(interactive));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onNotifyForegroundInteractiveStatus", "(Z)V",
        static_cast<jboolean>(interactive));
}

OHOS::Rosen::WMError WindowCallbackAdapter::NotifyDestroy(void)
{
    ALOGD("[LOG_ONLY] NotifyDestroy - lifecycle handled elsewhere (Activity/ViewRootImpl)");
    // Destruction is managed at a higher level via Activity lifecycle.
    // Intentionally not forwarding to Android IWindow.
    return OHOS::Rosen::WMError::WM_OK;
}

// ================================================================
// Category 5: Drag / Input
// ================================================================

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateWindowDragInfo(
    const OHOS::Rosen::PointInfo& point, OHOS::Rosen::DragEvent event)
{
    ALOGD("[BRIDGED] UpdateWindowDragInfo -> IWindow.dispatchDragEvent (x=%f, y=%f, event=%d)",
          point.x, point.y, static_cast<int>(event));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateWindowDragInfo", "(FFI)V",
        static_cast<jfloat>(point.x),
        static_cast<jfloat>(point.y),
        static_cast<jint>(event));

    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::NotifyWindowClientPointUp(
    const std::shared_ptr<OHOS::MMI::PointerEvent>& /*pointerEvent*/)
{
    ALOGD("[OH_ONLY] NotifyWindowClientPointUp - Android uses input channel for touch events");

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onNotifyWindowClientPointUp", "()V");

    return OHOS::Rosen::WMError::WM_OK;
}

void WindowCallbackAdapter::ConsumeKeyEvent(std::shared_ptr<OHOS::MMI::KeyEvent> /*event*/)
{
    ALOGD("[OH_ONLY] ConsumeKeyEvent - Android uses input channel for key events");

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onConsumeKeyEvent", "()V");
}

// ================================================================
// Category 6: Display
// ================================================================

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateDisplayId(
    OHOS::Rosen::DisplayId from, OHOS::Rosen::DisplayId to)
{
    ALOGD("[BRIDGED] UpdateDisplayId -> IWindow.resized (from=%llu, to=%llu)",
          static_cast<unsigned long long>(from), static_cast<unsigned long long>(to));

    std::lock_guard<std::mutex> lock(jniMutex_);
    callBridgeVoidMethod("onUpdateDisplayId", "(JJ)V",
        static_cast<jlong>(from), static_cast<jlong>(to));

    return OHOS::Rosen::WMError::WM_OK;
}

// ================================================================
// Category 7: Screenshot / Debug / Misc (all OH_ONLY)
// ================================================================

OHOS::Rosen::WMError WindowCallbackAdapter::NotifyScreenshot()
{
    ALOGD("[OH_ONLY] NotifyScreenshot - Android uses file observer or Activity callback");
    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::NotifyScreenshotAppEvent(
    OHOS::Rosen::ScreenshotEventType type)
{
    ALOGD("[OH_ONLY] NotifyScreenshotAppEvent (type=%d) - Android handles differently",
          static_cast<int>(type));
    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::NotifyTouchOutside()
{
    ALOGD("[OH_ONLY] NotifyTouchOutside - Android uses ACTION_OUTSIDE via input channel");
    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::sptr<OHOS::Rosen::WindowProperty> WindowCallbackAdapter::GetWindowProperty()
{
    ALOGD("[OH_ONLY] GetWindowProperty - Android uses WindowManager.LayoutParams");
    return nullptr;
}

OHOS::Rosen::WMError WindowCallbackAdapter::DumpInfo(const std::vector<std::string>& params)
{
    ALOGD("[OH_ONLY] DumpInfo - debug dump (%zu params)", params.size());
    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::UpdateZoomTransform(
    const OHOS::Rosen::Transform& /*trans*/, bool isDisplayZoomOn)
{
    ALOGD("[OH_ONLY] UpdateZoomTransform (zoomOn=%d) - Android handles zoom via Accessibility",
          static_cast<int>(isDisplayZoomOn));
    return OHOS::Rosen::WMError::WM_OK;
}

OHOS::Rosen::WMError WindowCallbackAdapter::RestoreSplitWindowMode(uint32_t mode)
{
    ALOGD("[OH_ONLY] RestoreSplitWindowMode (mode=%u) - Android manages split screen via WMS",
          mode);
    return OHOS::Rosen::WMError::WM_OK;
}

void WindowCallbackAdapter::NotifyMMIServiceOnline(uint32_t winId)
{
    ALOGD("[OH_ONLY] NotifyMMIServiceOnline (winId=%u) - OH MMI service, no Android equivalent",
          winId);
}

// ================================================================
// JNI Helpers
// ================================================================

JNIEnv* WindowCallbackAdapter::getJNIEnv(bool& needsDetach)
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
        args.name = "OH_WindowAdapter";
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

void WindowCallbackAdapter::detachIfNeeded(bool needsDetach)
{
    if (needsDetach && jvm_) {
        jvm_->DetachCurrentThread();
    }
}

void WindowCallbackAdapter::callBridgeVoidMethod(
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
