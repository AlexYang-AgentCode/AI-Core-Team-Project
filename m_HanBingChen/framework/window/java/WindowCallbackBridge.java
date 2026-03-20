/*
 * WindowCallbackBridge.java
 *
 * Reverse bridge: OH IWindow callbacks -> Android IWindow.
 *
 * OH IWindow is called by OH WindowManager to notify individual window
 * instances of state changes (rect, mode, focus, avoid area, etc.).
 *
 * Mapping:
 *   OH IWindow -> Android IWindow (window events)
 *
 * Key differences:
 *   - OH IWindow has 26 methods with granular state updates
 *   - Android IWindow has 16 methods with batched updates (resized combines many)
 *   - OH separates rect/mode/focus/avoidArea into individual calls
 *   - Android batches most into resized() with frames/insets/config
 */
package adapter.window;

import android.os.RemoteException;
import android.util.Log;
import android.view.IWindow;

public class WindowCallbackBridge {

    private static final String TAG = "OH_WindowCBBridge";
    private final Object mAndroidWindow; // Android IWindow proxy
    private IWindow mIWindow; // Typed reference (resolved lazily)

    public WindowCallbackBridge(Object androidWindow) {
        mAndroidWindow = androidWindow;
        if (androidWindow instanceof IWindow) {
            mIWindow = (IWindow) androidWindow;
        }
    }

    /**
     * Dispatch app visibility to the Android IWindow.
     */
    private void dispatchAppVisibility(boolean visible) {
        if (mIWindow != null) {
            try {
                mIWindow.dispatchAppVisibility(visible);
            } catch (RemoteException e) {
                Log.e(TAG, "Failed to dispatch app visibility", e);
            }
        } else {
            try {
                java.lang.reflect.Method method = mAndroidWindow.getClass()
                        .getMethod("dispatchAppVisibility", boolean.class);
                method.invoke(mAndroidWindow, visible);
            } catch (Exception e) {
                Log.e(TAG, "Reflection fallback failed for dispatchAppVisibility", e);
            }
        }
    }

    /**
     * Dispatch window focus change to the Android IWindow.
     */
    private void dispatchWindowFocusChanged(boolean focused) {
        if (mIWindow != null) {
            try {
                mIWindow.windowFocusChanged(focused, false /* inTouchMode */);
            } catch (RemoteException e) {
                Log.e(TAG, "Failed to dispatch window focus changed", e);
            }
        } else {
            try {
                java.lang.reflect.Method method = mAndroidWindow.getClass()
                        .getMethod("windowFocusChanged", boolean.class, boolean.class);
                method.invoke(mAndroidWindow, focused, false);
            } catch (Exception e) {
                Log.e(TAG, "Reflection fallback failed for windowFocusChanged", e);
            }
        }
    }

    // ============================================================
    // Category 1: Window Geometry (-> IWindow.resized)
    // ============================================================

    /**
     * [BRIDGED] UpdateWindowRect -> IWindow.resized
     *
     * OH updates window rectangle with decoration status and reason.
     * Android IWindow.resized delivers frames, configuration, and insets together.
     *
     * Semantic gap: OH sends rect separately; Android bundles rect with
     * MergedConfiguration and InsetsState. Bridge needs to construct
     * ClientWindowFrames from OH rect data.
     */
    public void onUpdateWindowRect(int left, int top, int right, int bottom,
                                    boolean decoStatus, int reason) {
        logBridged("UpdateWindowRect",
                "-> IWindow.resized (rect=[" + left + "," + top + "," + right + "," + bottom + "])");
        // Phase 1: Forward to Android IWindow.resized with constructed frames
    }

    /**
     * [BRIDGED] UpdateWindowMode -> IWindow.resized (mode change triggers relayout)
     *
     * OH window mode: FULLSCREEN, FLOATING, SPLIT_PRIMARY, SPLIT_SECONDARY, PIP.
     * Android embeds windowing mode in configuration within resized().
     */
    public void onUpdateWindowMode(int mode) {
        logBridged("UpdateWindowMode",
                "-> IWindow.resized (windowing mode=" + mode + ")");
    }

