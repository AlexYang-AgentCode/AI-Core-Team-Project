#!/bin/bash

# 本地 Obsidian Vault Git 初始化脚本
# 用途: 一键初始化 vault 的 git 仓库，连接到群晖 Git Server
# 使用: bash 本地初始化脚本.sh

set -e

echo "======================================"
echo "Obsidian Vault Git 初始化脚本"
echo "======================================"

# 配置
NAS_HOST="nas.local"  # 修改为你的 NAS 地址
NAS_USER="root"       # NAS 用户（通常是 root）
GIT_BASE_PATH="/volume1/git-server"  # NAS 上的 git 存储路径
VAULT_PATH="${PWD}"   # 当前目录作为 vault

echo ""
echo "配置信息:"
echo "- NAS 地址: $NAS_HOST"
echo "- Git 存储路径: $GIT_BASE_PATH"
echo "- Vault 路径: $VAULT_PATH"
echo ""

# Step 1: 验证 NAS 连接
echo "[Step 1] 验证 NAS SSH 连接..."
if ssh -o ConnectTimeout=5 $NAS_USER@$NAS_HOST "echo 'SSH connection OK'" > /dev/null 2>&1; then
    echo "✅ NAS 连接成功"
else
    echo "❌ 无法连接到 NAS ($NAS_HOST)"
    echo "请确保:"
    echo "1. NAS IP/域名正确"
    echo "2. NAS 开启了 SSH 服务"
    echo "3. 网络连接正常"
    exit 1
fi

# Step 2: 在 NAS 上创建裸仓库
echo ""
echo "[Step 2] 在 NAS 上创建裸仓库..."

ssh $NAS_USER@$NAS_HOST << 'EOFNAS'
mkdir -p /volume1/git-server
cd /volume1/git-server

# 初始化三个项目的裸仓库
for project in "11-2ndBrain" "12-BetterResearch" "16-DigitalEmployee"; do
    if [ ! -d "$project.git" ]; then
        git init --bare $project.git
        chmod -R 755 $project.git
        echo "✅ 创建了 $project.git"
    else
        echo "⚠️ $project.git 已存在"
    fi
done

echo "✅ NAS 端初始化完成"
EOFNAS

# Step 3: 本地初始化 git
echo ""
echo "[Step 3] 初始化本地 git 仓库..."

if [ ! -d "$VAULT_PATH/.git" ]; then
    cd "$VAULT_PATH"
    git init
    git config user.name "Obsidian Vault"
    git config user.email "vault@obsidian.local"

    # 创建 .gitignore
    cat > .gitignore << 'EOF'
# Obsidian
.obsidian/
*.swp
*.tmp

# System
.DS_Store
Thumbs.db

# Sensitive
.env.local
.env.*.local
*.key
secrets.md
EOF

    # 初始提交
    git add .
    git commit -m "Initial vault commit"

    echo "✅ 本地 git 初始化完成"
else
    echo "⚠️ vault 已是一个 git 仓库"
fi

# Step 4: 添加 remote
echo ""
echo "[Step 4] 配置远程仓库..."

cd "$VAULT_PATH"

# 读取用户输入：选择要备份的项目
echo "选择要初始化备份的项目（可多选，用空格分隔）:"
echo "1) 11-2ndBrain (第二大脑)"
echo "2) 12-BetterResearch (研究系统)"
echo "3) 16-DigitalEmployee (开发自动化)"
echo "4) 全部"
read -p "请输入选择 (默认: 全部): " choice
choice=${choice:-4}

case $choice in
    1)
        projects=("11-2ndBrain")
        ;;
    2)
        projects=("12-BetterResearch")
        ;;
    3)
        projects=("16-DigitalEmployee")
        ;;
    4)
        projects=("11-2ndBrain" "12-BetterResearch" "16-DigitalEmployee")
        ;;
    *)
        echo "❌ 无效选择"
        exit 1
        ;;
esac

# 为每个项目添加 remote
for project in "${projects[@]}"; do
    remote_name="${project//-/_}"  # 用下划线替换连字符
    remote_url="ssh://$NAS_USER@$NAS_HOST$GIT_BASE_PATH/${project}.git"

    if ! git remote | grep -q "$remote_name"; then
        git remote add "$remote_name" "$remote_url"
        echo "✅ 添加了 remote: $remote_name → $remote_url"
    else
        echo "⚠️ remote '$remote_name' 已存在"
    fi
done

# Step 5: 首次推送
echo ""
echo "[Step 5] 执行首次推送..."

for project in "${projects[@]}"; do
    remote_name="${project//-/_}"

    echo "推送 $project..."
    if git push -u "$remote_name" main 2>/dev/null || git push -u "$remote_name" master 2>/dev/null; then
        echo "✅ $project 推送成功"
    else
        echo "⚠️ $project 推送失败（可能分支名不是 main/master）"
        echo "   请手动执行: git push -u $remote_name [branch_name]"
    fi
done

# 完成
echo ""
echo "======================================"
echo "✅ 初始化完成！"
echo "======================================"
echo ""
echo "后续操作:"
echo "1. 日常 git 操作:"
echo "   git add ."
echo "   git commit -m '你的提交信息'"
echo "   git push [remote_name] [branch]"
echo ""
echo "2. 自动备份，将以下命令添加到 crontab:"
echo "   0 23 * * * cd $VAULT_PATH && git add . && git commit -m 'Daily backup' && git push"
echo ""
echo "3. 查看 remote 状态:"
echo "   git remote -v"
echo ""
