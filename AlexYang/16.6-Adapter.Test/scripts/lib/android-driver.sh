#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# Android Driver — adb 设备交互原语
#
# 16.6-Adapter.Test 的人格：我只相信仿真器屏幕上看到的东西。
# 本文件封装所有 adb 操作，供 test-engine.sh 调用。
# ═══════════════════════════════════════════════════════════════

# ── 连接 ──────────────────────────────────────────────────────

# 返回第一个在线设备 ID，无设备返回空字符串
android_get_device() {
    adb devices 2>/dev/null | grep -v "List" | grep "device$" | head -1 | awk '{print $1}'
}

# 检查设备是否在线
android_is_connected() {
    local dev=$(android_get_device)
    [ -n "$dev" ]
}

# ── 应用管理 ──────────────────────────────────────────────────

android_install() {
    local apk_path="$1"
    local dev=$(android_get_device)
    [ -z "$dev" ] && echo "ERROR: no device" && return 1
    adb -s "$dev" install -r "$apk_path" 2>&1
}

android_uninstall() {
    local package="$1"
    local dev=$(android_get_device)
    adb -s "$dev" uninstall "$package" 2>/dev/null
}

android_launch() {
    local package="$1"
    local activity="$2"
    local dev=$(android_get_device)
    adb -s "$dev" shell am start -n "${package}/${activity}" -W 2>&1
}

android_stop() {
    local package="$1"
    local dev=$(android_get_device)
    adb -s "$dev" shell am force-stop "$package" 2>&1
}

android_clear() {
    local package="$1"
    local dev=$(android_get_device)
    adb -s "$dev" shell pm clear "$package" 2>&1
}

# ── 截屏 ──────────────────────────────────────────────────────

android_screenshot() {
    local output_path="$1"
    local dev=$(android_get_device)
    adb -s "$dev" exec-out screencap -p > "$output_path" 2>/dev/null
    echo "$output_path"
}

# ── UI Dump (核心验证手段) ────────────────────────────────────

# dump UI XML 到本地文件，返回路径
android_dump_ui() {
    local output_path="${1:-/tmp/android-ui-dump.xml}"
    local dev=$(android_get_device)
    # 清除旧 dump
    adb -s "$dev" shell rm -f /sdcard/window_dump.xml 2>/dev/null
    adb -s "$dev" shell uiautomator dump /sdcard/window_dump.xml 2>/dev/null
    adb -s "$dev" pull /sdcard/window_dump.xml "$output_path" 2>/dev/null
    echo "$output_path"
}

# 从 UI dump XML 中按 resource-id 获取文本
# 注意: XML 属性顺序为 text="..." resource-id="..." class="..." bounds="..."
android_get_text_by_id() {
    local dump_file="$1"
    local resource_id="$2"
    grep -oP "text=\"[^\"]*\"[^>]*resource-id=\"[^\"]*${resource_id}[^\"]*\"" "$dump_file" \
        | grep -oP '^text="[^"]*"' | head -1 | sed 's/text="//;s/"//'
}

# 从 UI dump XML 中按文本内容查找元素，返回其 bounds
android_find_bounds_by_text() {
    local dump_file="$1"
    local text="$2"
    grep -oP "text=\"${text}\"[^>]*bounds=\"\[[0-9,]+\]\[[0-9,]+\]\"" "$dump_file" \
        | grep -oP 'bounds="\[[0-9,]+\]\[[0-9,]+\]"' | head -1 \
        | sed 's/bounds="//;s/"//'
}

# 从 UI dump 中按 class 和 text 查找元素 bounds
# 属性顺序: text → resource-id → class → ... → bounds
android_find_bounds_by_class_text() {
    local dump_file="$1"
    local class="$2"
    local text="$3"
    grep -oP "text=\"${text}\"[^>]*class=\"[^\"]*${class}[^\"]*\"[^>]*bounds=\"\[[0-9,]+\]\[[0-9,]+\]\"" "$dump_file" \
        | grep -oP 'bounds="\[[0-9,]+\]\[[0-9,]+\]"' | head -1 \
        | sed 's/bounds="//;s/"//'
}

# 从 bounds 字符串 "[x1,y1][x2,y2]" 计算中心点
android_bounds_center() {
    local bounds="$1"
    local x1 y1 x2 y2
    read x1 y1 x2 y2 <<< $(echo "$bounds" | sed 's/\[//g;s/\]/ /g;s/,/ /g')
    local cx=$(( (x1 + x2) / 2 ))
    local cy=$(( (y1 + y2) / 2 ))
    echo "$cx $cy"
}

