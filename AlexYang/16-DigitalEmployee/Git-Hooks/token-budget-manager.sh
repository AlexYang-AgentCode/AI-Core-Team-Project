#!/bin/bash

# Token 预算管理器 - 监控和优化模型使用
# 使用方法: ./token-budget-manager.sh [command]

VAULT_ROOT="/mnt/d/ObsidianVault"
PROJECT_ROOT="$VAULT_ROOT/10-Projects/16-DigitalEmployee"
STATS_FILE="$PROJECT_ROOT/.token-stats"
CONFIG_FILE="$PROJECT_ROOT/opencode.json"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 初始化统计文件
init_stats() {
    if [ ! -f "$STATS_FILE" ]; then
        cat > "$STATS_FILE" << EOF
# Token 使用统计
# 每日自动重置

claude_code:
  daily_limit: 100000
  used: 0
  last_reset: $(date +%Y-%m-%d)

deepseek:
  daily_limit: -1  # 无限制
  used: 0

kimi:
  daily_limit: -1
  used: 0

glm:
  daily_limit: -1
  used: 0

openclaw:
  daily_limit: 0
  used: 0
  note: "本地模型，无token成本"
EOF
        echo "✅ 统计文件已初始化: $STATS_FILE"
    fi
}

# 检查并重置每日统计
check_daily_reset() {
    TODAY=$(date +%Y-%m-%d)
    LAST_RESET=$(grep "last_reset:" "$STATS_FILE" | awk '{print $2}')
    
    if [ "$LAST_RESET" != "$TODAY" ]; then
        echo "🔄 检测到新的一天，重置统计..."
        
        # 备份昨天的统计
        cp "$STATS_FILE" "$STATS_FILE.$LAST_RESET.bak"
        
        # 重置今日统计
        sed -i "s/used: [0-9]*/used: 0/g" "$STATS_FILE"
        sed -i "s/last_reset: .*/last_reset: $TODAY/" "$STATS_FILE"
        
        echo "✅ 统计已重置"
    fi
}

# 记录 token 使用
record_usage() {
    local model=$1
    local tokens=$2
    
    # 更新统计文件 (简化版，实际应该用更可靠的方法)
    CURRENT=$(grep -A 5 "^$model:" "$STATS_FILE" | grep "used:" | awk '{print $2}')
    NEW=$((CURRENT + tokens))
    
    # 使用 Python 处理 YAML (如果可用)
    if command -v python3 &> /dev/null; then
        python3 << EOF
import yaml

with open('$STATS_FILE', 'r') as f:
    stats = yaml.safe_load(f)

if '$model' in stats:
    stats['$model']['used'] = $NEW

with open('$STATS_FILE', 'w') as f:
    yaml.dump(stats, f, default_flow_style=False)
EOF
    fi
    
    echo "📊 已记录: $model +$tokens tokens (总计: $NEW)"
}

