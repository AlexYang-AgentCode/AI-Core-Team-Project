/*
 * MainActivity.java
 *
 * Hello World main screen.
 * Demonstrates the full flow of calling OH system services via the adaptation layer:
 *
 * 1. On Activity start, lifecycle events are mapped to OH Ability states via LifecycleAdapter
 * 2. Button click calls startActivity(), intercepted by ServiceInterceptor
 * 3. Intent is converted to OH Want by IntentWantConverter
 * 4. OH AbilityManager.StartAbility() is called via JNI Bridge
 * 5. OH callback is relayed back to Android layer through CallbackHandler
 */
package com.example.helloworld;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;

import adapter.core.OHEnvironment;
import adapter.activity.ActivityManagerAdapter;

public class MainActivity extends Activity {

    private static final String TAG = "HelloWorld_Main";
    private TextView mStatusText;
    private TextView mHelloText;
    private int mColorIndex = 0;

    // Color palette for cycling
    private static final int[] COLORS = {
        Color.BLACK,
        Color.RED,
        Color.BLUE,
        Color.GREEN,
        Color.MAGENTA,
        Color.rgb(255, 128, 0),  // Orange
        Color.CYAN,
        Color.rgb(128, 0, 255),  // Purple
    };

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.i(TAG, "=== MainActivity.onCreate() ===");

        // Build simple UI
        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(48, 48, 48, 48);

        // Title
        TextView title = new TextView(this);
        title.setText("Android-OH Adapter Demo");
        title.setTextSize(24);
        title.setPadding(0, 0, 0, 24);
        layout.addView(title);

        // Hello World text - large, centered, color-changeable
        mHelloText = new TextView(this);
        mHelloText.setText("Hello World!");
        mHelloText.setTextSize(36);
        mHelloText.setTextColor(Color.BLACK);
        mHelloText.setGravity(Gravity.CENTER);
        mHelloText.setPadding(0, 32, 0, 32);
        layout.addView(mHelloText);

        // Button: Change color (verifies OH -> Android input event pipeline)
        // Touch event flow:
        //   OH MMI -> OH Input Channel -> InputEventBridge (native)
        //   -> InputPublisher -> Android InputChannel -> ViewRootImpl
        //   -> View.dispatchTouchEvent -> Button.onClick
        Button btnChangeColor = new Button(this);
        btnChangeColor.setText("Change Color (Input Event Test)");
        btnChangeColor.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                mColorIndex = (mColorIndex + 1) % COLORS.length;
                int newColor = COLORS[mColorIndex];
                mHelloText.setTextColor(newColor);

                String colorName = colorToName(newColor);
                Log.i(TAG, "Color changed to: " + colorName
                        + " (input event pipeline verified)");
                mStatusText.setText("[INPUT OK] Color -> " + colorName
                        + "\nTouch event delivered via OH->Android input bridge");
            }
        });
        layout.addView(btnChangeColor);

        // Adapter status display
        mStatusText = new TextView(this);
        updateStatus();
        mStatusText.setTextSize(14);
        mStatusText.setPadding(0, 32, 0, 32);
        layout.addView(mStatusText);

        // Button 1: Start another Activity via adaptation layer (verify startActivity interception)
        Button btnStartActivity = new Button(this);
        btnStartActivity.setText("Start SecondActivity (via OH Adapter)");
        btnStartActivity.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.i(TAG, "Button clicked: startActivity(SecondActivity)");

                Intent intent = new Intent(MainActivity.this, SecondActivity.class);
                intent.putExtra("greeting", "Hello from Android to OpenHarmony!");
                intent.putExtra("timestamp", System.currentTimeMillis());
                startActivity(intent);

                mStatusText.append("\n\n[SENT] startActivity -> OH StartAbility");
            }
        });
        layout.addView(btnStartActivity);

        // Button 2: Simulate Service binding
        Button btnBindService = new Button(this);
        btnBindService.setText("Connect to OH Service (Mock)");
        btnBindService.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Log.i(TAG, "Button clicked: ConnectAbility");

                if (OHEnvironment.isOHEnvironment()) {
                    int result = ActivityManagerAdapter.nativeConnectAbility(
                            "com.example.helloworld",
                            "DataServiceAbility",
                            0);
                    Log.i(TAG, "ConnectAbility result: " + result);
                    mStatusText.append("\n\n[SENT] connectAbility -> result=" + result);
                }
            }
        });
        layout.addView(btnBindService);

        // Button 3: Display call flow
        Button btnShowFlow = new Button(this);
        btnShowFlow.setText("Show Adapter Call Flow");
        btnShowFlow.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                showCallFlow();
            }
        });
        layout.addView(btnShowFlow);

        setContentView(layout);

        // Notify adaptation layer: Activity created
        notifyLifecycle("CREATED");
    }

    @Override
    protected void onResume() {
        super.onResume();
        Log.i(TAG, "=== MainActivity.onResume() ===");
        notifyLifecycle("RESUMED -> OH FOREGROUND");
    }

    @Override
    protected void onPause() {
        super.onPause();
        Log.i(TAG, "=== MainActivity.onPause() ===");
        notifyLifecycle("PAUSED");
    }

    @Override
    protected void onStop() {
        super.onStop();
        Log.i(TAG, "=== MainActivity.onStop() ===");
        notifyLifecycle("STOPPED -> OH BACKGROUND");
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        Log.i(TAG, "=== MainActivity.onDestroy() ===");
        notifyLifecycle("DESTROYED -> OH INITIAL");
    }

    private void updateStatus() {
        String status = OHEnvironment.isOHEnvironment()
                ? "Adapter Status: ACTIVE (connected to OH services)"
                : "Adapter Status: INACTIVE (using original Android services)";
        mStatusText.setText(status);
    }

    private void notifyLifecycle(String state) {
        Log.i(TAG, "Lifecycle: " + state);
        if (mStatusText != null) {
            mStatusText.append("\n[LIFECYCLE] " + state);
        }
    }

    private void showCallFlow() {
        String flow =
            "=== Input Event Flow (OH -> Android) ===\n\n" +
            "1. User touches screen\n" +
            "2. OH MMI Framework -> OH Input Channel\n" +
            "3. InputEventBridge (native C++)\n" +
            "   reads OH PointerEvent\n" +
            "4. InputPublisher.publishMotionEvent()\n" +
            "   writes to Android InputChannel\n" +
            "5. ViewRootImpl.WindowInputEventReceiver\n" +
            "   reads from InputChannel\n" +
            "6. View.dispatchTouchEvent()\n" +
            "7. Button.onClick() -> Change Color!\n\n" +
            "=== Activity Lifecycle (OH -> Android) ===\n\n" +
            "1. OH AbilityMgr -> AppSchedulerHost\n" +
            "2. JNI -> AppSchedulerBridge\n" +
            "3. ClientTransaction + LaunchActivityItem\n" +
            "4. ActivityThread.handleLaunchActivity()\n" +
            "5. Activity.onCreate() -> onResume()";

        mStatusText.setText(flow);
    }

    private static String colorToName(int color) {
        if (color == Color.BLACK) return "BLACK";
        if (color == Color.RED) return "RED";
        if (color == Color.BLUE) return "BLUE";
        if (color == Color.GREEN) return "GREEN";
        if (color == Color.MAGENTA) return "MAGENTA";
        if (color == Color.CYAN) return "CYAN";
        if (color == Color.rgb(255, 128, 0)) return "ORANGE";
        if (color == Color.rgb(128, 0, 255)) return "PURPLE";
        return String.format("#%06X", 0xFFFFFF & color);
    }
}
