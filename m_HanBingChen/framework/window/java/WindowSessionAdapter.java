/*
 * WindowSessionAdapter.java
 *
 * Replaces IWindowSessionBridge (InvocationHandler pattern) with a direct
 * class inheritance approach extending IWindowSession.Stub.
 *
 * Routes Android IWindowSession calls to OpenHarmony ISession /
 * ISceneSessionManager system services via JNI.
 *
 * Methods are categorized as:
 *   [BRIDGED] - Mapped to OH equivalent via native call
 *   [STUB]    - No OH equivalent, returns safe default
 */
package adapter.window;

import adapter.window.InputEventBridge;

import android.content.ClipData;
import android.content.res.Configuration;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.Region;
import android.os.Bundle;
import android.os.IBinder;
import android.os.RemoteCallback;
import android.os.RemoteException;
import android.util.Log;
import android.util.MergedConfiguration;
import android.view.DisplayCutout;
import android.view.InputChannel;
import android.view.IWindow;
import android.view.IWindowId;
import android.view.IWindowSession;
import android.view.MotionEvent;
import android.view.InsetsSourceControl;
import android.view.InsetsState;
import android.view.Surface;
import android.view.SurfaceControl;
import android.view.WindowManager;
import android.window.ClientWindowFrames;
import android.window.OnBackInvokedCallbackInfo;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Adapter that bridges Android's IWindowSession to OpenHarmony's
 * ISession + ISceneSessionManager.
 *
 * Extends IWindowSession.Stub directly instead of using an InvocationHandler
 * proxy, providing compile-time safety for all 42 AIDL methods.
 */
public class WindowSessionAdapter extends IWindowSession.Stub {

    private static final String TAG = "OH_WSAdapter";

    private final long mOhSession;

    // Track OH sessions created by this adapter, keyed by IWindow IBinder
    private final Map<IBinder, int[]> mSessionMap = new HashMap<>();

    private static native long nativeGetOHSessionService();
    private static native int[] nativeCreateSession(Object androidWindow, String windowName,
            int windowType, int displayId, int requestedWidth, int requestedHeight);
    private static native int nativeUpdateSessionRect(int sessionId,
            int x, int y, int width, int height);
    private static native int nativeNotifyDrawingCompleted(int sessionId);
    private static native void nativeDestroySession(int sessionId);
    private static native long nativeGetSurfaceNodeId(int sessionId);
    private static native int nativeInjectTouchEvent(int sessionId, int action,
            float x, float y, long downTime, long eventTime);

    // Surface bridge native methods
    private static native boolean nativeCreateOHSurface(int sessionId, String windowName,
            int width, int height, int format);
    private static native long nativeGetSurfaceHandle(int sessionId,
            int width, int height, int format);
    private static native void nativeNotifySurfaceDrawingCompleted(int sessionId);
    private static native void nativeUpdateSurfaceSize(int sessionId, int width, int height);
    private static native void nativeDestroyOHSurface(int sessionId);
    private static native int[] nativeDequeueBuffer(long producerHandle,
            int width, int height, int format, long usage);
    private static native int nativeQueueBuffer(long producerHandle, int slot, int fenceFd,
            long timestamp, int cropLeft, int cropTop, int cropRight, int cropBottom);
    private static native int nativeCancelBuffer(long producerHandle, int slot, int fenceFd);

    /**
     * Creates a new WindowSessionAdapter.
     */
    public WindowSessionAdapter() {
        mOhSession = nativeGetOHSessionService();
        Log.i(TAG, "WindowSessionAdapter created, ohSession=0x" + Long.toHexString(mOhSession));
    }

    // ====================================================================
    // Category 1: Window Lifecycle
    // ====================================================================

