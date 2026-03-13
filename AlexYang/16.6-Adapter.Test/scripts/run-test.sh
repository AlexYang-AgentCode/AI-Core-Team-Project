#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 16.6-Adapter.Test — 仿真器实机验证执行器
#
# 人格宣言：
#   我不是代码比对工具。我是一个坐在仿真器前面的测试员。
#   我启动 APP，我点击按钮，我读取屏幕。
#   我看到什么，就报告什么。
#   所有 PASS/FAIL 都有 UI dump 证据。
#
# 用法:
#   bash scripts/run-test.sh <case_id> [platform]
#   case_id:  120, 121 等 (对应 16.1.120, 16.1.121)
#   platform: android | harmony | both (默认 both)
#
# 测试用例来源：16.1 对应案例的 testcase/test-cases.yaml
# ═══════════════════════════════════════════════════════════════

set -uo pipefail
# 注意: 不用 set -e，因为测试失败(FAIL)不应中断执行
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 加载环境
source "$SCRIPT_DIR/env-setup.sh"

# 加载驱动
source "$SCRIPT_DIR/lib/android-driver.sh"
source "$SCRIPT_DIR/lib/harmony-driver.sh"
source "$SCRIPT_DIR/lib/test-engine.sh"

CASE_ID="${1:?用法: run-test.sh <case_id> [platform]}"
PLATFORM="${2:-both}"

# ── 查找 Demo 目录 ───────────────────────────────────────────

DEMO_DIR=$(find "$DEMO_ROOT" -maxdepth 1 -type d -name "16.1.${CASE_ID}-*" | head -1)
if [ -z "$DEMO_DIR" ]; then
    echo "ERROR: 找不到 16.1.${CASE_ID}-* 目录"
    exit 1
fi
DEMO_NAME=$(basename "$DEMO_DIR")

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  16.6-Adapter.Test — 仿真器实机验证                       ║"
echo "╠═══════════════════════════════════════════════════════════╣"
echo "║  案例: $DEMO_NAME"
echo "║  平台: $PLATFORM"
echo "║  验证方式: 仿真器 UI dump (不是代码比对)"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# ── 检查测试用例 YAML ────────────────────────────────────────

TEST_YAML="$DEMO_DIR/testcase/test-cases.yaml"
TEST_SPEC="$DEMO_DIR/testcase/TEST-SPEC.md"

if [ ! -f "$TEST_YAML" ]; then
    echo "ERROR: 找不到 $TEST_YAML"
    echo "16.6 只从 16.1 读取测试用例，不自己创造。"
    exit 1
fi
echo "测试用例: $TEST_YAML"
echo "测试规格: $TEST_SPEC"

# 检查 python3 和 pyyaml
if ! python3 -c "import yaml" 2>/dev/null; then
    echo "安装 PyYAML..."
    pip3 install pyyaml -q 2>/dev/null || pip install pyyaml -q 2>/dev/null
fi

TC_COUNT=$(get_test_count "$TEST_YAML")
echo "测试用例数: $TC_COUNT"
echo ""

# ── 创建报告目录 ─────────────────────────────────────────────

REPORT_DIR="$PROJECT_DIR/reports/16.1.${CASE_ID}"
mkdir -p "$REPORT_DIR"/{android,harmony}
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# ── 读取应用配置 ─────────────────────────────────────────────
# 从 Demo 目录中发现应用包名等信息

discover_app_info() {
    # Android 包名 — 从源代码的 package 声明获取
    ANDROID_PACKAGE=$(grep -r "^package " "$DEMO_DIR/src/"*.java 2>/dev/null | head -1 | sed 's/package //;s/;//;s/\r//')
    ANDROID_ACTIVITY=".MainActivity"

    # Android APK 路径
    ANDROID_APK=$(find "$DEMO_DIR" -name "*.apk" 2>/dev/null | head -1)

    # HarmonyOS bundle 名 — 从 harmony-app 的 app.json5 获取
    HARMONY_BUNDLE=$(grep -oP '"bundleName"\s*:\s*"[^"]*"' "$HARMONY_APP/AppScope/app.json5" 2>/dev/null \
        | head -1 | grep -oP '"[^"]*"$' | tr -d '"')
    HARMONY_ABILITY="EntryAbility"

    # HarmonyOS HAP 路径
    HARMONY_HAP=$(find "$HARMONY_APP" -path "*/default/entry-default-signed.hap" 2>/dev/null | head -1)

    echo "Android: package=$ANDROID_PACKAGE apk=$ANDROID_APK"
    echo "HarmonyOS: bundle=$HARMONY_BUNDLE hap=$HARMONY_HAP"
}

