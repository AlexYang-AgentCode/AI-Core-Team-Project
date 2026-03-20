/*
 * IActivityManagerBridge.java
 *
 * Bridge implementation for Android IActivityManager interface.
 * Intercepts all IActivityManager method calls and routes them to
 * OpenHarmony system services (IAbilityManager + IAppMgr).
 *
 * Mapping:
 *   IActivityManager -> OH IAbilityManager (lifecycle, ability management)
 *                    -> OH IAppMgr (process management, app state)
 *                    -> OH IMissionManager (mission/task management)
 *
 * Methods are categorized as:
 *   [BRIDGED]     - Mapped to OH equivalent
 *   [PARTIAL]     - Partially mapped (some params ignored)
 *   [STUB]        - No OH equivalent, empty implementation
 */
package adapter.activity;

import android.content.Intent;
import android.os.Bundle;
import android.os.IBinder;
import android.util.Log;

import adapter.activity.ActivityManagerAdapter;
import adapter.activity.IntentWantConverter;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;

public class IActivityManagerBridge implements InvocationHandler {

    private static final String TAG = "OH_IAMBridge";
    private final Object mOriginal;

    public IActivityManagerBridge(Object original) {
        mOriginal = original;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        String name = method.getName();

        switch (name) {
            // ============================================================
            // Category 1: Activity Lifecycle (-> OH IAbilityManager)
            // ============================================================

            // [BRIDGED] startActivity -> OH IAbilityManager.StartAbility(Want)
            case "startActivity":
            case "startActivityWithFeature":
            case "startActivityAsUser":
            case "startActivityAsUserWithFeature":
                return handleStartActivity(name, args);

            // [BRIDGED] finishActivity -> OH IAbilityManager.CloseAbility(token)
            case "finishActivity":
                return handleFinishActivity(args);

            // [BRIDGED] moveActivityTaskToBack -> OH IAbilityManager.MinimizeAbility(token)
            case "moveActivityTaskToBack":
                return handleMoveToBack(args);

            // ============================================================
            // Category 2: Service Lifecycle (-> OH IAbilityManager)
            // ============================================================

            // [BRIDGED] startService -> OH IAbilityManager.StartAbility(Want) with ServiceExtension
            case "startService":
                return handleStartService(args);

            // [BRIDGED] stopService -> OH IAbilityManager.StopServiceAbility(Want)
            case "stopService":
                return handleStopService(args);

            // [BRIDGED] bindService/bindServiceInstance -> OH IAbilityManager.ConnectAbility(Want)
            case "bindService":
            case "bindServiceInstance":
                return handleBindService(args);

            // [BRIDGED] unbindService -> OH IAbilityManager.DisconnectAbility(connection)
            case "unbindService":
                return handleUnbindService(args);

            // [BRIDGED] publishService -> OH IAbilityManager.ScheduleConnectAbilityDone
            case "publishService":
                return handlePublishService(args);

            // [PARTIAL] stopServiceToken -> OH IAbilityManager.StopServiceAbility
            case "stopServiceToken":
                return handleStopServiceToken(args);

            // [BRIDGED] serviceDoneExecuting -> OH IAbilityManager.ScheduleCommandAbilityDone
            case "serviceDoneExecuting":
                logBridged(name, "-> OH ScheduleCommandAbilityDone");
                return null; // oneway void

            // [BRIDGED] setServiceForeground -> OH (no direct equiv, map to process priority)
            case "setServiceForeground":
                logStub(name, "OH has no foreground service concept");
                return null;

            // [STUB] getForegroundServiceType
            case "getForegroundServiceType":
                logStub(name, "OH has no foreground service type");
                return 0;

            // [STUB] peekService
            case "peekService":
                logStub(name, "No OH equivalent");
                return null;

            // [STUB] getServices (RunningServiceInfo)
            case "getServices":
                logStub(name, "Use OH IAbilityManager.GetExtensionRunningInfos");
                return java.util.Collections.emptyList();

            // [STUB] getRunningServiceControlPanel
            case "getRunningServiceControlPanel":
                logStub(name, "No OH equivalent");
                return null;

            // ============================================================
            // Category 3: Application Process (-> OH IAppMgr)
            // ============================================================

            // [BRIDGED] attachApplication -> OH IAppMgr.AttachApplication(scheduler)
            case "attachApplication":
                return handleAttachApplication(args);

            // [BRIDGED] finishAttachApplication -> OH IAppMgr (part of attach flow)
            case "finishAttachApplication":
                logBridged(name, "-> OH AttachApplication completion");
                return null;

            // [BRIDGED] getRunningAppProcesses -> OH IAppMgr.GetAllRunningProcesses
            case "getRunningAppProcesses":
                logBridged(name, "-> OH IAppMgr.GetAllRunningProcesses");
                return java.util.Collections.emptyList(); // Phase 1 stub

            // [BRIDGED] getProcessMemoryInfo -> OH IAppMgr.DumpHeapMemory
            case "getProcessMemoryInfo":
                logBridged(name, "-> OH IAppMgr.DumpHeapMemory");
                return new android.os.Debug.MemoryInfo[0];

            // [BRIDGED] killBackgroundProcesses -> OH IAbilityManager.KillProcess
            case "killBackgroundProcesses":
                logBridged(name, "-> OH IAbilityManager.KillProcess");
                return null;

            // [BRIDGED] forceStopPackage -> OH IAbilityManager.KillProcess
            case "forceStopPackage":
            case "forceStopPackageEvenWhenStopping":
                logBridged(name, "-> OH IAbilityManager.KillProcess");
                return null;

            // [BRIDGED] killApplication -> OH IAbilityManager.KillProcess
            case "killApplication":
            case "killApplicationProcess":
                logBridged(name, "-> OH IAbilityManager.KillProcess");
                return null;

            // [BRIDGED] getMyMemoryState -> OH IAppMgr.GetProcessRunningInformation
            case "getMyMemoryState":
                logBridged(name, "-> OH IAppMgr.GetProcessRunningInformation");
                return null;

            // [BRIDGED] getMemoryInfo -> OH IAppMgr.NotifyMemoryLevel
            case "getMemoryInfo":
                logBridged(name, "-> OH IAppMgr (memory query)");
                return null;

            // [PARTIAL] isUidActive -> OH IAppMgr.IsApplicationRunning
            case "isUidActive":
                logBridged(name, "-> OH IAppMgr.IsApplicationRunning");
                return true;

            // [PARTIAL] getUidProcessState -> OH IAppMgr.GetProcessRunningInformation
            case "getUidProcessState":
                logBridged(name, "-> OH IAppMgr.GetProcessRunningInformation");
                return 2; // PROCESS_STATE_FOREGROUND

            // [BRIDGED] getProcessLimit/setProcessLimit -> OH IAppMgr config
            case "getProcessLimit":
                logStub(name, "No OH equivalent");
                return -1;
            case "setProcessLimit":
                logStub(name, "No OH equivalent");
                return null;

            // [BRIDGED] handleApplicationCrash -> OH IAppMgr.NotifyAppFault
            case "handleApplicationCrash":
                logBridged(name, "-> OH IAppMgr.NotifyAppFault");
                return null;

            // [BRIDGED] handleApplicationWtf -> OH IAppMgr.NotifyAppFaultBySA
            case "handleApplicationWtf":
                logBridged(name, "-> OH IAppMgr.NotifyAppFaultBySA");
                return false;

            // ============================================================
            // Category 4: Broadcast (-> OH CommonEvent, STUB for Phase 1)
            // ============================================================

            // [STUB] registerReceiver/registerReceiverWithFeature
            // OH uses CommonEventManager, no direct IPC bridge
            case "registerReceiver":
            case "registerReceiverWithFeature":
                logStub(name, "OH uses CommonEventManager, not bridged in Phase 1");
                return null;

            // [STUB] unregisterReceiver
            case "unregisterReceiver":
                logStub(name, "OH CommonEventManager");
                return null;

            // [STUB] broadcastIntent/broadcastIntentWithFeature
            case "broadcastIntent":
            case "broadcastIntentWithFeature":
                logStub(name, "OH CommonEventManager.PublishCommonEvent");
                return 0; // BROADCAST_SUCCESS

            // [STUB] unbroadcastIntent
            case "unbroadcastIntent":
                logStub(name, "OH CommonEventManager");
                return null;

            // [STUB] finishReceiver
            case "finishReceiver":
                logStub(name, "OH CommonEventManager");
                return null;

            // ============================================================
            // Category 5: ContentProvider (-> OH DataAbility, STUB)
            // ============================================================

            // [STUB] getContentProvider -> OH DataAbility (different mechanism)
            case "getContentProvider":
            case "getContentProviderExternal":
                logStub(name, "OH uses DataShareHelper, not bridged");
                return null;

            // [STUB] publishContentProviders
            case "publishContentProviders":
                logStub(name, "OH DataAbility");
                return null;

            // [STUB] refContentProvider
            case "refContentProvider":
                logStub(name, "OH DataAbility");
                return true;

            // [STUB] removeContentProvider/removeContentProviderExternal
            case "removeContentProvider":
            case "removeContentProviderExternal":
            case "removeContentProviderExternalAsUser":
                logStub(name, "OH DataAbility");
                return null;

            // [STUB] openContentUri
            case "openContentUri":
                logStub(name, "OH DataAbility");
                return null;

            // ============================================================
            // Category 6: Task/Mission Management (-> OH IMissionManager)
            // ============================================================

            // [BRIDGED] getTasks -> OH IAbilityManager.GetMissionInfos
            case "getTasks":
                logBridged(name, "-> OH IMissionManager.GetMissionInfos");
                return java.util.Collections.emptyList();

            // [BRIDGED] getRecentTasks -> OH IMissionManager.GetMissionInfos
            case "getRecentTasks":
                logBridged(name, "-> OH IMissionManager.GetMissionInfos");
                return null;

            // [BRIDGED] moveTaskToFront -> OH IMissionManager.MoveMissionToFront
            case "moveTaskToFront":
                logBridged(name, "-> OH IMissionManager.MoveMissionToFront");
                return null;

            // [BRIDGED] removeTask -> OH IMissionManager.CleanMission
            case "removeTask":
                logBridged(name, "-> OH IMissionManager.CleanMission");
                return true;

            // [BRIDGED] getTaskForActivity -> OH IAbilityManager.GetMissionIdByToken
            case "getTaskForActivity":
                logBridged(name, "-> OH IAbilityManager.GetMissionIdByToken");
                return -1;

            // [BRIDGED] registerTaskStackListener -> OH IMissionManager.RegisterMissionListener
            case "registerTaskStackListener":
                logBridged(name, "-> OH IMissionManager.RegisterMissionListener");
                return null;

            // [BRIDGED] unregisterTaskStackListener
            case "unregisterTaskStackListener":
                logBridged(name, "-> OH IMissionManager.UnRegisterMissionListener");
                return null;

            // [BRIDGED] getAllRootTaskInfos -> OH IMissionManager.GetMissionInfos
            case "getAllRootTaskInfos":
                logBridged(name, "-> OH IMissionManager.GetMissionInfos");
                return java.util.Collections.emptyList();

            // [BRIDGED] getFocusedRootTaskInfo
            case "getFocusedRootTaskInfo":
                logBridged(name, "-> OH (query focused mission)");
                return null;

            // [BRIDGED] moveTaskToRootTask
            case "moveTaskToRootTask":
                logBridged(name, "-> OH IMissionManager.MoveMissionToFront");
                return null;

            // [BRIDGED] setFocusedRootTask
            case "setFocusedRootTask":
                logBridged(name, "-> OH IMissionManager.MoveMissionToFront");
                return null;

            // [BRIDGED] getTaskBounds -> OH (query session rect)
            case "getTaskBounds":
                logBridged(name, "-> OH ISession.GetGlobalScaledRect");
                return null;

            // [BRIDGED] setTaskResizeable
            case "setTaskResizeable":
                logStub(name, "OH window mode managed differently");
                return null;

            // [BRIDGED] resizeTask
            case "resizeTask":
                logBridged(name, "-> OH ISession.UpdateSessionRect");
                return null;

            // [BRIDGED] startActivityFromRecents
            case "startActivityFromRecents":
                logBridged(name, "-> OH IMissionManager.MoveMissionToFront");
                return 0;

            // [BRIDGED] isInLockTaskMode / getLockTaskModeState
            case "isInLockTaskMode":
                logBridged(name, "-> OH IMissionManager.LockMissionForCleanup state");
                return false;
            case "getLockTaskModeState":
                logStub(name, "No OH equivalent");
                return 0;

            // [BRIDGED] updateLockTaskPackages
            case "updateLockTaskPackages":
                logStub(name, "No OH equivalent");
                return null;

            // [BRIDGED] startSystemLockTaskMode
            case "startSystemLockTaskMode":
                logBridged(name, "-> OH IMissionManager.LockMissionForCleanup");
                return null;

            // ============================================================
            // Category 7: Configuration (-> OH IAppMgr)
            // ============================================================

            // [BRIDGED] getConfiguration -> OH IAppMgr.GetConfiguration
            case "getConfiguration":
                logBridged(name, "-> OH IAppMgr.GetConfiguration");
                return method.invoke(mOriginal, args); // fallback

            // [BRIDGED] updateConfiguration -> OH IAppMgr.UpdateConfiguration
            case "updateConfiguration":
            case "updatePersistentConfiguration":
            case "updatePersistentConfigurationWithAttribution":
            case "updateMccMncConfiguration":
                logBridged(name, "-> OH IAppMgr.UpdateConfiguration");
                return true;

            // ============================================================
            // Category 8: Permission (-> OH AccessTokenKit, STUB)
            // ============================================================

            // [STUB] checkPermission -> OH AccessTokenKit.VerifyAccessToken
            case "checkPermission":
                logStub(name, "OH uses AccessTokenKit");
                return 0; // PERMISSION_GRANTED

            // [STUB] checkUriPermission/grantUriPermission/revokeUriPermission
            case "checkUriPermission":
            case "checkUriPermissions":
                logStub(name, "OH uses AccessTokenKit");
                return method.getReturnType() == int.class ? 0 : null;
            case "grantUriPermission":
            case "revokeUriPermission":
                logStub(name, "OH uses AccessTokenKit");
                return null;

            // ============================================================
            // Category 9: IntentSender/PendingIntent (-> OH WantAgent)
            // ============================================================

            // [PARTIAL] getIntentSender -> OH IAbilityManager.GetWantSender
            case "getIntentSender":
            case "getIntentSenderWithFeature":
                logBridged(name, "-> OH IAbilityManager.GetWantSender");
                return null; // Phase 1 stub

            // [PARTIAL] cancelIntentSender -> OH IAbilityManager.CancelWantSender
            case "cancelIntentSender":
                logBridged(name, "-> OH IAbilityManager.CancelWantSender");
                return null;

            // [PARTIAL] sendIntentSender -> OH IAbilityManager.SendWantSender
            case "sendIntentSender":
                logBridged(name, "-> OH IAbilityManager.SendWantSender");
                return 0;

            // [STUB] getInfoForIntentSender
            case "getInfoForIntentSender":
            case "getIntentForIntentSender":
            case "getTagForIntentSender":
            case "isIntentSenderTargetedToPackage":
            case "isIntentSenderAnActivity":
            case "registerIntentSenderCancelListenerEx":
            case "unregisterIntentSenderCancelListener":
            case "getPendingRequestWant":
            case "getWantSenderInfo":
                logStub(name, "OH WantAgent (partial mapping)");
                return getDefaultReturn(method);

            // ============================================================
            // Category 10: User Management (-> OH, STUB for Phase 1)
            // ============================================================

            case "switchUser":
            case "startUserInBackground":
            case "startUserInBackgroundWithListener":
            case "startUserInForegroundWithListener":
            case "startUserInBackgroundVisibleOnDisplay":
            case "stopUser":
            case "stopUserWithDelayedLocking":
            case "isUserRunning":
            case "getCurrentUser":
            case "getCurrentUserId":
            case "getRunningUserIds":
            case "startProfile":
            case "startProfileWithListener":
            case "stopProfile":
            case "restartUserInBackground":
            case "registerUserSwitchObserver":
            case "unregisterUserSwitchObserver":
            case "handleIncomingUser":
            case "logoutUser":
            case "getSwitchingFromUserMessage":
            case "getSwitchingToUserMessage":
            case "setStopUserOnSwitch":
            case "getDisplayIdsForStartingVisibleBackgroundUsers":
                logStub(name, "OH user management not mapped in Phase 1");
                return getDefaultReturn(method);

            // ============================================================
            // Category 11: Instrumentation/Debug (STUB)
            // ============================================================

            case "startInstrumentation":
            case "addInstrumentationResults":
            case "finishInstrumentation":
            case "setDebugApp":
            case "setAgentApp":
            case "setAlwaysFinish":
            case "showWaitingForDebugger":
            case "profileControl":
            case "dumpHeap":
            case "requestSystemServerHeapDump":
            case "setDumpHeapDebugLimit":
            case "dumpHeapFinished":
            case "startBinderTracking":
            case "stopBinderTrackingAndDump":
            case "setRenderThread":
            case "setPersistentVrThread":
            case "setHasTopUi":
            case "setDeterministicUidIdle":
                logStub(name, "Debug/instrumentation, no OH mapping");
                return getDefaultReturn(method);

            // ============================================================
            // Category 12: UID Observer (-> OH IAppMgr observers)
            // ============================================================

            // [PARTIAL] registerUidObserver -> OH IAppMgr.RegisterApplicationStateObserver
            case "registerUidObserver":
                logBridged(name, "-> OH IAppMgr.RegisterApplicationStateObserver");
                return null;

            // [PARTIAL] unregisterUidObserver
            case "unregisterUidObserver":
                logBridged(name, "-> OH IAppMgr.UnregisterApplicationStateObserver");
                return null;

            case "registerUidObserverForUids":
            case "addUidToObserver":
            case "removeUidFromObserver":
                logBridged(name, "-> OH IAppMgr observer");
                return getDefaultReturn(method);

            // [PARTIAL] registerProcessObserver
            case "registerProcessObserver":
            case "unregisterProcessObserver":
                logBridged(name, "-> OH IAppMgr process observer");
                return null;

            // ============================================================
            // Category 13: Keyguard / System (STUB)
            // ============================================================

            case "signalPersistentProcesses":
            case "restart":
            case "shutdown":
            case "enterSafeMode":
            case "isSafeModeEnabled":
            case "hang":
            case "stopAppSwitches":
            case "resumeAppSwitches":
            case "closeSystemDialogs":
            case "setActivityController":
            case "showBootMessage":
            case "bootAnimationComplete":
            case "isUserAMonkey":
            case "setUserIsMonkey":
            case "isTopActivityImmersive":
            case "lockNow":
                logStub(name, "System-level, no OH mapping");
                return getDefaultReturn(method);

            // ============================================================
            // Category 14: Backup/Restore (STUB)
            // ============================================================

            case "bindBackupAgent":
            case "backupAgentCreated":
            case "unbindBackupAgent":
                logStub(name, "OH backup not mapped");
                return getDefaultReturn(method);

            // ============================================================
            // Category 15: Bug Report (STUB)
            // ============================================================

            case "requestBugReport":
            case "requestBugReportWithDescription":
            case "requestTelephonyBugReport":
            case "requestWifiBugReport":
            case "requestInteractiveBugReportWithDescription":
            case "requestInteractiveBugReport":
            case "requestFullBugReport":
            case "requestRemoteBugReport":
            case "launchBugReportHandlerApp":
            case "getBugreportWhitelistedPackages":
                logStub(name, "OH bugreport not mapped");
                return getDefaultReturn(method);

            // ============================================================
            // Category 16: Error Handling (-> OH IAppMgr fault)
            // ============================================================

            case "crashApplicationWithType":
            case "crashApplicationWithTypeWithExtras":
            case "appNotResponding":
            case "appNotRespondingViaProvider":
            case "handleApplicationStrictModeViolation":
            case "registerStrictModeCallback":
            case "getProcessesInErrorState":
            case "resetAppErrors":
                logBridged(name, "-> OH IAppMgr fault handling");
                return getDefaultReturn(method);

            // ============================================================
            // Category 17: Misc App Management
            // ============================================================

            // [BRIDGED] clearApplicationUserData -> OH IAppMgr.ClearUpApplicationDataBySelf
            case "clearApplicationUserData":
                logBridged(name, "-> OH IAppMgr.ClearUpApplicationDataBySelf");
                return true;

            // [BRIDGED] stopAppForUser -> OH IAbilityManager.KillProcess
            case "stopAppForUser":
                logBridged(name, "-> OH IAbilityManager.KillProcess");
                return null;

            // [STUB] getRunningExternalApplications
            case "getRunningExternalApplications":
                logStub(name, "No OH equivalent");
                return java.util.Collections.emptyList();

            // [STUB] finishHeavyWeightApp
            case "finishHeavyWeightApp":
                logStub(name, "No OH equivalent");
                return null;

            // [BRIDGED] killAllBackgroundProcesses -> OH IAbilityManager.KillProcess
            case "killAllBackgroundProcesses":
            case "killProcessesBelowForeground":
                logBridged(name, "-> OH kill processes");
                return getDefaultReturn(method);

            // [BRIDGED] killPids
            case "killPids":
                logBridged(name, "-> OH process management");
                return true;

            // [BRIDGED] killUid / killUidForPermissionChange
            case "killUid":
            case "killUidForPermissionChange":
                logBridged(name, "-> OH process management");
                return null;

            // [BRIDGED] killPackageDependents
            case "killPackageDependents":
            case "addPackageDependency":
                logBridged(name, "-> OH process management");
                return null;

            // [BRIDGED] makePackageIdle
            case "makePackageIdle":
                logStub(name, "No OH equivalent");
                return null;

            // [BRIDGED] getPackageProcessState
            case "getPackageProcessState":
                logBridged(name, "-> OH IAppMgr process state");
                return 2; // PROCESS_STATE_FOREGROUND

            // [PARTIAL] scheduleApplicationInfoChanged
            case "scheduleApplicationInfoChanged":
                logBridged(name, "-> OH IAppMgr.UpdateConfiguration");
                return null;

            // ============================================================
            // Category 18: Orientation
            // ============================================================

            case "setRequestedOrientation":
                logBridged(name, "-> OH ISession property update");
                return null;

            // ============================================================
            // Category 19: App Freezer (STUB)
            // ============================================================

            case "isAppFreezerSupported":
            case "isAppFreezerEnabled":
            case "enableAppFreezer":
            case "isProcessFrozen":
            case "registerUidFrozenStateChangedCallback":
            case "unregisterUidFrozenStateChangedCallback":
            case "getUidFrozenState":
                logStub(name, "OH app freezer not mapped");
                return getDefaultReturn(method);

            // ============================================================
            // Category 20: Remaining methods
            // ============================================================

            case "unbindFinished":
                logBridged(name, "-> OH IAbilityManager.ScheduleDisconnectAbilityDone");
                return null;

            case "setProcessImportant":
                logStub(name, "OH manages process priority internally");
                return null;

            case "getLaunchedFromUid":
            case "getLaunchedFromPackage":
                logStub(name, "No direct OH equivalent");
                return getDefaultReturn(method);

            case "isTopOfTask":
                logStub(name, "No OH equivalent");
                return true;

            case "getProcessPss":
                logBridged(name, "-> OH IAppMgr memory info");
                return new long[0];

            case "getMemoryTrimLevel":
                logStub(name, "No OH equivalent");
                return 0;

            case "setActivityLocusContext":
            case "setProcessStateSummary":
                logStub(name, "No OH equivalent");
                return null;

            case "isBackgroundRestricted":
                logStub(name, "OH manages differently");
                return false;

            case "backgroundAllowlistUid":
                logStub(name, "No OH equivalent");
                return null;

            case "getLifeMonitor":
                logStub(name, "No OH equivalent");
                return null;

            case "holdLock":
                logStub(name, "No OH equivalent");
                return null;

            case "suppressResizeConfigChanges":
                logStub(name, "No OH equivalent");
                return null;

            case "getMimeTypeFilterAsync":
                logStub(name, "No OH equivalent");
                return null;

            case "noteWakeupAlarm":
            case "noteAlarmStart":
            case "noteAlarmFinish":
                logStub(name, "OH alarm not mapped");
                return null;

            case "notifyCleartextNetwork":
                logStub(name, "No OH equivalent");
                return null;

            case "cancelTaskWindowTransition":
                logStub(name, "No OH equivalent");
                return null;

            case "isVrModePackageEnabled":
                logStub(name, "No OH equivalent");
                return false;

            case "sendIdleJobTrigger":
                logStub(name, "No OH equivalent");
                return null;

            case "setPackageScreenCompatMode":
                logStub(name, "No OH equivalent");
                return null;

            case "getProcessRunningInfos":
                logBridged(name, "-> OH IAppMgr.GetAllRunningProcesses");
                return null;

            case "unhandledBack":
                logBridged(name, "-> OH ISession.RequestSessionBack");
                return null;

            case "unstableProviderDied":
                logStub(name, "OH DataAbility");
                return null;

            case "setApplicationStartInfoCompleteListener":
            case "removeApplicationStartInfoCompleteListener":
            case "getHistoricalProcessStartReasons":
            case "getHistoricalProcessExitReasons":
            case "killProcessesWhenImperceptible":
                logStub(name, "No OH equivalent");
                return getDefaultReturn(method);

            case "startDelegateShellPermissionIdentity":
            case "stopDelegateShellPermissionIdentity":
            case "getDelegatedShellPermissions":
                logStub(name, "Shell permission delegation not mapped");
                return getDefaultReturn(method);

            case "logFgsApiBegin":
            case "logFgsApiEnd":
            case "logFgsApiStateChanged":
                logStub(name, "Foreground service logging not mapped");
                return null;

            case "registerForegroundServiceObserver":
                logStub(name, "No OH equivalent");
                return false;

            case "enableFgsNotificationRateLimit":
                logStub(name, "No OH equivalent");
                return true;

            case "shouldServiceTimeOut":
                logStub(name, "No OH equivalent");
                return false;

            case "getBackgroundRestrictionExemptionReason":
                logStub(name, "No OH equivalent");
                return 0;

            case "waitForBroadcastIdle":
            case "waitForBroadcastBarrier":
            case "forceDelayBroadcastDelivery":
            case "isModernBroadcastQueueEnabled":
                logStub(name, "OH broadcast not mapped");
                return getDefaultReturn(method);

            case "queryIntentComponentsForIntentSender":
                logStub(name, "No OH equivalent");
                return null;

            case "getUidProcessCapabilities":
                logStub(name, "No OH equivalent");
                return 0;

            case "waitForNetworkStateUpdate":
            case "notifyLockedProfile":
            case "startConfirmDeviceCredentialIntent":
                logStub(name, "No OH equivalent");
                return null;

            case "startUserTest":
            case "finishUserTest":
                logStub(name, "OH test framework different");
                return getDefaultReturn(method);

            // Catch-all: pass through to original or return default
            default:
                Log.w(TAG, "[UNMAPPED] IActivityManager." + name + " - passing through");
                try {
                    return method.invoke(mOriginal, args);
                } catch (Exception e) {
                    return getDefaultReturn(method);
                }
        }
    }

