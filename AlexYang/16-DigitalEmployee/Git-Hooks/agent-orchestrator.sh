#!/bin/bash

# Agent 编排器 - 自动选择最佳模型并启动任务
# 使用方法: ./agent-orchestrator.sh <task-type> <input-file> [options]

set -e

# 颜色输出
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 帮助信息
show_help() {
    echo "🤖 Agent 编排器 - 智能模型选择"
    echo ""
    echo "使用方法: $0 <task-type> <input> [options]"
    echo ""
    echo "任务类型:"
    echo "  design    架构设计 (Claude Code)"
    echo "  code      代码生成 (DeepSeek)"
    echo "  test      测试生成 (GLM)"
    echo "  doc       文档生成 (Kimi)"
    echo "  review    代码审查 (Claude Code/DeepSeek)"
    echo "  analyze   需求分析 (Kimi)"
    echo "  refactor  代码重构 (GLM)"
    echo "  audit     安全审计 (Claude Code)"
    echo ""
    echo "选项:"
    echo "  --project <name>     指定项目名称"
    echo "  --model <model>      强制指定模型"
    echo "  --interactive        交互模式 (等待用户输入)"
    echo "  --dry-run            只显示将执行的命令，不实际执行"
    echo ""
    echo "示例:"
    echo "  $0 design requirement.md"
    echo "  $0 code architecture.md --project 16.1-AndroidToHarmonyOS"
    echo "  $0 test auth-module.py --interactive"
}

# 检查参数
if [ $# -lt 2 ]; then
    show_help
    exit 1
fi

TASK_TYPE=$1
INPUT=$2
shift 2

# 解析选项
PROJECT=""
MODEL_OVERRIDE=""
INTERACTIVE=false
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --project)
            PROJECT="$2"
            shift 2
            ;;
        --model)
            MODEL_OVERRIDE="$2"
            shift 2
            ;;
        --interactive)
            INTERACTIVE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# 检查输入文件
if [ ! -f "$INPUT" ]; then
    echo -e "${RED}❌ 输入文件不存在: $INPUT${NC}"
    exit 1
fi

# ============================================
# 模型选择策略
# ============================================

select_model() {
    local task=$1
    
    case $task in
        design)
            echo "claude-code"
            ;;
        code)
            echo "opencode:deepseek-coder"
            ;;
        test)
            echo "opencode:glm-4"
            ;;
        doc)
            echo "opencode:kimi-k2"
            ;;
        review)
            # 根据文件大小决定
            local size=$(wc -c < "$INPUT")
            if [ $size -gt 10000 ]; then
                echo "opencode:deepseek-coder"
            else
                echo "claude-code"
            fi
            ;;
        analyze)
            echo "opencode:kimi-k2"
            ;;
        refactor)
            echo "opencode:glm-4"
            ;;
        audit)
            echo "claude-code"
            ;;
        *)
            echo "opencode"
            ;;
    esac
}

# ============================================
# 构建 Prompt
# ============================================

build_prompt() {
    local task=$1
    local input=$2
    local project=$3
    
    local content=$(cat "$input")
    
    case $task in
        design)
            echo "基于以下需求，设计系统架构：

$content

请提供：
1. 系统架构图 (ASCII 或描述)
2. 模块划分和职责
3. 数据流设计
4. 技术选型建议
5. 潜在风险和缓解策略"
            ;;
        code)
            echo "基于以下设计文档，生成代码：

$content

要求：
- 代码质量高 (符合最佳实践)
- 包含错误处理
- 添加适当注释
- 模块化设计"
            ;;
        test)
            echo "为以下代码生成测试用例：

$content

要求：
- 单元测试覆盖主要功能
- 包含边界条件测试
- 使用 pytest 框架
- 目标覆盖率 > 80%"
            ;;
        doc)
            echo "为以下内容生成文档：

$content

要求：
- Markdown 格式
- 包含使用示例
- API 文档详细
- 清晰的结构"
            ;;
        review)
            echo "审查以下代码：

$content

检查项：
- 代码质量
- 潜在Bug
- 性能问题
- 安全隐患
- 改进建议"
            ;;
        analyze)
            echo "分析以下需求文档：

$content

