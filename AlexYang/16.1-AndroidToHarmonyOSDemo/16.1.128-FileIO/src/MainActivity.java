package com.example.fileio;

import android.os.Bundle;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import androidx.appcompat.app.AppCompatActivity;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;

public class MainActivity extends AppCompatActivity {
    private static final String FILENAME = "demo.txt";
    private EditText etInput;
    private TextView tvOutput;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        etInput = findViewById(R.id.etInput);
        tvOutput = findViewById(R.id.tvOutput);

        findViewById(R.id.btnSave).setOnClickListener(v -> {
            try (FileOutputStream fos = openFileOutput(FILENAME, MODE_PRIVATE)) {
                fos.write(etInput.getText().toString().getBytes());
                Toast.makeText(this, "Saved!", Toast.LENGTH_SHORT).show();
            } catch (IOException e) {
                Toast.makeText(this, "Save failed: " + e.getMessage(), Toast.LENGTH_SHORT).show();
            }
        });

        findViewById(R.id.btnLoad).setOnClickListener(v -> {
            try (FileInputStream fis = openFileInput(FILENAME)) {
                byte[] buf = new byte[fis.available()];
                fis.read(buf);
                tvOutput.setText(new String(buf));
            } catch (IOException e) {
                tvOutput.setText("Load failed: " + e.getMessage());
            }
        });
    }
}
