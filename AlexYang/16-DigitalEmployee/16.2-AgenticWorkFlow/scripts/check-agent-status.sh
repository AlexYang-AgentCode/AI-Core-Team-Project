#!/bin/bash

# Agent状态检查脚本
# 用途: 检查各AI Agent的状态和配额

set -e

echo "🤖 Agent状态检查 - $(date)"
echo "=================================="

# Claude Code状态检查
echo "🔵 Claude Code状态:"
if command -v claude &> /dev/null; then
    claude_status=$(claude --version 2>&1 | head -1)
    echo "  状态: ✅ 运行正常"
    echo "  版本: $claude_status"
    
    # 检查token使用情况
    if [ -f "$HOME/.claude/usage.txt" ]; then
        used_hours=$(cat "$HOME/.claude/usage.txt")
        remaining_hours=$(echo "5 - $used_hours" | bc -l 2>/dev/null || echo "5")
        echo "  已使用: $used_hours 小时"
        echo "  剩余: $remaining_hours 小时"
        
        if (( $(echo "$remaining_hours < 1" | bc -l) )); then
            echo "  ⚠️  警告: 剩余时间不足1小时"
        fi
    else
        echo "  未找到使用记录"
    fi
else
    echo "  ❌ 未安装Claude CLI"
fi

echo ""

# Kimi API状态检查
echo "🟡 Kimi API状态:"
if [ -n "$KIMI_API_KEY" ]; then
    echo "  API Key: ✅ 已配置"
    # 这里可以添加API调用测试
    echo "  状态: ✅ 配置正常"
else
    echo "  ❌ API Key未配置"
fi

echo ""

# GLM API状态检查
echo "🟢 GLM API状态:"
if [ -n "$GLM_API_KEY" ]; then
    echo "  API Key: ✅ 已配置"
    echo "  状态: ✅ 配置正常"
else
    echo "  ❌ API Key未配置"
fi

echo ""

# DeepSeek API状态检查
echo "🔴 DeepSeek API状态:"
if [ -n "$DEEPSEEK_API_KEY" ]; then
    echo "  API Key: ✅ 已配置"
    echo "  状态: ✅ 配置正常"
else
    echo "  ❌ API Key未配置"
fi

echo ""

# 项目状态检查
echo "📊 项目状态检查:"
echo "  16.1项目: $(find "../../16.1-AndroidToHarmonyOS" -name "*.md" | wc -l) 个文档"
echo "  16.3项目: $(find "../../16.3-AndroidAPI-Requirement" -name "*.md" | wc -l) 个文档"

echo ""
echo "✅ Agent状态检查完成"