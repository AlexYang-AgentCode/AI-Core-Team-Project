/*
 * AppSpawnXInit.java
 *
 * Java-side initialization for appspawn-x hybrid spawner.
 * Called from native code (appspawnx_runtime.cpp) via JNI.
 *
 * Two entry points:
 * 1. preload() - Called in parent process during startup to preload
 *    Android framework classes, resources, shared libraries, and adapter layer.
 *    All preloaded data is shared with child processes via fork() COW.
 *
 * 2. initChild(procName, targetClass, targetSdkVersion) - Called in child process
 *    after fork() and OH security specialization. Initializes the Android runtime
 *    environment and launches the target main class (typically ActivityThread).
 */
package com.android.internal.os;

import android.os.Process;
import android.util.Log;
import dalvik.system.VMRuntime;
import java.lang.reflect.Method;

public class AppSpawnXInit {

    private static final String TAG = "AppSpawnXInit";

    // ============================================================
    // Parent Process: Preload (called once during startup)
    // ============================================================

    /**
     * Preload Android framework classes, resources, and adapter layer.
     * Called from native appspawnx_runtime.cpp in the parent daemon process.
     * All loaded classes/resources are shared with children via COW after fork().
     */
    public static void preload() {
        Log.i(TAG, "=== Preloading Android framework ===");
        long startTime = System.currentTimeMillis();

        try {
            // 1. Preload classes (~7000 Android framework classes)
            Log.i(TAG, "Preloading classes...");
            preloadClasses();

            // 2. Preload system resources (Drawable, ColorStateList)
            Log.i(TAG, "Preloading resources...");
            preloadResources();

            // 3. Preload shared libraries
            Log.i(TAG, "Preloading shared libraries...");
            preloadSharedLibraries();

            // 4. Preload graphics driver
            Log.i(TAG, "Preloading graphics driver...");
            preloadGraphicsDriver();

            // 5. Preload JCA security providers
            Log.i(TAG, "Warming up JCA providers...");
            warmUpJcaProviders();

            // 6. Preload adapter bridge (appspawn-x specific)
            Log.i(TAG, "Preloading adapter bridge...");
            preloadAdapterBridge();

        } catch (Exception e) {
            Log.e(TAG, "Preload failed (non-fatal)", e);
        }

        long elapsed = System.currentTimeMillis() - startTime;
        Log.i(TAG, "=== Preload complete in " + elapsed + "ms ===");

        // GC after preload to clean up temporary objects
        gcAndFinalize();
    }

    /**
     * Preload Android framework classes from /system/etc/preloaded-classes.
     * Uses Class.forName() to force class loading and initialization.
     * In a real build, this delegates to ZygoteInit.preloadClasses().
     */
    private static void preloadClasses() {
        // In production, read /system/etc/preloaded-classes and load each class.
        // For development, load essential framework classes directly.
        String[] essentialClasses = {
            "android.app.ActivityThread",
            "android.app.Application",
            "android.app.Activity",
            "android.app.Service",
            "android.content.ContentProvider",
            "android.content.BroadcastReceiver",
            "android.content.Intent",
            "android.content.ComponentName",
            "android.content.Context",
            "android.os.Bundle",
            "android.os.Handler",
            "android.os.Looper",
            "android.os.Message",
            "android.os.MessageQueue",
            "android.os.Binder",
            "android.os.IBinder",
            "android.os.Parcel",
            "android.os.Process",
            "android.view.View",
            "android.view.Window",
            "android.view.WindowManager",
            "android.widget.TextView",
            "android.widget.LinearLayout",
            "android.widget.FrameLayout",
            "android.graphics.Bitmap",
            "android.graphics.Canvas",
            "android.graphics.Paint",
            "android.graphics.drawable.Drawable",
            "android.util.Log",
            "android.net.Uri",
        };

        int loaded = 0;
        int failed = 0;
        for (String className : essentialClasses) {
            try {
                Class.forName(className, true, null);
                loaded++;
            } catch (ClassNotFoundException e) {
                // Expected for some classes not on boot classpath
                failed++;
            }
        }
        Log.i(TAG, "Preloaded " + loaded + " classes (" + failed + " not found)");

        // In full build, also call:
        // ZygoteInit.preloadClasses();
        // which reads the full preloaded-classes file (~7000 entries)
    }

    /**
     * Preload system resources (Drawable, ColorStateList).
     * In production, delegates to ZygoteInit.preloadResources().
     */
    private static void preloadResources() {
        // In production:
        // TypedArray ar = Resources.getSystem().obtainTypedArray(
        //     com.android.internal.R.array.preloaded_drawables);
        // ... iterate and load each drawable
        //
        // For development, this is a no-op placeholder.
        Log.d(TAG, "Resource preload: placeholder (full preload in production build)");
    }

    /**
     * Preload essential shared native libraries.
     */
    private static void preloadSharedLibraries() {
        String[] libs = {
            "android",          // libandroid.so
            "jnigraphics",     // libjnigraphics.so
            "compiler_rt",     // libcompiler_rt.so
        };

        for (String lib : libs) {
            try {
                System.loadLibrary(lib);
                Log.d(TAG, "Loaded lib: " + lib);
            } catch (UnsatisfiedLinkError e) {
                Log.w(TAG, "Failed to preload lib: " + lib + " (" + e.getMessage() + ")");
            }
        }
    }

    /**
     * Preload graphics driver (OpenGL/Vulkan).
     * In production, calls native method to load GPU driver.
     */
    private static void preloadGraphicsDriver() {
        // In production:
        // ZygoteInit.nativePreloadGraphicsDriver();
        // or maybePreloadGraphicsDriver()
        Log.d(TAG, "Graphics driver preload: placeholder");
    }

