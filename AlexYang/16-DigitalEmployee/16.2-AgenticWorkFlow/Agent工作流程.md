---
tags:
  - system/workflow
  - ai/agent
  - project/management
  - 16-project
date: 2026-03-11
status: active
---

# 多AI Agent工作流程

> **目标**: 实现项目状态可视化、最大化token价值、多Agent并行协作

---

## 🎯 工作流程概览

### **核心原则**
1. **Claude Code**: 高复杂度任务、架构设计、代码审查
2. **Kimi/GLM**: 大文档处理、批量分析、中文优化
3. **DeepSeek**: 数据处理、测试生成、性能优化
4. **Obsidian**: 项目状态可视化、知识管理

---

## 🔄 Agent协作流程

### **Phase 1: 任务分配 (每日报到)**

```
09:00 Agent状态检查
├─ Claude Code: 检查5小时限制
├─ Kimi: 检查API配额
├─ GLM: 检查API配额
└─ DeepSeek: 检查API配额

09:30 任务优先级排序
├─ 高优先级: Claude Code (1小时内)
├─ 中优先级: Kimi/GLM (无限制)
└─ 低优先级: DeepSeek (数据处理)
```

### **Phase 2: 并行执行**

```
┌─────────────────────────────────────────────────────┐
│                Agent并行执行矩阵                      │
├─────────────────────────────────────────────────────┤
│ 时间段    │ Claude Code │ Kimi │ GLM │ DeepSeek │
├─────────────────────────────────────────────────────┤
│ 09:30-11:00│  架构设计   │ 文档 │ 分析 │ 数据处理 │
│ 11:00-12:00│  代码开发   │ 批量 │ 优化 │ 测试生成 │
│ 14:00-15:30│  代码审查   │ 翻译 │ 总结 │ 性能优化 │
│ 15:30-17:00│  项目管理   │ 协作 │ 整理 │ 部署支持 │
└─────────────────────────────────────────────────────┘
```

---

## 📊 Agent状态追踪系统

### **1. 项目状态仪表板**

```markdown
## 🎯 当前项目状态

### **16-DigitalEmployee项目组**
- **131项目**: Android→HarmonyOS适配开发
  - 状态: 🟡 进行中 (Phase 2: Adapter开发)
  - Agent: Claude Code + Kimi
  - 进度: 45%
  
- **133项目**: Android API分析研究
  - 状态: 🟡 进行中 (Phase 2: 映射规则)
  - Agent: GLM + DeepSeek
  - 进度: 60%

### **Agent运行状态**
- **Claude Code**: 🟢 正常 (剩余4.2小时)
- **Kimi**: 🟢 正常 (剩余配额充足)
- **GLM**: 🟢 正常 (剩余配额充足)
- **DeepSeek**: 🟢 正常 (剩余配额充足)
```

### **2. Agent任务队列**

```markdown
## 📋 Agent任务队列

### **等待中任务**
1. [ ] Claude Code: 131项目Adapter代码审查
2. [ ] Kimi: Android API文档批量翻译
3. [ ] GLM: HarmonyOS适配器优化建议
4. [ ] DeepSeek: 测试用例生成

### **进行中任务**
1. 🔄 Claude Code: 架构设计 (预计30分钟)
2. 🔄 Kimi: 文档整理 (预计45分钟)
3. 🔄 GLM: 代码优化 (预计1小时)

### **已完成任务**
1. ✅ Claude Code: 项目架构设计
2. ✅ Kimi: API分类完成
3. ✅ GLM: 映射规则文档
```

---

## 🚀 具体操作流程

### **每日启动流程 (09:00)**

```bash
# 1. 检查Agent状态
./scripts/check-agent-status.sh

# 2. 更新项目状态
./scripts/update-project-status.sh

# 3. 分配今日任务
./scripts/assign-daily-tasks.sh

# 4. 启动监控
./scripts/start-monitoring.sh
```

### **任务执行流程**

```bash
# 1. 根据任务类型选择Agent
case $task_type in
  "architecture")
    claude-code "架构设计任务"
    ;;
  "documentation")
    kimi "文档处理任务"
    ;;
  "analysis")
    glm "分析任务"
    ;;
  "data")
    deepseek "数据处理任务"
    ;;
esac

# 2. 执行任务并记录
./scripts/execute-task.sh $task_id

# 3. 更新状态
./scripts/update-task-status.sh $task_id "completed"
```

---

## 📈 Token使用监控

### **1. Claude Code使用监控**

```bash
# 每日使用统计
echo "Claude Code今日使用情况:"
echo "已使用: $(cat claude_usage.txt)小时"
echo "剩余: $(echo "5 - $(cat claude_usage.txt)")小时"

# 警告阈值
if [ $(cat claude_usage.txt) -gt 4 ]; then
  echo "⚠️  Claude Code即将达到限制，切换到其他Agent"
fi
```

### **2. 廉价Agent使用优化**

```bash
# 大文档处理使用Kimi/GLM
process_large_document() {
  local file=$1
  local size=$(wc -c < $file)
  
  if [ $size -gt 100000 ]; then  # >100KB
    kimi "处理大文档: $file"
  else
    claude-code "处理文档: $file"
  fi
}

# 数据处理使用DeepSeek
process_data() {
  deepseek "数据处理任务"
}
```

---

## 🔧 配置文件

### **1. Agent配置**

```yaml
# agent-config.yaml
agents:
  claude:
    name: "Claude Code"
    max_hours: 5
    daily_limit: 1
    priority: "high"
    tasks: ["architecture", "code_review", "project_management"]
  
  kimi:
    name: "Kimi"
    max_hours: "unlimited"
    priority: "medium"
    tasks: ["documentation", "translation", "batch_processing"]
  
  glm:
    name: "GLM"
    max_hours: "unlimited"
    priority: "medium"
    tasks: ["analysis", "optimization", "code_generation"]
  
  deepseek:
    name: "DeepSeek"
    max_hours: "unlimited"
    priority: "low"
    tasks: ["data_processing", "testing", "performance"]
```

### **2. 项目配置**

```yaml
# project-config.yaml
projects:
  "16.1-AndroidToHarmonyOS":
    agents: ["claude", "kimi"]
    priority: "high"
    status: "active"
  
  "16.3-AndroidAPI-Requirement":
    agents: ["glm", "deepseek"]
    priority: "high"
    status: "active"
```

---

## 🎯 实施步骤

### **第1天: 基础配置**
- [ ] 创建Agent状态监控系统
- [ ] 配置token使用监控
- [ ] 设置项目状态仪表板

### **第2天: 工作流程测试**
- [ ] 测试多Agent并行协作
- [ ] 验证token分配策略
- [ ] 优化任务分配逻辑

### **第3天: 正式运行**
- [ ] 启动每日自动化流程
- [ ] 建立监控和报警机制
- [ ] 收集反馈并优化

---

## 📊 监控指标

### **关键指标**
1. **Agent使用率**: 各Agent任务完成率
2. **Token效率**: 每小时完成的任务数
3. **项目进度**: 各项目完成百分比
4. **响应时间**: 任务平均处理时间

### **报警机制**
- Claude Code剩余时间 < 1小时
- 任何Agent任务失败 > 30分钟
- 项目进度落后 > 20%

---

## 🔗 相关文档

- [[项目状态报告]] - 项目整体进度
- [[16-项目总览]] - DigitalEmployee项目详情
- [[CLAUDE.md]] - 权限与安全边界

---

**维护者**: Claude Code  
**创建日期**: 2026-03-11  
**最后更新**: 2026-03-11