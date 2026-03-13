#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# HarmonyOS Driver — hdc 设备交互原语
#
# 16.6-Adapter.Test 的人格：我只相信仿真器屏幕上看到的东西。
# 本文件封装所有 hdc/uitest 操作，供 test-engine.sh 调用。
# ═══════════════════════════════════════════════════════════════

# 注意: hdc 是 Windows exe，从 WSL 调用需要特殊处理路径

# ── 连接 ──────────────────────────────────────────────────────

harmony_get_device() {
    local targets=$("$HDC" list targets 2>&1 | tr -d '\r')
    if [ "$targets" = "[Empty]" ] || [ -z "$targets" ]; then
        echo ""
        return 1
    fi
    echo "$targets" | head -1
}

harmony_is_connected() {
    local dev=$(harmony_get_device)
    [ -n "$dev" ]
}

# ── 应用管理 ──────────────────────────────────────────────────

harmony_install() {
    local hap_path="$1"
    local dev=$(harmony_get_device)
    [ -z "$dev" ] && echo "ERROR: no device" && return 1

    # 将 WSL 路径转换为 Windows 路径
    local win_path
    if [[ "$hap_path" == /mnt/* ]]; then
        win_path=$(wslpath -w "$hap_path")
    else
        win_path="$hap_path"
    fi
    "$HDC" -t "$dev" install "$win_path" 2>&1
}

harmony_uninstall() {
    local bundle="$1"
    local dev=$(harmony_get_device)
    "$HDC" -t "$dev" uninstall "$bundle" 2>/dev/null
}

harmony_launch() {
    local bundle="$1"
    local ability="${2:-EntryAbility}"
    local dev=$(harmony_get_device)
    "$HDC" -t "$dev" shell aa start -a "$ability" -b "$bundle" 2>&1
}

harmony_stop() {
    local bundle="$1"
    local dev=$(harmony_get_device)
    "$HDC" -t "$dev" shell aa force-stop "$bundle" 2>&1
}

# 清除应用数据（卸载重装是最可靠的方式）
harmony_clear() {
    local bundle="$1"
    local hap_path="$2"
    local dev=$(harmony_get_device)
    # HarmonyOS 没有直接的 pm clear，通过卸载重装实现
    harmony_uninstall "$bundle"
    if [ -n "$hap_path" ]; then
        sleep 1
        harmony_install "$hap_path"
    fi
}

# ── 截屏 ──────────────────────────────────────────────────────

harmony_screenshot() {
    local output_path="$1"
    local dev=$(harmony_get_device)

    # snapshot_display 只支持 .jpeg
    local remote_path="/data/local/tmp/screen_capture.jpeg"
    "$HDC" -t "$dev" shell snapshot_display -f "$remote_path" 2>/dev/null

    # 拉取到本地（hdc 是 Windows exe，需要 Windows 路径）
    local win_output
    win_output=$(wslpath -w "$output_path" 2>/dev/null || echo "$output_path")
    "$HDC" -t "$dev" file recv "$remote_path" "$win_output" 2>/dev/null
    echo "$output_path"
}

# ── UI Dump (核心验证手段) ────────────────────────────────────

# dump 布局 JSON 到本地文件
harmony_dump_ui() {
    local output_path="${1:-/tmp/harmony-ui-dump.json}"
    local dev=$(harmony_get_device)

    # 清除旧 dump 文件
    "$HDC" -t "$dev" shell "rm -f /data/local/tmp/layout_*.json" 2>/dev/null

    # uitest dumpLayout
    "$HDC" -t "$dev" shell uitest dumpLayout 2>/dev/null
    sleep 1

    # 找到生成的 layout 文件
    local remote_file=$("$HDC" -t "$dev" shell "ls -t /data/local/tmp/layout_*.json 2>/dev/null | head -1" | tr -d '\r')

    if [ -z "$remote_file" ]; then
        echo "ERROR: dumpLayout failed"
        return 1
    fi

    # 拉取到本地（hdc 是 Windows exe，需要 Windows 路径）
    local win_output
    win_output=$(wslpath -w "$output_path" 2>/dev/null || echo "$output_path")
    "$HDC" -t "$dev" file recv "$remote_file" "$win_output" 2>/dev/null
    echo "$output_path"
}

# 从 layout JSON 中按类型查找组件，返回其文本内容
# 实际结构: {attributes: {type: "Text", text: "xxx", bounds: "[x1,y1][x2,y2]"}, children: [...]}
# 用法: harmony_get_text_by_type dump.json "Text"
harmony_get_text_by_type() {
    local dump_file="$1"
    local comp_type="$2"
    python3 -c "
import json, sys
def find_all(node, comp_type, results=[]):
    attrs = node.get('attributes', {})
    t = attrs.get('type', '')
    if comp_type in t:
        text = attrs.get('text', attrs.get('originalText', ''))
        if text:
            results.append(text)
    for child in node.get('children', []):
        find_all(child, comp_type, results)
    return results

with open('$dump_file') as f:
    data = json.load(f)
results = find_all(data, '$comp_type')
for r in results:
    print(r)
" 2>/dev/null
}

# 按文本内容查找组件的 bounds
# bounds 格式: "[x1,y1][x2,y2]" — 与 Android XML 相同
harmony_find_bounds_by_text() {
    local dump_file="$1"
    local text="$2"
    python3 -c "
import json, re, sys
def parse_bounds(bounds_str):
    m = re.findall(r'\[(\d+),(\d+)\]', bounds_str)
    if len(m) == 2:
        x1, y1 = int(m[0][0]), int(m[0][1])
        x2, y2 = int(m[1][0]), int(m[1][1])
        return (x1+x2)//2, (y1+y2)//2
    return None

def find_by_text(node, target):
    attrs = node.get('attributes', {})
    val = attrs.get('text', attrs.get('originalText', ''))
    if target == str(val):
        bounds_str = attrs.get('bounds', '')
        center = parse_bounds(bounds_str)
        if center:
            print(f'{center[0]} {center[1]}')
            return True
    for child in node.get('children', []):
        if find_by_text(child, target):
            return True
    return False

with open('$dump_file') as f:
    data = json.load(f)
find_by_text(data, '$text')
" 2>/dev/null
}

# 获取所有 Text 组件的文本（用于发现显示内容）
harmony_get_all_texts() {
    local dump_file="$1"
    harmony_get_text_by_type "$dump_file" "Text"
}

# ── 坐标缓存 ────────────────────────────────────────────────
HARMONY_CACHED_INPUT=""   # TextInput 的 "cx cy"

# 发现并缓存 UI 元素
harmony_discover_ui() {
    local dump_file="${1:-/tmp/harmony-ui-dump.json}"
    harmony_dump_ui "$dump_file" > /dev/null

    local info=$(python3 -c "
import json, re, sys

def parse_bounds(bounds_str):
    m = re.findall(r'\[(\d+),(\d+)\]', bounds_str)
    if len(m) == 2:
        x1, y1 = int(m[0][0]), int(m[0][1])
        x2, y2 = int(m[1][0]), int(m[1][1])
        return (x1+x2)//2, (y1+y2)//2
    return None

def discover(node, bundle_found=False):
    attrs = node.get('attributes', {})
    bundle = attrs.get('bundleName', '')
    t = attrs.get('type', '')
    text = attrs.get('text', '')

    if bundle_found or bundle == '$HARMONY_BUNDLE':
        center = parse_bounds(attrs.get('bounds', ''))
        if center:
            if t == 'TextInput':
                print(f'INPUT:{center[0]} {center[1]}')
            elif t == 'Button' and text:
                print(f'BTN:{text}:{center[0]} {center[1]}')
            elif t == 'Text' and text:
                print(f'TEXT:{text}:{center[0]} {center[1]}')
        for child in node.get('children', []):
            discover(child, True)
    else:
        for child in node.get('children', []):
            discover(child, False)

with open('$dump_file') as f:
    discover(json.load(f))
" 2>/dev/null)

    # 解析 python 输出
    while IFS= read -r line; do
        case "$line" in
            INPUT:*)
                HARMONY_CACHED_INPUT="${line#INPUT:}"
                echo "  TextInput → $HARMONY_CACHED_INPUT"
                ;;
            BTN:*)
                local rest="${line#BTN:}"
                local btn_text="${rest%%:*}"
                local coords="${rest#*:}"
                echo "  按钮 '$btn_text' → $coords"
                ;;
            TEXT:*)
                local rest="${line#TEXT:}"
                local txt="${rest%%:*}"
                local coords="${rest#*:}"
                echo "  文本 '$txt' → $coords"
                ;;
        esac
    done <<< "$info"
}

# ── 交互操作 ──────────────────────────────────────────────────

harmony_tap() {
    local x="$1" y="$2"
    local dev=$(harmony_get_device)
    "$HDC" -t "$dev" shell uitest uiInput click "$x" "$y" 2>/dev/null
    sleep 0.5
}

# 按文本查找组件并点击
harmony_tap_text() {
    local text="$1"
    local dump_file="${2:-/tmp/harmony-ui-dump.json}"

    # 先 dump
    harmony_dump_ui "$dump_file" > /dev/null

    local center=$(harmony_find_bounds_by_text "$dump_file" "$text")
    if [ -z "$center" ]; then
        echo "WARN: element with text '$text' not found"
        return 1
    fi
    local cx=$(echo "$center" | awk '{print $1}')
    local cy=$(echo "$center" | awk '{print $2}')
    harmony_tap "$cx" "$cy"
}

# 输入文本（全选已有内容 → 用 text 命令替换）
harmony_input_text() {
    local text="$1"
    local dev=$(harmony_get_device)

    # 先全选（long-click → 全选），然后用 text 替换
    harmony_select_all
    "$HDC" -t "$dev" shell uitest uiInput text "$text" 2>/dev/null
    sleep 0.5

    # 关闭键盘（点击输入框外的区域）
    "$HDC" -t "$dev" shell uitest uiInput keyEvent Back 2>/dev/null
    sleep 0.5
}

# 点击输入框（查找 TextInput 类型的组件）
# 实际结构: attributes.type = "TextInput", attributes.bounds = "[x1,y1][x2,y2]"
harmony_focus_input() {
    local dump_file="${1:-/tmp/harmony-ui-dump.json}"
    harmony_dump_ui "$dump_file" > /dev/null

    local center=$(python3 -c "
import json, re
def parse_bounds(bounds_str):
    m = re.findall(r'\[(\d+),(\d+)\]', bounds_str)
    if len(m) == 2:
        x1, y1 = int(m[0][0]), int(m[0][1])
        x2, y2 = int(m[1][0]), int(m[1][1])
        return (x1+x2)//2, (y1+y2)//2
    return None

def find_input(node):
    attrs = node.get('attributes', {})
    t = attrs.get('type', '')
    if 'TextInput' in t or 'TextArea' in t:
        center = parse_bounds(attrs.get('bounds', ''))
        if center:
            print(f'{center[0]} {center[1]}')
            return True
    for child in node.get('children', []):
        if find_input(child):
            return True
    return False
with open('$dump_file') as f:
    find_input(json.load(f))
" 2>/dev/null)

    if [ -z "$center" ]; then
        echo "WARN: TextInput not found"
        return 1
    fi
    # 缓存 TextInput 坐标
    HARMONY_CACHED_INPUT="$center"
    local cx=$(echo "$center" | awk '{print $1}')
    local cy=$(echo "$center" | awk '{print $2}')
    harmony_tap "$cx" "$cy"
    sleep 0.3
}

# 全选输入框文本（long-click → 点击"全选"菜单）
# 调用后文本处于选中状态，下次 text 命令会替换选中内容
harmony_select_all() {
    local dev=$(harmony_get_device)
    local dump_file="/tmp/harmony-ui-dump.json"

    # 0. 先点击输入框确保聚焦
    if [ -n "$HARMONY_CACHED_INPUT" ]; then
        local cx=$(echo "$HARMONY_CACHED_INPUT" | awk '{print $1}')
        local cy=$(echo "$HARMONY_CACHED_INPUT" | awk '{print $2}')
        "$HDC" -t "$dev" shell uitest uiInput click "$cx" "$cy" 2>/dev/null
        sleep 0.5
    fi

    # 1. Long-click 输入框触发上下文菜单
    if [ -n "$HARMONY_CACHED_INPUT" ]; then
        "$HDC" -t "$dev" shell uitest uiInput longClick "$cx" "$cy" 2>/dev/null
    else
        "$HDC" -t "$dev" shell uitest uiInput longClick 658 599 2>/dev/null
    fi
    sleep 1.5

    # 2. Dump 找"全选"按钮位置
    harmony_dump_ui "$dump_file" > /dev/null
    local select_all_center=$(python3 -c "
import json, re
def parse_bounds(s):
    m = re.findall(r'\[(\d+),(\d+)\]', s)
    if len(m)==2:
        return (int(m[0][0])+int(m[1][0]))//2, (int(m[0][1])+int(m[1][1]))//2
    return None
def find(node):
    attrs = node.get('attributes',{})
    if '全选' in attrs.get('text','') or 'Select All' in attrs.get('text',''):
        c = parse_bounds(attrs.get('bounds',''))
        if c: print(f'{c[0]} {c[1]}'); return True
    for child in node.get('children',[]):
        if find(child): return True
    return False
with open('$dump_file') as f:
    find(json.load(f))
" 2>/dev/null)

    if [ -n "$select_all_center" ]; then
        local sx=$(echo "$select_all_center" | awk '{print $1}')
        local sy=$(echo "$select_all_center" | awk '{print $2}')
        "$HDC" -t "$dev" shell uitest uiInput click "$sx" "$sy" 2>/dev/null
        sleep 0.5
    else
        echo "WARN: '全选' 菜单未找到, 尝试点击外部关闭弹窗"
        # 点击输入框外的区域关闭弹窗/键盘
        "$HDC" -t "$dev" shell uitest uiInput click 658 300 2>/dev/null
        sleep 0.5
    fi
}

# 清除输入框文本（全选 + 删除键）
harmony_clear_field() {
    local dev=$(harmony_get_device)
    harmony_select_all
    "$HDC" -t "$dev" shell uitest uiInput keyEvent 2055 2>/dev/null  # DEL
    sleep 0.3
}

# 获取显示区域的文本
# 策略: 找 app 窗口中的最后一个 Text 组件（排除按钮文本和标题）
harmony_get_display_text() {
    local dump_file="${1:-/tmp/harmony-ui-dump.json}"
    harmony_dump_ui "$dump_file" > /dev/null

    python3 -c "
import json, re, sys

def find_app_texts(node, bundle_found=False, results=[]):
    attrs = node.get('attributes', {})
    bundle = attrs.get('bundleName', '')
    t = attrs.get('type', '')

    # 只收集 app 窗口内的 Text（不是 Button）
    if bundle_found or bundle == '$HARMONY_BUNDLE':
        if t == 'Text' and attrs.get('text', ''):
            results.append(attrs['text'])
        for child in node.get('children', []):
            find_app_texts(child, True, results)
    else:
        for child in node.get('children', []):
            find_app_texts(child, False, results)
    return results

with open('$dump_file') as f:
    data = json.load(f)
texts = find_app_texts(data)
# 排除标题、标签，取最后一个 (通常是显示区域)
skip = {'SharedPreferences', 'ArkTS HarmonyOS', 'SAVE', 'OPEN', 'DELETE'}
display = [t for t in texts if t not in skip]
if display:
    print(display[-1])
" 2>/dev/null
}

echo "harmony-driver.sh loaded"
