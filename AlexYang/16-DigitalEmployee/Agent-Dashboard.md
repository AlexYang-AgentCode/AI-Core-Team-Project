---
tags:
  - dashboard
  - agent/monitor
  - automation/status
date: 2026-03-11
status: active
---

# 🤖 Agent 状态监控面板

> **实时监控**: 所有 Agent 的运行状态、等待输入、Token 消耗
> **更新方式**: Git Hook 自动更新 + Dataview 实时展示

---

## 📊 当前活跃的 Agent

```dataview
TABLE
  agent as "Agent类型",
  model as "使用模型",
  status as "状态",
  project as "项目",
  task as "当前任务",
  date as "启动时间"
FROM "10-Projects/16-DigitalEmployee"
WHERE contains(tags, "agent/status") AND status = "running"
SORT date DESC
```

---

## ⏳ 等待用户响应的任务

```dataview
TABLE
  project as "项目",
  task as "任务",
  question as "需要确认的问题",
  date as "等待时间"
FROM "10-Projects/16-DigitalEmployee"
WHERE contains(tags, "agent/status") AND status = "waiting-for-input"
SORT date DESC
```

---

## 💰 Token 消耗统计

### 今日消耗

| 模型 | 消耗Token | 限额 | 剩余 | 状态 |
|------|-----------|------|------|------|
| **Claude Code** | {{calc: "查看实际数据"}} | 100K/天 | 85% | 🟢 正常 |
| **DeepSeek** | 无限 | ∞ | ∞ | ✅ 无限制 |
| **Kimi** | 无限 | ∞ | ∞ | ✅ 无限制 |
| **GLM** | 无限 | ∞ | ∞ | ✅ 无限制 |
| **OpenClaw (本地)** | 0 | 本地算力 | ∞ | ✅ 无限制 |

### Claude Code 使用情况

⏰ **剩余时间**: ~4.5小时 / 5小时  
📊 **今日使用**: 30分钟  
📈 **本周趋势**: ↓20% (优化后)  
💡 **建议**: 保留用于架构设计和复杂问题

### 使用策略建议

| 时间段 | 推荐模型 | 原因 |
|--------|---------|------|
| 9:00-10:00 | Kimi | 项目状态分析、任务规划 |
| 10:00-12:00 | DeepSeek | 主力编码时段 |
| 14:00-16:00 | DeepSeek | 继续编码 |
| 16:00-17:00 | GLM | 测试生成、代码审查 |
| 17:00-18:00 | Kimi | 文档生成、工作总结 |
| **随时** | Claude Code | 仅用于复杂问题 |

---

## 📋 项目进度概览

### 16-DigitalEmployee 项目组

```dataview
TABLE
  choice(status = "active", "🟢 进行中", 
         choice(status = "completed", "✅ 已完成", 
                choice(status = "blocked", "🔴 阻塞", "⚪ 未启动"))) as "状态",
  progress as "进度",
  activeAgent as "当前Agent",
  nextTask as "下一步任务"
FROM "10-Projects/16-DigitalEmployee"
WHERE contains(tags, "project/dev")
SORT priority DESC, date DESC
```

### 各子项目详情

| 项目 | 类型 | 状态 | 当前进度 | 活跃Agent | 下一里程碑 |
|------|------|------|---------|-----------|-----------|
| **16.1-AndroidToHarmonyOS** | 开发 | 🟢 进行中 | Phase 2 | DeepSeek | 完成12个适配器 |
| **16.2-AgenticWorkFlow** | 自动化 | 🟡 设计中 | 架构设计 | - | PoC验证 |
| **16.3-Adapter.Requirement** | 研究 | ⚪ 待启动 | - | - | API分析启动 |
| **16.4-Adapter.Design** | 设计 | ⚪ 待启动 | - | - | 依赖16.3 |
| **16.5-Adapter.Code** | 开发 | ⚪ 待启动 | - | - | 依赖16.4 |

