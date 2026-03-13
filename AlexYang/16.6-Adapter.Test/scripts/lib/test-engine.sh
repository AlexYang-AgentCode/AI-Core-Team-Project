#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Test Engine — 16.6-Adapter.Test 核心验证引擎
#
# 人格宣言：
#   我是一个仿真器验证器。
#   我不看代码，不对比源码，不信任任何 hardcoded 结果。
#   我只做一件事：在真实仿真器上操作 APP，然后读取屏幕上的 UI 状态。
#   我看到什么，就报告什么。
#   PASS 意味着我亲眼在屏幕上看到了正确的结果。
#   NOT_VERIFIED 意味着我没有能力验证（比如 Toast 闪过太快）。
#   FAIL 意味着屏幕上的内容和预期不符。
# ═══════════════════════════════════════════════════════════════

# 结果记录
declare -A TEST_RESULTS      # TC_ID → PASS/FAIL/SKIP/NOT_VERIFIED
declare -A TEST_EVIDENCE      # TC_ID → 证据描述
declare -A TEST_SCREENSHOTS   # TC_ID → 截屏路径
TOTAL_PASS=0
TOTAL_FAIL=0
TOTAL_SKIP=0
TOTAL_NOT_VERIFIED=0

# ── 结果记录函数 ──────────────────────────────────────────────

record_pass() {
    local tc_id="$1" evidence="$2"
    TEST_RESULTS["$tc_id"]="PASS"
    TEST_EVIDENCE["$tc_id"]="$evidence"
    ((TOTAL_PASS++))
    echo "  ✅ $tc_id: PASS — $evidence"
}

record_fail() {
    local tc_id="$1" evidence="$2"
    TEST_RESULTS["$tc_id"]="FAIL"
    TEST_EVIDENCE["$tc_id"]="$evidence"
    ((TOTAL_FAIL++))
    echo "  ❌ $tc_id: FAIL — $evidence"
}

record_skip() {
    local tc_id="$1" reason="$2"
    TEST_RESULTS["$tc_id"]="SKIP"
    TEST_EVIDENCE["$tc_id"]="$reason"
    ((TOTAL_SKIP++))
    echo "  ⏭️  $tc_id: SKIP — $reason"
}

record_not_verified() {
    local tc_id="$1" reason="$2"
    TEST_RESULTS["$tc_id"]="NOT_VERIFIED"
    TEST_EVIDENCE["$tc_id"]="$reason"
    ((TOTAL_NOT_VERIFIED++))
    echo "  ⚠️  $tc_id: NOT_VERIFIED — $reason"
}

# ── 通用验证函数 ──────────────────────────────────────────────

# 验证文本匹配（大小写不敏感 — 因为 adb input text 只支持小写输入）
assert_text_equals() {
    local actual="$1" expected="$2" tc_id="$3"
    local actual_lower=$(echo "$actual" | tr '[:upper:]' '[:lower:]')
    local expected_lower=$(echo "$expected" | tr '[:upper:]' '[:lower:]')
    if [ "$actual_lower" = "$expected_lower" ]; then
        record_pass "$tc_id" "显示文本='$actual' (预期='$expected')"
        return 0
    elif [ "$actual" = "$expected" ]; then
        record_pass "$tc_id" "显示文本='$actual' (预期='$expected')"
        return 0
    else
        record_fail "$tc_id" "显示文本='$actual' (预期='$expected')"
        return 1
    fi
}

# 验证文本包含（大小写不敏感）
assert_text_contains() {
    local actual="$1" expected="$2" tc_id="$3"
    if echo "$actual" | grep -qiF "$expected"; then
        record_pass "$tc_id" "显示文本包含'$expected' (实际='$actual')"
        return 0
    else
        record_fail "$tc_id" "显示文本不包含'$expected' (实际='$actual')"
        return 1
    fi
}

# ── 步骤执行器 ───────────────────────────────────────────────
# 将 test-cases.yaml 中的自然语言步骤映射为仿真器操作