discover_app_info
echo ""

# ══════════════════════════════════════════════════════════════
# Android 实机验证
# ══════════════════════════════════════════════════════════════

run_android_verification() {
    echo "══════════════════════════════════════"
    echo "  Android 仿真器验证"
    echo "  设备: $(android_get_device)"
    echo "  验证方式: adb + uiautomator dump"
    echo "══════════════════════════════════════"

    if ! android_is_connected; then
        echo "SKIP: 没有 Android 设备连接"
        echo '{"platform":"android","status":"SKIP","reason":"no device"}' > "$REPORT_DIR/android/result.json"
        return
    fi

    local dev=$(android_get_device)
    local dump_file="/tmp/android-ui-dump.xml"

    # 确认应用已安装（先检查，已安装则跳过安装）
    local installed=$(adb -s "$dev" shell pm list packages 2>/dev/null | grep "$ANDROID_PACKAGE")
    if [ -z "$installed" ]; then
        # 尝试安装
        if [ -n "$ANDROID_APK" ]; then
            echo "安装 APK: $ANDROID_APK"
            local install_result=$(android_install "$ANDROID_APK" 2>&1)
            if echo "$install_result" | grep -q "Success"; then
                echo "安装成功"
            else
                echo "APK 安装失败: $install_result"
                # 检查是否有 debug APK（从上次构建）
                local debug_apk="/tmp/build-${CASE_ID}/app/build/outputs/apk/debug/app-debug.apk"
                if [ -f "$debug_apk" ]; then
                    echo "尝试 debug APK: $debug_apk"
                    android_install "$debug_apk"
                else
                    echo "ERROR: 无可安装的 APK"
                    echo '{"platform":"android","status":"ERROR","reason":"app install failed"}' > "$REPORT_DIR/android/result.json"
                    return
                fi
            fi
        fi
        installed=$(adb -s "$dev" shell pm list packages 2>/dev/null | grep "$ANDROID_PACKAGE")
    fi

    if [ -z "$installed" ]; then
        echo "ERROR: 应用未安装 ($ANDROID_PACKAGE)"
        echo '{"platform":"android","status":"ERROR","reason":"app not installed"}' > "$REPORT_DIR/android/result.json"
        return
    fi
    echo "应用已确认安装: $ANDROID_PACKAGE"
    echo ""

    # 清除数据 + 启动
    android_clear "$ANDROID_PACKAGE"
    sleep 1
    android_launch "$ANDROID_PACKAGE" "$ANDROID_ACTIVITY"
    sleep 2

    # 截取初始状态
    android_screenshot "$REPORT_DIR/android/initial-${TIMESTAMP}.png"
    echo "初始截屏已保存"

    # 发现 UI 元素坐标（一次 dump，全程复用）
    android_discover_ui "$dump_file"
    echo ""

    # ── 逐个执行测试用例 ──────────────────────────────────────
    echo "[开始逐用例验证]"

    local i=0
    while [ $i -lt $TC_COUNT ]; do
        local tc_id=$(get_test_field "$TEST_YAML" $i "id")
        local tc_name=$(get_test_field "$TEST_YAML" $i "name")
        local tc_expected=$(get_test_field "$TEST_YAML" $i "expected")
        local tc_priority=$(get_test_field "$TEST_YAML" $i "priority")

        echo ""
        echo "── $tc_id: $tc_name ──"
        echo "  预期: $tc_expected"

        # 每个测试用例前重置状态（高优先级用例）
        if [ "$tc_priority" = "HIGH" ]; then
            android_clear "$ANDROID_PACKAGE" > /dev/null 2>&1
            sleep 0.5
            android_launch "$ANDROID_PACKAGE" "$ANDROID_ACTIVITY" > /dev/null 2>&1
            sleep 2
        fi

        # 执行步骤 (使用 fd 3 避免 adb 消耗 stdin)
        local steps=$(get_test_field "$TEST_YAML" $i "steps")
        while IFS= read -r step <&3; do
            [ -z "$step" ] && continue
            echo "  执行: $step"
            android_execute_step "$step"
        done 3<<< "$steps"

        # 截屏
        android_screenshot "$REPORT_DIR/android/${tc_id}-${TIMESTAMP}.png"
        TEST_SCREENSHOTS["$tc_id"]="$REPORT_DIR/android/${tc_id}-${TIMESTAMP}.png"

        # 验证预期结果
        local expected_type=$(parse_expected "$tc_expected")
        local exp_kind="${expected_type%%:*}"
        local exp_value="${expected_type#*:}"

        android_dump_ui "$dump_file" > /dev/null 2>&1
        local actual=$(android_get_display_text "$dump_file")
        echo "  UI dump 实际文本: '$actual'"

        case "$exp_kind" in
            TEXT)
                assert_text_equals "$actual" "$exp_value" "$tc_id" || true
                ;;
            CONTAINS)
                assert_text_contains "$actual" "$exp_value" "$tc_id" || true
                ;;
            OR_TEXT)
                # 多选项匹配，任一匹配即 PASS (大小写不敏感)
                local matched=false
                IFS='|' read -ra options <<< "$exp_value"
                for opt in "${options[@]}"; do
                    if echo "$actual" | grep -qiF "$opt"; then
                        matched=true
                        record_pass "$tc_id" "显示文本='$actual' (匹配选项='$opt')"
                        break
                    fi
                done
                if [ "$matched" = false ]; then
                    record_fail "$tc_id" "显示文本='$actual' (预期之一='$exp_value')"
                fi
                ;;
            NOT_EMPTY)
                if [ -n "$actual" ] && [ "$actual" != "" ]; then
                    record_pass "$tc_id" "显示文本='$actual' (非空)"
                else
                    record_fail "$tc_id" "显示文本为空"
                fi
                ;;
            TOAST)
                record_not_verified "$tc_id" "Toast验证需要logcat或截图OCR，UI dump无法捕获瞬态Toast"
                ;;
            VISUAL)
                record_not_verified "$tc_id" "视觉验证需要截图对比，当前仅记录截屏"
                ;;
        esac

        i=$((i + 1))
    done

    echo ""
    echo "── Android 验证完成 ──"
    echo "  PASS: $TOTAL_PASS  FAIL: $TOTAL_FAIL  NOT_VERIFIED: $TOTAL_NOT_VERIFIED  SKIP: $TOTAL_SKIP"

    # 输出结果 JSON
    generate_results_json "$REPORT_DIR/android/verify-result.json" "android" "16.1.${CASE_ID}"
}