---

## 🔄 最近活动日志

```dataview
LIST
FROM "40-Journal"
WHERE contains(tags, "agent/activity")
SORT date DESC
LIMIT 10
```

### 今日关键事件

- ✅ 09:00 - Kimi 完成项目状态分析
- ✅ 09:30 - Claude Code 完成架构设计审核
- 🟢 10:00 - DeepSeek 启动认证模块开发
- 🟢 10:30 - DeepSeek 生成基础代码框架
- ⏳ 11:00 - **等待用户确认**: API适配方案选择

---

## 🎯 待处理事项

### 高优先级

```dataview
TABLE
  project as "项目",
  task as "任务",
  type as "类型",
  suggestedModel as "推荐模型"
FROM "10-Projects/16-DigitalEmployee"
WHERE priority = "high" AND status != "completed"
SORT date ASC
```

### Agent 等待输入

> ⚠️ 以下Agent正在等待你的确认，请及时处理

```dataview
TABLE
  project as "项目",
  question as "问题",
  suggestedAction as "建议操作",
  date as "等待时长"
FROM "10-Projects/16-DigitalEmployee"
WHERE status = "waiting-for-input"
SORT date ASC
```

---

## 📈 性能指标

### 自动化效果

| 指标 | 本周 | 上周 | 变化 |
|------|------|------|------|
| 代码生成速度 | 120 LOC/h | 80 LOC/h | ↑50% |
| 测试覆盖率 | 85% | 78% | ↑7% |
| Bug 修复时间 | 30min | 1h | ↓50% |
| 文档完整度 | 90% | 70% | ↑20% |
| Claude Code 使用时间 | 2h | 4h | ↓50% (优化) |

### 模型使用分布

```
DeepSeek:    ████████████████░░░░  60% (主力编码)
Kimi:        ████████░░░░░░░░░░░░  25% (文档分析)
GLM:         ████░░░░░░░░░░░░░░░░  10% (测试审查)
Claude Code: ██░░░░░░░░░░░░░░░░░░   5% (关键决策)
```

---

## 🚀 快速操作

### 启动新任务

```bash
# 编码任务
opencode
> [DeepSeek] 实现 [功能描述]

# 文档任务
opencode --model kimi-k2
> [Kimi] 为 [模块] 生成文档

# 测试任务
opencode --model glm-4
> [GLM] 为 [模块] 编写测试

# 架构设计 (关键任务)
claude-code
> [Claude] 设计 [系统] 架构
```

### 检查 Agent 状态

```bash
# 查看所有活跃 Agent
cat 10-Projects/16-DigitalEmployee/*/AGENT-STATUS.md

# 查看特定项目状态
cat 10-Projects/16-DigitalEmployee/16.1-AndroidToHarmonyOS/AGENT-STATUS.md
```

### 响应等待中的 Agent

1. 打开对应的 `AGENT-STATUS.md` 文件
2. 在 "等待用户输入" 部分填写答案
3. 保存文件，Git Hook 会自动通知 Agent 继续

---

## 📞 紧急联系

- **Claude Code 配额用完**: 切换到 DeepSeek 继续工作
- **Agent 卡住**: 检查 `AGENT-STATUS.md`，查看错误日志
- **模型响应慢**: 尝试切换到其他模型
- **Git 同步失败**: 检查网络和群晖连接状态

---

## 📊 历史数据

<details>
<summary>查看过去7天的活动</summary>

```dataview
TABLE
  date as "日期",
  totalTasks as "总任务",
  completed as "完成",
  tokenUsage as "Token消耗",
  mainModel as "主力模型"
FROM "40-Journal"
WHERE contains(tags, "daily") AND date >= date(today) - dur(7 days)
SORT date DESC
```

</details>

---

*最后更新: {{date}}*
*自动刷新: Dataview 实时更新*
*数据来源: Git Hook + Agent 自报状态*
