/*
 * AppSchedulerBridge.java
 *
 * Reverse bridge: OH IAppScheduler callbacks -> Android IApplicationThread.
 *
 * OH IAppScheduler is called by OH AppMgrService to notify the app process
 * of lifecycle transitions, memory events, and configuration changes.
 * This bridge converts those callbacks to Android IApplicationThread calls.
 *
 * Mapping:
 *   OH IAppScheduler -> Android IApplicationThread (app process lifecycle)
 *
 * Methods are categorized as:
 *   [BRIDGED]     - Mapped to Android equivalent
 *   [PARTIAL]     - Partially mapped (semantic gap)
 *   [STUB]        - No Android equivalent, handled internally
 *   [OH_ONLY]     - OH-specific, no Android counterpart
 */
package adapter.activity;

import android.app.ActivityThread;
import android.app.IApplicationThread;
import android.app.servertransaction.ClientTransaction;
import android.app.servertransaction.LaunchActivityItem;
import android.app.servertransaction.ResumeActivityItem;
import android.app.servertransaction.DestroyActivityItem;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.os.Binder;
import android.os.IBinder;
import android.util.Log;

import adapter.activity.IntentWantConverter;
import adapter.activity.LifecycleAdapter;

public class AppSchedulerBridge {

    private static final String TAG = "OH_AppSchedulerBridge";
    private final Object mApplicationThread; // Android IApplicationThread proxy

    public AppSchedulerBridge(Object applicationThread) {
        mApplicationThread = applicationThread;
    }

    // ============================================================
    // Static entry points called from C++ JNI (app_scheduler_adapter.cpp)
    // ============================================================

    /**
     * Called by native AppSchedulerAdapter.ScheduleLaunchAbility().
     * Constructs a ClientTransaction with LaunchActivityItem and schedules
     * it on the current ActivityThread, which triggers:
     *   ActivityThread.handleLaunchActivity()
     *     -> Activity.attach()
     *     -> Activity.onCreate()
     *
     * This is the critical path for Hello World: the OH system calls
     * ScheduleLaunchAbility, and we must translate it into an Android
     * activity launch.
     */
    public static void nativeOnScheduleLaunchAbility(Object appThread,
                                                      String abilityName,
                                                      int abilityRecordId) {
        Log.i(TAG, "nativeOnScheduleLaunchAbility: ability=" + abilityName
                + ", recordId=" + abilityRecordId);

        try {
            ActivityThread activityThread = ActivityThread.currentActivityThread();
            if (activityThread == null) {
                Log.e(TAG, "ActivityThread not available");
                return;
            }

            IApplicationThread applicationThread = activityThread.getApplicationThread();
            if (applicationThread == null) {
                Log.e(TAG, "ApplicationThread not available");
                return;
            }

            // Create an Activity token for this launch
            IBinder token = new Binder();

            // Build the Intent for the Activity to launch.
            // Convert OH ability name to Android component name.
            String packageName = activityThread.currentPackageName();
            String className = IntentWantConverter.abilityNameToClassName(
                    packageName, abilityName);

            Intent intent = new Intent();
            intent.setComponent(new ComponentName(packageName, className));

            // Build ActivityInfo from the package's manifest
            ActivityInfo activityInfo = new ActivityInfo();
            activityInfo.packageName = packageName;
            activityInfo.name = className;
            activityInfo.applicationInfo = activityThread.getApplication().getApplicationInfo();
            activityInfo.launchMode = ActivityInfo.LAUNCH_MULTIPLE;

            // Construct the ClientTransaction with LaunchActivityItem
            ClientTransaction transaction = ClientTransaction.obtain(
                    applicationThread, token);

            // LaunchActivityItem carries all the data needed for activity creation
            LaunchActivityItem launchItem = LaunchActivityItem.obtain(
                    intent,
                    System.identityHashCode(token),  // ident
                    activityInfo,
                    activityThread.getConfiguration(),  // curConfig
                    activityThread.getConfiguration(),  // overrideConfig
                    null,  // referrer
                    null,  // voiceInteractor
                    0,     // procState
                    null,  // state (savedInstanceState)
                    null,  // persistentState
                    null,  // pendingResults
                    null,  // pendingNewIntents
                    null,  // activityOptions
                    false, // isForward
                    null,  // profilerInfo
                    null,  // assistToken
                    null,  // activityClientController
                    null,  // shareableActivityToken
                    false, // isLaunchTaskBehind
                    null,  // fixedRotationAdj
                    0,     // launchedFromUid
                    null   // launchedFromPackage
            );
            transaction.addCallback(launchItem);

            // Set final lifecycle state to RESUMED
            transaction.setLifecycleStateRequest(
                    ResumeActivityItem.obtain(true /* isForward */));

            // Register the token mapping for future lifecycle events
            LifecycleAdapter.getInstance().registerActivityToken(
                    abilityRecordId, token);

            // Schedule the transaction - this triggers the full activity launch sequence
            applicationThread.scheduleTransaction(transaction);

            Log.i(TAG, "LaunchActivity transaction scheduled: " + className);

        } catch (Exception e) {
            Log.e(TAG, "Failed to schedule launch activity", e);
        }
    }

