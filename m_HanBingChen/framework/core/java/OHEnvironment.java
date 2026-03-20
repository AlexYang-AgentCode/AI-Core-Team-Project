/*
 * OHEnvironment.java
 *
 * Minimal utility class serving as the environment detection and
 * native library loading entry point for the OH adapter layer.
 */

package adapter.core;

import android.os.SystemProperties;

/**
 * Static utility for detecting an OH environment, loading the adapter
 * bridge library, and managing the adapter lifecycle.
 */
public final class OHEnvironment {

    private static final String TAG = "OHEnvironment";
    private static final String PROP_OH_ADAPTER_ENABLED = "persist.oh.adapter.enabled";

    static {
        System.loadLibrary("oh_adapter_bridge");
    }

    private OHEnvironment() {
        // Prevent instantiation.
    }

    /**
     * Returns {@code true} when running inside an OH environment.
     * Checks the system property first; falls back to the native probe.
     */
    public static boolean isOHEnvironment() {
        String prop = SystemProperties.get(PROP_OH_ADAPTER_ENABLED);
        if ("true".equals(prop)) {
            return true;
        }
        if ("false".equals(prop)) {
            return false;
        }
        // Property not set or unrecognised value – ask native side.
        return nativeIsOHEnvironment();
    }

    /** Native probe for OH environment detection. */
    public static native boolean nativeIsOHEnvironment();

    /**
     * Initializes the OH IPC framework and connects to OH services.
     * Must be called early during process startup.
     */
    public static void initialize() {
        nativeInitialize();
        nativeConnectToOHServices();
    }

    /** Initialize the OH IPC framework. */
    public static native boolean nativeInitialize();

    /** Connect to OH services. */
    public static native boolean nativeConnectToOHServices();

    /**
     * Attaches an application to the OH adapter layer so that
     * subsequent calls can be routed correctly.
     *
     * @param pid         process id of the application
     * @param uid         user id of the application
     * @param packageName application package name
     */
    public static void attachApplication(int pid, int uid, String packageName) {
        nativeAttachApplication(pid, uid, packageName);
    }

    /** Native call to attach an application to the adapter layer. */
    public static native boolean nativeAttachApplication(int pid, int uid, String packageName);

    /**
     * Shuts down the OH adapter layer and releases associated resources.
     */
    public static void shutdown() {
        nativeShutdown();
    }

    /** Native call to shut down the adapter layer. */
    public static native void nativeShutdown();

    /**
     * Notifies the native side of an application state change.
     * Used by LifecycleAdapter to forward lifecycle events.
     *
     * @param state the new application state
     */
    public static native void nativeNotifyAppState(int state);
}
