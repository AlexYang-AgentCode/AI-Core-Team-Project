/*
 * oh_surface_bridge.h
 *
 * Surface bridging between Android Framework and OH RenderService.
 * Manages RSSurfaceNode lifecycle, RSUIDirector, and OH Surface Producer
 * for each window session.
 *
 * Core responsibility: create OH surfaces and wrap them as Android-compatible
 * IGraphicBufferProducer instances so that Android's BLASTBufferQueue/HWUI
 * can render directly into OH's BufferQueue (zero-copy via shared dmabuf).
 *
 * Lifecycle per window:
 *   1. createSurface()   — create RSSurfaceNode + RSUIDirector
 *   2. getSurfaceHandle() — return native handle for Android SurfaceControl
 *   3. notifyDrawingCompleted() — flush RSUIDirector + notify OH Session
 *   4. destroySurface()  — release all OH resources
 */
#ifndef OH_SURFACE_BRIDGE_H
#define OH_SURFACE_BRIDGE_H

#include <cstdint>
#include <memory>
#include <unordered_map>
#include <mutex>
#include <string>

// Forward declarations for OH types to avoid header dependency in this header.
// Actual includes are in the .cpp file.
namespace OHOS {
    template<typename T> class sptr;
    class Surface;
    class SurfaceBuffer;
    class SyncFence;
    namespace Rosen {
        class RSSurfaceNode;
        class RSUIDirector;
    }
}

namespace oh_adapter {

/**
 * Per-window surface state managed by OHSurfaceBridge.
 */
struct SurfaceSession {
    int32_t sessionId = -1;

    // OH RenderService objects
    std::shared_ptr<OHOS::Rosen::RSSurfaceNode> surfaceNode;
    std::shared_ptr<OHOS::Rosen::RSUIDirector> director;
    OHOS::sptr<OHOS::Surface> ohSurface;   // Producer side from surfaceNode->GetSurface()

    // Android-side adapter (opaque pointer; actual type is OHGraphicBufferProducer)
    // Prevent circular include; the .cpp manages the real type.
    void* producerAdapter = nullptr;
    void* surfaceControlNative = nullptr;

    int32_t width = 0;
    int32_t height = 0;
    int32_t format = 0;
};

/**
 * Singleton bridge managing OH surfaces for all window sessions.
 */
class OHSurfaceBridge {
public:
    static OHSurfaceBridge& getInstance();

    /**
     * Create OH RSSurfaceNode and RSUIDirector for a window session.
     *
     * @param sessionId       Session ID from OHWindowManagerClient.
     * @param windowName      Window name for the RSSurfaceNode.
     * @param width           Initial width.
     * @param height          Initial height.
     * @param format          Pixel format (Android PixelFormat value).
     * @return true on success.
     */
    bool createSurface(int32_t sessionId, const std::string& windowName,
                       int32_t width, int32_t height, int32_t format);

    /**
     * Get (or create) the native pointer that can back an Android SurfaceControl.
     * Internally creates OHGraphicBufferProducer wrapping the OH Surface.
     *
     * @param sessionId   Session ID.
     * @param width       Requested width (may trigger resize).
     * @param height      Requested height.
     * @param format      Pixel format.
     * @return Opaque native pointer for SurfaceControl creation, or 0 on failure.
     */
    int64_t getSurfaceHandle(int32_t sessionId,
                             int32_t width, int32_t height, int32_t format);

    /**
     * Notify OH that drawing is completed — flushes RSUIDirector::SendMessages().
     */
    void notifyDrawingCompleted(int32_t sessionId);

    /**
     * Update surface dimensions (called on relayout size change).
     */
    void updateSurfaceSize(int32_t sessionId, int32_t width, int32_t height);

    /**
     * Destroy all OH surface resources for a session.
     */
    void destroySurface(int32_t sessionId);

    /**
     * Get the RSSurfaceNode for external use (e.g. passing to SceneSessionManager).
     */
    std::shared_ptr<OHOS::Rosen::RSSurfaceNode> getSurfaceNode(int32_t sessionId);

private:
    OHSurfaceBridge() = default;
    ~OHSurfaceBridge() = default;

    std::mutex mutex_;
    std::unordered_map<int32_t, std::unique_ptr<SurfaceSession>> sessions_;
};

}  // namespace oh_adapter

#endif  // OH_SURFACE_BRIDGE_H
