package com.jit.performance.model;

import java.util.List;

/**
 * DEX解析结果数据类
 * 包含DEX文件的详细结构信息
 */
public class DexParseResult {
    
    private boolean success;
    private int fileSize;
    private int stringCount;
    private int typeCount;
    private int fieldCount;
    private int methodCount;
    private int classCount;
    private List<ClassInfo> classes;
    private String errorMessage;

    public DexParseResult() {
        this.success = false;
    }

    public static class ClassInfo {
        private String name;
        private String superClass;
        private int accessFlags;
        private int fieldCount;
        private int methodCount;
        private List<String> fields;
        private List<String> methods;

        public ClassInfo(String name, String superClass) {
            this.name = name;
            this.superClass = superClass;
        }

        // Getters and Setters
        public String getName() { return name; }
        public void setName(String name) { this.name = name; }

        public String getSuperClass() { return superClass; }
        public void setSuperClass(String superClass) { this.superClass = superClass; }

        public int getAccessFlags() { return accessFlags; }
        public void setAccessFlags(int accessFlags) { this.accessFlags = accessFlags; }

        public int getFieldCount() { return fieldCount; }
        public void setFieldCount(int fieldCount) { this.fieldCount = fieldCount; }

        public int getMethodCount() { return methodCount; }
        public void setMethodCount(int methodCount) { this.methodCount = methodCount; }

        public List<String> getFields() { return fields; }
        public void setFields(List<String> fields) { this.fields = fields; }

        public List<String> getMethods() { return methods; }
        public void setMethods(List<String> methods) { this.methods = methods; }
    }

    // Getters and Setters
    public boolean isSuccess() { return success; }
    public void setSuccess(boolean success) { this.success = success; }

    public int getFileSize() { return fileSize; }
    public void setFileSize(int fileSize) { this.fileSize = fileSize; }

    public int getStringCount() { return stringCount; }
    public void setStringCount(int stringCount) { this.stringCount = stringCount; }

    public int getTypeCount() { return typeCount; }
    public void setTypeCount(int typeCount) { this.typeCount = typeCount; }

    public int getFieldCount() { return fieldCount; }
    public void setFieldCount(int fieldCount) { this.fieldCount = fieldCount; }

    public int getMethodCount() { return methodCount; }
    public void setMethodCount(int methodCount) { this.methodCount = methodCount; }

    public int getClassCount() { return classCount; }
    public void setClassCount(int classCount) { this.classCount = classCount; }

    public List<ClassInfo> getClasses() { return classes; }
    public void setClasses(List<ClassInfo> classes) { this.classes = classes; }

    public String getErrorMessage() { return errorMessage; }
    public void setErrorMessage(String errorMessage) { this.errorMessage = errorMessage; }

    @Override
    public String toString() {
        return String.format(
            "DexParseResult{success=%s, fileSize=%d, strings=%d, types=%d, " +
            "fields=%d, methods=%d, classes=%d}",
            success, fileSize, stringCount, typeCount, fieldCount, methodCount, classCount
        );
    }
}
