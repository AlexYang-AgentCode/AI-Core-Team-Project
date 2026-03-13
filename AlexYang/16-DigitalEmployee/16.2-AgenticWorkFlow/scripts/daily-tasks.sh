#!/bin/bash

# 每日任务执行脚本
# 用途: 执行每日例行任务，包括状态检查、任务分配、项目更新等

set -e

# 配置参数
VAULT_DIR="/mnt/d/ObsidianVault"
SCRIPTS_DIR="$VAULT_DIR/10-Projects/16-DigitalEmployee/16.2-AgenticWorkFlow/scripts"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /tmp/daily-tasks-$(date +%Y%m%d).log
}

# 错误处理
error_exit() {
    log "❌ 错误: $1"
    exit 1
}

# 检查Agent状态
check_agent_status() {
    log "🔍 检查Agent状态..."
    
    # 检查Claude Code状态
    if command -v claude &> /dev/null; then
        if [ -f "$HOME/.claude/usage.txt" ]; then
            used_hours=$(cat "$HOME/.claude/usage.txt")
            remaining_hours=$(echo "5 - $used_hours" | bc -l 2>/dev/null || echo "5")
            log "🔵 Claude Code: 已使用 $used_hours 小时, 剩余 $remaining_hours 小时"
            
            if (( $(echo "$remaining_hours < 1" | bc -l) )); then
                log "⚠️  警告: Claude Code剩余时间不足1小时"
            fi
        fi
    else
        log "❌ Claude Code不可用"
    fi
    
    # 检查其他Agent
    if [ -n "$KIMI_API_KEY" ]; then
        log "🟡 Kimi: ✅ 配置正常"
    else
        log "❌ Kimi: API Key未配置"
    fi
    
    if [ -n "$GLM_API_KEY" ]; then
        log "🟢 GLM: ✅ 配置正常"
    else
        log "❌ GLM: API Key未配置"
    fi
    
    if [ -n "$DEEPSEEK_API_KEY" ]; then
        log "🔴 DeepSeek: ✅ 配置正常"
    else
        log "❌ DeepSeek: API Key未配置"
    fi
}

# 更新项目状态
update_project_status() {
    log "📊 更新项目状态..."
    
    cd "$VAULT_DIR/10-Projects/16-DigitalEmployee" || error_exit "无法进入项目目录"
    
    # 创建项目状态报告
    local status_file="项目状态报告_$(date +%Y%m%d).md"
    
    cat > "$status_file" << EOF
---
tags:
  - project/status
  - ai/agent
  - 16-project
date: $(date +%Y-%m-%d)
status: active
---

# 🎯 项目状态报告 - $(date)

---

## 📊 Agent运行状态

### **Claude Code**
- 状态: \$(if command -v claude &> /dev/null; then echo "🟢 正常"; else echo "❌ 不可用"; fi)
- 剩余时间: \$(if [ -f "\$HOME/.claude/usage.txt" ]; then used=\$(cat "\$HOME/.claude/usage.txt"); remaining=\$(echo "5 - \$used" | bc -l 2>/dev/null || echo "5"); echo "\$remaining 小时"; else echo "未知"; fi)

### **Kimi**
- 状态: \$(if [ -n "\$KIMI_API_KEY" ]; then echo "🟢 正常"; else echo "❌ 未配置"; fi)

### **GLM**
- 状态: \$(if [ -n "\$GLM_API_KEY" ]; then echo "🟢 正常"; else echo "❌ 未配置"; fi)

### **DeepSeek**
- 状态: \$(if [ -n "\$DEEPSEEK_API_KEY" ]; then echo "🟢 正常"; else echo "❌ 未配置"; fi)

---

## 🚀 项目进度

### **16.1-AndroidToHarmonyOS**
- 状态: 🟡 进行中
- 阶段: Phase 2 - Adapter开发
- 文档数: \$(find "16.1-AndroidToHarmonyOS" -name "*.md" | wc -l)
- Agent: Claude Code + Kimi

### **16.3-AndroidAPI-Requirement**
- 状态: 🟡 进行中
- 阶段: Phase 2 - 映射规则
- 文档数: \$(find "16.3-AndroidAPI-Requirement" -name "*.md" | wc -l)
- Agent: GLM + DeepSeek

---

## 📋 今日任务队列

### **等待中任务**
1. [ ] Claude Code: 131项目Adapter代码审查
2. [ ] Kimi: Android API文档批量翻译
3. [ ] GLM: HarmonyOS适配器优化建议
4. [ ] DeepSeek: 测试用例生成

### **进行中任务**
1. 🔄 \$(find . -name "*进行中*" -o -name "*in_progress*" | wc -l) 个任务正在执行

### **已完成任务**
1. ✅ \$(find . -name "*已完成*" -o -name "*completed*" | wc -l) 个任务已完成

---

## 📈 Token使用统计

### **Claude Code**
- 今日使用: \$(if [ -f "\$HOME/.claude/usage.txt" ]; then cat "\$HOME/.claude/usage.txt"; else echo "0"; fi) 小时
- 剩余配额: \$(if [ -f "\$HOME/.claude/usage.txt" ]; then used=\$(cat "\$HOME/.claude/usage.txt"); remaining=\$(echo "5 - \$used" | bc -l 2>/dev/null || echo "5"); echo "\$remaining"; else echo "5"; fi) 小时

### **其他Agent**
- Kimi/GLM/DeepSeek: 无限制使用

---

## ⚠️ 警告与提醒

### **当前警告**
\$(if [ -f "\$HOME/.claude/usage.txt" ]; then used=\$(cat "\$HOME/.claude/usage.txt"); remaining=\$(echo "5 - \$used" | bc -l 2>/dev/null || echo "5"); if (( \$(echo "\$remaining < 1" | bc -l) )); then echo "- 🔵 Claude Code剩余时间不足1小时"; fi; fi)

---

## 🔗 快速导航

- [[16-项目总览]] - 项目组整体规划
- [[Agent工作流程]] - 详细工作流程说明
- [[项目状态仪表板]] - 实时监控界面

---

**自动生成**: $(date)
**维护者**: Claude Code
EOF
    
    log "✅ 项目状态已更新: $status_file"
}