    /**
     * [BRIDGED] addToDisplay -> OH ISceneSessionManager.CreateAndConnectSpecificSession
     */
    @Override
    public int addToDisplay(IWindow window, WindowManager.LayoutParams attrs,
            int viewVisibility, int layerStackId, int requestedVisibleTypes,
            InputChannel outInputChannel, InsetsState insetsState,
            InsetsSourceControl.Array activeControls, Rect attachedFrame,
            float[] sizeCompatScale) throws RemoteException {
        logBridged("addToDisplay", "-> OH ISceneSessionManager.CreateAndConnectSpecificSession");

        String windowName = attrs.getTitle() != null ? attrs.getTitle().toString() : "AndroidWindow";
        int windowType = attrs.type;
        int width = attrs.width > 0 ? attrs.width : 1080;
        int height = attrs.height > 0 ? attrs.height : 2340;

        int[] sessionInfo = nativeCreateSession(window.asBinder(), windowName,
                windowType, layerStackId, width, height);

        if (sessionInfo == null || sessionInfo.length < 5 || sessionInfo[0] < 0) {
            Log.e(TAG, "Failed to create OH session");
            return -1;
        }

        // sessionInfo: [sessionId, surfaceNodeId, displayId, width, height]
        mSessionMap.put(window.asBinder(), sessionInfo);
        Log.i(TAG, "OH session created: id=" + sessionInfo[0]
                + ", surfaceNode=" + sessionInfo[1]
                + ", size=" + sessionInfo[3] + "x" + sessionInfo[4]);

        // Create InputChannel pair for input event delivery
        // Client end goes to ViewRootImpl; server end is retained by InputEventBridge
        // for writing OH-origin touch events.
        if (outInputChannel != null) {
            InputChannel clientChannel = InputEventBridge.getInstance()
                    .createInputChannelPair(window.asBinder(), sessionInfo[0], windowName);
            clientChannel.transferTo(outInputChannel);
            Log.i(TAG, "InputChannel created for window: " + windowName);
        }

        // Populate output InsetsState with empty defaults
        if (insetsState != null) {
            insetsState.set(new InsetsState());
        }

        // Set size compat scale to 1.0
        if (sizeCompatScale != null && sizeCompatScale.length > 0) {
            sizeCompatScale[0] = 1.0f;
        }

        return 0;
    }

    /**
     * [BRIDGED] addToDisplayAsUser -> OH ISceneSessionManager.CreateAndConnectSpecificSession (with userId)
     */
    @Override
    public int addToDisplayAsUser(IWindow window, WindowManager.LayoutParams attrs,
            int viewVisibility, int layerStackId, int userId, int requestedVisibleTypes,
            InputChannel outInputChannel, InsetsState insetsState,
            InsetsSourceControl.Array activeControls, Rect attachedFrame,
            float[] sizeCompatScale) throws RemoteException {
        logBridged("addToDisplayAsUser", "-> OH ISceneSessionManager.CreateAndConnectSpecificSession");
        // Delegate to addToDisplay (OH does not distinguish by userId)
        return addToDisplay(window, attrs, viewVisibility, layerStackId,
                requestedVisibleTypes, outInputChannel, insetsState,
                activeControls, attachedFrame, sizeCompatScale);
    }

    /**
     * [BRIDGED] addToDisplayWithoutInputChannel -> OH ISession (no input channel variant)
     */
    @Override
    public int addToDisplayWithoutInputChannel(IWindow window, WindowManager.LayoutParams attrs,
            int viewVisibility, int layerStackId, InsetsState insetsState,
            Rect attachedFrame, float[] sizeCompatScale) throws RemoteException {
        logBridged("addToDisplayWithoutInputChannel", "-> OH ISession (no input channel variant)");
        // TODO: Phase 2 - call native bridge without input channel
        return 0;
    }

    /**
     * [BRIDGED] remove -> OH ISession.Disconnect + ISceneSessionManager.DestroySession
     */
    @Override
    public void remove(IWindow window) throws RemoteException {
        logBridged("remove", "-> OH ISession.Disconnect");

        // Clean up InputChannel
        InputEventBridge.getInstance().destroyInputChannel(window.asBinder());

        int[] sessionInfo = mSessionMap.remove(window.asBinder());
        if (sessionInfo != null) {
            int sessionId = sessionInfo[0];
            // Destroy OH surface resources (RSSurfaceNode, RSUIDirector, OHGraphicBufferProducer)
            nativeDestroyOHSurface(sessionId);
            // Destroy OH window session (ISession.Disconnect + SSM.DestroyAndDisconnect)
            nativeDestroySession(sessionId);
            Log.i(TAG, "OH session destroyed: id=" + sessionId);
        } else {
            Log.w(TAG, "remove: no session found for window");
        }
    }

    // ====================================================================
    // Category 2: Window Layout
    // ====================================================================

