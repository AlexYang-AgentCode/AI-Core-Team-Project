---
tags:
  - guide/tool
  - terminal/vscode
date: 2026-03-11
---

# VSCode 集成终端 - OpenCode 轻量方案

> 最简单的解决方案，无需额外安装

---

## ✨ 优势

- ✅ 已安装VSCode的话，无需额外工具
- ✅ 图形界面，滚动方便
- ✅ 内置搜索功能
- ✅ 多终端标签页
- ✅ 分屏显示

---

## 🚀 快速开始

### 1. 打开VSCode集成终端

```bash
# 方法1: 快捷键
Ctrl + `  (反引号)

# 方法2: 菜单
Terminal > New Terminal

# 方法3: 命令面板
Ctrl+Shift+P -> "Terminal: Create New Terminal"
```

### 2. 启动 OpenCode

```bash
cd /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee
opencode
```

### 3. 查看历史输出

```
✅ 直接用鼠标滚轮滚动
✅ 使用 Ctrl+F 搜索
✅ 选中文本后 Ctrl+C 复制
```

---

## 🎨 推荐配置

在 VSCode 中打开设置 (Ctrl+,)，搜索 "terminal":

### settings.json

```json
{
  // 终端字体
  "terminal.integrated.fontFamily": "Consolas, 'Courier New', monospace",
  "terminal.integrated.fontSize": 14,
  
  // 增加滚动缓冲区 (默认1000, 改为100000)
  "terminal.integrated.scrollback": 100000,
  
  // 启用鼠标滚动
  "terminal.integrated.mouseWheelScrollSensitivity": 1.0,
  
  // 自动复制选中内容
  "terminal.integrated.copyOnSelection": true,
  
  // 光标样式
  "terminal.integrated.cursorStyle": "line",
  "terminal.integrated.cursorBlinking": true,
  
  // Shell 集成
  "terminal.integrated.shellIntegration.enabled": true,
  
  // 默认使用 WSL
  "terminal.integrated.defaultProfile.windows": "WSL",
  
  // 终端配置文件
  "terminal.integrated.profiles.windows": {
    "WSL": {
      "path": "C:\\Windows\\System32\\wsl.exe",
      "args": ["-d", "Ubuntu"]
    },
    "OpenCode": {
      "path": "C:\\Windows\\System32\\wsl.exe",
      "args": ["-d", "Ubuntu", "-e", "opencode"],
      "icon": "terminal"
    }
  }
}
```

---

## 💡 工作流

### 工作流1: 多终端标签页

```
┌─────────────────────────────────────────┐
│ Terminal 1 │ Terminal 2 │ Terminal 3    │ ← 多个终端标签
├─────────────────────────────────────────┤
│ $ opencode                              │
│ > 执行命令...                           │
│ [可滚动的历史输出]                      │
└─────────────────────────────────────────┘

操作:
- 点击 "+" 创建新终端
- 点击标签切换
- 右键标签 → "Split Terminal" 分屏
```

### 工作流2: 分屏显示

```
┌──────────────────┬──────────────────────┐
│ Terminal 1       │ Terminal 2           │
│ $ opencode       │ $ tail -f */STATUS   │
│ > 编码...        │ [实时监控]           │
│                  │                      │
└──────────────────┴──────────────────────┘

操作:
- 终端右侧 "Split" 按钮
- 或右键终端标签 → "Split Terminal"
```

### 工作流3: 搜索历史

```
在终端中按 Ctrl+F:

┌─────────────────────────────────────────┐
│ Find: [architecture        ] [X] [↵]  │ ← 搜索框
├─────────────────────────────────────────┤
│ [大量输出...]                           │
│ ... based on the **architecture** ...   │ ← 高亮匹配
│ ... architecture design ...             │
│ [可继续向上滚动查看更多匹配]            │
└─────────────────────────────────────────┘
```

---

## 🔧 快捷键

| 操作 | 快捷键 | 说明 |
|------|--------|------|
| **打开终端** | `Ctrl + \` ` | 打开/关闭终端 |
| **新建终端** | `Ctrl+Shift+\` ` | 创建新终端 |
| **滚动查找** | `Ctrl+F` | 在终端中搜索 |
| **分屏终端** | `Ctrl+Shift+5` | 分割终端 |
| **清屏** | `Ctrl+L` | 清除屏幕 (历史仍保留) |
| **上/下翻页** | `Ctrl+PgUp/PgDn` | 快速翻页 |

