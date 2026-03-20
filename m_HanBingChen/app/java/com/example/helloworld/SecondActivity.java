/*
 * SecondActivity.java
 *
 * Second Activity, used to verify the full call chain of cross-Activity
 * navigation through the adaptation layer.
 */
package com.example.helloworld;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;
import android.widget.LinearLayout;
import android.widget.TextView;

public class SecondActivity extends Activity {

    private static final String TAG = "HelloWorld_Second";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        Log.i(TAG, "=== SecondActivity.onCreate() ===");

        LinearLayout layout = new LinearLayout(this);
        layout.setOrientation(LinearLayout.VERTICAL);
        layout.setPadding(48, 48, 48, 48);

        TextView title = new TextView(this);
        title.setText("SecondActivity (Launched via OH Adapter)");
        title.setTextSize(20);
        layout.addView(title);

        // Display parameters passed from Intent/Want
        String greeting = getIntent().getStringExtra("greeting");
        long timestamp = getIntent().getLongExtra("timestamp", 0);

        TextView info = new TextView(this);
        info.setText("\nReceived from adapter:\n"
                + "  greeting: " + greeting + "\n"
                + "  timestamp: " + timestamp + "\n\n"
                + "This Activity was started through:\n"
                + "  Android Intent -> OH Want -> OH AbilityManager\n"
                + "  -> OH callback -> Android lifecycle");
        info.setTextSize(14);
        layout.addView(info);

        setContentView(layout);
    }
}