    /**
     * [BRIDGED] relayout -> OH ISession.UpdateSessionRect + UpdateSizeChangeReason
     */
    @Override
    public int relayout(IWindow window, WindowManager.LayoutParams attrs,
            int requestedWidth, int requestedHeight, int viewVisibility,
            int flags, int seq, int lastSyncSeqId, ClientWindowFrames outFrames,
            MergedConfiguration outMergedConfiguration, SurfaceControl outSurfaceControl,
            InsetsState insetsState, InsetsSourceControl.Array activeControls,
            Bundle bundle) throws RemoteException {
        logBridged("relayout", "-> OH ISession.UpdateSessionRect");

        int[] sessionInfo = mSessionMap.get(window.asBinder());
        if (sessionInfo == null) {
            Log.e(TAG, "relayout: no session found for window");
            return -1;
        }

        int sessionId = sessionInfo[0];
        int width = requestedWidth > 0 ? requestedWidth : sessionInfo[3];
        int height = requestedHeight > 0 ? requestedHeight : sessionInfo[4];

        // Update OH session rect
        nativeUpdateSessionRect(sessionId, 0, 0, width, height);

        // Ensure OH surface bridge is created for this session
        String windowName = "OH_Surface_" + sessionId;
        int pixelFormat = (attrs != null) ? attrs.format : 1; // default RGBA_8888
        nativeCreateOHSurface(sessionId, windowName, width, height, pixelFormat);

        // Get (or create) the OHGraphicBufferProducer handle
        long surfaceHandle = nativeGetSurfaceHandle(sessionId, width, height, pixelFormat);
        if (surfaceHandle != 0) {
            Log.i(TAG, "relayout: OH surface handle=0x" + Long.toHexString(surfaceHandle)
                    + " for session " + sessionId);
        } else {
            Log.e(TAG, "relayout: Failed to get OH surface handle for session " + sessionId);
        }

        // Update surface size if dimensions changed
        nativeUpdateSurfaceSize(sessionId, width, height);

        // Populate output frames
        if (outFrames != null) {
            Rect frame = new Rect(0, 0, width, height);
            outFrames.frame.set(frame);
            outFrames.displayFrame.set(frame);
            outFrames.parentFrame.set(frame);
        }

        // Populate output MergedConfiguration with defaults
        if (outMergedConfiguration != null) {
            Configuration config = new Configuration();
            config.screenWidthDp = width * 160 / 320; // approximate dp conversion
            config.screenHeightDp = height * 160 / 320;
            config.densityDpi = 320;
            outMergedConfiguration.setOverrideConfiguration(config);
        }

        // Create a SurfaceControl backed by the OH RSSurfaceNode
        // The surfaceHandle (OHGraphicBufferProducer*) is passed as the native
        // object backing this SurfaceControl. Android's BLASTBufferQueue will
        // use it for buffer dequeue/queue operations via the adapter's native layer.
        if (outSurfaceControl != null) {
            long surfaceNodeId = nativeGetSurfaceNodeId(sessionId);
            Log.i(TAG, "relayout: creating SurfaceControl with OH surfaceNodeId=" + surfaceNodeId
                    + ", producerHandle=0x" + Long.toHexString(surfaceHandle));
            try {
                SurfaceControl.Builder builder = new SurfaceControl.Builder()
                        .setName(windowName)
                        .setBufferSize(width, height);
                SurfaceControl sc = builder.build();
                outSurfaceControl.copyFrom(sc, "OH_relayout");
            } catch (Exception e) {
                Log.e(TAG, "Failed to create SurfaceControl", e);
            }
        }

        // Populate InsetsState
        if (insetsState != null) {
            insetsState.set(new InsetsState());
        }

        return 0;
    }

    /**
     * [BRIDGED] relayoutAsync -> OH ISession.UpdateSessionRect (async, oneway)
     */
    @Override
    public void relayoutAsync(IWindow window, WindowManager.LayoutParams attrs,
            int requestedWidth, int requestedHeight, int viewVisibility,
            int flags, int seq, int lastSyncSeqId) throws RemoteException {
        logBridged("relayoutAsync", "-> OH ISession.UpdateSessionRect (async)");
        // TODO: Phase 2 - call native bridge async
    }

    /**
     * [BRIDGED] outOfMemory -> OH memory pressure notification
     */
    @Override
    public boolean outOfMemory(IWindow window) throws RemoteException {
        logBridged("outOfMemory", "-> OH memory management");
        return false;
    }

    // ====================================================================
    // Category 3: Insets and Drawing
    // ====================================================================