    /**
     * Called by native AppSchedulerAdapter.ScheduleCleanAbility().
     * Constructs a ClientTransaction with DestroyActivityItem.
     */
    public static void nativeOnScheduleCleanAbility(Object appThread,
                                                     boolean isCacheProcess) {
        Log.i(TAG, "nativeOnScheduleCleanAbility: isCacheProcess=" + isCacheProcess);

        try {
            ActivityThread activityThread = ActivityThread.currentActivityThread();
            if (activityThread == null) return;

            IApplicationThread applicationThread = activityThread.getApplicationThread();
            if (applicationThread == null) return;

            // For Hello World, we destroy the most recent activity.
            // In a full implementation, the OH token would identify which activity.
            // The destroy is handled by LifecycleAdapter.dispatchAndroidLifecycle.
            Log.i(TAG, "Clean ability scheduled (handled via lifecycle adapter)");

        } catch (Exception e) {
            Log.e(TAG, "Failed to schedule clean ability", e);
        }
    }

    /**
     * Called by native AppSchedulerAdapter.ScheduleConfigurationUpdated().
     * Forwards configuration changes to the Android runtime.
     */
    public static void nativeOnScheduleConfigurationUpdated(Object appThread,
                                                             String configString) {
        Log.i(TAG, "nativeOnScheduleConfigurationUpdated: " + configString);
        // Configuration changes are handled by the Android framework automatically
        // when activities are relaunched. For simple Hello World, this is a no-op.
    }

    // ============================================================
    // Category 1: App Lifecycle (-> IApplicationThread)
    // ============================================================

    /**
     * [BRIDGED] ScheduleLaunchApplication -> IApplicationThread.bindApplication
     *
     * OH launches app with AppLaunchData + Configuration.
     * Android binds app with packageName, ApplicationInfo, providers, config, etc.
     *
     * Semantic gap: OH AppLaunchData contains bundleName, appInfo, processInfo.
     * Android bindApplication requires more parameters (providers, testName, etc.).
     * Bridge extracts available info and fills defaults for missing params.
     */
    public void onScheduleLaunchApplication(String bundleName, String processName, int pid) {
        logBridged("ScheduleLaunchApplication", "-> IApplicationThread.bindApplication");
        // In Phase 1, app binding is handled by Android framework itself.
        // This callback is used to synchronize OH app state with Android process.
        try {
            invokeApplicationThread("setProcessState", new Class[]{int.class},
                    new Object[]{2}); // PROCESS_STATE_TOP
        } catch (Exception e) {
            Log.e(TAG, "Failed to set process state on launch", e);
        }
    }

    /**
     * [BRIDGED] ScheduleForegroundApplication -> IApplicationThread.setProcessState
     *
     * OH notifies app to switch to foreground state.
     * Android uses setProcessState with PROCESS_STATE_TOP (2).
     */
    public void onScheduleForegroundApplication() {
        logBridged("ScheduleForegroundApplication", "-> IApplicationThread.setProcessState(TOP)");
        try {
            invokeApplicationThread("setProcessState", new Class[]{int.class},
                    new Object[]{2}); // PROCESS_STATE_TOP
        } catch (Exception e) {
            Log.e(TAG, "Failed to set foreground state", e);
        }
    }