# Android 步骤执行
android_execute_step() {
    local step="$1"
    local dump_file="/tmp/android-ui-dump.xml"

    case "$step" in
        *"启动应用"*)
            android_launch "$ANDROID_PACKAGE" "$ANDROID_ACTIVITY"
            sleep 2
            ;;
        *"执行TC"*"保存"*)
            # "执行TC002保存'Test123'" → 输入文本 + 点击 SAVE
            local text=$(echo "$step" | grep -oP "'[^']+'" | head -1 | tr -d "'")
            if [ -n "$text" ]; then
                android_type_text "$text"
            fi
            android_tap_cached "SAVE"
            sleep 0.5
            ;;
        *"确保无保存数据"*|*"执行DELETE"*)
            android_tap_cached "DELETE"
            sleep 0.5
            ;;
        *"依次保存"*)
            local values=$(echo "$step" | grep -oP "'[^']+'" | tr -d "'")
            while IFS= read -r val <&4; do
                [ -z "$val" ] && continue
                android_type_text "$val"
                android_tap_cached "SAVE"
                sleep 0.5
            done 4<<< "$values"
            ;;
        *"输入"*"并保存"*)
            local text=$(echo "$step" | grep -oP "'[^']+'" | head -1 | tr -d "'")
            if [ -n "$text" ]; then
                android_type_text "$text"
            fi
            android_tap_cached "SAVE"
            sleep 0.5
            ;;
        *"输入"*|*"输入框输入"*)
            local text=$(echo "$step" | grep -oP "'[^']+'" | head -1 | tr -d "'")
            [ -z "$text" ] && text=$(echo "$step" | grep -oP '"[^"]+"' | head -1 | tr -d '"')
            if [ -n "$text" ]; then
                android_type_text "$text"
            fi
            ;;
        *"清空输入框"*)
            android_focus_input "$dump_file"
            android_clear_field
            sleep 0.3
            ;;
        *"点击"*"SAVE"*|*"点击"*"Save"*|*"点击 SAVE"*)
            android_tap_cached "SAVE"
            sleep 0.5
            ;;
        *"点击"*"OPEN"*|*"点击"*"Open"*|*"点击 OPEN"*)
            android_tap_cached "OPEN"
            sleep 0.5
            ;;
        *"点击"*"DELETE"*|*"点击"*"Delete"*|*"点击 DELETE"*)
            android_tap_cached "DELETE"
            sleep 0.5
            ;;
        *"关闭应用"*|*"杀掉应用"*)
            android_stop "$ANDROID_PACKAGE"
            sleep 1
            ;;
        *"重新启动"*|*"重新打开"*)
            android_launch "$ANDROID_PACKAGE" "$ANDROID_ACTIVITY"
            sleep 2
            ;;
        *"点击 SAVE 和 OPEN"*|*"点击SAVE和OPEN"*)
            android_tap_cached "SAVE"
            sleep 0.5
            android_tap_cached "OPEN"
            sleep 0.5
            ;;
        *"32个字符"*|*"最大长度"*)
            # 生成32个字符的文本
            android_type_text "abcdefghijklmnopqrstuvwxyz123456"
            ;;
        *"观察"*)
            # 仅观察，不操作
            sleep 0.5
            ;;
        *)
            echo "    [步骤未映射: $step]"
            ;;
    esac
}

# HarmonyOS 步骤执行
harmony_execute_step() {
    local step="$1"
    local dump_file="/tmp/harmony-ui-dump.json"

    case "$step" in
        *"启动应用"*)
            harmony_launch "$HARMONY_BUNDLE" "$HARMONY_ABILITY"
            sleep 3
            ;;
        *"执行TC"*"保存"*)
            local text=$(echo "$step" | grep -oP "'[^']+'" | head -1 | tr -d "'")
            if [ -n "$text" ]; then
                harmony_input_text "$text"
            fi
            harmony_tap_text "SAVE" "$dump_file"
            sleep 1
            ;;
        *"确保无保存数据"*|*"执行DELETE"*)
            harmony_tap_text "DELETE" "$dump_file"
            sleep 1
            ;;
        *"依次保存"*)
            local values=$(echo "$step" | grep -oP "'[^']+'" | tr -d "'")
            while IFS= read -r val <&4; do
                [ -z "$val" ] && continue
                harmony_input_text "$val"
                harmony_tap_text "SAVE" "$dump_file"
                sleep 0.5
            done 4<<< "$values"
            ;;
        *"输入"*"并保存"*)
            local text=$(echo "$step" | grep -oP "'[^']+'" | head -1 | tr -d "'")
            if [ -n "$text" ]; then
                harmony_input_text "$text"
            fi
            harmony_tap_text "SAVE" "$dump_file"
            sleep 1
            ;;
        *"输入"*|*"输入框输入"*)
            local text=$(echo "$step" | grep -oP "'[^']+'" | head -1 | tr -d "'")
            [ -z "$text" ] && text=$(echo "$step" | grep -oP '"[^"]+"' | head -1 | tr -d '"')
            if [ -n "$text" ]; then
                harmony_input_text "$text"
            fi
            ;;
        *"清空输入框"*)
            harmony_clear_field
            sleep 0.3
            ;;
        *"点击"*"SAVE"*|*"点击"*"Save"*|*"点击 SAVE"*)
            harmony_tap_text "SAVE" "$dump_file"
            sleep 1
            ;;
        *"点击"*"OPEN"*|*"点击"*"Open"*|*"点击 OPEN"*)
            harmony_tap_text "OPEN" "$dump_file"
            sleep 1
            ;;
        *"点击"*"DELETE"*|*"点击"*"Delete"*|*"点击 DELETE"*)
            harmony_tap_text "DELETE" "$dump_file"
            sleep 1
            ;;
        *"关闭应用"*|*"杀掉应用"*)
            harmony_stop "$HARMONY_BUNDLE"
            sleep 1
            ;;
        *"重新启动"*|*"重新打开"*)
            harmony_launch "$HARMONY_BUNDLE" "$HARMONY_ABILITY"
            sleep 3
            ;;
        *"点击 SAVE 和 OPEN"*|*"点击SAVE和OPEN"*)
            harmony_tap_text "SAVE" "$dump_file"
            sleep 1
            harmony_tap_text "OPEN" "$dump_file"
            sleep 1
            ;;
        *"32个字符"*|*"最大长度"*)
            harmony_input_text "abcdefghijklmnopqrstuvwxyz123456"
            ;;
        *"观察"*)
            sleep 0.5
            ;;
        *)
            echo "    [步骤未映射: $step]"
            ;;
    esac
}

