#!/bin/bash

# Post-commit Hook - 自动化 Agent 状态管理和模型选择建议
# 安装: cp post-commit-hook.sh .git/hooks/post-commit && chmod +x .git/hooks/post-commit

set -e

VAULT_ROOT="/mnt/d/ObsidianVault"
PROJECT_ROOT="$VAULT_ROOT/10-Projects/16-DigitalEmployee"
JOURNAL_DIR="$VAULT_ROOT/40-Journal"

echo "🤖 Post-commit Hook 执行中..."

# ============================================
# 1. 检查并更新 Agent 状态
# ============================================

# 查找所有 AGENT-STATUS.md 文件
STATUS_FILES=$(git diff --cached --name-only | grep "AGENT-STATUS.md" || true)

if [ -n "$STATUS_FILES" ]; then
    echo "✅ 检测到 Agent 状态更新"
    
    for STATUS_FILE in $STATUS_FILES; do
        # 提取状态信息
        if [ -f "$STATUS_FILE" ]; then
            STATUS=$(grep "状态:" "$STATUS_FILE" | head -1 | awk -F': ' '{print $2}' || echo "未知")
            PROJECT=$(grep "项目:" "$STATUS_FILE" | head -1 | awk -F': ' '{print $2}' || echo "未知")
            MODEL=$(grep "使用模型:" "$STATUS_FILE" | head -1 | awk -F': ' '{print $2}' || echo "未知")
            TASK=$(grep "当前任务:" "$STATUS_FILE" | head -1 | awk -F': ' '{print $2}' || echo "未知")
            
            echo "  📊 项目: $PROJECT"
            echo "  🤖 模型: $MODEL"
            echo "  ✨ 状态: $STATUS"
            echo "  📝 任务: $TASK"
            
            # 记录到今日日志
            TODAY_LOG="$JOURNAL_DIR/$(date +%Y-%m-%d).md"
            if [ ! -f "$TODAY_LOG" ]; then
                cat > "$TODAY_LOG" << EOF
---
tags:
  - journal/daily
date: $(date +%Y-%m-%d)
---

# $(date +%Y年%m月%d日) 日记

## Agent 活动

EOF
            fi
            
            echo "- [$(date +%H:%M)] $PROJECT - $TASK ($MODEL) - $STATUS" >> "$TODAY_LOG"
        fi
    done
fi

# ============================================
# 2. 分析提交内容，建议最佳模型
# ============================================

CHANGED_FILES=$(git diff --cached --name-only)
CODE_FILES=$(echo "$CHANGED_FILES" | grep -E "\.(py|js|ts|java|kt|go|rs)$" || true)
DOC_FILES=$(echo "$CHANGED_FILES" | grep -E "\.(md|txt|rst)$" || true)
TEST_FILES=$(echo "$CHANGED_FILES" | grep -E "(test|spec)" || true)
ARCH_FILES=$(echo "$CHANGED_FILES" | grep -iE "(architecture|design|架构|设计)" || true)

CODE_COUNT=$(echo "$CODE_FILES" | wc -l)
DOC_COUNT=$(echo "$DOC_FILES" | wc -l)
TEST_COUNT=$(echo "$TEST_FILES" | wc -l)
ARCH_COUNT=$(echo "$ARCH_FILES" | wc -l)

echo ""
echo "📊 提交分析:"
echo "  💻 代码文件: $CODE_COUNT"
echo "  📝 文档文件: $DOC_COUNT"
echo "  🧪 测试文件: $TEST_COUNT"
echo "  🏗️ 架构文件: $ARCH_COUNT"

# 智能建议
SUGGESTION=""
REASON=""

if [ $ARCH_COUNT -gt 0 ]; then
    SUGGESTION="claude-code"
    REASON="检测到架构/设计相关变更，Claude Code 最适合复杂架构决策"
