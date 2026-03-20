/*
 * oh_window_manager_client.h
 *
 * OpenHarmony WindowManager / SceneSessionManager IPC client.
 * Manages window creation, layout, and surface allocation for the adapter layer.
 *
 * OH WMS has two system services:
 *   - SA 4606: WindowManagerService (IWindowManager, legacy interface)
 *   - SA 4607: SceneSessionManager (ISceneSessionManager extends IWindowManager)
 *
 * ISceneSessionManager is a superset of IWindowManager. On modern OH with
 * SceneBoard enabled, only SA 4607 is needed. This adapter connects to SA 4607.
 *
 * Architecture:
 *   ISceneSessionManager (SA 4607) creates sessions via CreateAndConnectSpecificSession().
 *   ISession (per-window proxy, returned by creation) handles all per-window operations.
 *   SSM.CreateAndConnect() -> ISession.UpdateSessionRect() -> ISession.DrawingCompleted()
 */
#ifndef OH_WINDOW_MANAGER_CLIENT_H
#define OH_WINDOW_MANAGER_CLIENT_H

#include <jni.h>
#include <string>
#include <mutex>
#include "iremote_object.h"
#include "session_interface.h"

namespace oh_adapter {

class SessionStageAdapter;
class WindowCallbackAdapter;

/**
 * Window session info returned after creating a session with OH SceneSessionManager.
 */
struct OHWindowSession {
    int32_t sessionId = -1;
    int32_t surfaceNodeId = -1;    // OH RSSurfaceNode ID for rendering
    int32_t displayId = 0;
    int32_t width = 0;
    int32_t height = 0;
    bool valid = false;
};

class OHWindowManagerClient {
public:
    static OHWindowManagerClient& getInstance();

    /**
     * Connect to OH SceneSessionManager (SA 4607).
     */
    bool connect();

    /**
     * Disconnect from services.
     */
    void disconnect();

    /**
     * Create a window session with OH SceneSessionManager.
     * Registers a SessionStageAdapter as the callback endpoint.
     *
     * @param jvm               JavaVM pointer for callback threads.
     * @param androidWindow     Java IWindow instance for callbacks.
     * @param windowName        Window name for identification.
     * @param windowType        Android window type (TYPE_APPLICATION etc.).
     * @param displayId         Target display.
     * @param requestedWidth    Requested width in pixels.
     * @param requestedHeight   Requested height in pixels.
     * @return Session info including surface node ID.
     */
    OHWindowSession createSession(JavaVM* jvm, jobject androidWindow,
                                   const std::string& windowName,
                                   int32_t windowType, int32_t displayId,
                                   int32_t requestedWidth, int32_t requestedHeight);

    /**
     * Update session rectangle (relayout).
     *
     * @param sessionId     Session ID from createSession.
     * @param x             Left position.
     * @param y             Top position.
     * @param width         Width in pixels.
     * @param height        Height in pixels.
     * @return 0 on success.
     */
    int updateSessionRect(int32_t sessionId, int32_t x, int32_t y,
                          int32_t width, int32_t height);

    /**
     * Notify OH that drawing is completed for a session.
     *
     * @param sessionId     Session ID.
     * @return 0 on success.
     */
    int notifyDrawingCompleted(int32_t sessionId);

    /**
     * Destroy a window session.
     *
     * @param sessionId     Session ID to destroy.
     */
    void destroySession(int32_t sessionId);

    /**
     * Get the OH RSSurfaceNode ID for a session, used by Android's
     * SurfaceControl to render into the OH compositing tree.
     */
    int64_t getSurfaceNodeId(int32_t sessionId) const;

    bool isConnected() const { return connected_; }

private:
    OHWindowManagerClient() = default;
    ~OHWindowManagerClient() = default;

    bool connected_ = false;
    OHOS::sptr<OHOS::IRemoteObject> ssmProxy_ = nullptr;  // SceneSessionManager (SA 4607)

    // Track active sessions
    struct SessionEntry {
        int32_t sessionId;
        int64_t surfaceNodeId;
        OHOS::sptr<OHOS::Rosen::ISession> sessionProxy;  // Per-window ISession for operations
        OHOS::sptr<SessionStageAdapter> stageAdapter;
        OHOS::sptr<WindowCallbackAdapter> windowAdapter;
    };
    std::map<int32_t, SessionEntry> sessions_;
    std::mutex sessionMutex_;
    int32_t nextSessionId_ = 1;
};

}  // namespace oh_adapter

#endif  // OH_WINDOW_MANAGER_CLIENT_H
