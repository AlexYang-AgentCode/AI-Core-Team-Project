---
tags:
  - 134-project
  - adapter-design
  - jni-runtime
  - native-bridge
  - android-to-harmonyos
date: 2026-03-12
status: planning
priority: P0
---

# 16.4.5-JNI.Runtime: JNI 兼容运行时

> **项目定位**: 16.4 适配层子项目，负责 Android JNI Native 层到 HarmonyOS NAPI 的桥接
> **项目状态**: 规划中，从 16.4.1 拆分独立
> **上游依赖**: 16.4.1-JIT.Compiler (编译器输出)
> **下游依赖**: 16.4.2-Activity.Bridge, 16.4.4-System.API

---

## 拆分背景

原 16.4.1-JIT.Performance 过于臃肿，包含编译器、JNI、并发等多个不同技术栈的模块。

本模块独立负责 **JNI 运行时兼容层**，与编译器解耦。

---

## 职责范围

### 核心任务

| 功能 | Android | HarmonyOS | 状态 |
|------|---------|-----------|------|
| Native 库加载 | `System.loadLibrary()` | `dlopen()` + JNI 模拟 | 待实现 |
| JNI 环境模拟 | `JNIEnv*` | `napi_env` 包装层 | 待实现 |
| JavaVM 模拟 | `JavaVM*` | 兼容运行时 | 待实现 |
| 方法注册 | `RegisterNatives()` | NAPI 方法注册桥接 | 待实现 |
| 类型转换 | `jstring/jobject/...` | `napi_value` 互转 | 待实现 |

### 技术架构

```
Android APK (.so)
    ↓
JNI Compatibility Runtime (JCR)
    ├── MockJavaVM
    ├── MockJNIEnv
    ├── Type Converter
    └── Native Method Registry
    ↓
HarmonyOS NAPI
```

---

## 项目结构

```
16.4.5-JNI.Runtime/
├── 01-Spec/           # JNI/NDK 规范分析
├── 02-Research/       # ArkCompiler NAPI 调研
├── 03-POC/            # JNI 加载 POC
├── 04-Design/         # 架构设计
├── 05-Implementation/ # C++/NAPI 实现
├── 06-Test/           # 单元/集成测试
└── 07-Docs/           # 文档
```

---

## 里程碑

| 阶段 | 内容 | 预计时间 |
|------|------|---------|
| Phase 0 | NAPI 机制调研 | 1周 |
| Phase 1 | JNI 环境基础模拟 | 2周 |
| Phase 2 | Native 库加载实现 | 2周 |
| Phase 3 | 类型系统完整映射 | 2周 |
| Phase 4 | 集成测试 | 1周 |

---

**创建日期**: 2026-03-12
**版本**: 1.0.0
