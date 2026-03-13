---
tags:
  - guide/tool
  - terminal/tmux
date: 2026-03-11
---

# tmux 使用指南 - OpenCode 最佳搭档

> 解决OpenCode历史输出查看问题的最佳方案

---

## 🎯 为什么选择 tmux?

| 功能 | OpenCode原生 | tmux增强 |
|------|-------------|---------|
| 滚动历史输出 | ❌ 不方便 | ✅ 自由滚动 |
| 分屏显示 | ❌ 不支持 | ✅ 多窗格 |
| 会话持久化 | ❌ 关闭丢失 | ✅ 后台运行 |
| 搜索历史 | ❌ 困难 | ✅ Ctrl+b [ 进入复制模式 |
| 多会话管理 | ❌ 不支持 | ✅ 多窗口切换 |

---

## 📦 安装

### WSL / Linux

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install tmux -y

# 验证安装
tmux -V

# 创建配置文件
cp /dev/null ~/.tmux.conf
```

---

## ⚙️ 配置 (推荐)

创建 `~/.tmux.conf`:

```bash
# 使用鼠标滚动和选择
set -g mouse on

# 增加历史记录大小 (默认2000, 改为50000)
set -g history-limit 50000

# 使用 Ctrl+a 作为前缀键 (更方便)
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# 分屏快捷键
bind | split-window -h    # Ctrl+a | 垂直分屏
bind - split-window -v    # Ctrl+a - 水平分屏

# 快速重载配置
bind r source-file ~/.tmux.conf \; display "配置已重载!"

# 启用256色
set -g default-terminal "screen-256color"

# 状态栏美化
set -g status-bg black
set -g status-fg white
set -g status-interval 60
set -g status-left-length 30
set -g status-left '#[fg=green](#S) '
set -g status-right '#[fg=yellow]#(whoami)@#H #[fg=white]%H:%M'

# 窗口编号从1开始
set -g base-index 1
setw -g pane-base-index 1

# 关闭窗口自动重编号
set -g renumber-windows on
```

应用配置：
```bash
tmux source-file ~/.tmux.conf
```

---

## 🚀 基本使用

### 启动 OpenCode 会话

```bash
# 创建新会话 (推荐命名)
tmux new -s opencode

# 在会话中启动 OpenCode
cd /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee
opencode

# 现在可以自由滚动查看输出了!
```

### 核心快捷键

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| **滚动历史** | `鼠标滚轮` 或 `Ctrl+a [` | 进入复制模式，可自由滚动 |
| **退出复制模式** | `q` | 返回正常模式 |
| **垂直分屏** | `Ctrl+a \|` | 左右分屏 |
| **水平分屏** | `Ctrl+a -` | 上下分屏 |
| **切换窗格** | `Ctrl+a 方向键` | 在分屏间切换 |
| **创建新窗口** | `Ctrl+a c` | 新建窗口 |
| **切换窗口** | `Ctrl+a 数字` | 切换到第N个窗口 |
| **列出窗口** | `Ctrl+a w` | 显示所有窗口 |
| **会话后台运行** | `Ctrl+a d` | detach会话 |
| **恢复会话** | `tmux attach -t opencode` | 重新连接 |

---

## 💡 OpenCode + tmux 工作流

### 工作流1: 多窗格监控

```bash
# 1. 创建会话
tmux new -s dev

# 2. 启动 OpenCode (左侧窗格)
opencode

# 3. 垂直分屏 (Ctrl+a |)
# 右侧窗格用于查看日志或其他操作

# 4. 在右侧窗格查看 Agent 状态
tail -f */AGENT-STATUS.md

# 5. 切换回左侧继续编码 (Ctrl+a ←)
```

### 工作流2: 查看长输出

```bash
# 1. 在 tmux 中运行 OpenCode
tmux new -s opencode
opencode

# 2. 执行长命令
> 分析整个项目的架构设计

# 3. 滚动查看输出
# 方法A: 直接用鼠标滚轮 (推荐)
# 方法B: Ctrl+a [ 进入复制模式

# 4. 在复制模式中搜索
Ctrl+a [
Ctrl+u  # 向上翻页
Ctrl+d  # 向下翻页
/       # 搜索关键词 (类似 vim)
n       # 下一个匹配
N       # 上一个匹配
q       # 退出复制模式
```

### 工作流3: 持久会话

```bash
# 早上启动工作
tmux new -s opencode
opencode

# 中午休息 - 会话后台运行
Ctrl+a d

# 下午继续工作 - 恢复会话
tmux attach -t opencode
# 所有历史输出都还在!

# 下班前 - 再次后台运行
Ctrl+a d
```

---

## 🎨 高级技巧

### 技巧1: 会话管理脚本

创建 `~/bin/opencode-session.sh`:

```bash
#!/bin/bash

SESSION_NAME="opencode"
PROJECT_ROOT="/mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee"

# 检查会话是否存在
tmux has-session -t $SESSION_NAME 2>/dev/null

if [ $? != 0 ]; then
    echo "🚀 创建新的 OpenCode 会话..."
    tmux new-session -d -s $SESSION_NAME -c $PROJECT_ROOT
    tmux send-keys -t $SESSION_NAME "opencode" C-m
    tmux attach -t $SESSION_NAME
else
    echo "✅ 恢复现有会话..."
    tmux attach -t $SESSION_NAME
fi
```

使用：
```bash
chmod +x ~/bin/opencode-session.sh
~/bin/opencode-session.sh
```

### 技巧2: 自动保存日志

```bash
# 在 tmux 会话中启用日志
Ctrl+a :
: pipe-pane -o "cat >> ~/opencode-#S.log"

# 查看日志
tail -f ~/opencode-opencode.log
```

### 技巧3: 快捷键绑定

在 `~/.tmux.conf` 中添加：

```bash
# F5 启动 OpenCode
bind F5 new-window -n opencode "cd /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee && opencode"

# F6 查看 Token 统计
bind F6 new-window -n stats "cd /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee && ./Git-Hooks/token-budget-manager.sh stats"

# F7 查看 Agent 状态
bind F7 new-window -n agents "cd /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee && tail -f */AGENT-STATUS.md"
```

---

## 🔧 常见问题

### Q1: 鼠标滚动不工作?

```bash
# 确保配置中有这一行
echo "set -g mouse on" >> ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

### Q2: 如何退出 tmux 但保留会话?

```bash
# 方法1: 快捷键
Ctrl+a d

# 方法2: 命令
tmux detach
```

### Q3: 如何杀死会话?

```bash
# 列出所有会话
tmux ls

# 杀死特定会话
tmux kill-session -t opencode

# 杀死所有会话
tmux kill-server
```

### Q4: 复制文本到剪贴板?

```bash
# 进入复制模式
Ctrl+a [

# 移动到起始位置
# 按 Space 开始选择
# 移动到结束位置
# 按 Enter 复制

# 粘贴
Ctrl+a ]
```

---

## 📊 tmux vs 原生终端对比

```
原生终端:
┌─────────────────────────────┐
│ $ opencode                  │
│ > 执行长命令...             │
│ [大量输出]                  │
│ [无法滚动]                  │  ← 上下键切换历史命令
│ [看不到完整输出]            │
│ $ _                         │
└─────────────────────────────┘

tmux:
┌─────────────────────────────┐
│ $ opencode                  │
│ > 执行长命令...             │
│ [大量输出 - 可滚动]         │  ← 鼠标滚轮自由滚动
│ ↑ 可向上滚动50000行        │  ← Ctrl+a [ 进入复制模式
│ $ _                         │
└─────────────────────────────┘

tmux 分屏:
┌────────────────┬────────────┐
│ $ opencode     │ $ tail -f  │
│ > 编码...      │ [日志]     │
│ [输出]         │ [实时]     │
│                │ [监控]     │
└────────────────┴────────────┘
  OpenCode窗格      日志窗格
```

---

## 🎯 推荐配置 (一键安装)

```bash
# 安装 tmux
sudo apt install tmux -y

# 创建优化配置
cat > ~/.tmux.conf << 'EOF'
# 基础设置
set -g mouse on
set -g history-limit 50000
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# 分屏
bind | split-window -h
bind - split-window -v

# 美化
set -g default-terminal "screen-256color"
set -g status-bg black
set -g status-fg white
set -g status-left '#[fg=green](#S) '
set -g status-right '#[fg=yellow]%H:%M'

# 编号
set -g base-index 1
setw -g pane-base-index 1
EOF

# 应用配置
tmux source-file ~/.tmux.conf

# 测试
tmux new -s test
echo "✅ tmux 已配置完成!"
echo "按 Ctrl+a d 退出，tmux attach -t test 恢复"
```

---

## 📚 学习资源

- tmux 官方文档: https://github.com/tmux/tmux/wiki
- tmux 速查表: https://tmuxcheatsheet.com/
- 视频教程: 搜索 "tmux tutorial"

---

*创建日期: 2026-03-11*
