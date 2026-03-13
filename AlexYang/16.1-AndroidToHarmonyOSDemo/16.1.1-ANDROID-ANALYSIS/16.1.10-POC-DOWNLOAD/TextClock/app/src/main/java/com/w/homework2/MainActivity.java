package com.w.homework2;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;

import java.util.TimeZone;

public class MainActivity extends AppCompatActivity {

        // set variable names for Button and TextView
        Button TimeZoneButton;
        TextView TimeZoneTextview;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        // find the ID that was made in XML file
        TimeZoneButton = (Button) findViewById(R.id.timeZoneButton);
        TimeZoneTextview = findViewById(R.id.timeZoneShow);

        // Allow the button to listen for a click and execute the time zone
        TimeZoneButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                // Gets default TimeZone for this host
                TimeZone tz = TimeZone.getDefault();

                //getDisplayName() gets the short or long name with either standard or daylight time, as written in local
                // getID() gets the ID of this time zone
                TimeZoneTextview.setText("Time Zone : " + tz.getDisplayName(false, TimeZone.SHORT) + "TimeZone Id: "+ tz.getID());
            }
        });
    }
}