请提供：
1. 需求摘要
2. 关键功能点
3. 技术难点
4. 任务拆解建议"
            ;;
        refactor)
            echo "重构以下代码：

$content

目标：
- 提高可读性
- 优化性能
- 减少重复
- 改善结构"
            ;;
        audit)
            echo "安全审计以下代码：

$content

检查项：
- OWASP Top 10
- 注入漏洞
- 认证授权
- 敏感数据处理
- 安全最佳实践"
            ;;
    esac
}

# ============================================
# 主逻辑
# ============================================

# 选择模型
if [ -n "$MODEL_OVERRIDE" ]; then
    SELECTED_MODEL="$MODEL_OVERRIDE"
else
    SELECTED_MODEL=$(select_model "$TASK_TYPE")
fi

echo -e "${BLUE}🤖 Agent 编排器${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "📋 任务类型: ${GREEN}$TASK_TYPE${NC}"
echo -e "📄 输入文件: $INPUT"

if [ -n "$PROJECT" ]; then
    echo -e "📁 项目: $PROJECT"
fi

echo -e "🤖 选择模型: ${YELLOW}$SELECTED_MODEL${NC}"
echo -e "🎯 交互模式: $INTERACTIVE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 构建 prompt
PROMPT=$(build_prompt "$TASK_TYPE" "$INPUT" "$PROJECT")

# 创建 Agent 状态文件
if [ -n "$PROJECT" ]; then
    STATUS_FILE="AGENT-STATUS.md"
    cat > "$STATUS_FILE" << EOF
---
tags:
  - agent/status
  - project/active
date: $(date +%Y-%m-%dT%H:%M:%S)
agent: $(echo $SELECTED_MODEL | cut -d: -f1)
model: $(echo $SELECTED_MODEL | cut -d: -f2)
project: $PROJECT
status: running
---

# Agent 状态

## 当前任务
- **类型**: $TASK_TYPE
- **项目**: $PROJECT
- **状态**: 🟢 运行中
- **启动时间**: $(date +%Y-%m-%dT%H:%M:%S)

## 输入
\`\`\`
$INPUT
\`\`\`

## 等待用户输入
*无*

## 统计
- **运行时长**: 刚启动

---
*Agent 状态由编排器自动维护*
EOF
    echo "✅ Agent 状态文件已创建: $STATUS_FILE"
fi

# 执行任务
if [ "$DRY_RUN" = true ]; then
    echo -e "${YELLOW}🔍 Dry-run 模式，显示将执行的命令:${NC}"
    echo ""
    
    if [[ "$SELECTED_MODEL" == "claude-code" ]]; then
        echo "claude-code"
        echo ">>> $PROMPT"
    elif [[ "$SELECTED_MODEL" == opencode:* ]]; then
        MODEL=$(echo "$SELECTED_MODEL" | cut -d: -f2)
        echo "opencode --model $MODEL"
        echo ">>> $PROMPT"
    else
        echo "$SELECTED_MODEL"
        echo ">>> $PROMPT"
    fi
else
    echo -e "${GREEN}▶️  开始执行任务...${NC}"
    echo ""
    
    if [[ "$SELECTED_MODEL" == "claude-code" ]]; then
        # 使用 Claude Code
        echo "$PROMPT" | claude-code
        
    elif [[ "$SELECTED_MODEL" == opencode:* ]]; then
        # 使用 OpenCode
        MODEL=$(echo "$SELECTED_MODEL" | cut -d: -f2)
        
        if [ "$INTERACTIVE" = true ]; then
            # 交互模式
            opencode --model "$MODEL"
            echo "$PROMPT"
        else
            # 自动模式
            echo "$PROMPT" | opencode --model "$MODEL"
        fi
    else
        # 直接使用命令
        echo "$PROMPT" | $SELECTED_MODEL
    fi
    
    # 更新状态为完成
    if [ -n "$PROJECT" ] && [ -f "$STATUS_FILE" ]; then
        sed -i "s/status: running/status: completed/" "$STATUS_FILE"
        echo ""
        echo "✅ Agent 状态已更新: completed"
    fi
fi

echo ""
echo -e "${GREEN}✅ 任务完成${NC}"