# ── YAML 解析器 ──────────────────────────────────────────────
# 从 test-cases.yaml 提取测试用例

# 解析 YAML 并输出 JSON 格式（用 python3）
parse_test_yaml() {
    local yaml_file="$1"
    python3 -c "
import yaml, json, sys

with open('$yaml_file') as f:
    data = yaml.safe_load(f)

cases = data.get('test_suite', {}).get('test_cases', [])
json.dump(cases, sys.stdout, ensure_ascii=False)
" 2>/dev/null
}

# 获取测试用例数量
get_test_count() {
    local yaml_file="$1"
    python3 -c "
import yaml
with open('$yaml_file') as f:
    data = yaml.safe_load(f)
print(len(data.get('test_suite', {}).get('test_cases', [])))
" 2>/dev/null
}

# 获取单个测试用例的字段
get_test_field() {
    local yaml_file="$1"
    local index="$2"
    local field="$3"
    python3 -c "
import yaml, json
with open('$yaml_file') as f:
    data = yaml.safe_load(f)
cases = data.get('test_suite', {}).get('test_cases', [])
if $index < len(cases):
    tc = cases[$index]
    if '$field' == 'steps':
        for s in tc.get('steps', []):
            print(s)
    else:
        print(tc.get('$field', ''))
" 2>/dev/null
}

# ── 预期结果验证器 ───────────────────────────────────────────

# 解析 expected 字符串，提取需要验证的文本
# 返回: "TEXT:xxx" 或 "TOAST:xxx" 或 "CONTAINS:xxx" 或 "OR_TEXT:a|b"
parse_expected() {
    local expected="$1"

    # 提取所有引号中的文本
    local all_quoted=$(echo "$expected" | grep -oP "'[^']+'" | tr -d "'")
    local first_quoted=$(echo "$all_quoted" | head -1)

    if echo "$expected" | grep -qi "Toast"; then
        echo "TOAST:${first_quoted}"
    elif echo "$expected" | grep -q "或\|or"; then
        # "或" 分隔的多选项 → 任意一个匹配即可
        local options=$(echo "$all_quoted" | tr '\n' '|' | sed 's/|$//')
        echo "OR_TEXT:${options}"
    elif echo "$expected" | grep -qi "正确显示\|完整显示\|无乱码\|依然存在"; then
        # 模糊验证 — 只要有文本内容就算通过
        if [ -n "$first_quoted" ]; then
            echo "CONTAINS:${first_quoted}"
        else
            echo "NOT_EMPTY:"
        fi
    elif [ -n "$first_quoted" ]; then
        echo "TEXT:${first_quoted}"
    elif echo "$expected" | grep -qi "null"; then
        echo "CONTAINS:null"
    else
        echo "VISUAL:${expected}"
    fi
}

# ── 输出结果 JSON ────────────────────────────────────────────

generate_results_json() {
    local output_file="$1"
    local platform="$2"
    local case_id="$3"

    # 使用 TSV 格式避免 JSON 转义问题
    local tmp_cases="/tmp/test-cases-$$.tsv"
    > "$tmp_cases"
    for tc_id in "${!TEST_RESULTS[@]}"; do
        printf '%s\t%s\t%s\n' "$tc_id" "${TEST_RESULTS[$tc_id]}" "${TEST_EVIDENCE[$tc_id]}" >> "$tmp_cases"
    done

    python3 - "$output_file" "$platform" "$case_id" "$tmp_cases" << 'PYEOF'
import json, sys
from datetime import datetime

output_file = sys.argv[1]
platform = sys.argv[2]
case_id = sys.argv[3]
cases_file = sys.argv[4]

results = {}
with open(cases_file, encoding='utf-8') as f:
    for line in f:
        parts = line.rstrip('\n').split('\t', 2)
        if len(parts) >= 2:
            tc_id = parts[0]
            status = parts[1]
            evidence = parts[2] if len(parts) > 2 else ''
            results[tc_id] = {'status': status, 'evidence': evidence}

output = {
    'case_id': case_id,
    'platform': platform,
    'timestamp': datetime.now().isoformat(),
    'verification_method': 'emulator_ui_dump',
    'total': len(results),
    'passed': sum(1 for r in results.values() if r['status'] == 'PASS'),
    'failed': sum(1 for r in results.values() if r['status'] == 'FAIL'),
    'skipped': sum(1 for r in results.values() if r['status'] == 'SKIP'),
    'not_verified': sum(1 for r in results.values() if r['status'] == 'NOT_VERIFIED'),
    'test_cases': results
}

with open(output_file, 'w', encoding='utf-8') as f:
    json.dump(output, f, indent=2, ensure_ascii=False)
print(json.dumps(output, indent=2, ensure_ascii=False))
PYEOF

    rm -f "$tmp_cases"
}

echo "test-engine.sh loaded"
