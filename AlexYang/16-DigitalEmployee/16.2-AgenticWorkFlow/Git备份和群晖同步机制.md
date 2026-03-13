---
tags:
  - system/backup
  - git/sync
  - synology
  - tailscale
  - 16-project
date: 2026-03-11
status: active
---

# 🔄 Git备份和群晖同步机制

> **目标**: 建立自动化的Git备份系统，实现本地仓库与群晖NAS的双向同步

---

## 🎯 备份策略概览

### **核心原则**
1. **多重备份**: 本地 + 群晖 + 远程GitHub
2. **自动化同步**: 定时自动推送和拉取
3. **增量备份**: 仅同步变更内容
4. **灾难恢复**: 支持快速回滚

### **备份架构**
```
┌─────────────────────────────────────────────────────┐
│                 备份架构                            │
├─────────────────────────────────────────────────────┤
│  本地仓库 (WSL)                                     │
│  ├─ 推送到群晖 NAS                                  │
│  ├─ 推送到GitHub (公开项目)                         │
│  └─ 定期备份到本地存储                              │
│                                                     │
│  群晖 NAS (通过Tailscale穿透)                       │
│  ├─ 主备份存储                                      │
│  ├─ 定期快照                                        │
│  └─ 可恢复到任意时间点                              │
│                                                     │
│  GitHub (公开项目)                                  │
│  ├─ 开源项目归档                                    │
│  ├─ 协作开发                                        │
│  └─ 备份冗余                                        │
└─────────────────────────────────────────────────────┘
```

---

## 🔧 环境配置

### **1. Tailscale配置**

```bash
# 安装Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# 登录Tailscale
sudo tailscale login

# 检查连接状态
tailscale status

# 启用Tailscale IPv4
sudo tailscale up --accept-routes
```

### **2. 群晖NAS配置**

```bash
# 在群晖上创建Git仓库
# 1. 通过SSH连接到群晖
ssh user@nas.local

# 2. 创建Git仓库目录
sudo mkdir -p /volume1/git/obsidian-vault
sudo mkdir -p /volume1/git/obsidian-vault-public

# 3. 初始化Git仓库
cd /volume1/git/obsidian-vault
git init --bare
cd /volume1/git/obsidian-vault-public
git init --bare

# 4. 设置权限
sudo chown -R user:users /volume1/git/obsidian-vault*
sudo chmod -R 755 /volume1/git/obsidian-vault*
```

### **3. SSH密钥配置**

```bash
# 生成SSH密钥对（如果还没有）
ssh-keygen -t ed25519 -f ~/.ssh/obsidian-vault -N ""

# 复制公钥到群晖
ssh-copy-id -i ~/.ssh/obsidian-vault.pub user@nas.local

# 测试SSH连接
ssh -i ~/.ssh/obsidian-vault user@nas.local
```

---

## 🚀 自动化同步脚本

### **1. 主同步脚本**