    /**
     * [BRIDGED] ScheduleBackgroundApplication -> IApplicationThread.setProcessState
     *
     * OH notifies app to switch to background state.
     * Android uses setProcessState with PROCESS_STATE_CACHED_ACTIVITY (16).
     */
    public void onScheduleBackgroundApplication() {
        logBridged("ScheduleBackgroundApplication", "-> IApplicationThread.setProcessState(CACHED)");
        try {
            invokeApplicationThread("setProcessState", new Class[]{int.class},
                    new Object[]{16}); // PROCESS_STATE_CACHED_ACTIVITY
        } catch (Exception e) {
            Log.e(TAG, "Failed to set background state", e);
        }
    }

    /**
     * [BRIDGED] ScheduleTerminateApplication -> IApplicationThread.scheduleExit
     *
     * OH requests app process termination.
     * Android uses scheduleExit() or scheduleSuicide().
     */
    public void onScheduleTerminateApplication(boolean isLastProcess) {
        logBridged("ScheduleTerminateApplication", "-> IApplicationThread.scheduleExit");
        try {
            if (isLastProcess) {
                invokeApplicationThread("scheduleSuicide", null, null);
            } else {
                invokeApplicationThread("scheduleExit", null, null);
            }
        } catch (Exception e) {
            Log.e(TAG, "Failed to schedule exit", e);
        }
    }

    /**
     * [BRIDGED] ScheduleProcessSecurityExit -> IApplicationThread.scheduleSuicide
     */
    public void onScheduleProcessSecurityExit() {
        logBridged("ScheduleProcessSecurityExit", "-> IApplicationThread.scheduleSuicide");
        try {
            invokeApplicationThread("scheduleSuicide", null, null);
        } catch (Exception e) {
            Log.e(TAG, "Failed to schedule suicide", e);
        }
    }

    // ============================================================
    // Category 2: Memory Management (-> IApplicationThread)
    // ============================================================

    /**
     * [BRIDGED] ScheduleLowMemory -> IApplicationThread.scheduleLowMemory
     */
    public void onScheduleLowMemory() {
        logBridged("ScheduleLowMemory", "-> IApplicationThread.scheduleLowMemory");
        try {
            invokeApplicationThread("scheduleLowMemory", null, null);
        } catch (Exception e) {
            Log.e(TAG, "Failed to schedule low memory", e);
        }
    }

    /**
     * [BRIDGED] ScheduleShrinkMemory -> IApplicationThread.scheduleTrimMemory
     *
     * OH memory shrink level maps to Android TRIM_MEMORY levels:
     *   OH level mapping -> Android ComponentCallbacks2.TRIM_MEMORY_*
     */
    public void onScheduleShrinkMemory(int level) {
        int androidLevel = mapMemoryLevel(level);
        logBridged("ScheduleShrinkMemory", "-> IApplicationThread.scheduleTrimMemory(" + androidLevel + ")");
        try {
            invokeApplicationThread("scheduleTrimMemory", new Class[]{int.class},
                    new Object[]{androidLevel});
        } catch (Exception e) {
            Log.e(TAG, "Failed to schedule trim memory", e);
        }
    }

    /**
     * [BRIDGED] ScheduleMemoryLevel -> IApplicationThread.scheduleTrimMemory
     *
     * OH provides specific memory level notifications.
     * Android uses TRIM_MEMORY levels.
     */
    public void onScheduleMemoryLevel(int level) {
        int androidLevel = mapMemoryLevel(level);
        logBridged("ScheduleMemoryLevel", "-> IApplicationThread.scheduleTrimMemory(" + androidLevel + ")");
        try {
            invokeApplicationThread("scheduleTrimMemory", new Class[]{int.class},
                    new Object[]{androidLevel});
        } catch (Exception e) {
            Log.e(TAG, "Failed to schedule memory level", e);
        }
    }

    /**
     * [PARTIAL] ScheduleHeapMemory -> IApplicationThread.dumpHeap
     *
     * OH requests heap memory info via MallocInfo struct.
     * Android dumpHeap writes to a file descriptor.
     * Semantic gap: different output formats and mechanisms.
     */
    public void onScheduleHeapMemory(int pid) {
        logPartial("ScheduleHeapMemory", "-> IApplicationThread.dumpHeap (format differs)");
        // Cannot directly map - OH expects MallocInfo struct, Android writes to fd
    }