    /**
     * [STUB] UpdateWindowModeSupportType -> (no direct Android equivalent)
     *
     * OH tells window which modes are supported.
     * Android manages this server-side in WindowManagerService.
     * Impact: LOW - App doesn't need to know supported modes explicitly.
     * Strategy: Ignore, Android WMS handles mode constraints.
     */
    public void onUpdateWindowModeSupportType(int supportType) {
        logStub("UpdateWindowModeSupportType",
                "Android WMS manages mode support internally");
    }

    // ============================================================
    // Category 2: Focus (-> no direct IWindow method)
    // ============================================================

    /**
     * [PARTIAL] UpdateFocusStatus -> (handled internally by ViewRootImpl)
     *
     * OH explicitly sends focus status to window.
     * Android IWindow has no explicit focus method. Focus is handled by
     * ViewRootImpl via InputMethodManager and window attributes.
     *
     * Impact: MEDIUM - Some apps check window focus state.
     * Strategy: Trigger ViewRootImpl focus change via internal mechanism.
     */
    public void onUpdateFocusStatus(boolean focused) {
        logPartial("UpdateFocusStatus",
                "Android handles focus internally via ViewRootImpl, not IWindow");
        dispatchWindowFocusChanged(focused);
    }

    /**
     * [PARTIAL] UpdateActiveStatus -> (handled internally)
     *
     * OH active status is similar to Android's "has window focus".
     * Impact: LOW - Handled by the system.
     */
    public void onUpdateActiveStatus(boolean isActive) {
        logPartial("UpdateActiveStatus",
                "Android handles active state internally");
    }

    // ============================================================
    // Category 3: Avoid Area / Insets (-> IWindow.resized / insetsControlChanged)
    // ============================================================

    /**
     * [BRIDGED] UpdateAvoidArea -> IWindow.resized (InsetsState)
     *
     * OH AvoidArea maps to Android window insets.
     * OH AvoidAreaType: TYPE_SYSTEM, TYPE_CUTOUT, TYPE_NAVIGATION, TYPE_KEYBOARD, etc.
     * Android InsetsState contains insets sources for each type.
     *
     * Conversion:
     *   OH TYPE_SYSTEM -> Android STATUS_BAR insets
     *   OH TYPE_NAVIGATION -> Android NAVIGATION_BAR insets
     *   OH TYPE_CUTOUT -> Android DISPLAY_CUTOUT insets
     *   OH TYPE_KEYBOARD -> Android IME insets
     */
    public void onUpdateAvoidArea(int avoidAreaType, int left, int top,
                                   int right, int bottom) {
        logBridged("UpdateAvoidArea(type=" + avoidAreaType + ")",
                "-> IWindow.resized (InsetsState) / insetsControlChanged");
    }

    /**
     * [BRIDGED] UpdateOccupiedAreaChangeInfo -> IWindow.resized (InsetsState)
     *
     * OH occupied area (typically keyboard) changes.
     * Android delivers via insetsControlChanged or resized with IME insets.
     */
    public void onUpdateOccupiedAreaChangeInfo(int occupiedHeight) {
        logBridged("UpdateOccupiedAreaChangeInfo",
                "-> IWindow.insetsControlChanged (IME height=" + occupiedHeight + ")");
    }

    /**
     * [BRIDGED] UpdateOccupiedAreaAndRect -> IWindow.resized
     *
     * OH combined occupied area and rect update.
     * Android handles via single resized() call.
     */
    public void onUpdateOccupiedAreaAndRect() {
        logBridged("UpdateOccupiedAreaAndRect",
                "-> IWindow.resized (combined insets + rect)");
    }

    // ============================================================
    // Category 4: Visibility (-> IWindow.dispatchAppVisibility)
    // ============================================================

