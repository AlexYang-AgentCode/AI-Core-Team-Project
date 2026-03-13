#!/bin/bash
# Git 同步脚本 - 使用 Token 认证
# 配置方法:
# 1. 在 Git 平台(GitHub/GitLab等)生成 Personal Access Token
# 2. 配置 remote URL: git remote set-url origin https://TOKEN@github.com/username/repo.git
#    或使用: git config --global credential.helper store (首次输入后会保存)

echo "========================================"
echo "正在同步: AndroidToHarmonyOSDemo"
echo "========================================"

# 进入脚本所在目录
cd "$(dirname "$0")"

# 检查是否是 git 仓库
if [ -d ".git" ]; then
    echo "→ 正在 pull 主仓库..."
    git pull
    if [ $? -eq 0 ]; then
        echo "✓ 主仓库同步成功"
    else
        echo "✗ 主仓库同步失败"
        echo "提示: 如果认证失败，请配置 Token"
        echo "  git remote set-url origin https://TOKEN@github.com/username/repo.git"
    fi
else
    echo "! 主目录不是 git 仓库，跳过"
fi

# 同步子项目
for dir in */; do
    if [ -d "$dir/.git" ]; then
        echo ""
        echo "→ 正在同步子项目: $dir"
        cd "$dir"
        git pull
        if [ $? -eq 0 ]; then
            echo "✓ $dir 同步成功"
        else
            echo "✗ $dir 同步失败"
        fi
        cd ..
    fi
done

echo ""
echo "========================================"
echo "同步完成"
echo "========================================"
