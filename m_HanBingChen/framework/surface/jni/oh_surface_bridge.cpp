/*
 * oh_surface_bridge.cpp
 *
 * Implements OHSurfaceBridge: manages OH RSSurfaceNode + RSUIDirector + Surface
 * per window session, and wraps them as OHGraphicBufferProducer for Android.
 *
 * Lifecycle per window:
 *   1. createSurface()           -> RSSurfaceNode::Create() + RSUIDirector::Create()
 *   2. getSurfaceHandle()        -> OHGraphicBufferProducer wrapping OH Surface
 *   3. notifyDrawingCompleted()  -> RSUIDirector::SendMessages() + RSTransaction commit
 *   4. updateSurfaceSize()       -> RSSurfaceNode resize
 *   5. destroySurface()          -> Release all OH resources
 *
 * Reference:
 *   OH: graphic_2d/rosen/modules/render_service_client/core/ui/rs_surface_node.h
 *   OH: graphic_2d/rosen/modules/render_service_client/core/ui/rs_ui_director.h
 *   OH: graphic_surface/surface/include/surface.h
 */
#include "oh_surface_bridge.h"
#include "oh_graphic_buffer_producer.h"
#include "pixel_format_mapper.h"

#include <android/log.h>

// OH RenderService client headers
#include "ui/rs_surface_node.h"
#include "ui/rs_ui_director.h"
#include "transaction/rs_transaction.h"

#define LOG_TAG "OH_SurfaceBridge"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

