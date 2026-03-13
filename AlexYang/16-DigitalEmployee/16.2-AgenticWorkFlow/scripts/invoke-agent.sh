#!/bin/bash
# ═══════════════════════════════════════════════════════
# 16.2 Orchestrator — 调用其他 Claude Code Agent
#
# 使用 claude-switch 调度:
#   - 最复杂任务 (16.3 设计): claude-switch anthropic enable_dangerous_mode
#   - 其他 Agent:             claude-switch kimi enable_dangerous_mode
#
# 用法: ./invoke-agent.sh <agent_id> <case_id> [prompt_override]
# 示例: ./invoke-agent.sh 16.1 122
#        ./invoke-agent.sh 16.3 125
#        ./invoke-agent.sh 16.4.3 121
# ═══════════════════════════════════════════════════════

set -euo pipefail

AGENT_ID="${1:?用法: $0 <agent_id> <case_id>}"
CASE_ID="${2:?用法: $0 <agent_id> <case_id>}"
PROMPT_OVERRIDE="${3:-}"

BASE_DIR="/mnt/e/10.Project"
ORCH_DIR="$BASE_DIR/16-DigitalEmployee/16.2-AgenticWorkFlow"
QUEUE_OUT="$ORCH_DIR/queue/outbox"
QUEUE_IN="$ORCH_DIR/queue/inbox"
LOG_DIR="$ORCH_DIR/logs"

# ── Agent 目录映射 ──
declare -A AGENT_DIRS=(
    ["16.1"]="$BASE_DIR/16.1-AndroidToHarmonyOSDemo"
    ["16.3"]="$BASE_DIR/16.3-Adapter.Requirement"
    ["16.4.1"]="$BASE_DIR/16.4.1-JIT.Performance"
    ["16.4.2"]="$BASE_DIR/16.4.2-Activity.Bridge"
    ["16.4.3"]="$BASE_DIR/16.4.3-View.Bridge"
    ["16.4.4"]="$BASE_DIR/16.4.4-System.Bridge"
    ["16.4.5"]="$BASE_DIR/16.4.5-JNI.Runtime"
    ["16.4.6"]="$BASE_DIR/16.4.6-Concurrency"
    ["16.4.9"]="$BASE_DIR/16.4.9-ThirdParty.Adapter"
    ["16.6"]="$BASE_DIR/16.6-Adapter.Test"
)

# ── Provider 分配: 哪些 Agent 用 anthropic，哪些用 kimi ──
# 16.3 (适配设计) 是最复杂的，需要全局 API 分析 + 架构决策 → anthropic
# 其他 Agent 执行具体任务 → kimi (省额度)
declare -A AGENT_PROVIDER=(
    ["16.1"]="kimi"
    ["16.3"]="anthropic"    # ← 最复杂: 全局设计决策
    ["16.4.1"]="kimi"
    ["16.4.2"]="kimi"
    ["16.4.3"]="kimi"
    ["16.4.4"]="kimi"
    ["16.4.5"]="kimi"
    ["16.4.6"]="kimi"
    ["16.4.9"]="kimi"
    ["16.6"]="kimi"
)

# ── Agent 默认 prompt 模板 ──
declare -A AGENT_PROMPTS=(
    ["16.1"]="分析案例 16.1.CASE_ID 的 Android 源码，产出 analysis/api-manifest.yaml。严格按照 CLAUDE.md 中的输出要求执行。"
    ["16.3"]="为案例 16.1.CASE_ID 设计适配策略，产出 mapping/design-report.yaml。读取 analysis/api-manifest.yaml 作为输入。基于全局 API 图谱做设计决策。"
    ["16.4.2"]="根据任务文件完成 Activity Bridge 实现。代码写入 05-Implementation/，测试写入 06-Test/。提交结果到 inbox。"
    ["16.4.3"]="根据任务文件完成 View Bridge 实现。代码写入 05-Implementation/，测试写入 06-Test/。提交结果到 inbox。"
    ["16.4.4"]="根据任务文件完成 System Bridge 实现。代码写入 05-Implementation/，测试写入 06-Test/。提交结果到 inbox。"
    ["16.4.6"]="根据任务文件完成 Concurrency Bridge 实现。代码写入 05-Implementation/，测试写入 06-Test/。提交结果到 inbox。"
    ["16.6"]="对案例 16.1.CASE_ID 执行 E2E 体验对比。需要运行仿真器，截屏，产出 comparison-report.yaml。无截屏不得标记 PASS。"
)