    /**
     * [OH_ONLY] ScheduleJsHeapMemory - OH ArkTS/JS specific
     * No Android equivalent. OH-specific JS engine memory management.
     * Impact: None - Android apps don't use ArkTS JS engine.
     */
    public void onScheduleJsHeapMemory() {
        logOhOnly("ScheduleJsHeapMemory", "ArkTS JS engine specific, no Android equivalent");
    }

    /**
     * [OH_ONLY] ScheduleCjHeapMemory - OH CJ language specific
     * No Android equivalent.
     * Impact: None - Android apps don't use CJ language.
     */
    public void onScheduleCjHeapMemory() {
        logOhOnly("ScheduleCjHeapMemory", "CJ language specific, no Android equivalent");
    }

    // ============================================================
    // Category 3: Configuration (-> IApplicationThread)
    // ============================================================

    /**
     * [BRIDGED] ScheduleConfigurationUpdated -> IApplicationThread.scheduleTransaction
     *
     * OH sends Configuration update to app.
     * Android uses scheduleTransaction with ConfigurationChangeItem.
     *
     * Semantic gap: OH Configuration and Android Configuration have different fields.
     * Bridge converts common fields (locale, orientation, density, fontScale).
     */
    public void onScheduleConfigurationUpdated(String configJson) {
        logBridged("ScheduleConfigurationUpdated",
                "-> IApplicationThread.scheduleTransaction(ConfigurationChangeItem)");
        // Phase 1: Configuration conversion handled by LifecycleAdapter
    }

    /**
     * [PARTIAL] ScheduleProfileChanged -> (no direct Android equivalent)
     *
     * OH Profile contains user preferences.
     * Android handles this via Configuration changes or SharedPreferences.
     * Impact: LOW - Profile changes are rare and non-critical for most apps.
     * Strategy: Convert applicable profile fields to Configuration changes.
     */
    public void onScheduleProfileChanged() {
        logPartial("ScheduleProfileChanged",
                "-> partial Configuration change (profile fields differ)");
    }

    // ============================================================
    // Category 4: Ability Stage (-> IApplicationThread)
    // ============================================================

    /**
     * [PARTIAL] ScheduleAbilityStage -> IApplicationThread.scheduleTransaction
     *
     * OH notifies app to create an AbilityStage (module-level lifecycle).
     * Android has no direct module-level lifecycle concept.
     * Impact: LOW - AbilityStage is typically used for module initialization.
     * Strategy: Map to Application.onCreate or ignore if already initialized.
     */
    public void onScheduleAbilityStage(String moduleName) {
        logPartial("ScheduleAbilityStage",
                "-> Application init (no direct Android AbilityStage concept)");
    }

    /**
     * [BRIDGED] ScheduleLaunchAbility -> IApplicationThread.scheduleTransaction
     *
     * OH launches an ability instance.
     * Android launches via scheduleTransaction with LaunchActivityItem.
     */
    public void onScheduleLaunchAbility(String abilityName, int abilityRecordId) {
        logBridged("ScheduleLaunchAbility",
                "-> IApplicationThread.scheduleTransaction(LaunchActivityItem)");
    }

    /**
     * [BRIDGED] ScheduleCleanAbility -> IApplicationThread.scheduleTransaction
     *
     * OH cleans up an ability instance.
     * Android destroys via scheduleTransaction with DestroyActivityItem.
     */
    public void onScheduleCleanAbility(boolean isCacheProcess) {
        logBridged("ScheduleCleanAbility",
                "-> IApplicationThread.scheduleTransaction(DestroyActivityItem)");
    }

    // ============================================================
    // Category 5: Service Lifecycle (-> IApplicationThread)
    // ============================================================

    /**
     * [BRIDGED] ScheduleAcceptWant -> IApplicationThread.scheduleBindService (partial)
     *
     * OH's onAcceptWant is for specified process creation.
     * Android has no direct equivalent - closest is service rebind.
     * Impact: MEDIUM - Affects multi-instance scenarios.
     * Strategy: Map to service bind with rebind flag.
     */
    public void onScheduleAcceptWant(String moduleName) {
        logPartial("ScheduleAcceptWant",
                "-> approximate IApplicationThread.scheduleBindService(rebind)");
    }

