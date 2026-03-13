package com.example.toastdialog;

import android.os.Bundle;
import android.widget.Button;
import android.widget.Toast;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        Button btnToast = findViewById(R.id.btnToast);
        btnToast.setOnClickListener(v ->
            Toast.makeText(this, "Hello Toast!", Toast.LENGTH_SHORT).show()
        );

        Button btnDialog = findViewById(R.id.btnDialog);
        btnDialog.setOnClickListener(v ->
            new AlertDialog.Builder(this)
                .setTitle("Confirm")
                .setMessage("Are you sure?")
                .setPositiveButton("Yes", (d, w) ->
                    Toast.makeText(this, "Confirmed", Toast.LENGTH_SHORT).show())
                .setNegativeButton("No", null)
                .show()
        );
    }
}
