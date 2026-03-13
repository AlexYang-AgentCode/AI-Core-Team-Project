---
tags:
  - guide/tool
  - opencode/logging
date: 2026-03-11
---

# OpenCode 日志方案 - 归档和查看历史

> 将 OpenCode 输出保存到文件，方便查看和搜索

---

## 🎯 适用场景

- ✅ 需要长期保存对话历史
- ✅ 需要搜索和分析输出
- ✅ 需要分享给他人
- ✅ 需要审计和回顾

---

## 📝 方案1: tee 命令 (推荐)

### 基本用法

```bash
# 启动 OpenCode 并同时输出到终端和文件
opencode 2>&1 | tee -a ~/opencode-$(date +%Y%m%d).log

# 参数说明:
# 2>&1  - 重定向错误输出到标准输出
# tee   - 同时输出到终端和文件
# -a    - 追加模式 (不覆盖)
# date  - 按日期命名文件
```

### 使用别名 (推荐)

添加到 `~/.bashrc`:

```bash
# OpenCode with logging
alias oclog='opencode 2>&1 | tee -a ~/opencode-logs/opencode-$(date +%Y%m%d-%H%M%S).log'

# 创建日志目录
mkdir -p ~/opencode-logs
```

使用:
```bash
source ~/.bashrc
oclog

# 现在所有输出都会保存到 ~/opencode-logs/ 目录
```

---

## 📝 方案2: script 命令 (完整记录)

### 基本用法

```bash
# 记录完整会话 (包括输入和输出)
script -f ~/opencode-logs/session-$(date +%Y%m%d-%H%M%S).log

# 在新shell中启动 opencode
opencode

# 退出时
exit  # 或 Ctrl+D

# 参数说明:
# -f  - 实时写入 (不缓冲)
```

### 查看日志

```bash
# 查看日志
cat ~/opencode-logs/session-*.log

# 或用 less 滚动查看
less ~/opencode-logs/session-*.log

# 搜索
grep "关键词" ~/opencode-logs/*.log
```

---

## 📝 方案3: 自动日志脚本

创建 `~/bin/opencode-with-log.sh`:

```bash
#!/bin/bash

LOG_DIR="$HOME/opencode-logs"
mkdir -p "$LOG_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$LOG_DIR/opencode-$TIMESTAMP.log"

echo "📝 OpenCode 日志文件: $LOG_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 启动 opencode 并记录日志
{
  echo "# OpenCode Session: $TIMESTAMP"
  echo "# Project: $(pwd)"
  echo "# Date: $(date)"
  echo ""
} | tee "$LOG_FILE"

opencode 2>&1 | tee -a "$LOG_FILE"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 会话日志已保存: $LOG_FILE"
```

使用:
```bash
chmod +x ~/bin/opencode-with-log.sh
~/bin/opencode-with-log.sh
```

---

## 🔍 查看和分析日志

### 工具1: less (滚动查看)

```bash
# 打开日志
less ~/opencode-logs/opencode-20260311.log

# 快捷键:
# 空格/回车  - 向下滚动
# b        - 向上滚动
# /        - 搜索
# n        - 下一个匹配
# N        - 上一个匹配
# g        - 跳到开头
# G        - 跳到结尾
# q        - 退出
```

### 工具2: grep (搜索)

```bash
# 搜索关键词
grep "架构设计" ~/opencode-logs/*.log

# 显示上下文 (前后3行)
grep -C 3 "架构设计" ~/opencode-logs/*.log

# 搜索并高亮
grep --color=always "DeepSeek" ~/opencode-logs/*.log | less -R

# 统计某个关键词出现次数
grep -c "error\|错误" ~/opencode-logs/*.log
```

### 工具3: fzf (模糊搜索，推荐)

```bash
# 安装 fzf
sudo apt install fzf

# 模糊搜索日志
cat ~/opencode-logs/*.log | fzf --tac --no-sort

# 实时搜索 (按 Ctrl+R)
# 或直接:
cat ~/opencode-logs/*.log | fzf
```

### 工具4: ripgrep (rg，更快)

```bash
# 安装
sudo apt install ripgrep

# 搜索 (更快，自动忽略.git等)
rg "关键词" ~/opencode-logs/

# 显示上下文
rg -C 5 "关键词" ~/opencode-logs/
```

---

## 🎨 日志管理脚本

创建 `~/bin/opencode-log-manager.sh`:

