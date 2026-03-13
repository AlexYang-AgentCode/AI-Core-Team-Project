package com.jit.performance.converter;

import android.content.Context;
import com.chaquo.python.PyObject;
import com.chaquo.python.Python;
import com.chaquo.python.android.AndroidPlatform;
import com.jit.performance.model.ConversionResult;
import com.jit.performance.model.DexParseResult;
import com.jit.performance.model.BenchmarkResult;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

/**
 * DEX到ABC转换器主API类
 * 
 * 提供完整的DEX解析、ABC生成和转换功能
 * 使用Chaquopy嵌入Python核心代码
 */
public class DexToAbcConverter {
    
    private static final String TAG = "DexToAbcConverter";
    private Python py;
    private PyObject converterModule;
    private PyObject parserModule;
    private PyObject generatorModule;
    private PyObject mapperModule;
    
    private boolean initialized = false;
    
    /**
     * 初始化转换器
     * @param context Android上下文
     * @return 是否初始化成功
     */
    public boolean initialize(Context context) {
        try {
            if (!Python.isStarted()) {
                Python.start(new AndroidPlatform(context));
            }
            
            py = Python.getInstance();
            
            // 导入Python模块
            converterModule = py.getModule("converter");
            parserModule = py.getModule("dex_parser");
            generatorModule = py.getModule("abc_generator");
            mapperModule = py.getModule("instruction_mapper");
            
            initialized = true;
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }
    
    /**
     * 将DEX文件转换为ABC
     * @param dexData DEX字节数据
     * @return 转换结果
     */
    public ConversionResult convert(byte[] dexData) {
        if (!initialized) {
            ConversionResult error = new ConversionResult();
            error.setSuccess(false);
            error.setErrorMessage("Converter not initialized");
            return error;
        }
        
        try {
            PyObject converterClass = converterModule.get("DexToAbcConverter");
            PyObject converter = converterClass.call();
            
            PyObject result = converter.callAttr("convert", dexData);
            PyObject pyResult = result.asList().get(1);
            
            return parseConversionResult(pyResult);
        } catch (Exception e) {
            ConversionResult error = new ConversionResult();
            error.setSuccess(false);
            error.setErrorMessage(e.getMessage());
            return error;
        }
    }
    
    /**
     * 从文件转换DEX到ABC
     * @param dexFile DEX文件路径
     * @param outputPath 输出ABC文件路径
     * @return 转换结果
     */
    public ConversionResult convertFile(String dexFile, String outputPath) {
        try {
            byte[] dexData = readFile(dexFile);
            ConversionResult result = convert(dexData);
            
            if (result.isSuccess()) {
                PyObject converterClass = converterModule.get("DexToAbcConverter");
                PyObject converter = converterClass.call();
                PyObject pyResult = converter.callAttr("convert", dexData);
                byte[] abcData = pyResult.asList().get(0).toJava(byte[].class);
                writeFile(outputPath, abcData);
            }
            
            return result;
        } catch (Exception e) {
            ConversionResult error = new ConversionResult();
            error.setSuccess(false);
            error.setErrorMessage(e.getMessage());
            return error;
        }
    }
    
    /**
     * 解析DEX文件结构
     * @param dexData DEX字节数据
     * @return 解析结果
     */
    public DexParseResult parseDex(byte[] dexData) {
        if (!initialized) {
            DexParseResult error = new DexParseResult();
            error.setSuccess(false);
            error.setErrorMessage("Converter not initialized");
            return error;
        }
        
        try {
            PyObject parserClass = parserModule.get("DexParser");
            PyObject parser = parserClass.call(dexData);
            parser.callAttr("parse");
            
            DexParseResult result = new DexParseResult();
            result.setSuccess(true);
            
            // 解析header信息
            PyObject header = parser.get("header");
            if (header != null) {
                result.setFileSize(header.get("file_size").toInt());
            }
            result.setStringCount(parser.get("strings").asList().size());
            result.setTypeCount(parser.get("types").asList().size());
            result.setFieldCount(parser.get("field_ids").asList().size());
            result.setMethodCount(parser.get("method_ids").asList().size());
            result.setClassCount(parser.get("class_defs").asList().size());
            
            return result;
        } catch (Exception e) {
            DexParseResult error = new DexParseResult();
            error.setSuccess(false);
            error.setErrorMessage(e.getMessage());
            return error;
        }
    }
    
    /**
     * 批量转换多个DEX文件
     * @param dexFiles DEX文件路径列表
     * @param outputDir 输出目录
     * @return 转换结果列表
     */
    public List<ConversionResult> batchConvert(List<String> dexFiles, String outputDir) {
        List<ConversionResult> results = new ArrayList<>();
        
        File dir = new File(outputDir);
        if (!dir.exists()) {
            dir.mkdirs();
        }
        
        for (String dexFile : dexFiles) {
            File file = new File(dexFile);
            String outputPath = outputDir + File.separator + file.getName().replace(".dex", ".abc");
            results.add(convertFile(dexFile, outputPath));
        }
        
        return results;
    }
    
    /**
     * 运行性能基准测试
     * @param iterations 迭代次数
     * @return 测试结果
     */
    public BenchmarkResult runBenchmark(int iterations) {
        if (!initialized) {
            BenchmarkResult error = new BenchmarkResult();
            error.setSuccess(false);
            return error;
        }
        
        try {
            PyObject generateTestDex = py.getModule("generate_test_dex");
            PyObject dexBuilder = generateTestDex.get("build_calculator");
            byte[] dexData = dexBuilder.call().toJava(byte[].class);
            
            long startTime = System.nanoTime();
            
            for (int i = 0; i < iterations; i++) {
                convert(dexData);
            }
            
            long endTime = System.nanoTime();
            double totalMs = (endTime - startTime) / 1_000_000.0;
            double avgMs = totalMs / iterations;
            double throughput = iterations / (totalMs / 1000.0);
            
            ConversionResult sample = convert(dexData);
            
            BenchmarkResult result = new BenchmarkResult();
            result.setSuccess(true);
            result.setIterations(iterations);
            result.setTotalTimeMs(totalMs);
            result.setAvgTimeMs(avgMs);
            result.setThroughput(throughput);
            result.setInputSize(sample.getDexSize());
            result.setOutputSize(sample.getAbcSize());
            result.setCompileSpeedPassed(avgMs < 100);
            result.setThroughputPassed(throughput > 10);
            result.setSizeRatioPassed(sample.getSizeRatio() < 200);
            
            return result;
        } catch (Exception e) {
            BenchmarkResult error = new BenchmarkResult();
            error.setSuccess(false);
            return error;
        }
    }
    
    /**
     * 获取指令映射器统计信息
     * @return 支持的DEX操作码数量
     */
    public int[] getMapperStats() {
        try {
            PyObject mapperClass = mapperModule.get("InstructionMapper");
            PyObject stats = mapperClass.callAttr("get_supported_count");
            int supported = stats.asList().get(0).toInt();
            int total = stats.asList().get(1).toInt();
            return new int[]{supported, total};
        } catch (Exception e) {
            return new int[]{0, 256};
        }
    }
    
    private ConversionResult parseConversionResult(PyObject pyResult) {
        ConversionResult result = new ConversionResult();
        result.setSuccess(pyResult.get("success").toBoolean());
        result.setClassName(pyResult.get("class_name").toString());
        result.setDexSize(pyResult.get("dex_size").toInt());
        result.setAbcSize(pyResult.get("abc_size").toInt());
        result.setFieldsCount(pyResult.get("fields_count").toInt());
        result.setMethodsCount(pyResult.get("methods_count").toInt());
        result.setInstructionsMapped(pyResult.get("instructions_mapped").toInt());
        result.setInstructionsTotal(pyResult.get("instructions_total").toInt());
        result.setMappingRate(pyResult.get("mapping_rate").toDouble());
        result.setParseTimeMs(pyResult.get("parse_time_ms").toDouble());
        result.setConvertTimeMs(pyResult.get("convert_time_ms").toDouble());
        result.setGenerateTimeMs(pyResult.get("generate_time_ms").toDouble());
        result.setTotalTimeMs(pyResult.get("total_time_ms").toDouble());
        return result;
    }
    
    private byte[] readFile(String path) throws IOException {
        File file = new File(path);
        java.io.FileInputStream fis = new java.io.FileInputStream(file);
        byte[] data = new byte[(int) file.length()];
        fis.read(data);
        fis.close();
        return data;
    }
    
    private void writeFile(String path, byte[] data) throws IOException {
        FileOutputStream fos = new FileOutputStream(path);
        fos.write(data);
        fos.close();
    }
}
