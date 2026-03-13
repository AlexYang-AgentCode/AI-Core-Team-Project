#!/bin/bash
#
# Vault Worker - 监控 Goals.md 中的 #task 任务，调用 Claude Code 执行
# 由 cron 每5分钟触发，仅在文件有变更且存在 #task 时才调用 Claude
#
# 标记规则：
#   #task      - 待执行任务（蓝色）
#   #tasking   - 执行中（绿色脉动）
#   #task-done - 已完成（灰色）
#   #next-task - AI 建议的下一步（橙色，确认后改为 #task）
#
# 智能切换：先用 Anthropic 原生，用量超 80% 后自动切换到 GLM
#

VAULT="/mnt/d/ObsidianVault"
GOALS="$VAULT/00-Inbox/Goals.md"
LOG="$VAULT/.vault-worker.log"
LOCK="/tmp/vault-worker.lock"
HASH_FILE="/tmp/vault-worker.hash"

# ---- Smart Provider 切换 ----
VAULT_GPG="$HOME/.claude/claude_switch.vault.gpg"
SMART_COUNTER_FILE="/tmp/vault-worker-smart-counter"
SMART_THRESHOLD_PCT=80
SMART_MAX_TASKS="${SMART_MAX_TASKS:-20}"  # 每天最多任务数，80% = 16 个后切 GLM
SMART_FALLBACK="glm"
GLM_BASE_URL="https://open.bigmodel.cn/api/paas/v4"

# 清除嵌套检测
unset CLAUDECODE

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG"
}

# ---- Smart Provider 选择 ----

# 读取/重置每日计数器（每天 00:00 自动归零）
smart_counter_read() {
    if [[ -f "$SMART_COUNTER_FILE" ]]; then
        local saved_date count
        saved_date=$(head -1 "$SMART_COUNTER_FILE")
        count=$(tail -1 "$SMART_COUNTER_FILE")
        if [[ "$saved_date" == "$(date +%Y-%m-%d)" ]]; then
            echo "$count"
            return
        fi
    fi
    echo "0"
}

smart_counter_increment() {
    local count
    count=$(smart_counter_read)
    count=$((count + 1))
    printf '%s\n%s\n' "$(date +%Y-%m-%d)" "$count" > "$SMART_COUNTER_FILE"
    echo "$count"
}

# 选择 provider：低于 80% 用 anthropic，超过后用 glm
select_provider() {
    local count threshold
    count=$(smart_counter_read)
    threshold=$(( SMART_MAX_TASKS * SMART_THRESHOLD_PCT / 100 ))

    if [[ $count -ge $threshold ]]; then
        # 切换到 GLM — 需要从 vault 解密 API key
        if [[ ! -f "$VAULT_GPG" ]]; then
            log "[Smart] 无法切换到 GLM：vault 不存在"
            echo "anthropic"
            return
        fi

        local vault_plain glm_key
        vault_plain=$(gpg --quiet --batch --yes --pinentry-mode loopback --decrypt "$VAULT_GPG" 2>/dev/null) || {
            log "[Smart] vault 解密失败，继续用 anthropic"
            echo "anthropic"
            return
        }
        glm_key=$(echo "$vault_plain" | grep '^GLM_API_KEY=' | cut -d= -f2-)
        vault_plain=""

        if [[ -z "$glm_key" ]]; then
            log "[Smart] GLM key 为空，继续用 anthropic"
            echo "anthropic"
            return
        fi

        export ANTHROPIC_API_KEY="$glm_key"
        export ANTHROPIC_BASE_URL="$GLM_BASE_URL"
        glm_key=""
        log "[Smart] 已切换到 GLM (任务 $count/$SMART_MAX_TASKS，超过 ${SMART_THRESHOLD_PCT}% 阈值)"
        echo "glm"
    else
        # 使用 Anthropic 原生（清除可能残留的环境变量）
        unset ANTHROPIC_API_KEY ANTHROPIC_BASE_URL 2>/dev/null || true
        log "[Smart] 使用 Anthropic 原生 (任务 $count/$SMART_MAX_TASKS)"
        echo "anthropic"
    fi
}