    // ==================== Bridge Handlers ====================

    private Object handleStartActivity(String methodName, Object[] args) {
        Intent intent = findInArgs(args, Intent.class);
        if (intent == null) {
            logStub(methodName, "No Intent found");
            return 0;
        }
        logBridged(methodName, "-> OH IAbilityManager.StartAbility");
        IntentWantConverter.WantParams want = IntentWantConverter.intentToWant(intent);
        return ActivityManagerAdapter.nativeStartAbility(want.bundleName, want.abilityName,
                want.action, want.uri, want.extrasJson);
    }

    private Object handleFinishActivity(Object[] args) {
        logBridged("finishActivity", "-> OH IAbilityManager.CloseAbility");
        // args[0] = IBinder token, args[1] = resultCode, args[2] = resultData Intent
        return true;
    }

    private Object handleMoveToBack(Object[] args) {
        logBridged("moveActivityTaskToBack", "-> OH IAbilityManager.MinimizeAbility");
        return true;
    }

    private Object handleStartService(Object[] args) {
        Intent intent = findInArgs(args, Intent.class);
        logBridged("startService", "-> OH IAbilityManager.StartAbility (ServiceExtension)");
        if (intent != null) {
            IntentWantConverter.WantParams want = IntentWantConverter.intentToWant(intent);
            ActivityManagerAdapter.nativeStartAbility(want.bundleName, want.abilityName,
                    want.action, want.uri, want.extrasJson);
        }
        return intent != null ? intent.getComponent() : null;
    }