---

## 🎯 推荐扩展

### 1. Terminal Manager

```bash
# 安装
code --install-extension fabiospampinato.terminal-manager

# 配置快捷启动 OpenCode
# settings.json:
{
  "terminalManager.terminalConfigs": {
    "OpenCode": {
      "command": "opencode",
      "cwd": "/mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee"
    }
  }
}

# 使用
Ctrl+Shift+P -> "Terminal Manager: Launch"
```

### 2. Code Runner (可选)

```bash
# 安装
code --install-extension formulahendry.code-runner

# 快速运行命令
# 但对于交互式 OpenCode 不太适用
```

---

## 📊 VSCode vs 原生终端对比

| 功能 | 原生WSL终端 | VSCode终端 |
|------|------------|-----------|
| 滚动历史 | ❌ 不方便 | ✅ 鼠标自由滚动 |
| 搜索 | ❌ 无 | ✅ Ctrl+F |
| 分屏 | ❌ 无 | ✅ 内置 |
| 多标签 | ❌ 无 | ✅ 内置 |
| 配置难度 | - | ✅ 简单 |
| 性能 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| 适合场景 | 纯命令行 | 开发+OpenCode |

---

## 🚀 推荐设置 (一键配置)

在 VSCode 中打开 settings.json (Ctrl+Shift+P -> "Open Settings (JSON)"):

```json
{
  // 终端基础设置
  "terminal.integrated.scrollback": 100000,
  "terminal.integrated.fontSize": 14,
  "terminal.integrated.fontFamily": "Consolas, 'Courier New', monospace",
  "terminal.integrated.copyOnSelection": true,
  "terminal.integrated.mouseWheelScrollSensitivity": 1.5,
  
  // 光标
  "terminal.integrated.cursorStyle": "line",
  "terminal.integrated.cursorBlinking": true,
  
  // Shell 集成
  "terminal.integrated.shellIntegration.enabled": true,
  "terminal.integrated.defaultProfile.windows": "WSL",
  
  // 快捷启动 OpenCode
  "terminal.integrated.profiles.windows": {
    "OpenCode": {
      "path": "C:\\Windows\\System32\\wsl.exe",
      "args": [
        "-d", "Ubuntu",
        "-e", "bash", "-c", 
        "cd /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee && opencode; exec bash"
      ],
      "icon": "server-process"
    }
  }
}
```

使用:
```
Ctrl+Shift+P -> "Terminal: Create New Terminal (With Profile)" -> 选择 "OpenCode"
```

---

## 💡 最佳实践

### 1. 项目工作区

创建 `.vscode/settings.json`:

```json
{
  "terminal.integrated.cwd": "${workspaceFolder}",
  "terminal.integrated.env.linux": {
    "OPENCODE_CONFIG": "${workspaceFolder}/opencode.json"
  }
}
```

### 2. 任务自动化

创建 `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "启动 OpenCode",
      "type": "shell",
      "command": "opencode",
      "problemMatcher": [],
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": true,
        "panel": "new",
        "showReuseMessage": false,
        "clear": false
      }
    },
    {
      "label": "查看 Agent 状态",
      "type": "shell",
      "command": "./Git-Hooks/token-budget-manager.sh stats",
      "problemMatcher": []
    }
  ]
}
```

使用: `Ctrl+Shift+B` -> 选择任务

---

## 🎯 适合人群

✅ **推荐使用 VSCode 终端，如果:**
- 已经在使用 VSCode 开发
- 喜欢图形界面
- 需要分屏和多标签
- 需要搜索历史输出

❌ **不推荐，如果:**
- 纯命令行工作
- 追求极致性能
- 需要会话持久化 (建议用 tmux)

---

*创建日期: 2026-03-11*
