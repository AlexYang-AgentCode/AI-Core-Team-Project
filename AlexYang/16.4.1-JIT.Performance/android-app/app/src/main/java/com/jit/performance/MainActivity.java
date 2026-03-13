package com.jit.performance;

import android.Manifest;
import android.content.pm.PackageManager;
import android.os.Bundle;
import android.os.Environment;
import android.view.View;
import android.widget.Button;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import com.jit.performance.converter.DexToAbcConverter;
import com.jit.performance.model.ConversionResult;
import com.jit.performance.model.BenchmarkResult;
import java.io.File;

/**
 * DEX-to-ABC转换器主界面
 */
public class MainActivity extends AppCompatActivity {
    
    private static final int REQUEST_CODE_PERMISSIONS = 1001;
    private static final String[] REQUIRED_PERMISSIONS = {
        Manifest.permission.READ_EXTERNAL_STORAGE,
        Manifest.permission.WRITE_EXTERNAL_STORAGE
    };
    
    private DexToAbcConverter converter;
    private TextView tvStatus;
    private TextView tvOutput;
    private ProgressBar progressBar;
    private Button btnConvert;
    private Button btnBenchmark;
    private Button btnTestCase;
    
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        
        initViews();
        checkPermissions();
    }
    
    private void initViews() {
        tvStatus = findViewById(R.id.tvStatus);
        tvOutput = findViewById(R.id.tvOutput);
        progressBar = findViewById(R.id.progressBar);
        btnConvert = findViewById(R.id.btnConvert);
        btnBenchmark = findViewById(R.id.btnBenchmark);
        btnTestCase = findViewById(R.id.btnTestCase);
        
        btnConvert.setOnClickListener(v -> runTestConversion());
        btnBenchmark.setOnClickListener(v -> runBenchmark());
        btnTestCase.setOnClickListener(v -> showTestCases());
    }
    
    private void checkPermissions() {
        boolean allGranted = true;
        for (String permission : REQUIRED_PERMISSIONS) {
            if (ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED) {
                allGranted = false;
                break;
            }
        }
        
        if (!allGranted) {
            ActivityCompat.requestPermissions(this, REQUIRED_PERMISSIONS, REQUEST_CODE_PERMISSIONS);
        } else {
            initializeConverter();
        }
    }
    
    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == REQUEST_CODE_PERMISSIONS) {
            boolean allGranted = true;
            for (int result : grantResults) {
                if (result != PackageManager.PERMISSION_GRANTED) {
                    allGranted = false;
                    break;
                }
            }
            if (allGranted) {
                initializeConverter();
            } else {
                Toast.makeText(this, "需要存储权限", Toast.LENGTH_LONG).show();
            }
        }
    }
    
    private void initializeConverter() {
        new Thread(() -> {
            converter = new DexToAbcConverter();
            boolean success = converter.initialize(this);
            
            runOnUiThread(() -> {
                if (success) {
                    tvStatus.setText(R.string.status_ready);
                    btnConvert.setEnabled(true);
                    btnBenchmark.setEnabled(true);
                    btnTestCase.setEnabled(true);
                    
                    int[] stats = converter.getMapperStats();
                    appendOutput("Converter initialized\n");
                    appendOutput(String.format("Supported DEX opcodes: %d/%d\n", stats[0], stats[1]));
                } else {
                    tvStatus.setText(R.string.status_error);
                    appendOutput("Failed to initialize converter\n");
                }
            });
        }).start();
    }
    
    private void runTestConversion() {
        if (converter == null) return;
        
        progressBar.setVisibility(View.VISIBLE);
        tvStatus.setText(R.string.status_converting);
        btnConvert.setEnabled(false);
        
        new Thread(() -> {
            // 生成测试DEX数据并转换
            try {
                com.chaquo.python.Python py = com.chaquo.python.Python.getInstance();
                com.chaquo.python.PyObject generateTestDex = py.getModule("generate_test_dex");
                byte[] dexData = generateTestDex.callAttr("build_calculator").toJava(byte[].class);
                
                ConversionResult result = converter.convert(dexData);
                
                runOnUiThread(() -> {
                    progressBar.setVisibility(View.GONE);
                    btnConvert.setEnabled(true);
                    
                    if (result.isSuccess()) {
                        tvStatus.setText(R.string.status_complete);
                        appendOutput("\n=== Test Conversion Result ===\n");
                        appendOutput(result.toString() + "\n");
                        appendOutput("Size ratio: " + String.format("%.1f%%\n", result.getSizeRatio()));
                        appendOutput("\nTiming:\n" + result.getTimingReport() + "\n");
                    } else {
                        tvStatus.setText(R.string.status_error);
                        appendOutput("Conversion failed: " + result.getErrorMessage() + "\n");
                    }
                });
            } catch (Exception e) {
                runOnUiThread(() -> {
                    progressBar.setVisibility(View.GONE);
                    btnConvert.setEnabled(true);
                    tvStatus.setText(R.string.status_error);
                    appendOutput("Error: " + e.getMessage() + "\n");
                });
            }
        }).start();
    }
    
    private void runBenchmark() {
        if (converter == null) return;
        
        progressBar.setVisibility(View.VISIBLE);
        tvStatus.setText("Running benchmark...");
        btnBenchmark.setEnabled(false);
        
        new Thread(() -> {
            BenchmarkResult result = converter.runBenchmark(100);
            
            runOnUiThread(() -> {
                progressBar.setVisibility(View.GONE);
                btnBenchmark.setEnabled(true);
                tvStatus.setText(R.string.status_complete);
                
                if (result.isSuccess()) {
                    appendOutput("\n" + result.getFullReport() + "\n");
                } else {
                    appendOutput("Benchmark failed\n");
                }
            });
        }).start();
    }
    
    private void showTestCases() {
        StringBuilder sb = new StringBuilder();
        sb.append("\n=== Supported Test Cases ===\n\n");
        sb.append("1. SimplePojo\n");
        sb.append("   - POJO with getter/setter\n");
        sb.append("   - Tests field access and basic methods\n\n");
        sb.append("2. SimpleLogic\n");
        sb.append("   - add(int,int), max(int,int)\n");
        sb.append("   - Tests arithmetic and conditional\n\n");
        sb.append("3. WithLoop\n");
        sb.append("   - sum(int), factorial(int)\n");
        sb.append("   - Tests loops and goto\n\n");
        sb.append("4. Calculator\n");
        sb.append("   - add/sub/mul/div operations\n");
        sb.append("   - Tests all arithmetic ops\n\n");
        sb.append("5. Person\n");
        sb.append("   - Multi-field class with accessors\n");
        sb.append("   - Tests multiple fields\n");
        appendOutput(sb.toString());
    }
    
    private void appendOutput(String text) {
        tvOutput.append(text);
        // Scroll to bottom
        tvOutput.post(() -> {
            int scrollAmount = tvOutput.getLayout().getLineTop(tvOutput.getLineCount()) - tvOutput.getHeight();
            if (scrollAmount > 0) {
                tvOutput.scrollTo(0, scrollAmount);
            }
        });
    }
}