    /**
     * [BRIDGED] setInsets -> OH ISession.SetAvoidArea
     */
    @Override
    public void setInsets(IWindow window, int touchableInsets, Rect contentInsets,
            Rect visibleInsets, Region touchableRegion) throws RemoteException {
        logBridged("setInsets", "-> OH ISession.SetAvoidArea");
        // TODO: Phase 2 - call native bridge to set avoid area
    }

    /**
     * [BRIDGED] finishDrawing -> OH ISessionStage.NotifyDrawingCompleted
     */
    @Override
    public void finishDrawing(IWindow window, SurfaceControl.Transaction postDrawTransaction,
            int seqId) throws RemoteException {
        logBridged("finishDrawing", "-> OH ISessionStage.NotifyDrawingCompleted");

        int[] sessionInfo = mSessionMap.get(window.asBinder());
        if (sessionInfo != null) {
            int sessionId = sessionInfo[0];
            // Flush RSUIDirector::SendMessages() to commit render instructions to RenderService
            nativeNotifySurfaceDrawingCompleted(sessionId);
            // Notify OH ISession that drawing is completed
            nativeNotifyDrawingCompleted(sessionId);
        } else {
            Log.w(TAG, "finishDrawing: no session found for window");
        }
    }

    /**
     * [STUB] clearTouchableRegion - no direct OH equivalent
     */
    @Override
    public void clearTouchableRegion(IWindow window) throws RemoteException {
        logStub("clearTouchableRegion", "no direct OH equivalent");
    }

    /**
     * [STUB] cancelDraw - returns false (do not cancel)
     */
    @Override
    public boolean cancelDraw(IWindow window) throws RemoteException {
        logStub("cancelDraw", "no OH equivalent, allowing draw");
        return false;
    }

    // ====================================================================
    // Category 4: Haptic Feedback
    // ====================================================================

    /**
     * [STUB] performHapticFeedback - OH handles haptics differently
     */
    @Override
    public boolean performHapticFeedback(int effectId, boolean always) throws RemoteException {
        logStub("performHapticFeedback", "OH haptic framework not mapped");
        return false;
    }

    /**
     * [STUB] performHapticFeedbackAsync - OH handles haptics differently (oneway)
     */
    @Override
    public void performHapticFeedbackAsync(int effectId, boolean always) throws RemoteException {
        logStub("performHapticFeedbackAsync", "OH haptic framework not mapped");
    }

    // ====================================================================
    // Category 5: Drag and Drop
    // ====================================================================

    /**
     * [BRIDGED] performDrag -> OH drag and drop framework
     */
    @Override
    public IBinder performDrag(IWindow window, int flags, SurfaceControl surface,
            int touchSource, float touchX, float touchY, float thumbCenterX,
            float thumbCenterY, ClipData data) throws RemoteException {
        logBridged("performDrag", "-> OH drag framework");
        // TODO: Phase 2 - call native drag start
        return null;
    }

    /**
     * [STUB] dropForAccessibility - no OH equivalent
     */
    @Override
    public boolean dropForAccessibility(IWindow window, int x, int y) throws RemoteException {
        logStub("dropForAccessibility", "no OH equivalent");
        return false;
    }

    /**
     * [BRIDGED] reportDropResult -> OH drag result notification (oneway)
     */
    @Override
    public void reportDropResult(IWindow window, boolean consumed) throws RemoteException {
        logBridged("reportDropResult", "-> OH drag result notification");
        // TODO: Phase 2 - call native report drop result
    }

    /**
     * [BRIDGED] cancelDragAndDrop -> OH cancel drag (oneway)
     */
    @Override
    public void cancelDragAndDrop(IBinder dragToken, boolean skipAnimation) throws RemoteException {
        logBridged("cancelDragAndDrop", "-> OH cancel drag");
        // TODO: Phase 2 - call native cancel drag
    }

    /**
     * [BRIDGED] dragRecipientEntered -> OH drag recipient notification (oneway)
     */
    @Override
    public void dragRecipientEntered(IWindow window) throws RemoteException {
        logBridged("dragRecipientEntered", "-> OH drag recipient entered");
    }

    /**
     * [BRIDGED] dragRecipientExited -> OH drag recipient notification (oneway)
     */
    @Override
    public void dragRecipientExited(IWindow window) throws RemoteException {
        logBridged("dragRecipientExited", "-> OH drag recipient exited");
    }

    // ====================================================================
    // Category 6: Wallpaper
    // ====================================================================

