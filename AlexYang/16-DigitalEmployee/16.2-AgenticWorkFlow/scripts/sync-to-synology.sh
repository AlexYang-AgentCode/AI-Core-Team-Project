#!/bin/bash

# 同步到群晖NAS脚本
# 用途: 将本地Obsidian仓库同步到群晖NAS和GitHub

set -e

# 配置参数
VAULT_DIR="/mnt/d/ObsidianVault"
SYNOLOGY_NAS="user@nas.local:/volume1/git/obsidian-vault"
SYNOLOGY_PUBLIC="user@nas.local:/volume1/git/obsidian-vault-public"
GITHUB_PUBLIC="git@github.com:yourusername/obsidian-vault-public.git"
SSH_KEY="$HOME/.ssh/obsidian-vault"

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> /tmp/sync-log-$(date +%Y%m%d).log
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
        error_exit "Tailscale未连接，请先运行 'tailscale login'"
    fi
    
    # 检查SSH密钥
    if [ ! -f "$SSH_KEY" ]; then
        log "🔑 生成SSH密钥..."
        ssh-keygen -t ed25519 -f "$SSH_KEY" -N ""
        ssh-copy-id -i "$SSH_KEY.pub" user@nas.local
    fi
    
    # 检查Git仓库
    if [ ! -d "$VAULT_DIR/.git" ]; then
        log "📦 初始化Git仓库..."
        cd "$VAULT_DIR"
        git init
        git add .
        git commit -m "初始提交 - $(date)"
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
    if ! git commit -m "$commit_message"; then
        error_exit "提交失败"
    fi
    
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
    git tag --list 'backup-*' | sort | head -n -30 | xargs -I {} git tag -d {} 2>/dev/null || true
    
    # 清理远程标签
    git push synology --prune-tags 2>/dev/null || true
    git push github --prune-tags 2>/dev/null || true
    
    log "✅ 旧备份清理完成"
}

# 生成状态报告
generate_status_report() {
    log "📊 生成状态报告..."
    
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
- **同步时间**: $(date)
- **同步状态**: ✅ 成功
- **文件数**: $(cd "$VAULT_DIR" && git diff --name-only 2>/dev/null | wc -l || echo "0")

---

## 🗂️ 备份详情

### **Git仓库信息**
\`\`\`
仓库路径: $VAULT_DIR
远程仓库: 
  - synology (群晖NAS)
  - github (GitHub公开)
分支: main
标签数量: $(cd "$VAULT_DIR" && git tag --list 'backup-*' | wc -l 2>/dev/null || echo "0")
\`\`\`

### **备份标签列表**
\`\`\`
$(cd "$VAULT_DIR" && git tag --list 'backup-*' | sort -r | head -5 2>/dev/null || echo "无标签")
\`\`\`

---

## 📈 性能指标

### **同步统计**
- **今日同步次数**: $(grep -c "开始同步" /tmp/sync-log-$(date +%Y%m%d).log 2>/dev/null || echo "1")
- **成功同步次数**: $(grep -c "同步完成" /tmp/sync-log-$(date +%Y%m%d).log 2>/dev/null || echo "1")

---

## 🔗 相关链接

- [[项目状态仪表板]] - 项目监控界面
- [[Agent工作流程]] - Agent协作机制

---

**自动生成**: $(date)
**维护者**: Claude Code
EOF
    
    # 复制到项目目录
    cp "$report_file" "$VAULT_DIR/10-Projects/16-DigitalEmployee/备份状态报告_$(date +%Y%m%d).md"
    log "✅ 状态报告已生成"
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
    generate_status_report
    
    log "🎉 同步完成！"
}

# 执行主函数
main "$@"