# ── 交互操作 ──────────────────────────────────────────────────

android_tap() {
    local x="$1" y="$2"
    local dev=$(android_get_device)
    adb -s "$dev" shell input tap "$x" "$y"
}

# 按文本查找元素并点击其中心
android_tap_text() {
    local text="$1"
    local dump_file="${2:-/tmp/android-ui-dump.xml}"

    # 先 dump 当前 UI
    android_dump_ui "$dump_file" > /dev/null

    local bounds=$(android_find_bounds_by_text "$dump_file" "$text")
    if [ -z "$bounds" ]; then
        echo "WARN: element with text '$text' not found"
        return 1
    fi
    local center=$(android_bounds_center "$bounds")
    local cx=$(echo "$center" | awk '{print $1}')
    local cy=$(echo "$center" | awk '{print $2}')
    android_tap "$cx" "$cy"
    sleep 0.5
}

# 输入文本（需先聚焦到输入框）
android_input_text() {
    local text="$1"
    local dev=$(android_get_device)
    # 转义空格为 %s
    local escaped=$(echo "$text" | sed 's/ /%s/g')
    adb -s "$dev" shell input text "$escaped"
}

# 清除输入框内容（MOVE_END → Shift+MOVE_HOME 全选 → DEL）
android_clear_field() {
    local dev=$(android_get_device)
    adb -s "$dev" shell input keyevent 123  # MOVE_END
    sleep 0.1
    adb -s "$dev" shell input keycombination 59 122  # SHIFT+MOVE_HOME (select all)
    sleep 0.1
    adb -s "$dev" shell input keyevent 67  # DEL
    sleep 0.1
}

# 点击输入框（通过 resource-id 或找 EditText）
android_focus_input() {
    local dump_file="${1:-/tmp/android-ui-dump.xml}"
    android_dump_ui "$dump_file" > /dev/null

    # 找 EditText 的 bounds (属性顺序: text → resource-id → class → ... → bounds)
    local bounds=$(grep -oP 'class="android\.widget\.EditText"[^>]*bounds="\[[0-9,]+\]\[[0-9,]+\]"' "$dump_file" \
        | grep -oP 'bounds="\[[0-9,]+\]\[[0-9,]+\]"' | head -1 | sed 's/bounds="//;s/"//')
    # 如果上面没找到，尝试反向搜索（某些设备属性顺序不同）
    if [ -z "$bounds" ]; then
        bounds=$(grep -oP 'text="[^"]*"[^>]*class="android\.widget\.EditText"[^>]*bounds="\[[0-9,]+\]\[[0-9,]+\]"' "$dump_file" \
            | grep -oP 'bounds="\[[0-9,]+\]\[[0-9,]+\]"' | head -1 | sed 's/bounds="//;s/"//')
    fi
    if [ -z "$bounds" ]; then
        echo "WARN: EditText not found"
        return 1
    fi
    local center=$(android_bounds_center "$bounds")
    local cx=$(echo "$center" | awk '{print $1}')
    local cy=$(echo "$center" | awk '{print $2}')
    android_tap "$cx" "$cy"
    sleep 0.3
}

# 获取显示区域的文本
# 优先按 resource-id (textViewSharedPreference 等)，退而求其次取最后一个 TextView
android_get_display_text() {
    local dump_file="${1:-/tmp/android-ui-dump.xml}"

    # 尝试按已知的显示区域 resource-id 获取
    local by_id=$(android_get_text_by_id "$dump_file" "textViewSharedPreference")
    if [ -n "$by_id" ]; then
        echo "$by_id"
        return
    fi

    # 退而求其次: 获取所有 TextView 的文本，取最后一个
    # XML 属性顺序: text="..." ... class="android.widget.TextView"
    local texts=$(grep -oP 'text="[^"]*"[^>]*class="android\.widget\.TextView"' "$dump_file" \
        | grep -oP '^text="[^"]*"' | sed 's/text="//;s/"//')
    echo "$texts" | tail -1
}

# ── 坐标缓存 (一次 dump，多次使用) ────────────────────────────

# 发现并缓存 UI 元素坐标
# 调用一次后，后续直接用 CACHED_* 变量
declare -A CACHED_BUTTONS=()    # text → "cx cy"
CACHED_EDITTEXT=""              # "cx cy"