# ── 预检查 ──
AGENT_DIR="${AGENT_DIRS[$AGENT_ID]:-}"
if [ -z "$AGENT_DIR" ]; then
    echo "❌ 未知 Agent: $AGENT_ID"
    echo "可用: ${!AGENT_DIRS[*]}"
    exit 1
fi

if [ ! -d "$AGENT_DIR" ]; then
    echo "❌ Agent 目录不存在: $AGENT_DIR"
    exit 1
fi

# ── 检查 CLAUDE.md ──
if [ ! -f "$AGENT_DIR/CLAUDE.md" ]; then
    echo "⚠️  $AGENT_DIR/CLAUDE.md 不存在"
    echo "请从 $ORCH_DIR/agent-templates/ 复制对应模板"
    exit 1
fi

# ── 确定 provider ──
PROVIDER="${AGENT_PROVIDER[$AGENT_ID]:-kimi}"

# ── 构造 prompt ──
if [ -n "$PROMPT_OVERRIDE" ]; then
    PROMPT="$PROMPT_OVERRIDE"
else
    PROMPT="${AGENT_PROMPTS[$AGENT_ID]:-请根据 CLAUDE.md 中的职责定义完成任务。}"
    PROMPT="${PROMPT//CASE_ID/$CASE_ID}"
fi

# 如果有任务文件，追加到 prompt
TASK_FILE="$QUEUE_OUT/to-${AGENT_ID}-task-${CASE_ID}.yaml"
if [ -f "$TASK_FILE" ]; then
    TASK_CONTENT=$(cat "$TASK_FILE")
    PROMPT="$PROMPT

任务详情:
$TASK_CONTENT"
fi

# 追加结果文件要求
PROMPT="$PROMPT

完成后将结果写入: $QUEUE_IN/${AGENT_ID}-result-${CASE_ID}.yaml"

# ── 确保目录存在 ──
mkdir -p "$QUEUE_IN" "$LOG_DIR"

# ── 调用 Agent ──
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_DIR/agent-${AGENT_ID}-case-${CASE_ID}-${TIMESTAMP}.log"

echo "═══════════════════════════════════════"
echo "16.2 Orchestrator → $AGENT_ID"
echo "案例: 16.1.$CASE_ID"
echo "Provider: $PROVIDER"
echo "工作目录: $AGENT_DIR"
echo "日志: $LOG_FILE"
echo "═══════════════════════════════════════"

# 进入 Agent 工作目录，用 claude-switch 启动
cd "$AGENT_DIR"
claude-switch "$PROVIDER" enable_dangerous_mode -p "$PROMPT" \
    2>&1 | tee "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

# ── 检查结果 ──
RESULT_FILE="$QUEUE_IN/${AGENT_ID}-result-${CASE_ID}.yaml"

echo ""
echo "═══════════════════════════════════════"
echo "Provider: $PROVIDER | Agent: $AGENT_ID | 案例: $CASE_ID"
if [ $EXIT_CODE -eq 0 ]; then
    if [ -f "$RESULT_FILE" ]; then
        echo "✅ 完成，结果: $RESULT_FILE"
    else
        echo "⚠️  退出正常，但未产出结果文件"
        echo "   预期: $RESULT_FILE"
        echo "   → Orchestrator 需实物验证交付物"
    fi
else
    echo "❌ 执行失败 (exit $EXIT_CODE)"
    echo "   日志: $LOG_FILE"
fi
echo "═══════════════════════════════════════"