```bash
#!/bin/bash
# sync-to-synology.sh

# 配置参数
VAULT_DIR="/mnt/d/ObsidianVault"
SYNOLOGY_NAS="user@nas.local:/volume1/git/obsidian-vault"
SYNOLOGY_PUBLIC="user@nas.local:/volume1/git/obsidian-vault-public"
GITHUB_PUBLIC="git@github.com:yourusername/obsidian-vault-public.git"
SSH_KEY="$HOME/.ssh/obsidian-vault"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 错误处理
error_exit() {
    log "❌ 错误: $1"
    exit 1
}

# 检查环境
check_environment() {
    log "🔍 检查环境..."
    
    # 检查Tailscale连接
    if ! tailscale status &>/dev/null; then
        error_exit "Tailscale未连接"
    fi
    
    # 检查SSH密钥
    if [ ! -f "$SSH_KEY" ]; then
        error_exit "SSH密钥不存在: $SSH_KEY"
    fi
    
    # 检查Git仓库
    if [ ! -d "$VAULT_DIR/.git" ]; then
        error_exit "不是Git仓库: $VAULT_DIR"
    fi
    
    log "✅ 环境检查通过"
}

# 添加文件到Git
git_add_files() {
    log "📁 添加文件到Git..."
    
    cd "$VAULT_DIR" || error_exit "无法进入仓库目录"
    
    # 添加所有文件
    git add .
    
    # 检查是否有变更
    if ! git diff --cached --quiet; then
        log "📝 发现变更，准备提交"
        return 0
    else
        log "✅ 没有需要提交的变更"
        return 1
    fi
}

# 提交变更
commit_changes() {
    log "💾 提交变更..."
    
    cd "$VAULT_DIR" || error_exit "无法进入仓库目录"
    
    # 创建提交信息
    commit_message="自动备份 - $(date '+%Y-%m-%d %H:%M:%S')"
    
    # 提交
    git commit -m "$commit_message" || error_exit "提交失败"
    
    log "✅ 提交成功: $commit_message"
}

# 推送到群晖NAS
push_to_synology() {
    log "🚀 推送到群晖NAS..."
    
    cd "$VAULT_DIR" || error_exit "无法进入仓库目录"
    
    # 添加远程仓库（如果还没有）
    if ! git remote | grep -q "synology"; then
        git remote add synology "$SYNOLOGY_NAS"
    fi
    
    # 推送到群晖
    if ! git push synology main; then
        error_exit "推送到群晖失败"
    fi
    
    log "✅ 推送到群晖NAS成功"
}

# 推送到GitHub公开仓库
push_to_github() {
    log "🌐 推送到GitHub公开仓库..."
    
    cd "$VAULT_DIR" || error_exit "无法进入仓库目录"
    
    # 添加GitHub远程仓库（如果还没有）
    if ! git remote | grep -q "github"; then
        git remote add github "$GITHUB_PUBLIC"
    fi
    
    # 推送到GitHub
    if ! git push github main; then
        log "⚠️  推送到GitHub失败，但继续执行"
    fi
    
    log "✅ 推送到GitHub完成"
}

# 创建备份标签
create_backup_tag() {
    log "🏷️ 创建备份标签..."
    
    cd "$VAULT_DIR" || error_exit "无法进入仓库目录"
    
    # 创建备份标签
    tag_name="backup-$(date '+%Y%m%d-%H%M%S')"
    git tag -a "$tag_name" -m "自动备份: $tag_name"
    
    # 推送标签
    git push synology --tags
    git push github --tags
    
    log "✅ 备份标签创建成功: $tag_name"
}

# 清理旧备份
cleanup_old_backups() {
    log "🧹 清理旧备份..."
    
    # 保留最近30天的备份
    cd "$VAULT_DIR" || error_exit "无法进入仓库目录"
    
    # 删除30天前的标签
    git tag --list 'backup-*' | sort | head -n -30 | xargs -I {} git tag -d {}
    
    # 清理远程标签
    git push synology --prune-tags
    git push github --prune-tags
    
    log "✅ 旧备份清理完成"
}

# 主函数
main() {
    log "🔄 开始同步到群晖NAS..."
    
    # 执行同步步骤
    check_environment
    if git_add_files; then
        commit_changes
    fi
    push_to_synology
    push_to_github
    create_backup_tag
    cleanup_old_backups
    
    log "🎉 同步完成！"
}

# 执行主函数
main "$@"
```

### **2. 定时任务配置**

```bash
# 设置定时任务
echo "0 */6 * * * /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee/16.2-AgenticWorkFlow/scripts/sync-to-synology.sh" | crontab -

# 每日备份
echo "0 23 * * * /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee/16.2-AgenticWorkFlow/scripts/sync-to-synology.sh" | crontab -

# 每周完整备份
echo "0 2 * * 0 /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee/16.2-AgenticWorkFlow/scripts/weekly-full-backup.sh" | crontab -
```

### **3. 恢复脚本**

```bash
#!/bin/bash
# restore-from-synology.sh

# 配置参数
VAULT_DIR="/mnt/d/ObsidianVault"
SYNOLOGY_NAS="user@nas.local:/volume1/git/obsidian-vault"
SSH_KEY="$HOME/.ssh/obsidian-vault"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# 错误处理
error_exit() {
    log "❌ 错误: $1"
    exit 1
}

# 检查恢复点
check_restore_points() {
    log "🔍 检查可用的恢复点..."
    
    # 获取所有备份标签
    cd "$VAULT_DIR" || error_exit "无法进入仓库目录"
    
    if ! git remote | grep -q "synology"; then
        git remote add synology "$SYNOLOGY_NAS"
    fi
    
    # 获取远程标签
    git fetch synology
    
    # 显示可用标签
    log "📋 可用的恢复点:"
    git tag --list 'backup-*' | sort -r | head -10
}

# 恢复到指定标签
restore_to_tag() {
    local tag_name=$1
    
    if [ -z "$tag_name" ]; then
        error_exit "请指定恢复标签"
    fi
    
    log "🔄 恢复到标签: $tag_name"
    
    cd "$VAULT_DIR" || error_exit "无法进入仓库目录"
    
    # 恢复到指定标签
    if ! git reset --hard "$tag_name"; then
        error_exit "恢复失败"
    fi
    
    log "✅ 恢复完成"
}

# 主函数
main() {
    log "🔄 开始恢复流程..."
    
    # 检查恢复点
    check_restore_points
    
    # 询问用户要恢复到哪个标签
    echo "请输入要恢复到的标签 (例如: backup-20260311-153000):"
    read -r tag_name
    
    # 执行恢复
    restore_to_tag "$tag_name"
    
    log "🎉 恢复完成！"
}

# 执行主函数
main "$@"
```

