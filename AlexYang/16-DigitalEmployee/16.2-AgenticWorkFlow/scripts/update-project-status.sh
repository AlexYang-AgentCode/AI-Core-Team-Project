#!/bin/bash

# 项目状态更新脚本
# 用途: 自动更新项目状态和进度

set -e

echo "📊 更新项目状态 - $(date)"
echo "=================================="

# 获取当前日期
current_date=$(date +%Y-%m-%d)
current_time=$(date +%H:%M)

# 创建状态报告
status_file="/tmp/project_status_$current_date.md"

echo "---" > "$status_file"
echo "tags:" >> "$status_file"
echo "  - project/status" >> "$status_file"
echo "  - ai/agent" >> "$status_file"
echo "  - 16-project" >> "$status_file"
echo "date: $current_date" >> "$status_file"
echo "status: active" >> "$status_file"
echo "---" >> "$status_file"
echo "" >> "$status_file"

echo "# 🎯 项目状态报告 - $current_date $current_time" >> "$status_file"
echo "" >> "$status_file"

echo "## 📊 Agent运行状态" >> "$status_file"
echo "" >> "$status_file"

# 检查Claude Code状态
if command -v claude &> /dev/null; then
    if [ -f "$HOME/.claude/usage.txt" ]; then
        used_hours=$(cat "$HOME/.claude/usage.txt")
        remaining_hours=$(echo "5 - $used_hours" | bc -l 2>/dev/null || echo "5")
        echo "### 🔵 Claude Code" >> "$status_file"
        echo "- 状态: 🟢 运行正常" >> "$status_file"
        echo "- 剩余时间: $remaining_hours 小时" >> "$status_file"
        echo "- 今日使用: $used_hours 小时" >> "$status_file"
        echo "" >> "$status_file"
    fi
fi

# 检查其他Agent状态
echo "### 🟡 Kimi" >> "$status_file"
if [ -n "$KIMI_API_KEY" ]; then
    echo "- 状态: 🟢 配置正常" >> "$status_file"
else
    echo "- 状态: ❌ API Key未配置" >> "$status_file"
fi
echo "" >> "$status_file"

echo "### 🟢 GLM" >> "$status_file"
if [ -n "$GLM_API_KEY" ]; then
    echo "- 状态: 🟢 配置正常" >> "$status_file"
else
    echo "- 状态: ❌ API Key未配置" >> "$status_file"
fi
echo "" >> "$status_file"

echo "### 🔴 DeepSeek" >> "$status_file"
if [ -n "$DEEPSEEK_API_KEY" ]; then
    echo "- 状态: 🟢 配置正常" >> "$status_file"
else
    echo "- 状态: ❌ API Key未配置" >> "$status_file"
fi
echo "" >> "$status_file"

echo "## 🚀 项目进度" >> "$status_file"
echo "" >> "$status_file"

# 16.1项目进度
echo "### 16.1-AndroidToHarmonyOS" >> "$status_file"
echo "- 状态: 🟡 进行中" >> "$status_file"
echo "- 阶段: Phase 2 - Adapter开发" >> "$status_file"
echo "- 进度: $(find "../../16.1-AndroidToHarmonyOS" -name "*.md" | wc -l) 个文档" >> "$status_file"
echo "- Agent: Claude Code + Kimi" >> "$status_file"
echo "" >> "$status_file"

# 16.3项目进度
echo "### 16.3-AndroidAPI-Requirement" >> "$status_file"
echo "- 状态: 🟡 进行中" >> "$status_file"
echo "- 阶段: Phase 2 - 映射规则" >> "$status_file"
echo "- 进度: $(find "../../16.3-AndroidAPI-Requirement" -name "*.md" | wc -l) 个文档" >> "$status_file"
echo "- Agent: GLM + DeepSeek" >> "$status_file"
echo "" >> "$status_file"

echo "## 📋 今日任务队列" >> "$status_file"
echo "" >> "$status_file"

# 检查待处理任务
echo "### 等待中任务" >> "$status_file"
echo "1. [ ] Claude Code: 131项目Adapter代码审查" >> "$status_file"
echo "2. [ ] Kimi: Android API文档批量翻译" >> "$status_file"
echo "3. [ ] GLM: HarmonyOS适配器优化建议" >> "$status_file"
echo "4. [ ] DeepSeek: 测试用例生成" >> "$status_file"
echo "" >> "$status_file"

echo "### 进行中任务" >> "$status_file"
echo "1. 🔄 Claude Code: 架构设计 (预计30分钟)" >> "$status_file"
echo "2. 🔄 Kimi: 文档整理 (预计45分钟)" >> "$status_file"
echo "3. 🔄 GLM: 代码优化 (预计1小时)" >> "$status_file"
echo "" >> "$status_file"

echo "## 📈 Token使用统计" >> "$status_file"
echo "" >> "$status_file"

if [ -f "$HOME/.claude/usage.txt" ]; then
    total_used=$(cat "$HOME/.claude/usage.txt")
    echo "- Claude Code今日使用: $total_used 小时" >> "$status_file"
    echo "- 剩余配额: $(echo "5 - $total_used" | bc -l 2>/dev/null || echo "5") 小时" >> "$status_file"
else
    echo "- Claude Code今日使用: 0 小时" >> "$status_file"
    echo "- 剩余配额: 5 小时" >> "$status_file"
fi

echo "- Kimi/GLM/DeepSeek: 无限制" >> "$status_file"

echo "" >> "$status_file"
echo "---" >> "$status_file"
echo "**自动生成**: $current_date $current_time" >> "$status_file"
echo "**维护者**: Claude Code" >> "$status_file"

# 复制到项目目录
cp "$status_file" "../../16-DigitalEmployee/项目状态报告_$(date +%Y%m%d).md"

echo "✅ 项目状态已更新: ../../16-DigitalEmployee/项目状态报告_$(date +%Y%m%d).md"

# 清理临时文件
rm -f "$status_file"