# 防止重复运行
if [ -f "$LOCK" ]; then
    pid=$(cat "$LOCK")
    if kill -0 "$pid" 2>/dev/null; then
        exit 0
    fi
fi
echo $$ > "$LOCK"
trap "rm -f $LOCK" EXIT

# 检查是否有 #task 或 #tasking 任务
has_tasks() {
    grep -E '#task |#tasking ' "$GOALS" 2>/dev/null | grep -qvE '#task-done|#next-task'
}

# 检查文件是否变更
file_changed() {
    local current_hash
    current_hash=$(md5sum "$GOALS" 2>/dev/null | cut -d' ' -f1)
    local saved_hash
    saved_hash=$(cat "$HASH_FILE" 2>/dev/null)

    if [ "$current_hash" = "$saved_hash" ]; then
        return 1
    fi
    echo "$current_hash" > "$HASH_FILE"
    return 0
}

# 提取第一个 #task 或 #tasking 任务
extract_task() {
    grep -n -E '#task |#tasking ' "$GOALS" 2>/dev/null | grep -vE '#task-done|#next-task' | head -1
}

# 执行单个任务
execute_task() {
    local line_num="$1"
    local task_text="$2"
    local clean_task=$(echo "$task_text" | sed -E 's/^.*(#task |#tasking )//')

    # 先标记为 #tasking（执行中）
    sed -i "${line_num}s/#task /#tasking /" "$GOALS"

    # 智能选择 provider
    local provider
    provider=$(select_provider)
    local new_count
    new_count=$(smart_counter_increment)

    log "执行任务 [L${line_num}] (provider: $provider, 第${new_count}个): $clean_task"

    cd "$VAULT"
    local result
    result=$(claude -p "你是 Obsidian Vault 助手，工作目录是 /mnt/d/ObsidianVault。
请执行以下任务，直接创建或修改文件。笔记用中文，带YAML frontmatter。

任务：${clean_task}

完成任务后，请额外思考：基于这个任务的结果，用户下一步最值得做的事情是什么？
在输出最后一行写：next-task建议：<你的建议>" --allowedTools "Write,Edit,Read,Glob,Grep,Bash" --output-format text 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        # 标记完成（从 #tasking 变为 #task-done）
        sed -i "${line_num}s/#tasking /#task-done /" "$GOALS"
        sed -i "${line_num}s/- \[ \]/- [x]/" "$GOALS"

        # 提取 NextTask 建议并追加到任务下方
        local suggestion=$(echo "$result" | grep 'next-task建议：' | sed 's/.*next-task建议：//')
        if [ -n "$suggestion" ]; then
            sed -i "${line_num}a\\    - [ ] #next-task ${suggestion}" "$GOALS"
        fi

        log "任务完成 [L${line_num}] (via $provider)"
        [ -n "$suggestion" ] && log "建议下一步: $suggestion"
    else
        log "任务失败 [L${line_num}] (via $provider): $(echo "$result" | head -3)"
    fi

    # 清理：恢复环境变量避免泄漏到后续非 claude 进程
    unset ANTHROPIC_API_KEY ANTHROPIC_BASE_URL 2>/dev/null || true
}

# === 主逻辑 ===

# 快速检查：没有 #task 直接退出
if ! has_tasks; then
    exit 0
fi

# 文件没变也退出
if ! file_changed; then
    exit 0
fi

log "=== 检测到新任务，开始执行 ==="

# 逐个处理所有 #task
while true; do
    task_line=$(extract_task)
    [ -z "$task_line" ] && break

    line_num=$(echo "$task_line" | cut -d: -f1)
    task_text=$(echo "$task_line" | cut -d: -f2-)

    execute_task "$line_num" "$task_text"

    # 更新 hash
    md5sum "$GOALS" 2>/dev/null | cut -d' ' -f1 > "$HASH_FILE"
done

log "=== 所有任务执行完毕 ==="