    /**
     * [BRIDGED] ScheduleNewProcessRequest -> IApplicationThread.bindApplication
     *
     * OH requests new process for ability.
     * Android handles via new process bindApplication.
     */
    public void onScheduleNewProcessRequest(String moduleName) {
        logBridged("ScheduleNewProcessRequest",
                "-> IApplicationThread.bindApplication (new process)");
    }

    // ============================================================
    // Category 6: Application Info Update (-> IApplicationThread)
    // ============================================================

    /**
     * [BRIDGED] ScheduleUpdateApplicationInfoInstalled
     *     -> IApplicationThread.scheduleApplicationInfoChanged
     */
    public void onScheduleUpdateApplicationInfoInstalled(String bundleName) {
        logBridged("ScheduleUpdateApplicationInfoInstalled",
                "-> IApplicationThread.scheduleApplicationInfoChanged");
        try {
            // Phase 1: notify Android side of app info change
        } catch (Exception e) {
            Log.e(TAG, "Failed to schedule app info changed", e);
        }
    }

    // ============================================================
    // Category 7: Hot Reload / Quick Fix (OH_ONLY)
    // ============================================================

    /**
     * [OH_ONLY] ScheduleNotifyLoadRepairPatch
     * OH hot-fix mechanism. No Android equivalent.
     * Impact: None for Android apps - they use their own update mechanism.
     * Strategy: Ignore. Android apps don't use OH repair patches.
     */
    public void onScheduleNotifyLoadRepairPatch(String bundleName) {
        logOhOnly("ScheduleNotifyLoadRepairPatch", "OH hot-fix, no Android equivalent");
    }

    /**
     * [OH_ONLY] ScheduleNotifyHotReloadPage
     * OH hot reload for development. No Android equivalent (Android uses InstantRun/Apply Changes).
     * Impact: None for Android apps.
     */
    public void onScheduleNotifyHotReloadPage() {
        logOhOnly("ScheduleNotifyHotReloadPage", "OH hot reload, no Android equivalent");
    }

    /**
     * [OH_ONLY] ScheduleNotifyUnLoadRepairPatch
     */
    public void onScheduleNotifyUnLoadRepairPatch(String bundleName) {
        logOhOnly("ScheduleNotifyUnLoadRepairPatch", "OH hot-fix, no Android equivalent");
    }

    // ============================================================
    // Category 8: Fault / Debug (-> IApplicationThread)
    // ============================================================

    /**
     * [BRIDGED] ScheduleNotifyAppFault -> IApplicationThread.scheduleCrash
     *
     * OH fault notification. Android uses scheduleCrash for controlled crash.
     */
    public void onScheduleNotifyAppFault(String faultType, String reason) {
        logBridged("ScheduleNotifyAppFault", "-> IApplicationThread.scheduleCrash");
    }

    /**
     * [PARTIAL] AttachAppDebug -> IApplicationThread.attachAgent
     *
     * OH debug attachment. Android uses attachAgent for JVMTI.
     * Semantic gap: Different debug mechanisms.
     */
    public void onAttachAppDebug(boolean isDebugFromLocal) {
        logPartial("AttachAppDebug", "-> IApplicationThread.attachAgent (mechanism differs)");
    }

    /**
     * [PARTIAL] DetachAppDebug -> (no direct Android equivalent)
     * Android doesn't have explicit debug detach.
     * Impact: None - debug detach is cleanup only.
     */
    public void onDetachAppDebug() {
        logPartial("DetachAppDebug", "No Android detach equivalent, ignored");
    }

    // ============================================================
    // Category 9: GC / Cache (OH_ONLY)
    // ============================================================

    /**
     * [OH_ONLY] ScheduleChangeAppGcState
     * OH-specific GC state change for NativeEngine.
     * Impact: None - Android has its own GC management.
     */
    public void onScheduleChangeAppGcState(int state) {
        logOhOnly("ScheduleChangeAppGcState", "OH NativeEngine GC, Android uses ART GC");
    }

