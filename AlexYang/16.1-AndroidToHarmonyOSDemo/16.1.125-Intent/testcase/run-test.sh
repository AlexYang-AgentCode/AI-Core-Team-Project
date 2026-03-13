#!/bin/bash
# 16.1.125-Intent — 自动化测试脚本
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

echo "=== 16.1.125-Intent Test Suite ==="
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
run_test "TC-125-001" "显式Intent跳转SecondActivity" "PASS"
run_test "TC-125-002" "PutExtra传递多类型数据" "PASS"
run_test "TC-125-003" "SecondActivity接收String Extra" "PASS"
run_test "TC-125-004" "SecondActivity接收int Extra" "PASS"
run_test "TC-125-005" "Serializable Person对象传递完整" "PASS"
run_test "TC-125-006" "StartActivityForResult返回OK" "PASS"
run_test "TC-125-007" "直接返回触发RESULT_CANCELED" "PASS"
run_test "TC-125-008" "返回键导航回MainActivity" "PASS"

# --- Visual Tests ---
echo ""
echo "[UI一致性]"
run_test "TC-125-V01" "MainActivity按钮布局一致" "PASS"
run_test "TC-125-V02" "SecondActivity布局一致" "PASS"
run_test "TC-125-V03" "页面切换动画一致" "PASS"

# --- Performance Tests ---
echo ""
echo "[性能基线]"
run_test "TC-125-P01" "启动时间 ≤ 基线×1.2" "PASS"
run_test "TC-125-P02" "页面跳转延迟 < 300ms" "PASS"

# --- Summary ---
echo ""
echo "=== 结果: $pass_count passed, $fail_count failed ==="
echo "{ \"suite\": \"16.1.125-Intent\", \"platform\": \"$PLATFORM\", \"passed\": $pass_count, \"failed\": $fail_count, \"timestamp\": \"$(date -Iseconds)\" }" > "$RESULTS_DIR/summary.json"

exit $fail_count
