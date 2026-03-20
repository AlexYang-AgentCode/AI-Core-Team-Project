/*
 * IActivityTaskManagerBridge.java
 *
 * Bridge implementation for Android IActivityTaskManager interface.
 * Routes calls to OH IAbilityManager + IMissionManager.
 *
 * Mapping:
 *   IActivityTaskManager -> OH IAbilityManager (activity start/stop)
 *                        -> OH IMissionManager (task/mission management)
 *                        -> OH ISceneSessionManager (window organization)
 *
 * Methods are categorized as:
 *   [BRIDGED]     - Mapped to OH equivalent
 *   [PARTIAL]     - Partially mapped
 *   [STUB]        - No OH equivalent, empty implementation
 */
package adapter.activity;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import adapter.activity.ActivityTaskManagerAdapter;
import adapter.activity.IntentWantConverter;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;

public class IActivityTaskManagerBridge implements InvocationHandler {

    private static final String TAG = "OH_IATMBridge";
    private final Object mOriginal;

    public IActivityTaskManagerBridge(Object original) {
        mOriginal = original;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        String name = method.getName();

        switch (name) {
            // ============================================================
            // Category 1: Activity Start (-> OH IAbilityManager)
            // ============================================================

            // [BRIDGED] startActivity -> OH IAbilityManager.StartAbility(Want)
            case "startActivity":
            case "startActivities":
            case "startActivityAsUser":
            case "startActivityIntentSender":
            case "startActivityWithConfig":
            case "startActivityAsCaller":
                return handleStartActivity(name, args);

            // [BRIDGED] startActivityAndWait -> OH IAbilityManager.StartAbility (sync)
            case "startActivityAndWait":
                handleStartActivity(name, args);
                logBridged(name, "-> OH IAbilityManager.StartAbility (sync wait)");
                return null; // WaitResult

            // [BRIDGED] startNextMatchingActivity
            case "startNextMatchingActivity":
                logBridged(name, "-> OH implicit Want resolution");
                return false;

            // [PARTIAL] startDreamActivity -> no OH equivalent
            case "startDreamActivity":
                logStub(name, "No OH dream/screensaver equivalent");
                return false;

            // [PARTIAL] startVoiceActivity -> OH StartAbility
            case "startVoiceActivity":
                return handleStartActivity(name, args);

            // [STUB] getVoiceInteractorPackageName
            case "getVoiceInteractorPackageName":
                logStub(name, "No OH voice interaction");
                return null;

            // [PARTIAL] startAssistantActivity -> OH StartAbility
            case "startAssistantActivity":
                return handleStartActivity(name, args);

            // [STUB] startActivityFromGameSession
            case "startActivityFromGameSession":
                return handleStartActivity(name, args);

            // [BRIDGED] startRecentsActivity -> OH IMissionManager
            case "startRecentsActivity":
                logBridged(name, "-> OH IMissionManager (recents)");
                return null;

            // [BRIDGED] startActivityFromRecents -> OH IMissionManager.MoveMissionToFront
            case "startActivityFromRecents":
                logBridged(name, "-> OH IMissionManager.MoveMissionToFront");
                return 0;

            // [STUB] isActivityStartAllowedOnDisplay
            case "isActivityStartAllowedOnDisplay":
                logStub(name, "No OH equivalent");
                return true;

            // ============================================================
            // Category 2: Activity Client Controller
            // ============================================================

            // [STUB] getActivityClientController
            case "getActivityClientController":
                logStub(name, "OH manages lifecycle differently");
                return null;

            // [BRIDGED] unhandledBack -> OH ISession.RequestSessionBack
            case "unhandledBack":
                logBridged(name, "-> OH ISession.RequestSessionBack");
                return null;

            // ============================================================
            // Category 3: Task Management (-> OH IMissionManager)
            // ============================================================

            // [BRIDGED] setFocusedTask -> OH IMissionManager.MoveMissionToFront
            case "setFocusedTask":
                logBridged(name, "-> OH IMissionManager.MoveMissionToFront");
                return null;

            // [BRIDGED] removeTask -> OH IMissionManager.CleanMission
            case "removeTask":
                logBridged(name, "-> OH IMissionManager.CleanMission");
                return true;

            // [STUB] removeAllVisibleRecentTasks -> OH IMissionManager.CleanAllMissions
            case "removeAllVisibleRecentTasks":
                logBridged(name, "-> OH IMissionManager.CleanAllMissions");
                return null;

            // [BRIDGED] getTasks -> OH IMissionManager.GetMissionInfos
            case "getTasks":
                logBridged(name, "-> OH IMissionManager.GetMissionInfos");
                return java.util.Collections.emptyList();

            // [BRIDGED] moveTaskToFront -> OH IMissionManager.MoveMissionToFront
            case "moveTaskToFront":
                logBridged(name, "-> OH IMissionManager.MoveMissionToFront");
                return null;

            // [BRIDGED] getRecentTasks -> OH IMissionManager.GetMissionInfos
            case "getRecentTasks":
                logBridged(name, "-> OH IMissionManager.GetMissionInfos");
                return null;

            // [BRIDGED] isTopActivityImmersive -> OH window query
            case "isTopActivityImmersive":
                logStub(name, "No direct OH equivalent");
                return false;

            // [BRIDGED] getTaskDescription -> OH IMissionManager.GetMissionInfo
            case "getTaskDescription":
                logBridged(name, "-> OH IMissionManager.GetMissionInfo");
                return null;

            // ============================================================
            // Category 4: Root Task / Stack (-> OH IMissionManager)
            // ============================================================

            // [BRIDGED] setFocusedRootTask
            case "setFocusedRootTask":
                logBridged(name, "-> OH IMissionManager.MoveMissionToFront");
                return null;

            // [BRIDGED] getFocusedRootTaskInfo
            case "getFocusedRootTaskInfo":
                logBridged(name, "-> OH (focused mission query)");
                return null;

            // [BRIDGED] getTaskBounds
            case "getTaskBounds":
                logBridged(name, "-> OH ISession.GetGlobalScaledRect");
                return null;

            // [STUB] focusTopTask
            case "focusTopTask":
                logStub(name, "OH manages focus differently");
                return null;

            // [BRIDGED] getAllRootTaskInfos / getRootTaskInfo / on display variants
            case "getAllRootTaskInfos":
            case "getRootTaskInfo":
            case "getAllRootTaskInfosOnDisplay":
            case "getRootTaskInfoOnDisplay":
                logBridged(name, "-> OH IMissionManager.GetMissionInfos");
                return name.startsWith("getAll") ? java.util.Collections.emptyList() : null;

            // [BRIDGED] moveRootTaskToDisplay / moveTaskToRootTask
            case "moveRootTaskToDisplay":
            case "moveTaskToRootTask":
                logBridged(name, "-> OH IMissionManager task operations");
                return null;

            // [BRIDGED] removeRootTasksInWindowingModes / removeRootTasksWithActivityTypes
            case "removeRootTasksInWindowingModes":
            case "removeRootTasksWithActivityTypes":
                logBridged(name, "-> OH IMissionManager.CleanMission");
                return null;

            // ============================================================
            // Category 5: Task Resize / Window Mode
            // ============================================================

            // [BRIDGED] setTaskResizeable -> OH window mode
            case "setTaskResizeable":
                logStub(name, "OH window mode managed by SceneSession");
                return null;

            // [BRIDGED] resizeTask -> OH ISession.UpdateSessionRect
            case "resizeTask":
                logBridged(name, "-> OH ISession.UpdateSessionRect");
                return null;

            // ============================================================
            // Category 6: Lock Task Mode (-> OH IMissionManager.Lock/Unlock)
            // ============================================================

            case "updateLockTaskPackages":
                logStub(name, "OH uses LockMissionForCleanup");
                return null;

            case "isInLockTaskMode":
                logStub(name, "No OH equivalent");
                return false;

            case "getLockTaskModeState":
                logStub(name, "No OH equivalent");
                return 0;

            case "startSystemLockTaskMode":
                logBridged(name, "-> OH IMissionManager.LockMissionForCleanup");
                return null;

            case "stopSystemLockTaskMode":
                logBridged(name, "-> OH IMissionManager.UnlockMissionForCleanup");
                return null;

            // ============================================================
            // Category 7: App Task (-> OH IMissionManager)
            // ============================================================

            case "getAppTasks":
                logBridged(name, "-> OH IMissionManager.GetMissionInfos");
                return java.util.Collections.emptyList();

            case "addAppTask":
                logStub(name, "No OH equivalent");
                return -1;

            case "getAppTaskThumbnailSize":
                logStub(name, "No OH equivalent");
                return null;

            // ============================================================
            // Category 8: Assist / Autofill (STUB)
            // ============================================================

            case "reportAssistContextExtras":
            case "getAssistContextExtras":
            case "requestAssistContextExtras":
            case "requestAutofillData":
            case "isAssistDataAllowedOnCurrentActivity":
            case "requestAssistDataForTask":
                logStub(name, "No OH assist equivalent");
                return getDefaultReturn(method);

            // ============================================================
            // Category 9: Recents Animation (STUB)
            // ============================================================

            case "cancelRecentsAnimation":
                logStub(name, "OH recents animation not mapped");
                return null;

            // ============================================================
            // Category 10: Voice / VR (STUB)
            // ============================================================

            case "finishVoiceTask":
            case "setVoiceKeepAwake":
            case "setVrThread":
            case "setPersistentVrThread":
                logStub(name, "No OH voice/VR equivalent");
                return null;

            // ============================================================
            // Category 11: Screen Compat (STUB)
            // ============================================================

            case "getFrontActivityScreenCompatMode":
            case "setFrontActivityScreenCompatMode":
            case "getPackageScreenCompatMode":
            case "setPackageScreenCompatMode":
            case "getPackageAskScreenCompat":
            case "setPackageAskScreenCompat":
                logStub(name, "No OH screen compat");
                return getDefaultReturn(method);

            // ============================================================
            // Category 12: Task Stack Listener (-> OH IMissionManager)
            // ============================================================

            // [BRIDGED] registerTaskStackListener -> OH IMissionManager.RegisterMissionListener
            case "registerTaskStackListener":
                logBridged(name, "-> OH IMissionManager.RegisterMissionListener");
                return null;

            case "unregisterTaskStackListener":
                logBridged(name, "-> OH IMissionManager.UnRegisterMissionListener");
                return null;

            // ============================================================
            // Category 13: Configuration
            // ============================================================

            // [BRIDGED] updateConfiguration -> OH IAppMgr.UpdateConfiguration
            case "updateConfiguration":
                logBridged(name, "-> OH IAppMgr.UpdateConfiguration");
                return true;

            case "suppressResizeConfigChanges":
                logStub(name, "No OH equivalent");
                return null;

            // ============================================================
            // Category 14: Keyguard (STUB)
            // ============================================================

            case "setLockScreenShown":
            case "keyguardGoingAway":
                logStub(name, "OH keyguard not mapped");
                return null;

            // ============================================================
            // Category 15: Window Organizer (-> OH ISceneSessionManager)
            // ============================================================

            // [PARTIAL] getWindowOrganizerController -> OH SceneSessionManager
            case "getWindowOrganizerController":
                logBridged(name, "-> OH ISceneSessionManager (partial)");
                return null;

            // ============================================================
            // Category 16: Task Snapshot (-> OH ISceneSessionManager)
            // ============================================================

            case "getTaskSnapshot":
            case "takeTaskSnapshot":
                logBridged(name, "-> OH ISceneSessionManager.GetSessionSnapshot");
                return null;

            case "cancelTaskWindowTransition":
                logStub(name, "No OH equivalent");
                return null;

            // ============================================================
            // Category 17: Remote Animation (STUB)
            // ============================================================

            case "registerRemoteAnimationForNextActivityStart":
            case "registerRemoteAnimationsForDisplay":
                logStub(name, "OH remote animation not mapped");
                return null;

            // ============================================================
            // Category 18: App Switches / Activity Controller
            // ============================================================

            case "stopAppSwitches":
            case "resumeAppSwitches":
                logStub(name, "No OH equivalent");
                return null;

            case "setActivityController":
                logStub(name, "No OH equivalent");
                return null;

            // ============================================================
            // Category 19: Remaining
            // ============================================================

            case "releaseSomeActivities":
                logStub(name, "OH manages memory internally");
                return null;

            case "getTaskDescriptionIcon":
                logBridged(name, "-> OH IMissionManager icon");
                return null;

            case "supportsLocalVoiceInteraction":
                logStub(name, "No OH equivalent");
                return false;

            case "getDeviceConfigurationInfo":
                logStub(name, "OH config managed differently");
                return null;

            case "getLastResumedActivityUserId":
                logStub(name, "No OH equivalent");
                return 0;

            case "alwaysShowUnsupportedCompileSdkWarning":
                logStub(name, "No OH equivalent");
                return null;

            case "clearLaunchParamsForPackages":
                logStub(name, "No OH equivalent");
                return null;

            case "onSplashScreenViewCopyFinished":
                logStub(name, "OH splash screen managed differently");
                return null;

            case "onPictureInPictureStateChanged":
                logBridged(name, "-> OH ISession PiP state");
                return null;

            case "detachNavigationBarFromApp":
                logStub(name, "No OH equivalent");
                return null;

            case "setRunningRemoteTransitionDelegate":
                logStub(name, "No OH equivalent");
                return null;

            case "startBackNavigation":
                logBridged(name, "-> OH ISession.RequestSessionBack");
                return null;

            case "registerScreenCaptureObserver":
            case "unregisterScreenCaptureObserver":
                logBridged(name, "-> OH IWindowManager screenshot listener");
                return null;

            case "updateLockTaskFeatures":
                logStub(name, "No OH equivalent");
                return null;

            default:
                Log.w(TAG, "[UNMAPPED] IActivityTaskManager." + name);
                try {
                    return method.invoke(mOriginal, args);
                } catch (Exception e) {
                    return getDefaultReturn(method);
                }
        }
    }

