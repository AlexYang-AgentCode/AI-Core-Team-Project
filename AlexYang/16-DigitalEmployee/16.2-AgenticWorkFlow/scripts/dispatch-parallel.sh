#!/bin/bash
# ═══════════════════════════════════════════════════════
# 16.2 Orchestrator — 并行调度多个 Agent
# 用法: ./dispatch-parallel.sh <case_id>
#
# 读取案例的 design-report.yaml，
# 找出所有需要的 Bridge Agent，并行启动它们。
# ═══════════════════════════════════════════════════════

set -euo pipefail

CASE_ID="${1:?用法: $0 <case_id>}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ORCH_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="/mnt/e/10.Project"

# 找到案例目录
CASE_DIR=$(find "$BASE_DIR/16.1-AndroidToHarmonyOSDemo" -maxdepth 1 -type d -name "16.1.${CASE_ID}-*" | head -1)
if [ -z "$CASE_DIR" ]; then
    echo "❌ 案例 16.1.$CASE_ID 不存在"
    exit 1
fi

DESIGN_FILE="$CASE_DIR/mapping/design-report.yaml"
if [ ! -f "$DESIGN_FILE" ]; then
    echo "❌ 设计报告不存在: $DESIGN_FILE"
    echo "请先执行: /wf-design-adapter $CASE_ID"
    exit 1
fi

# 提取需要的 Bridge Agent 列表 (去重)
AGENTS=$(grep "bridge_agent:" "$DESIGN_FILE" | grep -oP '"16\.4\.\d+"' | sort -u | tr -d '"')

if [ -z "$AGENTS" ]; then
    echo "ℹ️  案例 $CASE_ID 全部 DIRECT_MAP，无需 Bridge Agent"
    exit 0
fi

echo "═══════════════════════════════════════"
echo "并行调度 — 案例 16.1.$CASE_ID"
# Provider 映射 (与 invoke-agent.sh 一致)
declare -A AGENT_PROVIDER=(
    ["16.3"]="anthropic"
)

echo "需要的 Bridge Agents:"
echo "$AGENTS" | while read agent; do
    provider="${AGENT_PROVIDER[$agent]:-kimi}"
    echo "  → $agent ($provider)"
done
echo "═══════════════════════════════════════"

# 并行启动所有 Agent
PIDS=()
for AGENT in $AGENTS; do
    provider="${AGENT_PROVIDER[$AGENT]:-kimi}"
    echo "🚀 启动 $AGENT ($provider) ..."
    "$SCRIPT_DIR/invoke-agent.sh" "$AGENT" "$CASE_ID" &
    PIDS+=($!)
done

echo ""
echo "⏳ 等待 ${#PIDS[@]} 个 Agent 完成..."

# 等待所有完成
FAILED=0
for PID in "${PIDS[@]}"; do
    if ! wait "$PID"; then
        ((FAILED++))
    fi
done

echo ""
echo "═══════════════════════════════════════"
if [ "$FAILED" -eq 0 ]; then
    echo "✅ 所有 Agent 完成"
    echo "下一步: /wf-check-deliverable $CASE_ID"
else
    echo "⚠️  $FAILED 个 Agent 失败"
    echo "检查日志: $ORCH_DIR/logs/agent-*-case-${CASE_ID}-*.log"
fi
echo "═══════════════════════════════════════"
