---
tags:
  - project/dev
  - architecture
date: 2026-03-09
---

# 16-DigitalEmployee Git 工作流

## 架构概览

```
[开发者代码提交]
   ↓
[群晖 Git Server]
   ↓
[post-receive hook 触发]
   ↓
[自动更新 vault 项目状态]
   ↓
[生成开发报告]
```

## Git Server 配置

### 群晖端
- **位置**: `/volume1/git-server/`
- **访问**: `ssh://nas.local/volume1/git-server/[project].git`
- **触发脚本**: `post-receive.sh` (在 Git-Hooks/ 目录)

### 本地端
- **克隆**: `git clone ssh://nas.local/...`
- **提交**: 正常的 git push/pull
- **同步**: 自动推送到群晖，失败时发送通知

## Kanban 状态管理

| 状态 | 文件 | 更新频率 |
|------|------|--------|
| Backlog | `Kanban/Backlog.md` | 每日检查 |
| In Progress | `Kanban/In-Progress.md` | Git push 时更新 |
| Review | `Kanban/Review.md` | PR 时更新 |
| Completed | `Kanban/Completed.md` | 合并时更新 |

---
*Last Updated: 2026-03-09*