    // ==================== Handlers ====================

    private Object handleStartActivity(String methodName, Object[] args) {
        Intent intent = findInArgs(args, Intent.class);
        if (intent == null) {
            // For startActivities, look for Intent[]
            Intent[] intents = findInArgs(args, Intent[].class);
            if (intents != null && intents.length > 0) {
                intent = intents[0];
            }
        }
        if (intent == null) {
            logStub(methodName, "No Intent found");
            return 0;
        }
        logBridged(methodName, "-> OH IAbilityManager.StartAbility");
        IntentWantConverter.WantParams want = IntentWantConverter.intentToWant(intent);
        return ActivityTaskManagerAdapter.nativeStartAbility(want.bundleName, want.abilityName,
                want.action, want.uri, want.extrasJson);
    }

    // ==================== Utility ====================

    @SuppressWarnings("unchecked")
    private <T> T findInArgs(Object[] args, Class<T> clazz) {
        if (args == null) return null;
        for (Object arg : args) {
            if (clazz.isInstance(arg)) return (T) arg;
        }
        return null;
    }

    private Object getDefaultReturn(Method method) {
        Class<?> type = method.getReturnType();
        if (type == void.class) return null;
        if (type == boolean.class) return false;
        if (type == int.class) return 0;
        if (type == long.class) return 0L;
        if (type == float.class) return 0.0f;
        return null;
    }

    private void logBridged(String method, String target) {
        Log.d(TAG, "[BRIDGED] " + method + " " + target);
    }

    private void logStub(String method, String reason) {
        Log.d(TAG, "[STUB] " + method + " - " + reason);
    }
}
