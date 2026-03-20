/*
 * LifecycleAdapter.java
 *
 * Bidirectional mapping between Android Activity lifecycle and
 * OpenHarmony Ability lifecycle.
 *
 * Android:  onCreate -> onStart -> onResume -> onPause -> onStop -> onDestroy
 * OH:       onCreate -> onWindowStageCreate -> onForeground -> onBackground
 *                    -> onWindowStageDestroy -> onDestroy
 *
 * Mapping strategy:
 *   Android onCreate + onStart   <->  OH onCreate + onWindowStageCreate
 *   Android onResume             <->  OH onForeground
 *   Android onPause              <->  (intermediate state, no direct OH equivalent)
 *   Android onStop               <->  OH onBackground
 *   Android onDestroy            <->  OH onWindowStageDestroy + onDestroy
 */
package adapter.activity;

import adapter.core.OHEnvironment;

import android.app.ActivityThread;
import android.app.IApplicationThread;
import android.app.servertransaction.ClientTransaction;
import android.app.servertransaction.LaunchActivityItem;
import android.app.servertransaction.ResumeActivityItem;
import android.app.servertransaction.PauseActivityItem;
import android.app.servertransaction.StopActivityItem;
import android.app.servertransaction.DestroyActivityItem;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.os.IBinder;
import android.util.Log;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class LifecycleAdapter {

    private static final String TAG = "OH_LifecycleAdapter";

    // OH Ability lifecycle state constants (maps to OH AbilityLifecycleExecutor::LifecycleState)
    public static final int OH_STATE_INITIAL = 0;
    public static final int OH_STATE_INACTIVE = 1;       // onCreate completed
    public static final int OH_STATE_FOREGROUND_NEW = 2;  // onForeground
    public static final int OH_STATE_BACKGROUND_NEW = 4;  // onBackground

    // Android Activity lifecycle state constants
    public static final int ANDROID_STATE_CREATED = 1;
    public static final int ANDROID_STATE_STARTED = 2;
    public static final int ANDROID_STATE_RESUMED = 3;
    public static final int ANDROID_STATE_PAUSED = 4;
    public static final int ANDROID_STATE_STOPPED = 5;
    public static final int ANDROID_STATE_DESTROYED = 6;

    private static volatile LifecycleAdapter sInstance;

    // Track current lifecycle state of each Activity/Ability
    // key: Android Activity token (hashCode), value: current OH state
    private final Map<Integer, Integer> mStateMap = new ConcurrentHashMap<>();

    public static LifecycleAdapter getInstance() {
        if (sInstance == null) {
            synchronized (LifecycleAdapter.class) {
                if (sInstance == null) {
                    sInstance = new LifecycleAdapter();
                }
            }
        }
        return sInstance;
    }

    private LifecycleAdapter() {
    }

    /**
     * Convert Android Activity lifecycle state changes to OH Ability state changes.
     * Called when ActivityThread processes lifecycle events.
     *
     * @param activityToken Activity identifier
     * @param androidState  Target Android lifecycle state
     */
    public void onAndroidLifecycleChanged(int activityToken, int androidState) {
        int currentOHState = mStateMap.getOrDefault(activityToken, OH_STATE_INITIAL);
        int targetOHState = mapAndroidToOH(androidState);

        Log.d(TAG, "Android state change: " + androidStateName(androidState)
                + " -> OH state: " + ohStateName(targetOHState)
                + " (token=" + activityToken + ")");

        if (targetOHState != currentOHState) {
            mStateMap.put(activityToken, targetOHState);
            notifyOHStateChange(activityToken, targetOHState);
        }

        // Clean up state when Activity is destroyed
        if (androidState == ANDROID_STATE_DESTROYED) {
            mStateMap.remove(activityToken);
        }
    }

    /**
     * OH system service callback: Ability state change -> convert to Android Activity
     * lifecycle event. Called by the JNI layer's AbilitySchedulerStub.
     *
     * @param abilityToken OH Ability identifier
     * @param ohState      OH target lifecycle state
     */
    public void onOHLifecycleCallback(int abilityToken, int ohState) {
        int androidState = mapOHToAndroid(ohState);

        Log.d(TAG, "OH callback: state=" + ohStateName(ohState)
                + " -> Android state: " + androidStateName(androidState)
                + " (token=" + abilityToken + ")");

        // Trigger the corresponding Android lifecycle change via internal mechanism
        dispatchAndroidLifecycle(abilityToken, androidState);
    }

    // ==================== State Mapping ====================

    private int mapAndroidToOH(int androidState) {
        switch (androidState) {
            case ANDROID_STATE_CREATED:
            case ANDROID_STATE_STARTED:
                return OH_STATE_INACTIVE;
            case ANDROID_STATE_RESUMED:
                return OH_STATE_FOREGROUND_NEW;
            case ANDROID_STATE_PAUSED:
                // OH has no pause equivalent, stay in foreground
                return OH_STATE_FOREGROUND_NEW;
            case ANDROID_STATE_STOPPED:
                return OH_STATE_BACKGROUND_NEW;
            case ANDROID_STATE_DESTROYED:
                return OH_STATE_INITIAL;
            default:
                return OH_STATE_INITIAL;
        }
    }

    private int mapOHToAndroid(int ohState) {
        switch (ohState) {
            case OH_STATE_INACTIVE:
                return ANDROID_STATE_STARTED;
            case OH_STATE_FOREGROUND_NEW:
                return ANDROID_STATE_RESUMED;
            case OH_STATE_BACKGROUND_NEW:
                return ANDROID_STATE_STOPPED;
            case OH_STATE_INITIAL:
                return ANDROID_STATE_DESTROYED;
            default:
                return ANDROID_STATE_DESTROYED;
        }
    }

    // ==================== Notification Methods ====================

    /**
     * Notify OH system service of Ability state change.
     * Calls OH AbilityScheduler via JNI.
     */
    private void notifyOHStateChange(int token, int ohState) {
        OHEnvironment.nativeNotifyAppState(ohState);
    }

    /**
     * Dispatch Android lifecycle event to ActivityThread.
     * Constructs ClientTransaction with the appropriate lifecycle item
     * and schedules it via ApplicationThread.
     *
     * This is the key bridge method: when OH AbilityScheduler notifies us of
     * a lifecycle state change, we construct the corresponding Android
     * ClientTransaction and deliver it to ActivityThread for execution.
     */
    private void dispatchAndroidLifecycle(int token, int androidState) {
        Log.i(TAG, "Dispatching Android lifecycle: token=" + token
                + ", state=" + androidStateName(androidState));

        try {
            ActivityThread activityThread = ActivityThread.currentActivityThread();
            if (activityThread == null) {
                Log.e(TAG, "ActivityThread not available");
                return;
            }

            IApplicationThread appThread = activityThread.getApplicationThread();
            if (appThread == null) {
                Log.e(TAG, "ApplicationThread not available");
                return;
            }

            // Find the activity token for the given ability token.
            // In the adapter, we map OH ability tokens to Android activity tokens.
            IBinder activityToken = getActivityToken(token);
            if (activityToken == null && androidState != ANDROID_STATE_CREATED) {
                Log.w(TAG, "No activity token found for OH token " + token
                        + ", cannot dispatch " + androidStateName(androidState));
                return;
            }

            // Construct ClientTransaction with the appropriate lifecycle item
            ClientTransaction transaction = ClientTransaction.obtain(appThread, activityToken);

            switch (androidState) {
                case ANDROID_STATE_CREATED:
                    // LaunchActivityItem triggers handleLaunchActivity -> Activity.onCreate
                    // This is handled separately via AppSchedulerBridge.nativeOnScheduleLaunchAbility
                    Log.d(TAG, "CREATED state dispatched via LaunchActivityItem (separate path)");
                    return;

                case ANDROID_STATE_STARTED:
                    // No separate StartActivityItem in Android; handled via resume path
                    Log.d(TAG, "STARTED state handled as part of resume sequence");
                    return;

                case ANDROID_STATE_RESUMED:
                    // ResumeActivityItem triggers handleResumeActivity -> Activity.onResume
                    transaction.setLifecycleStateRequest(
                            ResumeActivityItem.obtain(true /* isForward */));
                    break;

                case ANDROID_STATE_PAUSED:
                    // PauseActivityItem triggers handlePauseActivity -> Activity.onPause
                    transaction.setLifecycleStateRequest(
                            PauseActivityItem.obtain());
                    break;

                case ANDROID_STATE_STOPPED:
                    // StopActivityItem triggers handleStopActivity -> Activity.onStop
                    transaction.setLifecycleStateRequest(
                            StopActivityItem.obtain(0 /* configChanges */));
                    break;

                case ANDROID_STATE_DESTROYED:
                    // DestroyActivityItem triggers handleDestroyActivity -> Activity.onDestroy
                    transaction.setLifecycleStateRequest(
                            DestroyActivityItem.obtain(false /* finished */,
                                    0 /* configChanges */));
                    break;

                default:
                    Log.w(TAG, "Unknown Android state: " + androidState);
                    return;
            }

            // Schedule the transaction on the ActivityThread
            activityThread.getApplicationThread().scheduleTransaction(transaction);
            Log.i(TAG, "ClientTransaction scheduled: " + androidStateName(androidState));

        } catch (Exception e) {
            Log.e(TAG, "Failed to dispatch Android lifecycle", e);
        }
    }

    // ==================== Activity Token Management ====================

    // Maps OH ability tokens to Android Activity IBinder tokens
    private final Map<Integer, IBinder> mTokenMap = new ConcurrentHashMap<>();

    /**
     * Register an Android Activity token for an OH ability token.
     * Called when a new Activity is launched via the adapter.
     */
    public void registerActivityToken(int ohToken, IBinder activityToken) {
        mTokenMap.put(ohToken, activityToken);
        Log.d(TAG, "Registered activity token for OH token " + ohToken);
    }

    /**
     * Remove a token mapping.
     */
    public void unregisterActivityToken(int ohToken) {
        mTokenMap.remove(ohToken);
    }

    /**
     * Get the Android Activity IBinder token for an OH ability token.
     */
    private IBinder getActivityToken(int ohToken) {
        return mTokenMap.get(ohToken);
    }

    // ==================== Utility Methods ====================

    private static String androidStateName(int state) {
        switch (state) {
            case ANDROID_STATE_CREATED:   return "CREATED";
            case ANDROID_STATE_STARTED:   return "STARTED";
            case ANDROID_STATE_RESUMED:   return "RESUMED";
            case ANDROID_STATE_PAUSED:    return "PAUSED";
            case ANDROID_STATE_STOPPED:   return "STOPPED";
            case ANDROID_STATE_DESTROYED: return "DESTROYED";
            default: return "UNKNOWN(" + state + ")";
        }
    }

    private static String ohStateName(int state) {
        switch (state) {
            case OH_STATE_INITIAL:        return "INITIAL";
            case OH_STATE_INACTIVE:       return "INACTIVE";
            case OH_STATE_FOREGROUND_NEW: return "FOREGROUND";
            case OH_STATE_BACKGROUND_NEW: return "BACKGROUND";
            default: return "UNKNOWN(" + state + ")";
        }
    }
}