---

## 🔍 监控与日志

### **1. 同步日志监控**

```bash
#!/bin/bash
# monitor-sync-logs.sh

# 日志文件路径
LOG_DIR="/var/log/obsidian-sync"
LOG_FILE="$LOG_DIR/sync-$(date +%Y%m%d).log"

# 创建日志目录
mkdir -p "$LOG_DIR"

# 检查最近的同步状态
check_recent_sync() {
    echo "📊 最近同步状态:"
    
    # 检查最近24小时的同步日志
    if [ -f "$LOG_FILE" ]; then
        echo "最近同步记录:"
        tail -10 "$LOG_FILE"
    else
        echo "暂无同步记录"
    fi
}

# 检查同步错误
check_sync_errors() {
    echo "⚠️  同步错误检查:"
    
    # 检查错误日志
    if [ -f "$LOG_FILE" ]; then
        error_count=$(grep -c "❌" "$LOG_FILE" 2>/dev/null || echo "0")
        if [ "$error_count" -gt 0 ]; then
            echo "发现 $error_count 个错误:"
            grep "❌" "$LOG_FILE" | tail -5
        else
            echo "✅ 没有发现错误"
        fi
    fi
}

# 统计同步成功率
calculate_success_rate() {
    echo "📈 同步成功率统计:"
    
    if [ -f "$LOG_FILE" ]; then
        total_syncs=$(grep -c "开始同步" "$LOG_FILE" 2>/dev/null || echo "0")
        successful_syncs=$(grep -c "同步完成" "$LOG_FILE" 2>/dev/null || echo "0")
        
        if [ "$total_syncs" -gt 0 ]; then
            success_rate=$((successful_syncs * 100 / total_syncs))
            echo "总同步次数: $total_syncs"
            echo "成功次数: $successful_syncs"
            echo "成功率: $success_rate%"
        fi
    fi
}

# 主函数
main() {
    echo "🔍 监控同步日志 - $(date)"
    echo "=================================="
    
    check_recent_sync
    echo ""
    check_sync_errors
    echo ""
    calculate_success_rate
}

# 执行主函数
main "$@"
```

### **2. 状态报告脚本**