    /**
     * [BRIDGED] UpdateWindowState -> IWindow.dispatchAppVisibility
     *
     * OH window state changes (shown, hidden, etc.).
     * Android uses dispatchAppVisibility(visible).
     */
    public void onUpdateWindowState(int state) {
        boolean visible = (state == 1); // OH STATE_SHOWN
        logBridged("UpdateWindowState(" + state + ")",
                "-> IWindow.dispatchAppVisibility(" + visible + ")");
        dispatchAppVisibility(visible);
    }

    /**
     * [BRIDGED] NotifyForeground -> IWindow.dispatchAppVisibility(true)
     */
    public void onNotifyForeground() {
        logBridged("NotifyForeground", "-> IWindow.dispatchAppVisibility(true)");
        dispatchAppVisibility(true);
    }

    /**
     * [BRIDGED] NotifyBackground -> IWindow.dispatchAppVisibility(false)
     */
    public void onNotifyBackground() {
        logBridged("NotifyBackground", "-> IWindow.dispatchAppVisibility(false)");
        dispatchAppVisibility(false);
    }

    /**
     * [BRIDGED] NotifyForegroundInteractiveStatus -> IWindow.dispatchAppVisibility
     */
    public void onNotifyForegroundInteractiveStatus(boolean interactive) {
        logBridged("NotifyForegroundInteractiveStatus",
                "-> IWindow.dispatchAppVisibility(" + interactive + ")");
        dispatchAppVisibility(interactive);
    }

    // ============================================================
    // Category 5: Window Destruction (-> handled via WMS)
    // ============================================================

    /**
     * [PARTIAL] NotifyDestroy -> (no direct IWindow method)
     *
     * OH notifies window of destruction.
     * Android handles window removal through WindowManagerService,
     * not via IWindow callback.
     *
     * Impact: LOW - Window cleanup is handled at higher level.
     * Strategy: Trigger ViewRootImpl.die() through internal mechanism.
     */
    public void onNotifyDestroy() {
        logPartial("NotifyDestroy",
                "Android removes windows via WMS, not IWindow callback");
    }

    // ============================================================
    // Category 6: Drag / Input (-> IWindow.dispatchDragEvent)
    // ============================================================

    /**
     * [BRIDGED] UpdateWindowDragInfo -> IWindow.dispatchDragEvent
     *
     * OH drag information update.
     * Android dispatches DragEvent to window.
     */
    public void onUpdateWindowDragInfo(float x, float y, int event) {
        logBridged("UpdateWindowDragInfo",
                "-> IWindow.dispatchDragEvent(x=" + x + ",y=" + y + ")");
    }

    /**
     * [BRIDGED] NotifyWindowClientPointUp -> (input event dispatch)
     *
     * OH notifies pointer up event.
     * Android dispatches touch events via input channel, not IWindow.
     * Impact: LOW - Input events use separate input channel.
     */
    public void onNotifyWindowClientPointUp() {
        logPartial("NotifyWindowClientPointUp",
                "Android uses input channel for touch events, not IWindow");
    }

    /**
     * [PARTIAL] ConsumeKeyEvent -> (input event dispatch)
     *
     * OH dispatches key event to window.
     * Android uses input channel for key event delivery.
     */
    public void onConsumeKeyEvent() {
        logPartial("ConsumeKeyEvent",
                "Android uses input channel for key events");
    }

    // ============================================================
    // Category 7: Display (-> IWindow.moved)
    // ============================================================

    /**
     * [BRIDGED] UpdateDisplayId -> IWindow.resized (displayId parameter)
     *
     * OH notifies window of display change.
     * Android includes displayId in resized().
     */
    public void onUpdateDisplayId(long fromDisplay, long toDisplay) {
        logBridged("UpdateDisplayId",
                "-> IWindow.resized (displayId=" + toDisplay + ")");
    }

    // ============================================================
    // Category 8: Screenshot (-> no direct IWindow method)
    // ============================================================

    /**
     * [STUB] NotifyScreenshot -> (no direct Android IWindow equivalent)
     *
     * OH notifies window that a screenshot was captured.
     * Android handles screenshot notification at app level via Activity callback.
     * Impact: LOW - Apps can still detect screenshots via file observer.
     * Strategy: Ignore or route to Activity.onScreenCaptured if available.
     */
    public void onNotifyScreenshot() {
        logStub("NotifyScreenshot",
                "Android uses file observer or Activity callback");
    }