# 分配每日任务
assign_daily_tasks() {
    log "📋 分配每日任务..."
    
    cd "$SCRIPTS_DIR" || error_exit "无法进入脚本目录"
    
    # 执行任务分配脚本
    if [ -f "assign-daily-tasks.sh" ]; then
        bash "assign-daily-tasks.sh"
        log "✅ 每日任务分配完成"
    else
        log "❌ 任务分配脚本不存在"
    fi
}

# 执行同步任务
execute_sync_tasks() {
    log "🔄 执行同步任务..."
    
    cd "$SCRIPTS_DIR" || error_exit "无法进入脚本目录"
    
    # 执行同步脚本
    if [ -f "sync-to-synology.sh" ]; then
        bash "sync-to-synology.sh"
        log "✅ 同步任务完成"
    else
        log "❌ 同步脚本不存在"
    fi
}

# 启动监控
start_monitoring() {
    log "🔍 启动监控..."
    
    cd "$SCRIPTS_DIR" || error_exit "无法进入脚本目录"
    
    # 启动监控脚本
    if [ -f "start-monitoring.sh" ]; then
        # 在后台运行监控
        bash "start-monitoring.sh" &
        log "✅ 监控已启动"
    else
        log "❌ 监控脚本不存在"
    fi
}

# 生成每日报告
generate_daily_report() {
    log "📊 生成每日报告..."
    
    local report_file="/tmp/daily-report-$(date +%Y%m%d).md"
    
    cat > "$report_file" << EOF
---
tags:
  - report/daily
  - ai/agent
  - 16-project
date: $(date +%Y-%m-%d)
status: active
---

# 📋 每日工作报告

**报告时间**: $(date)
**报告类型**: 自动化日报

---

## 🎯 今日工作总结

### **任务完成情况**
- ✅ Agent状态检查
- ✅ 项目状态更新
- ✅ 每日任务分配
- ✅ 数据同步
- ✅ 监控启动

### **关键指标**
- **Agent数量**: 4个
- **项目数量**: 2个
- **任务总数**: $(find "$VAULT_DIR/10-Projects/16-DigitalEmployee" -name "*任务*" | wc -l)
- **文档总数**: $(find "$VAULT_DIR/10-Projects/16-DigitalEmployee" -name "*.md" | wc -l)

---

## 📈 明日计划

### **重点任务**
1. 继续执行每日任务队列
2. 监控Agent状态变化
3. 更新项目进度
4. 执行数据同步

### **预期目标**
- 完成5个Agent任务
- 更新2个项目状态
- 执行1次数据同步
- 生成1次状态报告

---

## 🔗 相关链接

- [[项目状态报告]] - 项目进度详情
- [[Agent工作流程]] - 工作流程说明
- [[Git备份和群晖同步机制]] - 备份策略

---

**自动生成**: $(date)
**维护者**: Claude Code
EOF
    
    # 复制到项目目录
    cp "$report_file" "$VAULT_DIR/10-Projects/16-DigitalEmployee/每日工作报告_$(date +%Y%m%d).md"
    log "✅ 每日报告已生成"
}

# 主函数
main() {
    log "🌅 开始每日例行任务..."
    
    # 执行每日任务
    check_agent_status
    update_project_status
    assign_daily_tasks
    execute_sync_tasks
    start_monitoring
    generate_daily_report
    
    log "🎉 每日例行任务完成！"
}

# 执行主函数
main "$@"