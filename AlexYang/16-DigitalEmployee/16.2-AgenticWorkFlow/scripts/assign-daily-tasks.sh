#!/bin/bash

# 每日任务分配脚本
# 用途: 根据Agent状态和项目优先级分配任务

set -e

echo "📋 每日任务分配 - $(date)"
echo "=================================="

# 创建任务分配文件
task_file="/tmp/daily_tasks_$(date +%Y%m%d).md"

echo "---" > "$task_file"
echo "tags:" >> "$task_file"
echo "  - task/daily" >> "$task_file"
echo "  - ai/agent" >> "$task_file"
echo "  - 16-project" >> "$task_file"
echo "date: $(date +%Y-%m-%d)" >> "$task_file"
echo "status: active" >> "$task_file"
echo "---" >> "$task_file"
echo "" >> "$task_file"

echo "# 📋 每日任务分配 - $(date)" >> "$task_file"
echo "" >> "$task_file"

# 检查Agent状态
echo "## 🤖 Agent状态评估" >> "$task_file"
echo "" >> "$task_file"

# Claude Code状态
claude_available=true
if command -v claude &> /dev/null; then
    if [ -f "$HOME/.claude/usage.txt" ]; then
        used_hours=$(cat "$HOME/.claude/usage.txt")
        remaining_hours=$(echo "5 - $used_hours" | bc -l 2>/dev/null || echo "5")
        echo "### 🔵 Claude Code" >> "$task_file"
        echo "- 状态: 🟢 可用" >> "$task_file"
        echo "- 剩余时间: $remaining_hours 小时" >> "$status_file"
        
        if (( $(echo "$remaining_hours < 1" | bc -l) )); then
            claude_available=false
            echo "- ⚠️  今日限制，仅处理高优先级任务" >> "$task_file"
        fi
    fi
else
    claude_available=false
    echo "### 🔵 Claude Code" >> "$task_file"
    echo "- 状态: ❌ 不可用" >> "$task_file"
fi
echo "" >> "$task_file"

# 其他Agent状态
echo "### 🟡 Kimi" >> "$task_file"
if [ -n "$KIMI_API_KEY" ]; then
    echo "- 状态: 🟢 可用" >> "$task_file"
    kimi_available=true
else
    echo "- 状态: ❌ 不可用" >> "$task_file"
    kimi_available=false
fi
echo "" >> "$task_file"

echo "### 🟢 GLM" >> "$task_file"
if [ -n "$GLM_API_KEY" ]; then
    echo "- 状态: 🟢 可用" >> "$task_file"
    glm_available=true
else
    echo "- 状态: ❌ 不可用" >> "$task_file"
    glm_available=false
fi
echo "" >> "$task_file"

echo "### 🔴 DeepSeek" >> "$task_file"
if [ -n "$DEEPSEEK_API_KEY" ]; then
    echo "- 状态: 🟢 可用" >> "$task_file"
    deepseek_available=true
else
    echo "- 状态: ❌ 不可用" >> "$task_file"
    deepseek_available=false
fi
echo "" >> "$task_file"

echo "" >> "$task_file"
echo "## 🎯 任务分配策略" >> "$task_file"
echo "" >> "$task_file"

# 根据Agent可用性分配任务
echo "### 高优先级任务 (Claude Code)" >> "$task_file"
echo "" >> "$task_file"

if [ "$claude_available" = true ]; then
    echo "1. **架构设计** - 131项目Adapter架构优化" >> "$task_file"
    echo "   - Agent: Claude Code" >> "$task_file"
    echo "   - 预计时间: 30分钟" >> "$task_file"
    echo "   - 优先级: 🔴 高" >> "$task_file"
    echo "" >> "$task_file"
    
    echo "2. **代码审查** - 16.1项目代码质量检查" >> "$task_file"
    echo "   - Agent: Claude Code" >> "$task_file"
    echo "   - 预计时间: 45分钟" >> "$task_file"
    echo "   - 优先级: 🔴 高" >> "$task_file"
    echo "" >> "$task_file"
else
    echo "1. **无高优先级任务** - Claude Code已达今日限制" >> "$task_file"
    echo "" >> "$task_file"
fi

echo "### 中优先级任务 (Kimi/GLM)" >> "$task_file"
echo "" >> "$task_file"

if [ "$kimi_available" = true ]; then
    echo "1. **文档整理** - Android API文档批量处理" >> "$task_file"
    echo "   - Agent: Kimi" >> "$task_file"
    echo "   - 预计时间: 1小时" >> "$task_file"
    echo "   - 优先级: 🟡 中" >> "$task_file"
    echo "" >> "$task_file"
fi

if [ "$glm_available" = true ]; then
    echo "2. **代码优化** - HarmonyOS适配器性能优化" >> "$task_file"
    echo "   - Agent: GLM" >> "$task_file"
    echo "   - 预计时间: 1.5小时" >> "$task_file"
    echo "   - 优先级: 🟡 中" >> "$task_file"
    echo "" >> "$task_file"
fi

echo "### 低优先级任务 (DeepSeek)" >> "$task_file"
echo "" >> "$task_file"

if [ "$deepseek_available" = true ]; then
    echo "1. **数据处理** - 测试用例生成" >> "$task_file"
    echo "   - Agent: DeepSeek" >> "$task_file"
    echo "   - 预计时间: 2小时" >> "$task_file"
    echo "   - 优先级: 🟢 低" >> "$status_file"
    echo "" >> "$task_file"
    
    echo "2. **性能分析** - 代码性能优化建议" >> "$task_file"
    echo "   - Agent: DeepSeek" >> "$task_file"
    echo "   - 预计时间: 1小时" >> "$task_file"
    echo "   - 优先级: 🟢 低" >> "$task_file"
    echo "" >> "$task_file"
else
    echo "1. **无低优先级任务** - DeepSeek不可用" >> "$task_file"
    echo "" >> "$task_file"
fi

echo "" >> "$task_file"
echo "## ⏰ 时间安排建议" >> "$task_file"
echo "" >> "$task_file"

echo "### 上午 (09:00-12:00)" >> "$task_file"
echo "- 09:00-09:30: Agent状态检查" >> "$task_file"
echo "- 09:30-11:00: 高优先级任务 (Claude Code)" >> "$task_file"
echo "- 11:00-12:00: 中优先级任务 (Kimi/GLM)" >> "$task_file"
echo "" >> "$task_file"

echo "### 下午 (14:00-17:00)" >> "$task_file"
echo "- 14:00-15:30: 中优先级任务 (Kimi/GLM)" >> "$task_file"
echo "- 15:30-17:00: 低优先级任务 (DeepSeek)" >> "$task_file"
echo "" >> "$task_file"

echo "" >> "$task_file"
echo "## 📊 预期产出" >> "$task_file"
echo "" >> "$task_file"

echo "- ✅ 完成架构设计和代码审查" >> "$task_file"
echo "- ✅ 处理50+ API文档" >> "$task_file"
echo "- ✅ 生成20+ 测试用例" >> "$task_file"
echo "- ✅ 优化3个核心适配器" >> "$task_file"
echo "" >> "$task_file"

echo "---" >> "$task_file"
echo "**自动生成**: $(date)" >> "$task_file"
echo "**维护者**: Claude Code" >> "$task_file"

# 复制到项目目录
cp "$task_file" "../../16-DigitalEmployee/每日任务分配_$(date +%Y%m%d).md"

echo "✅ 每日任务分配已生成: ../../16-DigitalEmployee/每日任务分配_$(date +%Y%m%d).md"

# 清理临时文件
rm -f "$task_file"