elif [ $CODE_COUNT -gt 5 ]; then
    SUGGESTION="opencode --model deepseek-coder"
    REASON="大量代码变更，DeepSeek 高效且成本最优"
elif [ $TEST_COUNT -gt 0 ]; then
    SUGGESTION="opencode --model glm-4"
    REASON="测试文件变更，GLM 适合测试生成和代码审查"
elif [ $DOC_COUNT -gt 3 ]; then
    SUGGESTION="opencode --model kimi-k2"
    REASON="文档密集型变更，Kimi 长上下文优势明显"
elif [ $CODE_COUNT -gt 0 ]; then
    SUGGESTION="opencode"
    REASON="常规代码变更，DeepSeek (默认) 即可"
fi

if [ -n "$SUGGESTION" ]; then
    echo ""
    echo "💡 建议使用: $SUGGESTION"
    echo "   理由: $REASON"
fi

# ============================================
# 3. 检查是否需要切换环境
# ============================================

if [ $ARCH_COUNT -gt 0 ] || echo "$CHANGED_FILES" | grep -qiE "(关键|critical|重要|决策)"; then
    echo ""
    echo "⚠️  检测到关键变更，建议使用 Claude Code 进行审查"
    echo "   运行: claude-code"
    echo "   然后执行: 审查本次提交的架构设计"
fi

# ============================================
# 4. 更新 Dashboard (如果存在)
# ============================================

DASHBOARD_FILE="$PROJECT_ROOT/Agent-Dashboard.md"
if [ -f "$DASHBOARD_FILE" ]; then
    # 更新最后更新时间
    sed -i "s/\*最后更新: .*/\*最后更新: $(date '+%Y-%m-%d %H:%M:%S')\*/" "$DASHBOARD_FILE"
    echo ""
    echo "📊 Dashboard 已更新"
fi

# ============================================
# 5. Token 使用统计 (可选)
# ============================================

STATS_FILE="$PROJECT_ROOT/.agent-stats"
if [ -f "$STATS_FILE" ]; then
    # 读取上次统计
    CLAUDE_TOKEN=$(grep "claude_token:" "$STATS_FILE" | awk -F': ' '{print $2}')
    
    # 简单估算本次提交的 token (约 1 token = 4 字符)
    COMMIT_SIZE=$(git diff --cached --stat | tail -1 | awk '{print $3}' | sed 's/insertion(s)//' | tr -d ' ')
    
    if [ -n "$COMMIT_SIZE" ] && [ "$COMMIT_SIZE" -gt 0 ]; then
        ESTIMATED_TOKEN=$((COMMIT_SIZE / 4))
        
        echo ""
        echo "📈 Token 估算:"
        echo "   本次提交: ~$ESTIMATED_TOKEN tokens"
        
        # 如果估算超过 10K，建议使用廉价模型
        if [ $ESTIMATED_TOKEN -gt 10000 ]; then
            echo "   💡 提示: 大型变更，建议使用 DeepSeek/Kimi 而非 Claude Code"
        fi
    fi
fi

# ============================================
# 6. 同步到群晖 (可选)
# ============================================

# 如果配置了群晖远程仓库
if git remote | grep -q "synology"; then
    echo ""
    echo "🔄 检查是否需要同步到群晖..."
    
    # 只在特定情况下自动推送
    # - 完成重要里程碑
    # - 工作日结束前
    HOUR=$(date +%H)
    COMMIT_MSG=$(git log -1 --pretty=%B)
    
    if echo "$COMMIT_MSG" | grep -qiE "(完成|finish|release|版本|version)" || [ $HOUR -ge 17 ]; then
        echo "📤 自动同步到群晖..."
        git push synology main 2>/dev/null || echo "⚠️  同步失败，请手动推送"
    else
        echo "⏭️  跳过自动同步 (非关键提交且未到下班时间)"
    fi
fi

echo ""
echo "✅ Post-commit Hook 完成"

exit 0