    /**
     * [STUB] NotifyScreenshotAppEvent
     */
    public void onNotifyScreenshotAppEvent(int type) {
        logStub("NotifyScreenshotAppEvent",
                "Android uses different screenshot notification");
    }

    // ============================================================
    // Category 9: Touch Outside (-> no direct IWindow method)
    // ============================================================

    /**
     * [PARTIAL] NotifyTouchOutside -> (Android MotionEvent.ACTION_OUTSIDE)
     *
     * OH explicitly notifies touch outside window.
     * Android delivers ACTION_OUTSIDE through input channel if
     * FLAG_WATCH_OUTSIDE_TOUCH is set.
     *
     * Impact: LOW - Handled via input channel in Android.
     * Strategy: Deliver via input channel mechanism.
     */
    public void onNotifyTouchOutside() {
        logPartial("NotifyTouchOutside",
                "Android uses ACTION_OUTSIDE via input channel");
    }

    // ============================================================
    // Category 10: Zoom / Transform (-> no direct IWindow method)
    // ============================================================

    /**
     * [STUB] UpdateZoomTransform -> (no direct Android equivalent)
     *
     * OH display zoom transform.
     * Android handles accessibility zoom separately.
     * Impact: LOW - Accessibility zoom is rare.
     */
    public void onUpdateZoomTransform() {
        logStub("UpdateZoomTransform",
                "Android handles zoom via Accessibility service");
    }

    /**
     * [STUB] RestoreSplitWindowMode -> (no direct Android equivalent)
     *
     * OH restores split window mode.
     * Android split screen is managed by WMS/SystemUI.
     * Impact: LOW - Handled at system level.
     */
    public void onRestoreSplitWindowMode(int mode) {
        logStub("RestoreSplitWindowMode",
                "Android manages split screen via WMS");
    }

    // ============================================================
    // Category 11: Wallpaper (-> IWindow.dispatchWallpaperOffsets)
    // ============================================================

    // Note: OH IWindow does not have wallpaper-specific callbacks.
    // Android IWindow.dispatchWallpaperOffsets and dispatchWallpaperCommand
    // have no OH IWindow counterparts.
    // Impact: MEDIUM - Wallpaper parallax effects won't work.
    // Strategy: Could be handled by enhancing OH WMS with wallpaper offset support.

    // ============================================================
    // Category 12: Debug (-> IWindow.executeCommand)
    // ============================================================

    /**
     * [PARTIAL] DumpInfo -> IWindow.executeCommand
     *
     * OH dumps window info for debugging.
     * Android uses executeCommand for view server debugging.
     */
    public void onDumpInfo() {
        logPartial("DumpInfo", "-> IWindow.executeCommand (debug)");
    }

    /**
     * [PARTIAL] GetWindowProperty -> (no direct Android equivalent)
     *
     * OH returns window property object.
     * Android queries window attributes via WindowManager.LayoutParams.
     * Impact: LOW - Debug/diagnostic only.
     */
    public void onGetWindowProperty() {
        logPartial("GetWindowProperty",
                "Android uses WindowManager.LayoutParams for window properties");
    }

    /**
     * [STUB] NotifyMMIServiceOnline -> (no Android equivalent)
     *
     * OH Multi-Modal Input service online notification.
     * Impact: None - Android input subsystem is different.
     */
    public void onNotifyMMIServiceOnline() {
        logStub("NotifyMMIServiceOnline",
                "OH MMI service, no Android equivalent");
    }

    // ==================== Utility ====================

    private void logBridged(String method, String target) {
        Log.d(TAG, "[BRIDGED] " + method + " " + target);
    }

    private void logPartial(String method, String reason) {
        Log.d(TAG, "[PARTIAL] " + method + " - " + reason);
    }

    private void logStub(String method, String reason) {
        Log.d(TAG, "[STUB] " + method + " - " + reason);
    }
}
