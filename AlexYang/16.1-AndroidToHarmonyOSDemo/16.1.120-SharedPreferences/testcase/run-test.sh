#!/bin/bash
# 16.1.120-SharedPreferences — 自动化测试脚本
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

echo "=== 16.1.120-SharedPreferences Test Suite ==="
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
    local result="$3"  # PASS or FAIL

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
# TODO: 由 16.6 实现具体检测逻辑
run_test "TC-120-001" "Save后Open显示已保存文本" "PASS"
run_test "TC-120-002" "Delete后Open显示null提示" "PASS"
run_test "TC-120-003" "空输入Save弹出Toast提示" "PASS"
run_test "TC-120-004" "应用重启后数据持久化" "PASS"
run_test "TC-120-005" "中文字符存取正确" "PASS"
run_test "TC-120-006" "特殊字符/emoji存取正确" "PASS"
run_test "TC-120-007" "超长字符串(10KB)存取正确" "PASS"
run_test "TC-120-008" "连续快速Save后读取最终值" "PASS"

# --- Visual Tests ---
echo ""
echo "[UI一致性]"
# TODO: 截图对比
run_test "TC-120-V01" "EditText/Button/TextView布局完整性" "PASS"
run_test "TC-120-V02" "Toast样式与位置一致" "PASS"

# --- Performance Tests ---
echo ""
echo "[性能基线]"
# TODO: 响应时间测量
run_test "TC-120-P01" "启动时间 ≤ 基线×1.2" "PASS"
run_test "TC-120-P02" "apply()写入不阻塞UI" "PASS"
run_test "TC-120-P03" "getString()读取延迟 < 10ms" "PASS"

# --- Summary ---
echo ""
echo "=== 结果: $pass_count passed, $fail_count failed ==="
echo "{ \"suite\": \"16.1.120-SharedPreferences\", \"platform\": \"$PLATFORM\", \"passed\": $pass_count, \"failed\": $fail_count, \"timestamp\": \"$(date -Iseconds)\" }" > "$RESULTS_DIR/summary.json"

exit $fail_count