# 显示统计
show_stats() {
    echo -e "${BLUE}📊 Token 使用统计${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    check_daily_reset
    
    # Claude Code (有限制)
    CLAUDE_USED=$(grep -A 5 "^claude_code:" "$STATS_FILE" | grep "used:" | awk '{print $2}')
    CLAUDE_LIMIT=$(grep -A 5 "^claude_code:" "$STATS_FILE" | grep "daily_limit:" | awk '{print $2}')
    CLAUDE_PERCENT=$((CLAUDE_USED * 100 / CLAUDE_LIMIT))
    CLAUDE_REMAINING=$((CLAUDE_LIMIT - CLAUDE_USED))
    
    echo -e "🤖 ${YELLOW}Claude Code${NC} (稀缺资源)"
    echo "   使用: $CLAUDE_USED / $CLAUDE_LIMIT tokens ($CLAUDE_PERCENT%)"
    echo "   剩余: $CLAUDE_REMAINING tokens"
    
    # 根据使用情况给出建议
    if [ $CLAUDE_PERCENT -gt 80 ]; then
        echo -e "   ${RED}⚠️  已使用超过80%，建议切换到 DeepSeek/Kimi${NC}"
    elif [ $CLAUDE_PERCENT -gt 50 ]; then
        echo -e "   ${YELLOW}💡 已使用50%，建议优先使用廉价模型${NC}"
    else
        echo -e "   ${GREEN}✅ 使用正常${NC}"
    fi
    
    echo ""
    
    # 其他模型 (无限制)
    echo -e "🤖 ${GREEN}DeepSeek${NC} (主力编码)"
    DEEPSEEK_USED=$(grep -A 5 "^deepseek:" "$STATS_FILE" | grep "used:" | awk '{print $2}')
    echo "   使用: $DEEPSEEK_USED tokens (无限制)"
    echo -e "   ${GREEN}✅ 推荐用于编码任务${NC}"
    
    echo ""
    
    echo -e "🤖 ${GREEN}Kimi${NC} (文档分析)"
    KIMI_USED=$(grep -A 5 "^kimi:" "$STATS_FILE" | grep "used:" | awk '{print $2}')
    echo "   使用: $KIMI_USED tokens (无限制)"
    echo -e "   ${GREEN}✅ 推荐用于文档和分析${NC}"
    
    echo ""
    
    echo -e "🤖 ${GREEN}GLM${NC} (测试审查)"
    GLM_USED=$(grep -A 5 "^glm:" "$STATS_FILE" | grep "used:" | awk '{print $2}')
    echo "   使用: $GLM_USED tokens (无限制)"
    echo -e "   ${GREEN}✅ 推荐用于测试和重构${NC}"
    
    echo ""
    
    echo -e "🤖 ${GREEN}OpenClaw${NC} (本地模型)"
    echo "   使用: 本地算力 (无token成本)"
    echo -e "   ${GREEN}✅ 推荐用于敏感数据和批量处理${NC}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 智能模型选择建议
suggest_model() {
    local task_type=$1
    
    echo -e "${BLUE}💡 模型选择建议${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # 检查 Claude Code 使用情况
    CLAUDE_USED=$(grep -A 5 "^claude_code:" "$STATS_FILE" | grep "used:" | awk '{print $2}')
    CLAUDE_LIMIT=$(grep -A 5 "^claude_code:" "$STATS_FILE" | grep "daily_limit:" | awk '{print $2}')
    CLAUDE_PERCENT=$((CLAUDE_USED * 100 / CLAUDE_LIMIT))
    
    case $task_type in
        design|architecture)
            if [ $CLAUDE_PERCENT -lt 80 ]; then
                echo "🏗️ 架构设计任务"
                echo -e "   推荐: ${YELLOW}Claude Code${NC}"
                echo "   理由: Claude 最擅长复杂架构决策"
            else
                echo "🏗️ 架构设计任务"
                echo -e "   推荐: ${GREEN}Kimi${NC} (Claude Code 配额紧张)"
                echo "   理由: Kimi 长上下文也能处理架构分析"
            fi
            ;;
        code|implement)
            echo "💻 代码实现任务"
            echo -e "   推荐: ${GREEN}DeepSeek${NC}"
            echo "   理由: 编码能力强，成本低，无限制"
            ;;
        test)
            echo "🧪 测试生成任务"
            echo -e "   推荐: ${GREEN}GLM${NC}"
            echo "   理由: 测试生成质量好，速度快"
            ;;
        doc|document)
            echo "📝 文档生成任务"
            echo -e "   推荐: ${GREEN}Kimi${NC}"
            echo "   理由: 长上下文，中文好，文档理解强"
            ;;
        review)
            echo "🔍 代码审查任务"
            if [ $CLAUDE_PERCENT -lt 70 ]; then
                echo -e "   推荐: ${YELLOW}Claude Code${NC} (关键代码)"
                echo -e "   或: ${GREEN}DeepSeek${NC} (常规代码)"
            else
                echo -e "   推荐: ${GREEN}DeepSeek${NC}"
                echo "   理由: Claude Code 配额紧张，DeepSeek 也能做好审查"
            fi
            ;;
        *)
            echo "📋 常规任务"
            echo -e "   推荐: ${GREEN}DeepSeek${NC}"
            echo "   理由: 通用性强，成本低"
            ;;
    esac
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 设置预算提醒
set_budget_alert() {
    local threshold=$1
    
    echo "🔔 设置预算提醒: Claude Code 使用超过 $threshold%"
    
    # 创建 cron 任务检查 (简化示例)
    CRON_JOB="0 */1 * * * $PROJECT_ROOT/Git-Hooks/token-budget-manager.sh check-alert $threshold"
    
    # 提示用户手动添加
    echo "请将以下内容添加到 crontab:"
    echo "$CRON_JOB"
    echo ""
    echo "运行: crontab -e"
}

# 检查并发送提醒
check_alert() {
    local threshold=$1
    
    CLAUDE_USED=$(grep -A 5 "^claude_code:" "$STATS_FILE" | grep "used:" | awk '{print $2}')
    CLAUDE_LIMIT=$(grep -A 5 "^claude_code:" "$STATS_FILE" | grep "daily_limit:" | awk '{print $2}')
    CLAUDE_PERCENT=$((CLAUDE_USED * 100 / CLAUDE_LIMIT))
    
    if [ $CLAUDE_PERCENT -ge $threshold ]; then
        # 发送通知 (使用 notify-send 或其他方式)
        if command -v notify-send &> /dev/null; then
            notify-send "Token 预算提醒" "Claude Code 已使用 $CLAUDE_PERCENT%\n建议切换到 DeepSeek/Kimi"
        fi
        
        echo -e "${YELLOW}⚠️  Claude Code 已使用 $CLAUDE_PERCENT%${NC}"
        echo "建议切换到 DeepSeek/Kimi 以节省配额"
    fi
}

# 主命令
case "${1:-stats}" in
    init)
        init_stats
        ;;
    stats|show)
        show_stats
        ;;
    record)
        record_usage "$2" "$3"
        ;;
    suggest)
        suggest_model "$2"
        ;;
    alert)
        set_budget_alert "$2"
        ;;
    check-alert)
        check_alert "$2"
        ;;
    reset)
        TODAY=$(date +%Y-%m-%d)
        sed -i "s/used: [0-9]*/used: 0/g" "$STATS_FILE"
        sed -i "s/last_reset: .*/last_reset: $TODAY/" "$STATS_FILE"
        echo "✅ 统计已重置"
        ;;
    *)
        echo "Token 预算管理器"
        echo ""
        echo "使用方法: $0 <command>"
        echo ""
        echo "命令:"
        echo "  init              初始化统计文件"
        echo "  stats             显示统计信息"
        echo "  record <model> <tokens>   记录使用"
        echo "  suggest <task>    获取模型建议"
        echo "  alert <percent>   设置预算提醒"
        echo "  check-alert <percent>   检查并发送提醒"
        echo "  reset             重置统计"
        ;;
esac
