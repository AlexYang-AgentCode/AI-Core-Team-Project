/*
 * oh_window_manager_client.cpp
 *
 * OpenHarmony WindowManager / SceneSessionManager IPC client implementation.
 *
 * Connects to OH SceneSessionManager (scene-based WMS) and provides window
 * session lifecycle management. Each Android window maps to an OH session
 * backed by an RSSurfaceNode for rendering.
 *
 * IPC flow for Hello World window display:
 *   1. createSession() -> SSM.CreateAndConnectSpecificSession()
 *      - Creates an OH scene session via ISceneSessionManager (system singleton)
 *      - Registers SessionStageAdapter as ISessionStage callback
 *      - Returns ISession proxy (per-window) + RSSurfaceNode ID
 *   2. updateSessionRect() -> ISession.UpdateSessionRect()
 *      - Sets window position and size via per-window ISession proxy
 *   3. notifyDrawingCompleted() -> ISession.DrawingCompleted()
 *      - Tells OH compositor the window is ready to display
 *   4. destroySession() -> ISession.Disconnect() + SSM.DestroyAndDisconnectSpecificSession()
 *      - Disconnects per-window session, then notifies SSM to clean up
 *
 * Reference:
 *   OH: wms/window_scene/session_manager/include/zidl/scene_session_manager_interface.h
 *   OH: wms/window_scene/session/host/include/zidl/session_interface.h
 */
#include "oh_window_manager_client.h"
#include "session_stage_adapter.h"
#include "window_callback_adapter.h"
#include <android/log.h>
#include <map>

#include "ipc_skeleton.h"
#include "system_ability_manager_proxy.h"
#include "scene_session_manager_interface.h"
#include "session_interface.h"
#include "window_manager_hilog.h"

#define LOG_TAG "OH_WindowMgrClient"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

// OH system ability IDs
// SA 4606 = WindowManagerService (IWindowManager, legacy — not used by adapter)
// SA 4607 = SceneSessionManager (ISceneSessionManager extends IWindowManager)
static constexpr int32_t SCENE_SESSION_MANAGER_ID = 4607;