namespace oh_adapter {

OHSurfaceBridge& OHSurfaceBridge::getInstance() {
    static OHSurfaceBridge instance;
    return instance;
}

bool OHSurfaceBridge::createSurface(int32_t sessionId, const std::string& windowName,
                                     int32_t width, int32_t height, int32_t format)
{
    std::lock_guard<std::mutex> lock(mutex_);

    // Check if session already exists
    if (sessions_.find(sessionId) != sessions_.end()) {
        LOGW("createSurface: Session %d already exists, destroying first", sessionId);
        // Clean up existing session (without holding lock — use internal helper)
        auto& existing = sessions_[sessionId];
        if (existing->producerAdapter) {
            auto* producer = static_cast<OHGraphicBufferProducer*>(existing->producerAdapter);
            producer->disconnect();
            delete producer;
        }
        sessions_.erase(sessionId);
    }

    auto session = std::make_unique<SurfaceSession>();
    session->sessionId = sessionId;
    session->width = width;
    session->height = height;
    session->format = format;

    // Create RSSurfaceNode
    // RSSurfaceNode is the client-side representation of a surface in OH's
    // RenderService compositing tree. It holds the BufferQueue producer.
    OHOS::Rosen::RSSurfaceNodeConfig config;
    config.SurfaceNodeName = windowName;

    auto surfaceNode = OHOS::Rosen::RSSurfaceNode::Create(config);
    if (!surfaceNode) {
        LOGE("createSurface: Failed to create RSSurfaceNode for session %d", sessionId);
        return false;
    }

    // Set initial bounds
    surfaceNode->SetBoundsWidth(width);
    surfaceNode->SetBoundsHeight(height);

    session->surfaceNode = surfaceNode;

    // Get the producer Surface from the RSSurfaceNode
    // This is the OH ProducerSurface backed by the BufferQueue
    auto ohSurface = surfaceNode->GetSurface();
    if (!ohSurface) {
        LOGE("createSurface: Failed to get Surface from RSSurfaceNode for session %d", sessionId);
        return false;
    }

    session->ohSurface = ohSurface;

    // Create RSUIDirector for managing render instructions
    // RSUIDirector batches UI commands and sends them to RenderService
    // via RSTransactionProxy -> RSIClientToRenderConnection
    auto director = OHOS::Rosen::RSUIDirector::Create();
    if (director) {
        director->Init();
        director->SetRSSurfaceNode(surfaceNode);
        session->director = director;
    } else {
        LOGW("createSurface: Failed to create RSUIDirector for session %d", sessionId);
        // Non-fatal: surface can still work without director for simple buffer submission
    }

    sessions_[sessionId] = std::move(session);

    LOGI("createSurface: session=%d, name=%s, size=%dx%d, surfaceNodeId=%llu",
         sessionId, windowName.c_str(), width, height,
         static_cast<unsigned long long>(surfaceNode->GetId()));

    return true;
}

int64_t OHSurfaceBridge::getSurfaceHandle(int32_t sessionId,
                                           int32_t width, int32_t height,
                                           int32_t format)
{
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = sessions_.find(sessionId);
    if (it == sessions_.end()) {
        LOGE("getSurfaceHandle: Session %d not found", sessionId);
        return 0;
    }

    auto& session = it->second;

    // Create OHGraphicBufferProducer if not already created
    if (session->producerAdapter == nullptr) {
        if (!session->ohSurface) {
            LOGE("getSurfaceHandle: OH Surface is null for session %d", sessionId);
            return 0;
        }

        // Set buffer queue size for triple buffering
        session->ohSurface->SetQueueSize(3);

        auto* producer = new OHGraphicBufferProducer(session->ohSurface);
        producer->connect();
        session->producerAdapter = producer;

        LOGI("getSurfaceHandle: Created OHGraphicBufferProducer for session %d", sessionId);
    }

    // Handle resize if dimensions changed
    if ((width > 0 && width != session->width) ||
        (height > 0 && height != session->height)) {
        session->width = width > 0 ? width : session->width;
        session->height = height > 0 ? height : session->height;

        if (session->surfaceNode) {
            session->surfaceNode->SetBoundsWidth(session->width);
            session->surfaceNode->SetBoundsHeight(session->height);
        }
        LOGI("getSurfaceHandle: Resized session %d to %dx%d",
             sessionId, session->width, session->height);
    }

    // Return the OHGraphicBufferProducer pointer as opaque handle
    // Android side casts this to create a SurfaceControl that delegates to it
    return reinterpret_cast<int64_t>(session->producerAdapter);
}

void OHSurfaceBridge::notifyDrawingCompleted(int32_t sessionId) {
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = sessions_.find(sessionId);
    if (it == sessions_.end()) {
        LOGW("notifyDrawingCompleted: Session %d not found", sessionId);
        return;
    }

    auto& session = it->second;

    // Flush RSUIDirector: sends batched render instructions to RenderService
    // This triggers RSTransactionProxy::FlushImplicitTransaction() which commits
    // all pending UI operations (node properties, transforms, etc.) via
    // RSIClientToRenderConnection::CommitTransaction()
    if (session->director) {
        session->director->SendMessages();
        LOGI("notifyDrawingCompleted: RSUIDirector::SendMessages() for session %d", sessionId);
    }

    // Also commit any pending RSTransaction (explicit transaction mode)
    OHOS::Rosen::RSTransaction::FlushImplicitTransaction();
}

void OHSurfaceBridge::updateSurfaceSize(int32_t sessionId, int32_t width, int32_t height) {
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = sessions_.find(sessionId);
    if (it == sessions_.end()) {
        LOGW("updateSurfaceSize: Session %d not found", sessionId);
        return;
    }

    auto& session = it->second;
    session->width = width;
    session->height = height;

    if (session->surfaceNode) {
        session->surfaceNode->SetBoundsWidth(width);
        session->surfaceNode->SetBoundsHeight(height);
        LOGI("updateSurfaceSize: session=%d, size=%dx%d", sessionId, width, height);
    }
}

void OHSurfaceBridge::destroySurface(int32_t sessionId) {
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = sessions_.find(sessionId);
    if (it == sessions_.end()) {
        LOGW("destroySurface: Session %d not found", sessionId);
        return;
    }

    auto& session = it->second;

    // Disconnect and delete the OHGraphicBufferProducer
    if (session->producerAdapter) {
        auto* producer = static_cast<OHGraphicBufferProducer*>(session->producerAdapter);
        producer->disconnect();
        delete producer;
        session->producerAdapter = nullptr;
    }

    // Release RSUIDirector
    if (session->director) {
        session->director->Destroy();
        session->director = nullptr;
    }

    // Release OH Surface and RSSurfaceNode
    session->ohSurface = nullptr;
    session->surfaceNode = nullptr;

    sessions_.erase(it);

    LOGI("destroySurface: session=%d destroyed", sessionId);
}

std::shared_ptr<OHOS::Rosen::RSSurfaceNode>
OHSurfaceBridge::getSurfaceNode(int32_t sessionId) {
    std::lock_guard<std::mutex> lock(mutex_);

    auto it = sessions_.find(sessionId);
    if (it == sessions_.end()) {
        return nullptr;
    }
    return it->second->surfaceNode;
}

}  // namespace oh_adapter
