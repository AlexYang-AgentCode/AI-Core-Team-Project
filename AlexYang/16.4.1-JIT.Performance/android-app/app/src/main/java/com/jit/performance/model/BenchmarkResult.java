package com.jit.performance.model;

/**
 * 性能基准测试结果数据类
 */
public class BenchmarkResult {
    
    private boolean success;
    private int iterations;
    private double totalTimeMs;
    private double avgTimeMs;
    private double throughput;  // conversions per second
    private int inputSize;
    private int outputSize;
    private boolean compileSpeedPassed;
    private boolean throughputPassed;
    private boolean sizeRatioPassed;

    public BenchmarkResult() {
        this.success = false;
    }

    // Getters and Setters
    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public int getIterations() { return iterations; }
    public void setIterations(int iterations) { this.iterations = iterations; }

    public double getTotalTimeMs() { return totalTimeMs; }
    public void setTotalTimeMs(double totalTimeMs) { this.totalTimeMs = totalTimeMs; }

    public double getAvgTimeMs() { return avgTimeMs; }
    public void setAvgTimeMs(double avgTimeMs) { this.avgTimeMs = avgTimeMs; }

    public double getThroughput() { return throughput; }
    public void setThroughput(double throughput) { this.throughput = throughput; }

    public int getInputSize() { return inputSize; }
    public void setInputSize(int inputSize) { this.inputSize = inputSize; }

    public int getOutputSize() { return outputSize; }
    public void setOutputSize(int outputSize) { this.outputSize = outputSize; }

    public boolean isCompileSpeedPassed() { return compileSpeedPassed; }
    public void setCompileSpeedPassed(boolean compileSpeedPassed) { this.compileSpeedPassed = compileSpeedPassed; }

    public boolean isThroughputPassed() { return throughputPassed; }
    public void setThroughputPassed(boolean throughputPassed) { this.throughputPassed = throughputPassed; }

    public boolean isSizeRatioPassed() { return sizeRatioPassed; }
    public void setSizeRatioPassed(boolean sizeRatioPassed) { this.sizeRatioPassed = sizeRatioPassed; }

    public double getSizeRatio() {
        return inputSize > 0 ? (double) outputSize / inputSize * 100.0 : 0.0;
    }

    @Override
    public String toString() {
        return String.format(
            "BenchmarkResult{iterations=%d, total=%.1fms, avg=%.3fms, " +
            "throughput=%.0f/s, sizeRatio=%.1f%%}",
            iterations, totalTimeMs, avgTimeMs, throughput, getSizeRatio()
        );
    }

    /**
     * 获取完整的性能报告
     */
    public String getFullReport() {
        StringBuilder sb = new StringBuilder();
        sb.append("=== Performance Benchmark Report ===\n\n");
        sb.append(String.format("Iterations: %d\n", iterations));
        sb.append(String.format("Total Time: %.1f ms\n", totalTimeMs));
        sb.append(String.format("Avg per file: %.3f ms\n", avgTimeMs));
        sb.append(String.format("Throughput: %.0f conversions/sec\n", throughput));
        sb.append(String.format("Input Size: %d bytes\n", inputSize));
        sb.append(String.format("Output Size: %d bytes\n", outputSize));
        sb.append(String.format("Size Ratio: %.1f%%\n\n", getSizeRatio()));
        
        sb.append("=== Targets vs Actual ===\n");
        sb.append(String.format("[%-4s] Compile Speed: %.3f ms (target < 100 ms)\n", 
            compileSpeedPassed ? "PASS" : "FAIL", avgTimeMs));
        sb.append(String.format("[%-4s] Throughput: %.0f/s (target > 10/s)\n", 
            throughputPassed ? "PASS" : "FAIL", throughput));
        sb.append(String.format("[%-4s] Size Ratio: %.1f%% (target < 200%%)\n", 
            sizeRatioPassed ? "PASS" : "FAIL", getSizeRatio()));
        
        return sb.toString();
    }
}