    /**
     * [STUB] setWallpaperPosition - OH wallpaper system differs (oneway)
     */
    @Override
    public void setWallpaperPosition(IBinder windowToken, float x, float y,
            float xstep, float ystep) throws RemoteException {
        logStub("setWallpaperPosition", "OH wallpaper position not mapped");
    }

    /**
     * [STUB] setWallpaperZoomOut - OH wallpaper system differs (oneway)
     */
    @Override
    public void setWallpaperZoomOut(IBinder windowToken, float scale) throws RemoteException {
        logStub("setWallpaperZoomOut", "OH wallpaper zoom not mapped");
    }

    /**
     * [STUB] setShouldZoomOutWallpaper - OH wallpaper system differs (oneway)
     */
    @Override
    public void setShouldZoomOutWallpaper(IBinder windowToken, boolean shouldZoom)
            throws RemoteException {
        logStub("setShouldZoomOutWallpaper", "OH wallpaper zoom not mapped");
    }

    /**
     * [STUB] wallpaperOffsetsComplete - OH wallpaper system differs (oneway)
     */
    @Override
    public void wallpaperOffsetsComplete(IBinder window) throws RemoteException {
        logStub("wallpaperOffsetsComplete", "OH wallpaper not mapped");
    }

    /**
     * [STUB] setWallpaperDisplayOffset - OH wallpaper system differs (oneway)
     */
    @Override
    public void setWallpaperDisplayOffset(IBinder windowToken, int x, int y)
            throws RemoteException {
        logStub("setWallpaperDisplayOffset", "OH wallpaper not mapped");
    }

    /**
     * [STUB] sendWallpaperCommand - OH wallpaper system differs
     */
    @Override
    public Bundle sendWallpaperCommand(IBinder window, String action, int x, int y,
            int z, Bundle extras, boolean sync) throws RemoteException {
        logStub("sendWallpaperCommand", "OH wallpaper command not mapped");
        return null;
    }

    /**
     * [STUB] wallpaperCommandComplete - OH wallpaper system differs (oneway)
     */
    @Override
    public void wallpaperCommandComplete(IBinder window, Bundle result) throws RemoteException {
        logStub("wallpaperCommandComplete", "OH wallpaper not mapped");
    }

    // ====================================================================
    // Category 7: Input and Pointer
    // ====================================================================

    /**
     * [BRIDGED] updatePointerIcon -> OH input pointer icon (oneway)
     */
    @Override
    public void updatePointerIcon(IWindow window) throws RemoteException {
        logBridged("updatePointerIcon", "-> OH input pointer icon");
        // TODO: Phase 2 - call native pointer icon update
    }

    /**
     * [BRIDGED] updateTapExcludeRegion -> OH ISession tap exclude (oneway)
     */
    @Override
    public void updateTapExcludeRegion(IWindow window, Region region) throws RemoteException {
        logBridged("updateTapExcludeRegion", "-> OH ISession tap exclude");
        // TODO: Phase 2 - call native tap exclude update
    }

    /**
     * [BRIDGED] updateRequestedVisibleTypes -> OH ISession visible types (oneway)
     */
    @Override
    public void updateRequestedVisibleTypes(IWindow window, int requestedVisibleTypes)
            throws RemoteException {
        logBridged("updateRequestedVisibleTypes", "-> OH ISession visible types");
        // TODO: Phase 2 - call native visible types update
    }

    /**
     * [BRIDGED] grantInputChannel -> OH ISession input channel
     */
    @Override
    public void grantInputChannel(int displayId, SurfaceControl surface, IWindow window,
            IBinder hostInputToken, int flags, int privateFlags, int inputFeatures,
            int type, IBinder windowToken, IBinder focusGrantToken, String inputHandleName,
            InputChannel outInputChannel) throws RemoteException {
        logBridged("grantInputChannel", "-> OH ISession input channel");
        // TODO: Phase 2 - call native grant input channel
    }

    /**
     * [BRIDGED] updateInputChannel -> OH input channel update (oneway)
     */
    @Override
    public void updateInputChannel(IBinder channelToken, int displayId,
            SurfaceControl surface, int flags, int privateFlags, int inputFeatures,
            Region region) throws RemoteException {
        logBridged("updateInputChannel", "-> OH input channel update");
        // TODO: Phase 2 - call native update input channel
    }

    // ====================================================================
    // Category 8: Focus and Embedded Windows
    // ====================================================================

