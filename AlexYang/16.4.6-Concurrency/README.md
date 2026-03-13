---
tags:
  - 134-project
  - adapter-design
  - concurrency
  - thread-model
  - android-to-harmonyos
date: 2026-03-12
status: planning
priority: P1
---

# 16.4.6-Concurrency: 并发模型适配层

> **项目定位**: 16.4 适配层子项目，负责 Android 并发模型到 HarmonyOS 的映射
> **项目状态**: 规划中，从 16.4.1 拆分独立
> **上游依赖**: 16.4.1-JIT.Compiler
> **下游依赖**: 16.4.2-Activity.Bridge

---

## 拆分背景

原 16.4.1-JIT.Performance 包含 JIT 编译器与运行时支持，本模块独立负责 **并发模型适配**。

---

## 职责范围

### 核心适配点

| Android | HarmonyOS | 策略 |
|---------|-----------|------|
| `synchronized` | TaskPool + 锁模拟 | 语法转换/运行时模拟 |
| `volatile` | `@Concurrent` + 原子操作 | 语义映射 |
| `Thread` | `Task` / `Worker` | 模型转换 |
| `Handler/Looper` | `emitter` / `async` | 事件驱动替代 |
| `AsyncTask` | `Promise` / `async-await` | 异步范式转换 |

### 技术挑战

1. **synchronized 块**: Java 关键字无法在 ArkTS 直接使用
2. **线程模型差异**: Android 线程 vs HarmonyOS TaskPool
3. **内存可见性**: volatile 语义保证

---

## 项目结构

```
16.4.6-Concurrency/
├── 01-Spec/           # 并发规范对比
├── 02-Research/       # HarmonyOS 并发调研
├── 03-POC/            # 锁机制 POC
├── 04-Design/         # 并发映射设计
├── 05-Implementation/ # ArkTS/C++ 实现
├── 06-Test/           # 并发测试
└── 07-Docs/           # 文档
```

---

## 里程碑

| 阶段 | 内容 | 预计时间 |
|------|------|---------|
| Phase 0 | HarmonyOS 并发机制调研 | 1周 |
| Phase 1 | synchronized 模拟实现 | 2周 |
| Phase 2 | 线程模型映射 | 2周 |
| Phase 3 | Handler 替代方案 | 1周 |

---

**创建日期**: 2026-03-12
**版本**: 1.0.0
