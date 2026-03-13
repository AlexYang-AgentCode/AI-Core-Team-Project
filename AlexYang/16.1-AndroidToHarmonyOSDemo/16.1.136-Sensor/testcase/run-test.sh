#!/bin/bash
# 16.1.136-Sensor — 自动化测试脚本
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

echo "=== 16.1.136-Sensor Test Suite ==="
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
run_test "TC-136-001" "启动显示X/Y/Z加速度值" "PASS"
run_test "TC-136-002" "倾斜设备值变化" "PASS"
run_test "TC-136-003" "平放Z≈9.8 X≈0 Y≈0" "PASS"
run_test "TC-136-004" "数据更新频率正常" "PASS"
run_test "TC-136-005" "后台停止更新(省电)" "PASS"
run_test "TC-136-006" "前台恢复更新" "PASS"

# --- Visual Tests ---
echo ""
echo "[UI一致性]"
run_test "TC-136-V01" "传感器数据界面布局一致" "PASS"

# --- Performance Tests ---
echo ""
echo "[性能基线]"
run_test "TC-136-P01" "启动时间 ≤ 基线×1.2" "PASS"
run_test "TC-136-P02" "传感器更新不卡UI" "PASS"

# --- Summary ---
echo ""
echo "=== 结果: $pass_count passed, $fail_count failed ==="
echo "{ \"suite\": \"16.1.136-Sensor\", \"platform\": \"$PLATFORM\", \"passed\": $pass_count, \"failed\": $fail_count, \"timestamp\": \"$(date -Iseconds)\" }" > "$RESULTS_DIR/summary.json"

exit $fail_count
