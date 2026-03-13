---
tags:
  - 134-project
  - adapter-design
  - third-party
  - library-migration
  - android-to-harmonyos
date: 2026-03-12
status: planning
priority: P1
---

# 16.4.9-ThirdParty.Adapter: 第三方库适配策略

> **项目定位**: 16.4 适配层子项目，负责 Android 第三方库的替代/移除/适配策略
> **项目状态**: 规划中，从 16.4.4 拆分独立
> **上游依赖**: 16.4.1-JIT.Compiler
> **下游依赖**: 16.4.2-Activity.Bridge, 16.4.3-View.Bridge

---

## 拆分背景

原 16.4.4-System.Bridge 包含系统 API 和第三方库策略，职责混杂。

本模块独立负责 **第三方库的识别、分析与迁移策略**。

---

## 职责范围

### 第三方库分类策略

| 策略 | 说明 | 示例 |
|------|------|------|
| **编译时移除** | 注解处理器，生成代码后移除 | ButterKnife |
| **自实现替代** | 功能简单，自研轻量替代 | EvalEx |
| **ArkUI原生替代** | ArkUI已提供，直接替换 | Calligraphy → fontFamily |
| **HarmonyOS SDK替代** | 使用系统提供的能力 | Snackbar → promptAction |
| **源码移植** | 纯Java/Kotlin库，编译到ArkTS | Gson, Retrofit等 |

### 16.1 Demo 涉及的第三方库

| 三方库 | 使用场景 | 策略 | 优先级 |
|--------|----------|------|--------|
| **ButterKnife** | @BindView, @OnClick | **编译时移除**: 注解处理为直接引用 | P0 |
| **EvalEx** | 计算器表达式求值 | **自实现**: 表达式解析器 | P0 |
| **Calligraphy** | 自定义字体 | **移除**: ArkUI 原生 fontFamily | P2 |
| **Rhino (javax.script)** | JS 求值 | **替代**: ArkTS eval 或自实现 | P0 |
| **Snackbar** (Material) | 提示信息 | **替代**: promptAction | P2 |
| **JUnit/Mockito** | 单元测试 | **替代**: OpenHarmony 测试框架 | P3 |

---

## 项目结构

```
16.4.9-ThirdParty.Adapter/
├── 01-Spec/                    # 第三方库分析规范
│   └── Library-Analysis-Template.md
├── 02-Research/                # 热门库调研
│   ├── ButterKnife-Analysis.md
│   ├── EvalEx-Analysis.md
│   └── Popular-Libraries-List.md
├── 03-POC/                     # 迁移 POC
│   ├── ButterKnife-Removal/
│   └── Expression-Evaluator/
├── 04-Design/                  # 适配架构设计
│   ├── Annotation-Processor.md
│   └── Migration-Pipeline.md
├── 05-Implementation/          # 实现工具
│   ├── analyzers/              # 库分析工具
│   ├── transformers/           # 代码转换器
│   └── replacements/           # 自实现替代库
├── 06-Test/                    # 测试
│   └── migration-tests/
└── 07-Docs/                    # 文档
    └── migration-guides/
```

---

## 核心工具链

### 1. 库分析器 (Library Analyzer)

```typescript
// 分析 APK 中的第三方库依赖
export class LibraryAnalyzer {
  analyzeDependencies(apkPath: string): LibraryInfo[] {
    // 识别 classes.dex 中的外部引用
    // 匹配已知库特征（包名、类名、方法签名）
  }
}
```

### 2. 注解处理器 (Annotation Processor)

```typescript
// ButterKnife @BindView → 直接引用
// 编译时转换，不保留运行时依赖
export class ButterKnifeProcessor {
  processBindView(classNode: ClassNode): void {
    // 将 @BindView(R.id.xxx) 字段
    // 转换为 findViewById 直接赋值
  }
}
```

### 3. 表达式引擎 (Expression Evaluator)

```typescript
// 替代 EvalEx + javax.script
export class ExpressionEvaluator {
  evaluate(expression: string): number {
    // 安全的数学表达式解析
    // 支持: +, -, *, /, (, ), %, ^
    // 不支持: 函数调用、变量（安全考虑）
  }
}
```

---

## 里程碑

| 阶段 | 内容 | 预计时间 |
|------|------|---------|
| Phase 0 | 16.1 Demo 第三方库清单梳理 | 3天 |
| Phase 1 | ButterKnife 编译时移除 | 1周 |
| Phase 2 | 表达式引擎实现 | 1周 |
| Phase 3 | 自动化分析工具 | 2周 |
| Phase 4 | 常见库迁移指南 | 持续 |

---

## 与其他模块的关系

```
16.4.1-JIT.Compiler
    ↓ 编译时处理
16.4.9-ThirdParty.Adapter (本项目)
    ├── ButterKnife 移除 → 生成纯 findViewById 代码
    ├── EvalEx 替代 → 自实现表达式引擎
    └── 其他库策略 → 标记/转换/替代建议
    ↓
16.4.2-Activity.Bridge / 16.4.3-View.Bridge
```

---

**创建日期**: 2026-03-12
**拆分来源**: 16.4.4-System.Bridge
**版本**: 1.0.0