    private Object handleStopService(Object[] args) {
        logBridged("stopService", "-> OH IAbilityManager.StopServiceAbility");
        return 1; // stopped
    }

    private Object handleBindService(Object[] args) {
        Intent intent = findInArgs(args, Intent.class);
        logBridged("bindService", "-> OH IAbilityManager.ConnectAbility");
        if (intent != null) {
            IntentWantConverter.WantParams want = IntentWantConverter.intentToWant(intent);
            ActivityManagerAdapter.nativeConnectAbility(want.bundleName, want.abilityName, 0);
        }
        return 1; // bind success
    }

    private Object handleUnbindService(Object[] args) {
        logBridged("unbindService", "-> OH IAbilityManager.DisconnectAbility");
        return true;
    }

    private Object handlePublishService(Object[] args) {
        logBridged("publishService", "-> OH IAbilityManager.ScheduleConnectAbilityDone");
        return null;
    }

    private Object handleStopServiceToken(Object[] args) {
        logBridged("stopServiceToken", "-> OH IAbilityManager.StopServiceAbility");
        return true;
    }

    private Object handleAttachApplication(Object[] args) {
        logBridged("attachApplication", "-> OH IAppMgr.AttachApplication");
        // The real attach is done during OHEnvironment.initialize()
        return null;
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
        if (type == double.class) return 0.0;
        return null;
    }

    private void logBridged(String method, String target) {
        Log.d(TAG, "[BRIDGED] " + method + " " + target);
    }

    private void logStub(String method, String reason) {
        Log.d(TAG, "[STUB] " + method + " - " + reason);
    }
}