    /**
     * Warm up Java Cryptography Architecture providers.
     */
    private static void warmUpJcaProviders() {
        try {
            java.security.Security.getProviders();
            Log.d(TAG, "JCA providers warmed up");
        } catch (Exception e) {
            Log.w(TAG, "JCA warmup failed", e);
        }
    }

    /**
     * Preload adapter bridge (appspawn-x specific).
     * Loads liboh_adapter_bridge.so and caches adapter Java classes.
     */
    private static void preloadAdapterBridge() {
        // Load adapter JNI library
        try {
            System.loadLibrary("oh_adapter_bridge");
            Log.i(TAG, "Loaded liboh_adapter_bridge.so");
        } catch (UnsatisfiedLinkError e) {
            Log.w(TAG, "Failed to load adapter bridge: " + e.getMessage());
            return;
        }

        // Cache adapter Java classes so they're COW-shared after fork
        String[] adapterClasses = {
            "adapter.core.OHEnvironment",
            "adapter.activity.ActivityManagerAdapter",
            "adapter.activity.ActivityTaskManagerAdapter",
            "adapter.window.WindowManagerAdapter",
            "adapter.window.WindowSessionAdapter",
            "adapter.activity.ServiceConnectionRegistry",
            "adapter.activity.AppSchedulerBridge",
            "adapter.activity.AbilitySchedulerBridge",
            "adapter.activity.AbilityConnectionBridge",
            "adapter.activity.IntentWantConverter",
            "adapter.activity.LifecycleAdapter",
        };

        int cached = 0;
        for (String cls : adapterClasses) {
            try {
                Class.forName(cls);
                cached++;
            } catch (ClassNotFoundException e) {
                Log.d(TAG, "Adapter class not found (OK in dev): " + cls);
            }
        }
        Log.i(TAG, "Cached " + cached + " adapter classes");
    }

    /**
     * Force GC and finalization to clean up preload garbage
     * before entering the event loop (objects created during preload
     * that won't be needed are freed now, reducing COW page faults).
     */
    private static void gcAndFinalize() {
        VMRuntime runtime = VMRuntime.getRuntime();
        System.gc();
        runtime.runFinalizationSync();
        System.gc();
        Log.d(TAG, "Post-preload GC complete");
    }

    // ============================================================
    // Child Process: Initialization (called after fork + specialize)
    // ============================================================

    /**
     * Initialize the child process after fork() and OH security specialization.
     * Called from native child_main.cpp via JNI.
     *
     * @param procName       Process name (e.g. "com.example.app")
     * @param targetClass    Main class to invoke (e.g. "android.app.ActivityThread")
     * @param targetSdkVersion Target SDK version for the app
     */
    public static void initChild(String procName, String targetClass, int targetSdkVersion) {
        Log.i(TAG, "initChild: proc=" + procName + " target=" + targetClass
                + " sdk=" + targetSdkVersion);

        try {
            // 1. Set process name
            Process.setArgV0(procName);

            // 2. Set target SDK version
            if (targetSdkVersion > 0) {
                VMRuntime.getRuntime().setTargetSdkVersion(targetSdkVersion);
            }

            // 3. Common runtime initialization
            // In production: RuntimeInit.commonInit()
            // Sets default uncaught exception handler, timezone, etc.
            initCommonRuntime();

            // 4. Initialize adapter layer (connects to OH system services)
            initAdapterLayer();

            // 5. Find and invoke target class main()
            // This is equivalent to RuntimeInit.findStaticMain()
            Log.i(TAG, "Launching " + targetClass + ".main()");
            invokeStaticMain(targetClass);

        } catch (Exception e) {
            Log.e(TAG, "initChild failed", e);
            System.exit(1);
        }
    }

    /**
     * Common runtime initialization for child process.
     * Equivalent to RuntimeInit.commonInit().
     */
    private static void initCommonRuntime() {
        // Set default uncaught exception handler
        Thread.setDefaultUncaughtExceptionHandler((t, e) -> {
            Log.e(TAG, "FATAL EXCEPTION in " + t.getName(), e);
            System.exit(1);
        });

        // In production, also:
        // - Set timezone from system property
        // - Configure log redirects (stdout/stderr -> Android log)
        // - Initialize security providers
        Log.d(TAG, "Common runtime initialized");
    }

    /**
     * Initialize the Android-OH adapter layer.
     * Calls OHEnvironment.initialize() to connect to OH system services.
     */
    private static void initAdapterLayer() {
        try {
            Class<?> envClass = Class.forName("adapter.core.OHEnvironment");
            Method initMethod = envClass.getMethod("initialize");
            initMethod.invoke(null);
            Log.i(TAG, "Adapter layer initialized");
        } catch (ClassNotFoundException e) {
            Log.w(TAG, "OHEnvironment not found - adapter layer not available");
        } catch (Exception e) {
            Log.e(TAG, "Failed to initialize adapter layer", e);
        }
    }

    /**
     * Find and invoke the static main() method of the target class.
     * This does not return - the target class enters its event loop.
     * Equivalent to RuntimeInit.findStaticMain().
     */
    private static void invokeStaticMain(String className) throws Exception {
        Class<?> clazz = Class.forName(className);
        Method mainMethod = clazz.getMethod("main", String[].class);

        // ActivityThread.main() expects empty args
        String[] args = new String[0];

        // This call blocks forever (enters Looper.loop())
        mainMethod.invoke(null, (Object) args);

        // Should never reach here
        throw new RuntimeException(className + ".main() returned unexpectedly");
    }
}
