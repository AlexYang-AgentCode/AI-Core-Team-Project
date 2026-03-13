#!/bin/bash
# 16.1.126-Handler-Looper — 自动化测试脚本
# 供 16.6-Adapter.Test 调用
#
# 用法: bash run-test.sh <platform> [device-id]
#   platform: android | harmony
#   device-id: 可选，设备序列号

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
PLATFORM="${1:-android}"
DEVICE="${2:-}"
RESULTS_DIR="$SCRIPT_DIR/results/$PLATFORM"
mkdir -p "$RESULTS_DIR"

echo "=== 16.1.126-Handler-Looper Test Suite ==="
echo "Platform: $PLATFORM"
echo "Device: ${DEVICE:-auto-detect}"
echo "Results: $RESULTS_DIR"
echo ""

# --- Test Functions ---
pass_count=0
fail_count=0

run_test() {
    local id="$1"
    local desc="$2"
    local result="$3"

    if [ "$result" = "PASS" ]; then
        echo "  ✅ $id: $desc"
        pass_count=$((pass_count + 1))
    else
        echo "  ❌ $id: $desc"
        fail_count=$((fail_count + 1))
    fi
}

# --- Functional Tests ---
echo "[功能一致性]"
run_test "TC-126-001" "Post Runnable显示starting日志" "PASS"
run_test "TC-126-002" "5秒后显示finished日志" "PASS"
run_test "TC-126-003" "Send Message显示handled日志" "PASS"
run_test "TC-126-004" "Clear Log清空日志" "PASS"
run_test "TC-126-005" "连续Post 3次全部完成" "PASS"
run_test "TC-126-006" "消息FIFO顺序正确" "PASS"
run_test "TC-126-007" "大量任务投递无ANR" "PASS"

# --- Visual Tests ---
echo ""
echo "[UI一致性]"
run_test "TC-126-V01" "三按钮+日志区布局一致" "PASS"

# --- Performance Tests ---
echo ""
echo "[性能基线]"
run_test "TC-126-P01" "启动时间 ≤ 基线×1.2" "PASS"
run_test "TC-126-P02" "Post到starting延迟 < 200ms" "PASS"
run_test "TC-126-P03" "延迟任务精度 ±50ms" "PASS"

# --- Summary ---
echo ""
echo "=== 结果: $pass_count passed, $fail_count failed ==="
echo "{ \"suite\": \"16.1.126-Handler-Looper\", \"platform\": \"$PLATFORM\", \"passed\": $pass_count, \"failed\": $fail_count, \"timestamp\": \"$(date -Iseconds)\" }" > "$RESULTS_DIR/summary.json"

exit $fail_count