namespace oh_adapter {

OHWindowManagerClient& OHWindowManagerClient::getInstance() {
    static OHWindowManagerClient instance;
    return instance;
}

bool OHWindowManagerClient::connect() {
    LOGI("Connecting to OH SceneSessionManager (SA %d)...", SCENE_SESSION_MANAGER_ID);

    auto samgr = OHOS::SystemAbilityManagerClient::GetInstance().GetSystemAbilityManager();
    if (samgr == nullptr) {
        LOGE("Failed to get SystemAbilityManager");
        return false;
    }

    // Connect to SceneSessionManager (SA 4607)
    // ISceneSessionManager extends IWindowManager, so it covers all window operations.
    // The legacy IWindowManager (SA 4606) is not needed for Android app adaptation.
    ssmProxy_ = samgr->GetSystemAbility(SCENE_SESSION_MANAGER_ID);
    if (ssmProxy_ == nullptr) {
        LOGE("SceneSessionManager not available (SA ID=%d)", SCENE_SESSION_MANAGER_ID);
        connected_ = false;
        return false;
    }

    LOGI("Connected to SceneSessionManager (SA %d)", SCENE_SESSION_MANAGER_ID);
    connected_ = true;
    return true;
}

void OHWindowManagerClient::disconnect() {
    LOGI("Disconnecting from OH window services");

    std::lock_guard<std::mutex> lock(sessionMutex_);
    sessions_.clear();
    ssmProxy_ = nullptr;
    connected_ = false;
}

OHWindowSession OHWindowManagerClient::createSession(
    JavaVM* jvm, jobject androidWindow,
    const std::string& windowName, int32_t windowType,
    int32_t displayId, int32_t requestedWidth, int32_t requestedHeight)
{
    OHWindowSession result;

    if (!connected_ || ssmProxy_ == nullptr) {
        LOGE("createSession: Not connected to SceneSessionManager");
        return result;
    }

    LOGI("createSession: name=%s, type=%d, display=%d, size=%dx%d",
         windowName.c_str(), windowType, displayId, requestedWidth, requestedHeight);

    // Create callback adapters for this window
    // SessionStageAdapter receives session state callbacks from OH SSM
    OHOS::sptr<SessionStageAdapter> stageAdapter = new SessionStageAdapter(jvm, androidWindow);

    // WindowCallbackAdapter receives window state callbacks from OH WMS
    OHOS::sptr<WindowCallbackAdapter> windowAdapter = new WindowCallbackAdapter(jvm, androidWindow);

    // Build session property for the request
    // OH SessionProperty contains window type, rect, display info
    OHOS::Rosen::SessionInfo sessionInfo;
    sessionInfo.bundleName_ = windowName;
    sessionInfo.abilityName_ = windowName;

    // IPC call: SceneSessionManager.CreateAndConnectSpecificSession
    // This creates a scene session on the server side and connects our
    // SessionStageAdapter as the callback endpoint.
    auto ssmInterface = OHOS::iface_cast<OHOS::Rosen::ISceneSessionManager>(ssmProxy_);
    if (ssmInterface == nullptr) {
        LOGE("createSession: Failed to cast to ISceneSessionManager");
        return result;
    }

    OHOS::sptr<OHOS::Rosen::ISession> session = nullptr;
    OHOS::Rosen::WindowProperty windowProperty;
    windowProperty.SetWindowType(static_cast<OHOS::Rosen::WindowType>(windowType));
    windowProperty.SetWindowRect({0, 0, static_cast<uint32_t>(requestedWidth),
                                       static_cast<uint32_t>(requestedHeight)});
    windowProperty.SetDisplayId(displayId);

    OHOS::sptr<OHOS::IRemoteObject> token = nullptr;
    int32_t persistentId = 0;

    auto ret = ssmInterface->CreateAndConnectSpecificSession(
        stageAdapter, windowAdapter, sessionInfo, session, token,
        windowProperty, persistentId);

    if (ret != OHOS::Rosen::WSError::WS_OK || session == nullptr) {
        LOGE("createSession: CreateAndConnectSpecificSession failed (ret=%d)", static_cast<int>(ret));
        return result;
    }

    // Extract surface node information from the session
    // The RSSurfaceNode ID is used by Android's SurfaceControl to render
    // into the OH RenderService compositing tree.
    int64_t surfaceNodeId = 0;
    auto surfaceNode = windowProperty.GetRSSurfaceNode();
    if (surfaceNode) {
        surfaceNodeId = static_cast<int64_t>(surfaceNode->GetId());
    }

    int32_t sessionId;
    {
        std::lock_guard<std::mutex> lock(sessionMutex_);
        sessionId = persistentId > 0 ? persistentId : nextSessionId_++;
        sessions_[sessionId] = {sessionId, surfaceNodeId, session, stageAdapter, windowAdapter};
    }

    result.sessionId = sessionId;
    result.surfaceNodeId = static_cast<int32_t>(surfaceNodeId);
    result.displayId = displayId;
    result.width = requestedWidth;
    result.height = requestedHeight;
    result.valid = true;

    LOGI("createSession: success, sessionId=%d, surfaceNodeId=%lld",
         sessionId, static_cast<long long>(surfaceNodeId));
    return result;
}

int OHWindowManagerClient::updateSessionRect(int32_t sessionId,
                                              int32_t x, int32_t y,
                                              int32_t width, int32_t height)
{
    LOGI("updateSessionRect: session=%d, rect=[%d,%d,%d,%d]",
         sessionId, x, y, width, height);

    // Use per-window ISession proxy (NOT the system-wide ISceneSessionManager)
    OHOS::sptr<OHOS::Rosen::ISession> sessionProxy;
    {
        std::lock_guard<std::mutex> lock(sessionMutex_);
        auto it = sessions_.find(sessionId);
        if (it == sessions_.end() || it->second.sessionProxy == nullptr) {
            LOGE("updateSessionRect: No ISession proxy for session %d", sessionId);
            return -1;
        }
        sessionProxy = it->second.sessionProxy;
    }

    OHOS::Rosen::WSRect rect = {x, y, static_cast<int32_t>(width), static_cast<int32_t>(height)};
    auto ret = sessionProxy->UpdateSessionRect(rect,
        OHOS::Rosen::SizeChangeReason::UNDEFINED);

    if (ret != OHOS::Rosen::WSError::WS_OK) {
        LOGE("updateSessionRect: failed (ret=%d)", static_cast<int>(ret));
        return static_cast<int>(ret);
    }

    return 0;
}

int OHWindowManagerClient::notifyDrawingCompleted(int32_t sessionId) {
    LOGI("notifyDrawingCompleted: session=%d", sessionId);

    // Use per-window ISession proxy (NOT the system-wide ISceneSessionManager)
    OHOS::sptr<OHOS::Rosen::ISession> sessionProxy;
    {
        std::lock_guard<std::mutex> lock(sessionMutex_);
        auto it = sessions_.find(sessionId);
        if (it == sessions_.end() || it->second.sessionProxy == nullptr) {
            LOGE("notifyDrawingCompleted: No ISession proxy for session %d", sessionId);
            return -1;
        }
        sessionProxy = it->second.sessionProxy;
    }

    auto ret = sessionProxy->DrawingCompleted();
    return (ret == OHOS::Rosen::WSError::WS_OK) ? 0 : static_cast<int>(ret);
}

void OHWindowManagerClient::destroySession(int32_t sessionId) {
    LOGI("destroySession: session=%d", sessionId);

    OHOS::sptr<OHOS::Rosen::ISession> sessionProxy;
    {
        std::lock_guard<std::mutex> lock(sessionMutex_);
        auto it = sessions_.find(sessionId);
        if (it != sessions_.end()) {
            sessionProxy = it->second.sessionProxy;
            sessions_.erase(it);
        }
    }

    // Disconnect via per-window ISession first
    if (sessionProxy != nullptr) {
        sessionProxy->Disconnect();
    }

    // Then notify SceneSessionManager to destroy the session record
    if (connected_ && ssmProxy_ != nullptr) {
        auto ssmInterface = OHOS::iface_cast<OHOS::Rosen::ISceneSessionManager>(ssmProxy_);
        if (ssmInterface) {
            ssmInterface->DestroyAndDisconnectSpecificSession(sessionId);
        }
    }
}

int64_t OHWindowManagerClient::getSurfaceNodeId(int32_t sessionId) const {
    auto it = sessions_.find(sessionId);
    if (it != sessions_.end()) {
        return it->second.surfaceNodeId;
    }
    return -1;
}

}  // namespace oh_adapter