```bash
#!/bin/bash

LOG_DIR="$HOME/opencode-logs"

case "$1" in
  clean)
    # 清理30天前的日志
    find "$LOG_DIR" -name "*.log" -mtime +30 -delete
    echo "✅ 已清理30天前的日志"
    ;;
  
  list)
    # 列出所有日志
    ls -lht "$LOG_DIR" | head -20
    ;;
  
  search)
    # 搜索日志
    if [ -z "$2" ]; then
      echo "用法: $0 search <关键词>"
      exit 1
    fi
    rg --color=always -C 3 "$2" "$LOG_DIR" | less -R
    ;;
  
  view)
    # 查看最新日志
    LATEST=$(ls -t "$LOG_DIR"/*.log | head -1)
    less "$LATEST"
    ;;
  
  stats)
    # 统计信息
    echo "📊 OpenCode 日志统计"
    echo "━━━━━━━━━━━━━━━━━━━━━━"
    echo "总日志数: $(ls "$LOG_DIR"/*.log | wc -l)"
    echo "总大小: $(du -sh "$LOG_DIR" | cut -f1)"
    echo "最新日志: $(ls -t "$LOG_DIR"/*.log | head -1)"
    echo ""
    echo "今日会话:"
    ls -lh "$LOG_DIR"/*$(date +%Y%m%d)*.log 2>/dev/null || echo "无"
    ;;
  
  export)
    # 导出为Markdown (方便在Obsidian查看)
    if [ -z "$2" ]; then
      echo "用法: $0 export <日志文件>"
      exit 1
    fi
    
    MD_FILE="${2%.log}.md"
    cat > "$MD_FILE" << EOF
---
tags:
  - opencode/session
date: $(date +%Y-%m-%d)
---

# OpenCode 会话记录

\`\`\`
$(cat "$2")
\`\`\`
EOF
    echo "✅ 已导出: $MD_FILE"
    ;;
  
  *)
    echo "OpenCode 日志管理器"
    echo ""
    echo "用法: $0 <命令>"
    echo ""
    echo "命令:"
    echo "  clean       清理30天前的日志"
    echo "  list        列出所有日志"
    echo "  search <关键词>  搜索日志"
    echo "  view        查看最新日志"
    echo "  stats       显示统计"
    echo "  export <文件>    导出为Markdown"
    ;;
esac
```

使用:
```bash
chmod +x ~/bin/opencode-log-manager.sh

# 查看统计
~/bin/opencode-log-manager.sh stats

# 搜索
~/bin/opencode-log-manager.sh search "架构设计"

# 查看最新
~/bin/opencode-log-manager.sh view

# 清理旧日志
~/bin/opencode-log-manager.sh clean
```

---

## 📊 日志归档到 Obsidian

### 方案: 自动归档重要会话

创建 `~/bin/archive-opencode-session.sh`:

```bash
#!/bin/bash

VAULT_ROOT="/mnt/d/ObsidianVault"
ARCHIVE_DIR="$VAULT_ROOT/30-Resources/OpenCode-Sessions"

mkdir -p "$ARCHIVE_DIR"

# 查找今天的重要会话 (包含关键词)
TODAY_LOGS=$(find ~/opencode-logs -name "*$(date +%Y%m%d)*.log")

for LOG in $TODAY_LOGS; do
  # 检查是否包含重要关键词
  if grep -qiE "架构|设计|决策|关键|important|critical" "$LOG"; then
    TIMESTAMP=$(basename "$LOG" .log | sed 's/opencode-//')
    MD_FILE="$ARCHIVE_DIR/session-$TIMESTAMP.md"
    
    cat > "$MD_FILE" << EOF
---
tags:
  - opencode/session
  - resource/archive
date: $(date +%Y-%m-%d)
importance: high
---

# OpenCode 重要会话 - $TIMESTAMP

> 自动归档: 包含关键决策或设计内容

## 会话内容

\`\`\`
$(cat "$LOG")
\`\`\`

---
*自动归档于: $(date)*
EOF
    
    echo "✅ 已归档: $MD_FILE"
  fi
done
```

### 添加到 cron (每天自动归档)

```bash
# 编辑 crontab
crontab -e

# 添加以下行 (每天23:30归档)
30 23 * * * ~/bin/archive-opencode-session.sh
```

---

## 💡 最佳实践

### 1. 日常使用

```bash
# 早上启动 (自动记录日志)
alias oc='opencode 2>&1 | tee -a ~/opencode-logs/$(date +%Y%m%d).log'
oc

# 查看今天的日志
less ~/opencode-logs/$(date +%Y%m%d).log
```

### 2. 搜索历史

```bash
# 搜索所有会话中的某个关键词
rg "认证模块" ~/opencode-logs/

# 或用 fzf 交互式搜索
cat ~/opencode-logs/*.log | fzf
```

### 3. 定期清理

```bash
# 每周清理一次 (保留最近30天)
find ~/opencode-logs -name "*.log" -mtime +30 -delete
```

---

## 🎯 推荐组合方案

```
OpenCode
    ↓
tee 记录日志 → ~/opencode-logs/
    ↓
fzf/ripgrep 搜索历史
    ↓
归档重要会话 → Obsidian
```

---

## 📊 日志方案对比

| 工具 | 优点 | 缺点 | 适用场景 |
|------|------|------|---------|
| **tee** | 简单、实时 | 仅输出 | 日常使用 |
| **script** | 完整记录 | 需要退出 | 会话回放 |
| **自动脚本** | 自动化 | 需配置 | 长期使用 |

---

*创建日期: 2026-03-11*
