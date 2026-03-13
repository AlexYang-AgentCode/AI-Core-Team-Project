#!/bin/bash
# AlexYang 项目 Git 同步脚本
# 使用 Token 认证方式推送到 GitHub

set -e

echo "========================================"
echo "AlexYang 项目 Git 同步"
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"

# 获取脚本所在目录的父目录（AI-Core-Team-Project 根目录）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "→ 项目根目录: $PROJECT_ROOT"
cd "$PROJECT_ROOT"

# 检查是否是 git 仓库
if [ ! -d ".git" ]; then
    echo "✗ 错误: 当前目录不是 git 仓库"
    exit 1
fi

# 获取当前分支
BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
echo "→ 当前分支: $BRANCH"

# 获取 remote 信息
echo "→ Remote URL:"
git remote -v

echo ""
echo "========================================"
echo "开始同步"
echo "========================================"

# 1. 拉取最新代码
echo ""
echo "→ Step 1: 拉取远程更新..."
if git pull origin "$BRANCH"; then
    echo "✓ 拉取成功"
else
    echo "⚠ 拉取失败，继续执行..."
fi

# 2. 检查是否有变更
echo ""
echo "→ Step 2: 检查本地变更..."
if git status --porcelain | grep -q .; then
    echo "✓ 发现本地变更:"
    git status -s

    # 3. 添加变更
    echo ""
    echo "→ Step 3: 添加变更到暂存区..."
    git add AlexYang/
    echo "✓ 已添加 AlexYang/ 目录"

    # 4. 提交变更
    echo ""
    echo "→ Step 4: 提交变更..."
    COMMIT_MSG="更新 AlexYang 项目 - $(date '+%Y-%m-%d %H:%M')"
    git commit -m "$COMMIT_MSG"
    echo "✓ 提交成功: $COMMIT_MSG"

    # 5. 推送到远程
    echo ""
    echo "→ Step 5: 推送到远程..."
    if git push origin "$BRANCH"; then
        echo "✓ 推送成功"
    else
        echo "✗ 推送失败"
        echo ""
        echo "可能的解决方案:"
        echo "  1. 检查 Token 是否有效: git remote -v"
        echo "  2. 更新 remote URL: git remote set-url origin https://TOKEN@github.com/AlexYang-AgentCode/AI-Core-Team-Project.git"
        echo "  3. 检查网络连接"
        exit 1
    fi
else
    echo "✓ 没有本地变更需要提交"
fi

echo ""
echo "========================================"
echo "同步完成: $(date '+%H:%M:%S')"
echo "========================================"
echo ""
echo "最新提交:"
git log -1 --oneline --no-decorate
