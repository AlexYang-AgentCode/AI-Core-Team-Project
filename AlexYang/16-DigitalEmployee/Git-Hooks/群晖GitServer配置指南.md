---
tags:
  - project/dev
  - system/setup
date: 2026-03-09
---

# 群晖 Git Server 配置指南

## 前置条件

- ✅ 群晖 NAS（任何型号）
- ✅ SSH 访问权限
- ✅ 至少 1GB 可用空间

---

## Step 1: 群晖 NAS 端配置

### 1.1 创建 Git 存储目录

SSH 登入群晖，执行：

```bash
# 创建 git-server 目录
mkdir -p /volume1/git-server
cd /volume1/git-server

# 初始化裸仓库（示例：项目 11-2ndBrain）
git init --bare 11-2ndBrain.git
git init --bare 12-BetterResearch.git
git init --bare 16-DigitalEmployee.git

# 设置权限
chmod -R 755 *.git
chown -R root:users *.git
```

### 1.2 配置 post-receive Hook（自动同步到 Obsidian）

在 NAS 上，创建文件：`/volume1/git-server/11-2ndBrain.git/hooks/post-receive`

```bash
#!/bin/bash

# Git Server 端的 post-receive hook
# 在 push 完成后自动更新 Obsidian vault 中的项目状态

VAULT_PATH="/volume1/obsidian-sync/vault"  # 修改为你的 vault 路径
PROJECT="11-2ndBrain"
GIT_DIR="/volume1/git-server/11-2ndBrain.git"

# 检查 vault 是否存在
if [ ! -d "$VAULT_PATH" ]; then
    echo "ERROR: Vault 路径不存在: $VAULT_PATH"
    exit 1
fi

# 获取 push 信息
while read oldrev newrev refname; do
    COMMIT_MSG=$(git --git-dir="$GIT_DIR" log -1 --format=%B $newrev)
    COMMIT_AUTHOR=$(git --git-dir="$GIT_DIR" log -1 --format=%an $newrev)
    COMMIT_TIME=$(git --git-dir="$GIT_DIR" log -1 --format=%ai $newrev)

    # 生成项目状态更新文件
    REPORT_FILE="$VAULT_PATH/10-Projects/$PROJECT/Git-Push-Report.md"

    cat >> "$REPORT_FILE" <<EOF

## [自动记录] $(date '+%Y-%m-%d %H:%M:%S')

**提交者**: $COMMIT_AUTHOR
**提交时间**: $COMMIT_TIME
**提交信息**:
$COMMIT_MSG

**新 Commit Hash**: $newrev

EOF

    echo "[Success] Project status updated in vault"
done

exit 0
```

设置执行权限：

```bash
chmod +x /volume1/git-server/11-2ndBrain.git/hooks/post-receive
chmod +x /volume1/git-server/12-BetterResearch.git/hooks/post-receive
chmod +x /volume1/git-server/16-DigitalEmployee.git/hooks/post-receive
```

---

## Step 2: 本地开发端配置

### 2.1 添加 Git Remote

在你的本地项目中：

```bash
# 进入项目目录
cd /path/to/your/project

# 添加远程仓库
git remote add synology ssh://nas.local/volume1/git-server/11-2ndBrain.git

# 验证（可选）
git remote -v
```

### 2.2 首次推送

```bash
# 创建本地分支（如还没有）
git branch -M main

# 推送到群晖
git push -u synology main
```

### 2.3 日常工作流

```bash
# 正常提交
git add .
git commit -m "描述你的修改"

# 推送到群晖（自动触发 post-receive hook）
git push synology main
```

---

## Step 3: Obsidian Vault 与 Git 集成

### 3.1 在 Vault 根目录配置

创建 `.git-config.sh` 脚本，供 vault-worker.sh 调用：

```bash
#!/bin/bash

# 每日自动备份 Obsidian vault 到群晖 Git Server

VAULT_PATH="/path/to/obsidian/vault"
BACKUP_REMOTE="ssh://nas.local/volume1/git-server/vault-backup.git"

cd "$VAULT_PATH"

# 检查是否有未提交的更改
if [ -n "$(git status --porcelain)" ]; then
    echo "[$(date '+%Y-%m-%d %H:%M')] Backing up vault to NAS..."

    git add -A
    git commit -m "Vault backup: $(date '+%Y-%m-%d %H:%M:%S')"
    git push origin main || echo "Push failed, will retry later"
else
    echo "[$(date '+%Y-%m-%d %H:%M')] No changes to backup"
fi
```

### 3.2 集成到 vault-worker.sh

在现有的 `vault-worker.sh` 中添加：

```bash
# 在脚本末尾添加备份命令
/path/to/.git-config.sh
```

---

## Step 4: 测试与验证

### 4.1 NAS 端验证

```bash
# SSH 登入 NAS
ssh admin@nas.local

# 验证仓库是否创建成功
ls -la /volume1/git-server/
# 应该看到: 11-2ndBrain.git/  12-BetterResearch.git/  16-DigitalEmployee.git/

# 验证 hook 是否存在且可执行
ls -l /volume1/git-server/11-2ndBrain.git/hooks/post-receive
# 应该显示: -rwxr-xr-x
```

### 4.2 本地端验证

```bash
# 执行一次推送测试
git push synology main

# 检查返回消息
# 应该看到: "[Success] Project status updated in vault"
```

### 4.3 验证 Vault 更新

检查 `10-Projects/11-2ndBrain/Git-Push-Report.md` 中是否有新的自动记录。

---

## 故障排查

### 问题 1: SSH 连接失败

**错误信息**: `Permission denied (publickey,gssapi-keyex,gssapi-with-mic)`

**解决方案**:
```bash
# 确保群晖开启了 SSH 服务
# 群晖 → 控制面板 → 终端机和 SNMP → 启用 SSH 功能

# 测试连接
ssh -v admin@nas.local
```

### 问题 2: post-receive Hook 未执行

**症状**: 推送成功但 vault 中没有更新

**解决方案**:
```bash
# SSH 登入 NAS，检查 hook 权限
chmod +x /volume1/git-server/*/hooks/post-receive

# 检查 hook 是否有输出
# 修改 hook 脚本，加入日志输出：
echo "Hook executed at $(date)" >> /volume1/git-server/hook-log.txt
```

### 问题 3: 仓库大小过大

**症状**: 推送速度慢或失败

**解决方案**:
```bash
# 在本地执行垃圾回收
git gc --aggressive

# 再试一次推送
git push synology main
```

---

## 安全建议

| 项目 | 建议 |
|------|------|
| **SSH 密钥** | 使用 4096 位 RSA 或 Ed25519 密钥 |
| **备份** | 定期备份 `/volume1/git-server/` 目录 |
| **权限** | 只授予需要的用户 git 访问权限 |
| **日志** | 启用审计日志追踪所有 git 操作 |

---

## 参考资源

- [[16-DigitalEmployee CONTEXT]]
- [[Git-Workflow Architecture]]

---

*Last Updated: 2026-03-09* | *维护者: Claude Code*
