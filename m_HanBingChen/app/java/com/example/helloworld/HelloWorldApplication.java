/*
 * HelloWorldApplication.java
 *
 * Application entry point. Initializes the OH adaptation layer in Application.onCreate(),
 * so all subsequent Activity system service calls are automatically redirected to OH.
 */
package com.example.helloworld;

import android.app.Application;
import android.util.Log;

import adapter.core.OHEnvironment;

public class HelloWorldApplication extends Application {

    private static final String TAG = "HelloWorld";

    @Override
    public void onCreate() {
        super.onCreate();

        Log.i(TAG, "=== Hello World Application Starting ===");
        Log.i(TAG, "Initializing Android-OH Adaptation Layer...");

        // Initialize OH IPC and connect to services
        OHEnvironment.initialize();
        OHEnvironment.attachApplication(
                android.os.Process.myPid(),
                android.os.Process.myUid(),
                getPackageName());

        Log.i(TAG, "Adaptation Layer initialized.");
        Log.i(TAG, "All system service calls will be redirected to OH services.");
    }

    @Override
    public void onTerminate() {
        OHEnvironment.shutdown();
        super.onTerminate();
    }
}