android_discover_ui() {
    local dump_file="${1:-/tmp/android-ui-dump.xml}"
    android_dump_ui "$dump_file" > /dev/null

    # 发现所有 Button
    while IFS= read -r line; do
        local text=$(echo "$line" | grep -oP '^text="[^"]*"' | sed 's/text="//;s/"//')
        local bounds=$(echo "$line" | grep -oP 'bounds="\[[0-9,]+\]\[[0-9,]+\]"' | sed 's/bounds="//;s/"//')
        if [ -n "$text" ] && [ -n "$bounds" ]; then
            local center=$(android_bounds_center "$bounds")
            CACHED_BUTTONS["$text"]="$center"
        fi
    done <<< "$(grep -oP 'text="[^"]*"[^>]*class="android\.widget\.Button"[^>]*bounds="\[[0-9,]+\]\[[0-9,]+\]"' "$dump_file")"

    # 发现 EditText
    local et_bounds=$(grep -oP 'class="android\.widget\.EditText"[^>]*bounds="\[[0-9,]+\]\[[0-9,]+\]"' "$dump_file" \
        | grep -oP 'bounds="\[[0-9,]+\]\[[0-9,]+\]"' | head -1 | sed 's/bounds="//;s/"//')
    if [ -z "$et_bounds" ]; then
        et_bounds=$(grep -oP 'text="[^"]*"[^>]*class="android\.widget\.EditText"[^>]*bounds="\[[0-9,]+\]\[[0-9,]+\]"' "$dump_file" \
            | grep -oP 'bounds="\[[0-9,]+\]\[[0-9,]+\]"' | head -1 | sed 's/bounds="//;s/"//')
    fi
    if [ -n "$et_bounds" ]; then
        CACHED_EDITTEXT=$(android_bounds_center "$et_bounds")
    fi

    echo "  已发现 UI 元素: ${#CACHED_BUTTONS[@]} 个按钮, EditText=$CACHED_EDITTEXT"
    for btn in "${!CACHED_BUTTONS[@]}"; do
        echo "    按钮 '$btn' → ${CACHED_BUTTONS[$btn]}"
    done
}

# 用缓存的坐标点击按钮
android_tap_cached() {
    local text="$1"
    local coords="${CACHED_BUTTONS[$text]}"
    if [ -z "$coords" ]; then
        echo "WARN: 缓存中无 '$text'，尝试实时查找"
        android_tap_text "$text"
        return
    fi
    local cx=$(echo "$coords" | awk '{print $1}')
    local cy=$(echo "$coords" | awk '{print $2}')
    android_tap "$cx" "$cy"
    sleep 0.3
}

# 高效输入文本（点击 EditText → 清除 → 输入）
android_type_text() {
    local text="$1"
    local dev=$(android_get_device)
    echo "    [android_type_text: '$text']"

    # 点击 EditText
    if [ -n "$CACHED_EDITTEXT" ]; then
        local cx=$(echo "$CACHED_EDITTEXT" | awk '{print $1}')
        local cy=$(echo "$CACHED_EDITTEXT" | awk '{print $2}')
        adb -s "$dev" shell input tap "$cx" "$cy"
        sleep 0.5
    fi

    # 清除现有内容
    adb -s "$dev" shell input keyevent 123  # MOVE_END
    sleep 0.1
    adb -s "$dev" shell input keycombination 59 122  # SHIFT+MOVE_HOME
    sleep 0.1
    adb -s "$dev" shell input keyevent 67  # DEL
    sleep 0.2

    # 输入新文本 (转义 shell 特殊字符)
    local escaped=$(echo "$text" | sed 's/ /%s/g; s/[;&|<>()$`\\!"'"'"']/\\&/g')
    adb -s "$dev" shell input text "'$escaped'"
    sleep 0.5

    # 隐藏键盘并等待布局恢复
    adb -s "$dev" shell input keyevent 111  # ESC
    sleep 1
    echo "    [android_type_text: done]"
}

# ── 高级操作 ──────────────────────────────────────────────────

# 隐藏键盘
android_hide_keyboard() {
    local dev=$(android_get_device)
    adb -s "$dev" shell input keyevent 111  # ESCAPE
    sleep 0.3
}

# 按 Back 键
android_back() {
    local dev=$(android_get_device)
    adb -s "$dev" shell input keyevent 4
}

echo "android-driver.sh loaded"