# ══════════════════════════════════════════════════════════════
# HarmonyOS 实机验证
# ══════════════════════════════════════════════════════════════

run_harmony_verification() {
    # 重置计数器
    TOTAL_PASS=0; TOTAL_FAIL=0; TOTAL_SKIP=0; TOTAL_NOT_VERIFIED=0
    declare -A TEST_RESULTS=()
    declare -A TEST_EVIDENCE=()
    declare -A TEST_SCREENSHOTS=()

    echo ""
    echo "══════════════════════════════════════"
    echo "  HarmonyOS 仿真器验证"
    echo "  设备: $(harmony_get_device)"
    echo "  验证方式: hdc + uitest dumpLayout"
    echo "══════════════════════════════════════"

    if ! harmony_is_connected; then
        echo "SKIP: 没有 HarmonyOS 设备连接"
        echo '{"platform":"harmony","status":"SKIP","reason":"no device"}' > "$REPORT_DIR/harmony/result.json"
        return
    fi

    local dev=$(harmony_get_device)
    local dump_file="/tmp/harmony-ui-dump.json"

    # 安装 HAP（如有）
    if [ -n "$HARMONY_HAP" ]; then
        echo "安装 HAP: $HARMONY_HAP"
        harmony_install "$HARMONY_HAP"
    else
        echo "注意: 未找到预构建 HAP，假设应用已安装"
    fi

    # 启动应用
    harmony_launch "$HARMONY_BUNDLE" "$HARMONY_ABILITY"
    sleep 3

    # 初始截屏
    harmony_screenshot "$REPORT_DIR/harmony/initial-${TIMESTAMP}.jpeg"
    echo "初始截屏已保存"

    # 发现 UI 元素坐标
    harmony_discover_ui "$dump_file"
    echo ""

    # ── 逐个执行测试用例 ──────────────────────────────────────
    echo "[开始逐用例验证]"

    local i=0
    while [ $i -lt $TC_COUNT ]; do
        local tc_id=$(get_test_field "$TEST_YAML" $i "id")
        local tc_name=$(get_test_field "$TEST_YAML" $i "name")
        local tc_expected=$(get_test_field "$TEST_YAML" $i "expected")
        local tc_priority=$(get_test_field "$TEST_YAML" $i "priority")

        echo ""
        echo "── $tc_id: $tc_name ──"
        echo "  预期: $tc_expected"

        # 高优先级用例重置状态
        # HarmonyOS 无 pm clear：重启应用 + 点击 DELETE 清除偏好数据
        if [ "$tc_priority" = "HIGH" ]; then
            harmony_stop "$HARMONY_BUNDLE" > /dev/null 2>&1
            sleep 0.5
            harmony_launch "$HARMONY_BUNDLE" "$HARMONY_ABILITY" > /dev/null 2>&1
            sleep 3
            # 清除偏好数据（通过 app 自身的 DELETE 按钮）
            harmony_tap 658 1313 > /dev/null 2>&1  # DELETE button coordinates
            sleep 0.5
        fi

        # 执行步骤 (使用 fd 3 避免 hdc 消耗 stdin)
        local steps=$(get_test_field "$TEST_YAML" $i "steps")
        while IFS= read -r step <&3; do
            [ -z "$step" ] && continue
            echo "  执行: $step"
            harmony_execute_step "$step"
        done 3<<< "$steps"

        # 截屏
        harmony_screenshot "$REPORT_DIR/harmony/${tc_id}-${TIMESTAMP}.jpeg"
        TEST_SCREENSHOTS["$tc_id"]="$REPORT_DIR/harmony/${tc_id}-${TIMESTAMP}.jpeg"

        # 验证预期结果
        local expected_type=$(parse_expected "$tc_expected")
        local exp_kind="${expected_type%%:*}"
        local exp_value="${expected_type#*:}"

        local actual=$(harmony_get_display_text "$dump_file")
        echo "  UI dump 实际文本: '$actual'"

        case "$exp_kind" in
            TEXT)
                assert_text_equals "$actual" "$exp_value" "$tc_id" || true
                ;;
            CONTAINS)
                assert_text_contains "$actual" "$exp_value" "$tc_id" || true
                ;;
            OR_TEXT)
                local matched=false
                IFS='|' read -ra options <<< "$exp_value"
                for opt in "${options[@]}"; do
                    if echo "$actual" | grep -qiF "$opt"; then
                        matched=true
                        record_pass "$tc_id" "显示文本='$actual' (匹配选项='$opt')"
                        break
                    fi
                done
                if [ "$matched" = false ]; then
                    record_fail "$tc_id" "显示文本='$actual' (预期之一='$exp_value')"
                fi
                ;;
            NOT_EMPTY)
                if [ -n "$actual" ] && [ "$actual" != "" ]; then
                    record_pass "$tc_id" "显示文本='$actual' (非空)"
                else
                    record_fail "$tc_id" "显示文本为空"
                fi
                ;;
            TOAST)
                record_not_verified "$tc_id" "Toast验证需要logcat或截图OCR，UI dump无法捕获瞬态Toast"
                ;;
            VISUAL)
                record_not_verified "$tc_id" "视觉验证需要截图对比，当前仅记录截屏"
                ;;
        esac

        i=$((i + 1))
    done

    echo ""
    echo "── HarmonyOS 验证完成 ──"
    echo "  PASS: $TOTAL_PASS  FAIL: $TOTAL_FAIL  NOT_VERIFIED: $TOTAL_NOT_VERIFIED  SKIP: $TOTAL_SKIP"

    # 输出结果 JSON
    generate_results_json "$REPORT_DIR/harmony/verify-result.json" "harmony" "16.1.${CASE_ID}"
}

# ══════════════════════════════════════════════════════════════
# 执行
# ══════════════════════════════════════════════════════════════

case "$PLATFORM" in
    android)  run_android_verification ;;
    harmony)  run_harmony_verification ;;
    both)     run_android_verification; run_harmony_verification ;;
    *)        echo "ERROR: platform 须为 android/harmony/both"; exit 1 ;;
esac

# ── 生成对比报告 ─────────────────────────────────────────────
echo ""
echo "生成 HTML 对比报告..."
bash "$SCRIPT_DIR/gen-report.sh" "$CASE_ID"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  验证完成                                                  ║"
echo "║  案例: $DEMO_NAME"
echo "║  报告: $REPORT_DIR/comparison-report.html"
echo "╚═══════════════════════════════════════════════════════════╝"
