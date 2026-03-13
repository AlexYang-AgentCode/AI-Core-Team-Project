#!/bin/bash
# Git 同步脚本

echo "========================================"
echo "正在同步: 16.2-AgenticWorkFlow"
echo "========================================"

# 进入脚本所在目录
cd "$(dirname "$0")"

# 检查是否是 git 仓库
if [ -d ".git" ]; then
    echo "→ 正在执行 git pull..."
    git pull
    if [ $? -eq 0 ]; then
        echo "✓ 同步成功"
    else
        echo "✗ 同步失败"
    fi
else
    echo "! 当前目录不是 git 仓库"
    exit 1
fi

echo "========================================"
