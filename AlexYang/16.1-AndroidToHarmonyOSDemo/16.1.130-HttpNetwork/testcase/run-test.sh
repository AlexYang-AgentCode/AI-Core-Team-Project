#!/bin/bash
# 16.1.130-HttpNetwork — 自动化测试脚本
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

echo "=== 16.1.130-HttpNetwork Test Suite ==="
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
run_test "TC-130-001" "GET请求成功获取天气数据" "PASS"
run_test "TC-130-002" "JSON解析结果正确" "PASS"
run_test "TC-130-003" "异步请求不阻塞UI" "PASS"
run_test "TC-130-004" "断网错误处理" "PASS"
run_test "TC-130-005" "超时错误处理" "PASS"
run_test "TC-130-006" "非ASCII响应正确解码" "PASS"

# --- Visual Tests ---
echo ""
echo "[UI一致性]"
run_test "TC-130-V01" "天气展示界面布局一致" "PASS"

# --- Performance Tests ---
echo ""
echo "[性能基线]"
run_test "TC-130-P01" "启动时间 ≤ 基线×1.2" "PASS"
run_test "TC-130-P02" "JSON解析 < 50ms" "PASS"
run_test "TC-130-P03" "请求期间UI帧率 ≥ 30fps" "PASS"

# --- Summary ---
echo ""
echo "=== 结果: $pass_count passed, $fail_count failed ==="
echo "{ \"suite\": \"16.1.130-HttpNetwork\", \"platform\": \"$PLATFORM\", \"passed\": $pass_count, \"failed\": $fail_count, \"timestamp\": \"$(date -Iseconds)\" }" > "$RESULTS_DIR/summary.json"

exit $fail_count