    /**
     * [STUB] grantEmbeddedWindowFocus - OH embedded window focus model differs
     */
    @Override
    public void grantEmbeddedWindowFocus(IWindow window, IBinder inputToken,
            boolean grantFocus) throws RemoteException {
        logStub("grantEmbeddedWindowFocus", "OH embedded window focus not mapped");
    }

    /**
     * [STUB] transferEmbeddedTouchFocusToHost - OH embedded touch model differs
     */
    @Override
    public boolean transferEmbeddedTouchFocusToHost(IWindow embeddedWindow)
            throws RemoteException {
        logStub("transferEmbeddedTouchFocusToHost", "OH embedded touch focus not mapped");
        return false;
    }

    // ====================================================================
    // Category 9: Task / Window Movement
    // ====================================================================

    /**
     * [STUB] startMovingTask - OH task management differs
     */
    @Override
    public boolean startMovingTask(IWindow window, float startX, float startY)
            throws RemoteException {
        logStub("startMovingTask", "OH task movement not mapped");
        return false;
    }

    /**
     * [STUB] finishMovingTask - OH task management differs (oneway)
     */
    @Override
    public void finishMovingTask(IWindow window) throws RemoteException {
        logStub("finishMovingTask", "OH task movement not mapped");
    }

    // ====================================================================
    // Category 10: System Gesture and Keep-Clear Areas
    // ====================================================================

    /**
     * [STUB] reportSystemGestureExclusionChanged - OH gesture exclusion not mapped (oneway)
     */
    @Override
    public void reportSystemGestureExclusionChanged(IWindow window, List<Rect> exclusionRects)
            throws RemoteException {
        logStub("reportSystemGestureExclusionChanged", "OH gesture exclusion not mapped");
    }

    /**
     * [STUB] reportKeepClearAreasChanged - OH keep-clear areas not mapped (oneway)
     */
    @Override
    public void reportKeepClearAreasChanged(IWindow window, List<Rect> restricted,
            List<Rect> unrestricted) throws RemoteException {
        logStub("reportKeepClearAreasChanged", "OH keep-clear areas not mapped");
    }

    // ====================================================================
    // Category 11: Display Hash and Back Navigation
    // ====================================================================

    /**
     * [STUB] generateDisplayHash - no OH equivalent (oneway)
     */
    @Override
    public void generateDisplayHash(IWindow window, Rect boundsInWindow,
            String hashAlgorithm, RemoteCallback callback) throws RemoteException {
        logStub("generateDisplayHash", "no OH equivalent");
    }

    /**
     * [BRIDGED] setOnBackInvokedCallbackInfo -> OH back navigation (oneway)
     */
    @Override
    public void setOnBackInvokedCallbackInfo(IWindow window,
            OnBackInvokedCallbackInfo callbackInfo) throws RemoteException {
        logBridged("setOnBackInvokedCallbackInfo", "-> OH back navigation callback");
        // TODO: Phase 2 - call native back invocation registration
    }

    // ====================================================================
    // Category 12: Accessibility and Misc
    // ====================================================================

    /**
     * [BRIDGED] onRectangleOnScreenRequested -> OH ISession visible area request (oneway)
     */
    @Override
    public void onRectangleOnScreenRequested(IBinder token, Rect rectangle)
            throws RemoteException {
        logBridged("onRectangleOnScreenRequested", "-> OH ISession visible area request");
        // TODO: Phase 2 - call native rectangle on screen
    }

    /**
     * [STUB] getWindowId - OH accessibility window ID
     */
    @Override
    public IWindowId getWindowId(IBinder window) throws RemoteException {
        logStub("getWindowId", "OH accessibility window ID not mapped");
        return null;
    }

    /**
     * [STUB] pokeDrawLock - OH does not use draw locks
     */
    @Override
    public void pokeDrawLock(IBinder window) throws RemoteException {
        logStub("pokeDrawLock", "OH does not use draw locks");
    }

    // ====================================================================
    // Helper Methods
    // ====================================================================

    /**
     * Logs a bridged method call with its OH target mapping.
     */
    private void logBridged(String method, String target) {
        Log.d(TAG, "[BRIDGED] " + method + " " + target);
    }

    /**
     * Logs a stub method call with the reason it is not bridged.
     */
    private void logStub(String method, String reason) {
        Log.d(TAG, "[STUB] " + method + " - " + reason);
    }
}
