package com.jit.performance.model;

/**
 * 转换结果数据类
 * 封装DEX到ABC转换的结果
 */
public class ConversionResult {
    
    private boolean success;
    private String className;
    private int dexSize;
    private int abcSize;
    private int fieldsCount;
    private int methodsCount;
    private int instructionsMapped;
    private int instructionsTotal;
    private double mappingRate;
    private double parseTimeMs;
    private double convertTimeMs;
    private double generateTimeMs;
    private double totalTimeMs;
    private String errorMessage;

    public ConversionResult() {
        this.success = false;
    }

    // Getters and Setters
    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public String getClassName() { return className; }
    public void setClassName(String className) { this.className = className; }

    public int getDexSize() { return dexSize; }
    public void setDexSize(int dexSize) { this.dexSize = dexSize; }

    public int getAbcSize() { return abcSize; }
    public void setAbcSize(int abcSize) { this.abcSize = abcSize; }

    public int getFieldsCount() { return fieldsCount; }
    public void setFieldsCount(int fieldsCount) { this.fieldsCount = fieldsCount; }

    public int getMethodsCount() { return methodsCount; }
    public void setMethodsCount(int methodsCount) { this.methodsCount = methodsCount; }

    public int getInstructionsMapped() { return instructionsMapped; }
    public void setInstructionsMapped(int instructionsMapped) { this.instructionsMapped = instructionsMapped; }

    public int getInstructionsTotal() { return instructionsTotal; }
    public void setInstructionsTotal(int instructionsTotal) { this.instructionsTotal = instructionsTotal; }

    public double getMappingRate() { return mappingRate; }
    public void setMappingRate(double mappingRate) { this.mappingRate = mappingRate; }

    public double getParseTimeMs() { return parseTimeMs; }
    public void setParseTimeMs(double parseTimeMs) { this.parseTimeMs = parseTimeMs; }

    public double getConvertTimeMs() { return convertTimeMs; }
    public void setConvertTimeMs(double convertTimeMs) { this.convertTimeMs = convertTimeMs; }

    public double getGenerateTimeMs() { return generateTimeMs; }
    public void setGenerateTimeMs(double generateTimeMs) { this.generateTimeMs = generateTimeMs; }

    public double getTotalTimeMs() { return totalTimeMs; }
    public void setTotalTimeMs(double totalTimeMs) { this.totalTimeMs = totalTimeMs; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    @Override
    public String toString() {
        return String.format(
            "ConversionResult{success=%s, class='%s', dex=%dB, abc=%dB, fields=%d, methods=%d, " +
            "instructions=%d/%d (%.1f%%), time=%.2fms}",
            success, className, dexSize, abcSize, fieldsCount, methodsCount,
            instructionsMapped, instructionsTotal, mappingRate, totalTimeMs
        );
    }

    /**
     * 获取大小比例 (ABC大小 / DEX大小)
     */
    public double getSizeRatio() {
        return dexSize > 0 ? (double) abcSize / dexSize * 100.0 : 0.0;
    }

    /**
     * 获取格式化的时间报告
     */
    public String getTimingReport() {
        return String.format(
            "Parse: %.2fms\nConvert: %.2fms\nGenerate: %.2fms\nTotal: %.2fms",
            parseTimeMs, convertTimeMs, generateTimeMs, totalTimeMs
        );
    }
}