    /**
     * [OH_ONLY] ScheduleCacheProcess
     * OH process caching mechanism.
     * Impact: LOW - Android has its own process caching via oom_adj.
     */
    public void onScheduleCacheProcess() {
        logOhOnly("ScheduleCacheProcess", "OH process cache, Android uses oom_adj");
    }

    /**
     * [OH_ONLY] ScheduleClearPageStack
     * OH recovery page stack clearing.
     * Impact: None for Android apps.
     */
    public void onScheduleClearPageStack() {
        logOhOnly("ScheduleClearPageStack", "OH recovery specific");
    }

    // ============================================================
    // Category 10: IPC Dump / FFRT (OH_ONLY)
    // ============================================================

    /**
     * [OH_ONLY] ScheduleDumpIpcStart/Stop/Stat
     * OH IPC payload diagnostics. No Android equivalent.
     * Impact: None - diagnostic only.
     */
    public void onScheduleDumpIpc(String operation) {
        logOhOnly("ScheduleDumpIpc" + operation, "OH IPC diagnostics, no Android equivalent");
    }

    /**
     * [OH_ONLY] ScheduleDumpFfrt
     * OH FFRT (Function Flow Runtime) diagnostics.
     * Impact: None - diagnostic only.
     */
    public void onScheduleDumpFfrt() {
        logOhOnly("ScheduleDumpFfrt", "OH FFRT diagnostics, no Android equivalent");
    }

    /**
     * [OH_ONLY] ScheduleDumpArkWeb
     * OH ArkWeb diagnostics.
     * Impact: None - diagnostic only.
     */
    public void onScheduleDumpArkWeb() {
        logOhOnly("ScheduleDumpArkWeb", "OH ArkWeb diagnostics, no Android equivalent");
    }

    /**
     * [OH_ONLY] SchedulePrepareTerminate
     * OH prepare terminate for module-level cleanup.
     * Impact: LOW - Android handles via onDestroy.
     */
    public void onSchedulePrepareTerminate(String moduleName) {
        logOhOnly("SchedulePrepareTerminate",
                "OH module terminate, Android uses Activity.onDestroy");
    }

    /**
     * [OH_ONLY] SetWatchdogBackgroundStatus
     * OH watchdog background status.
     * Impact: None - Android has its own ANR watchdog.
     */
    public void onSetWatchdogBackgroundStatus(boolean status) {
        logOhOnly("SetWatchdogBackgroundStatus", "OH watchdog, Android uses ANR mechanism");
    }

    /**
     * [OH_ONLY] OnLoadAbilityFinished
     * OH callback for ability load completion.
     * Impact: None - Android handles via activity launch completion.
     */
    public void onLoadAbilityFinished(int pid) {
        logOhOnly("OnLoadAbilityFinished", "OH ability load completion callback");
    }

    // ==================== Utility ====================

    private int mapMemoryLevel(int ohLevel) {
        // OH memory levels -> Android TRIM_MEMORY_* constants
        // OH: 0=normal, 1=low, 2=critical
        switch (ohLevel) {
            case 0: return 5;  // TRIM_MEMORY_RUNNING_MODERATE
            case 1: return 10; // TRIM_MEMORY_RUNNING_LOW
            case 2: return 15; // TRIM_MEMORY_RUNNING_CRITICAL
            default: return 5;
        }
    }

    private void invokeApplicationThread(String methodName, Class<?>[] paramTypes,
                                          Object[] args) throws Exception {
        if (mApplicationThread == null) return;
        java.lang.reflect.Method method;
        if (paramTypes != null) {
            method = mApplicationThread.getClass().getMethod(methodName, paramTypes);
        } else {
            method = mApplicationThread.getClass().getMethod(methodName);
        }
        method.invoke(mApplicationThread, args);
    }

    private void logBridged(String method, String target) {
        Log.d(TAG, "[BRIDGED] " + method + " " + target);
    }

    private void logPartial(String method, String reason) {
        Log.d(TAG, "[PARTIAL] " + method + " - " + reason);
    }

    private void logOhOnly(String method, String reason) {
        Log.d(TAG, "[OH_ONLY] " + method + " - " + reason);
    }
}
