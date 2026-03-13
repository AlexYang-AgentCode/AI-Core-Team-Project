# AlexYang 个人项目目录

本目录包含 AlexYang 的 AI Core Team 相关项目。

## 项目列表

| 目录 | 说明 |
|------|------|
| 16-DigitalEmployee | 数字员工项目 |
| 16.1-AndroidToHarmonyOSDemo | Android 到 HarmonyOS 迁移 Demo |
| 16.2-AgenticWorkFlow | Agentic 工作流 |
| 16.3-Adapter.Requirement | Adapter 需求分析 |
| 16.4-Adapter.Design | Adapter 设计 |
| 16.4.1-JIT.Performance | JIT 性能优化 |
| 16.4.2-Activity.Bridge | Activity 桥接 |
| 16.4.3-View.Bridge | View 桥接 |
| 16.4.4-System.Bridge | 系统桥接 |
| 16.4.5-JNI.Runtime | JNI 运行时 |
| 16.4.6-Concurrency | 并发处理 |
| 16.4.7-Data.Bridge | 数据桥接 |
| 16.4.9-ThirdParty.Adapter | 第三方库适配 |
| 16.5-Adapter.Code | Adapter 代码 |
| 16.6-Adapter.Test | Adapter 测试 |
| 16.7-Adapter.Release | Adapter 发布 |
| 16.9-DevelopingBoard | 开发板项目 |

## 使用方法

### Git 同步

在项目根目录运行：

```bash
./update.sh
```

或手动同步：

```bash
cd /mnt/e/10.project/AI-Core-Team-Project
git pull
git add AlexYang/
git commit -m "更新 AlexYang 项目"
git push
```

### Token 认证配置

首次推送前配置 GitHub Token：

```bash
# 方法1: 修改 remote URL（替换 YOUR_TOKEN 为实际 token）
git remote set-url origin https://YOUR_TOKEN@github.com/AlexYang-AgentCode/AI-Core-Team-Project.git

# 方法2: 使用 credential helper
git config --global credential.helper store
# 然后执行 git push，输入用户名和 token 作为密码
```

## 注意事项

- 所有项目已排除 `.git` 目录，作为 AI-Core-Team-Project 的子目录管理
- 请勿直接修改原始 16* 目录，请在此目录下修改后提交
