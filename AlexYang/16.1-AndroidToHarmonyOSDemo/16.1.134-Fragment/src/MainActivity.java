package com.example.fragmentdemo;

import android.os.Bundle;
import android.widget.Button;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.FragmentTransaction;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button btnShow = findViewById(R.id.btnShowFragment);
        btnShow.setOnClickListener(v -> {
            FragmentTransaction ft = getSupportFragmentManager().beginTransaction();
            ft.replace(R.id.fragmentContainer, new HelloFragment());
            ft.addToBackStack(null);
            ft.commit();
        });
    }
}