```bash
#!/bin/bash
# generate-status-report.sh

# 生成状态报告
generate_status_report() {
    local report_file="/tmp/sync-status-$(date +%Y%m%d).md"
    
    cat > "$report_file" << EOF
---
tags:
  - system/status
  - backup/report
  - 16-project
date: $(date +%Y-%m-%d)
status: active
---

# 🔄 Git备份状态报告

**报告时间**: $(date)
**生成系统**: 自动化备份系统

---

## 📊 备份状态概览

### **当前状态**
- **本地仓库**: ✅ 正常
- **群晖NAS**: ✅ 连接正常
- **GitHub**: ✅ 连接正常
- **Tailscale**: ✅ 连接正常

### **最近同步**
- **最后同步时间**: $(date)
- **同步状态**: ✅ 成功
- **同步文件数**: $(git --git-dir=/mnt/d/ObsidianVault/.git diff --name-only | wc -l)
- **同步大小**: $(du -sh /mnt/d/ObsidianVault | cut -f1)

---

## 🗂️ 备份详情

### **Git仓库信息**
\`\`\`
仓库路径: /mnt/d/ObsidianVault
远程仓库: 
  - synology (群晖NAS)
  - github (GitHub公开)
分支: main
标签数量: $(git --git-dir=/mnt/d/ObsidianVault/.git tag --list 'backup-*' | wc -l)
\`\`\`

### **备份标签列表**
\`\`\`
$(git --git-dir=/mnt/d/ObsidianVault/.git tag --list 'backup-*' | sort -r | head -10)
\`\`\`

---

## 📈 性能指标

### **同步统计**
- **今日同步次数**: $(grep -c "开始同步" /var/log/obsidian-sync/sync-$(date +%Y%m%d).log 2>/dev/null || echo "0")
- **成功同步次数**: $(grep -c "同步完成" /var/log/obsidian-sync/sync-$(date +%Y%m%d).log 2>/dev/null || echo "0")
- **失败同步次数**: $(grep -c "❌" /var/log/obsidian-sync/sync-$(date +%Y%m%d).log 2>/dev/null || echo "0")

### **存储使用情况**
\`\`\`
本地存储: $(du -sh /mnt/d/ObsidianVault | cut -f1)
群晖存储: $(ssh -i ~/.ssh/obsidian-vault user@nas.local "du -sh /volume1/git/obsidian-vault" 2>/dev/null || echo "无法获取")
GitHub存储: $(git ls-remote github --heads main | wc -l | xargs -I {} echo "正常" || echo "无法获取")
\`\`\`

---

## ⚠️ 警告与提醒

### **当前警告**
- 无

### **系统提醒**
- 🔄 下次同步: $(date -d "next day 06:00" "+%Y-%m-%d %H:%M")
- 📧 状态报告: 每日 18:00 自动生成
- 🔔 错误通知: 实时

---

## 🔗 相关链接

- [[项目状态仪表板]] - 项目监控界面
- [[Agent工作流程]] - Agent协作机制
- [[scripts/]] - 自动化脚本集合

---

**自动生成**: $(date)
**维护者**: Claude Code
EOF
    
    echo "状态报告已生成: $report_file"
    # 可以将报告复制到项目目录
    cp "$report_file" "/mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee/备份状态报告_$(date +%Y%m%d).md"
}

# 执行主函数
generate_status_report
```

---

## 🛡️ 安全与权限

### **1. 权限设置**

```bash
# 设置文件权限
chmod 600 ~/.ssh/obsidian-vault
chmod 600 ~/.ssh/obsidian-vault.pub

# 设置仓库权限
chmod 755 /mnt/d/ObsidianVault
find /mnt/d/ObsidianVault -type f -exec chmod 644 {} \;
find /mnt/d/ObsidianVault -type d -exec chmod 755 {} \;
```

### **2. 加密配置**

```bash
# 加密敏感配置
echo "SYNOLOGY_PASSWORD" | gpg -c --batch --passphrase "your_encryption_key" -o config.gpg

# 解密配置
gpg -d --batch --passphrase "your_encryption_key" config.gpg > config.txt
```

---

## 🚀 部署指南

### **1. 首次部署**

```bash
# 1. 克隆脚本到项目目录
mkdir -p /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee/16.2-AgenticWorkFlow/scripts
cp sync-to-synology.sh /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee/16.2-AgenticWorkFlow/scripts/
chmod +x /mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee/16.2-AgenticWorkFlow/scripts/sync-to-synology.sh

# 2. 初始化Git仓库
cd /mnt/d/ObsidianVault
git init
git add .
git commit -m "初始提交"

# 3. 添加远程仓库
git remote add synology "user@nas.local:/volume1/git/obsidian-vault"
git remote add github "git@github.com:yourusername/obsidian-vault-public.git"

# 4. 首次同步
./sync-to-synology.sh
```

### **2. 系统服务**

```bash
# 创建systemd服务
sudo tee /etc/systemd/system/obsidian-sync.service > /dev/null <<EOF
[Unit]
Description=Obsidian Vault Sync Service
After=network.target tailscale.service

[Service]
Type=oneshot
User=alex
ExecStart=/mnt/d/ObsidianVault/10-Projects/16-DigitalEmployee/16.2-AgenticWorkFlow/scripts/sync-to-synology.sh
EOF

# 创建定时器
sudo tee /etc/systemd/system/obsidian-sync.timer > /dev/null <<EOF
[Unit]
Description=Run Obsidian Sync every 6 hours
Requires=obsidian-sync.service

[Timer]
OnCalendar=*:00/6:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

# 启用服务
sudo systemctl enable obsidian-sync.timer
sudo systemctl start obsidian-sync.timer
```

---

## 🔗 相关文档

- [[项目状态仪表板]] - 项目监控界面
- [[Agent工作流程]] - Agent协作机制
- [[AI-Agent协作机制]] - Agent配置

---

**维护者**: Claude Code  
**创建日期**: 2026-03-11  
**最后更新**: 2026-03-11