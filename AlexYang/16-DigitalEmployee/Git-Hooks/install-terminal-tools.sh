#!/bin/bash

# OpenCode 终端优化 - 一键安装脚本
# 使用: ./install-terminal-tools.sh

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}🚀 OpenCode 终端优化工具安装${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ============================================
# 1. 安装基础工具
# ============================================

echo -e "${GREEN}📦 安装基础工具...${NC}"

# ripgrep (快速搜索)
if ! command -v rg &> /dev/null; then
    echo "  安装 ripgrep..."
    sudo apt update -qq
    sudo apt install -y ripgrep
else
    echo "  ✅ ripgrep 已安装"
fi

# fzf (模糊搜索)
if ! command -v fzf &> /dev/null; then
    echo "  安装 fzf..."
    sudo apt install -y fzf
else
    echo "  ✅ fzf 已安装"
fi

# less (查看器，通常已有)
if ! command -v less &> /dev/null; then
    echo "  安装 less..."
    sudo apt install -y less
else
    echo "  ✅ less 已安装"
fi

echo ""

# ============================================
# 2. 安装 tmux (可选但推荐)
# ============================================

echo -e "${YELLOW}是否安装 tmux? (推荐用于分屏和会话持久化) [Y/n]${NC}"
read -r response

if [[ ! "$response" =~ ^[Nn]$ ]]; then
    echo -e "${GREEN}📦 安装 tmux...${NC}"
    
    # 安装 tmux
    if ! command -v tmux &> /dev/null; then
        sudo apt install -y tmux
        echo "  ✅ tmux 已安装"
    else
        echo "  ✅ tmux 已安装"
    fi
    
    # 创建配置文件
    echo "  配置 tmux..."
    cat > ~/.tmux.conf << 'TMUXEOF'
# 基础设置
set -g mouse on
set -g history-limit 50000
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# 分屏快捷键
bind | split-window -h
bind - split-window -v

# 快速重载配置
bind r source-file ~/.tmux.conf \; display "✅ 配置已重载!"

# 美化
set -g default-terminal "screen-256color"
set -g status-bg black
set -g status-fg white
set -g status-interval 60
set -g status-left '#[fg=green](#S) '
set -g status-right '#[fg=yellow]%H:%M'

# 窗口编号
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on

# OpenCode 专用快捷键
bind F5 new-window -n opencode "cd /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee && opencode 2>&1 | tee -a ~/opencode-logs/$(date +%Y%m%d-%H%M%S).log"
bind F6 new-window -n stats "cd /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee && ./Git-Hooks/token-budget-manager.sh stats; read -p '按回车继续...'"
TMUXEOF
    
    echo "  ✅ tmux 配置已创建: ~/.tmux.conf"
    
    # 创建 tmux 会话脚本
    cat > ~/bin/tmux-opencode << 'TMUXSCRIPT'
#!/bin/bash

SESSION_NAME="opencode"
PROJECT_ROOT="/mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee"

tmux has-session -t $SESSION_NAME 2>/dev/null

if [ $? != 0 ]; then
    echo "🚀 创建新的 OpenCode 会话..."
    tmux new-session -d -s $SESSION_NAME -c $PROJECT_ROOT
    tmux send-keys -t $SESSION_NAME "opencode 2>&1 | tee -a ~/opencode-logs/$(date +%Y%m%d-%H%M%S).log" C-m
    echo "✅ 会话已创建: $SESSION_NAME"
    echo "💡 连接命令: tmux attach -t $SESSION_NAME"
else
    echo "✅ 会话已存在: $SESSION_NAME"
    echo "💡 连接命令: tmux attach -t $SESSION_NAME"
fi

tmux attach -t $SESSION_NAME
TMUXSCRIPT
    
    chmod +x ~/bin/tmux-opencode
    echo "  ✅ tmux 快捷脚本已创建: ~/bin/tmux-opencode"
else
    echo "  ⏭️  跳过 tmux 安装"
fi

echo ""

# ============================================
# 3. 创建日志管理脚本
# ============================================

echo -e "${GREEN}📝 创建日志管理脚本...${NC}"

mkdir -p ~/bin

cat > ~/bin/opencode-logs << 'LOGSCRIPT'
#!/bin/bash

LOG_DIR="$HOME/opencode-logs"

case "$1" in
  list|ls)
    echo "📋 OpenCode 日志列表"
    echo "━━━━━━━━━━━━━━━━━━━━━━"
    ls -lht "$LOG_DIR" | head -20
    ;;
  
  view)
    LATEST=$(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1)
    if [ -n "$LATEST" ]; then
        echo "📄 查看最新日志: $(basename $LATEST)"
        less "$LATEST"
    else
        echo "❌ 没有找到日志文件"
    fi
    ;;
  
  search)
    if [ -z "$2" ]; then
        echo "用法: opencode-logs search <关键词>"
        exit 1
    fi
    echo "🔍 搜索: $2"
    echo "━━━━━━━━━━━━━━━━━━━━━━"
    rg --color=always -C 3 "$2" "$LOG_DIR" | less -R
    ;;
  
  today)
    TODAY=$(date +%Y%m%d)
    echo "📅 今日日志"
    echo "━━━━━━━━━━━━━━━━━━━━━━"
    ls -lh "$LOG_DIR"/*$TODAY*.log 2>/dev/null || echo "今日暂无日志"
    ;;
  
  clean)
    echo "🧹 清理30天前的日志..."
    find "$LOG_DIR" -name "*.log" -mtime +30 -delete
    echo "✅ 清理完成"
    ;;
  
  stats)
    echo "📊 OpenCode 日志统计"
    echo "━━━━━━━━━━━━━━━━━━━━━━"
    echo "总日志数: $(ls "$LOG_DIR"/*.log 2>/dev/null | wc -l)"
    echo "总大小: $(du -sh "$LOG_DIR" 2>/dev/null | cut -f1)"
    echo "最新日志: $(ls -t "$LOG_DIR"/*.log 2>/dev/null | head -1 | xargs basename 2>/dev/null || echo '无')"
    echo ""
    echo "今日会话:"
    ls -lh "$LOG_DIR"/*$(date +%Y%m%d)*.log 2>/dev/null || echo "无"
    ;;
  
  fuzzy)
    echo "🔍 模糊搜索 (按 Ctrl+C 退出)..."
    cat "$LOG_DIR"/*.log 2>/dev/null | fzf --tac --no-sort
    ;;
  
  *)
    echo "OpenCode 日志管理器"
    echo ""
    echo "用法: opencode-logs <命令>"
    echo ""
    echo "命令:"
    echo "  list, ls       列出所有日志"
    echo "  view           查看最新日志"
    echo "  search <关键词>  搜索日志"
    echo "  today          显示今日日志"
    echo "  clean          清理30天前的日志"
    echo "  stats          显示统计信息"
    echo "  fuzzy          模糊搜索 (fzf)"
    ;;
esac
LOGSCRIPT

chmod +x ~/bin/opencode-logs
echo "  ✅ 日志管理脚本已创建: ~/bin/opencode-logs"

echo ""

# ============================================
# 4. 添加别名到 bashrc (如果还没有)
# ============================================

echo -e "${GREEN}📝 检查 bash 别名...${NC}"

if ! grep -q "# OpenCode 快捷命令" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# ============================================
# OpenCode 快捷命令
# ============================================

# OpenCode + 日志记录 (推荐)
alias oc='opencode 2>&1 | tee -a ~/opencode-logs/$(date +%Y%m%d-%H%M%S).log'

# OpenCode + DeepSeek (编码主力)
alias ocd='opencode --model deepseek-coder 2>&1 | tee -a ~/opencode-logs/$(date +%Y%m%d-%H%M%S).log'

# OpenCode + Kimi (文档分析)
alias ock='opencode --model kimi-k2 2>&1 | tee -a ~/opencode-logs/$(date +%Y%m%d-%H%M%S).log'

# OpenCode + GLM (测试审查)
alias ocg='opencode --model glm-4 2>&1 | tee -a ~/opencode-logs/$(date +%Y%m%d-%H%M%S).log'

# 查看最新日志
alias ocl='less ~/opencode-logs/$(ls -t ~/opencode-logs/*.log 2>/dev/null | head -1 | xargs basename)'

# 搜索日志
alias ocs='function _search_logs() { rg --color=always -C 3 "$1" ~/opencode-logs/ | less -R; }; _search_logs'

# Token 统计
alias token-stats='cd /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee && ./Git-Hooks/token-budget-manager.sh stats'

# 快速进入项目目录
alias proj='cd /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee'

EOF
    echo "  ✅ 别名已添加到 ~/.bashrc"
else
    echo "  ✅ 别名已存在"
fi

echo ""

# ============================================
# 5. 完成提示
# ============================================

echo -e "${GREEN}✅ 安装完成!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🎯 现在你可以:"
echo ""
echo "1️⃣  在 VSCode 中使用 OpenCode:"
echo "    code /mnt/d/ObsidianVault"
echo "    Ctrl + \` (打开终端)"
echo "    oc (启动 OpenCode + 日志)"
echo ""
echo "2️⃣  使用 tmux (如果安装了):"
echo "    ~/bin/tmux-opencode"
echo "    或: tmux new -s opencode"
echo ""
echo "3️⃣  管理日志:"
echo "    opencode-logs stats     # 查看统计"
echo "    opencode-logs view      # 查看最新"
echo "    opencode-logs search X  # 搜索"
echo "    opencode-logs fuzzy     # 模糊搜索"
echo ""
echo "4️⃣  快捷命令:"
echo "    oc    # OpenCode + 日志"
echo "    ocd   # OpenCode + DeepSeek"
echo "    ock   # OpenCode + Kimi"
echo "    ocl   # 查看最新日志"
echo "    ocs   # 搜索日志"
echo ""
echo "📚 详细文档:"
echo "    VSCode终端: VSCode终端使用指南.md"
echo "    tmux: tmux使用指南.md"
echo "    日志: OpenCode日志方案.md"
echo ""

# 重载 bashrc
echo -e "${YELLOW}💡 运行以下命令重载配置:${NC}"
echo "    source ~/.bashrc"
