# 🤖 AI-Core-Team-Project

> **AI主导、人类辅助 | AI-Driven, Human-Assisted Perpetual Team Project**
>
> ---
>
> ## 🌟 项目核心理念 | Core Philosophy
>
> 本项目以 **AI为主干、人类为辅助** 的全新协作模式运行。AI主干永远不停止运行，持续处理任务、优化流程、生成输出。人类团队成员通过提交 Prompt 和需求来引导AI方向。
>
> > **The AI Core never stops. Humans guide, AI executes.**
> >
> > ---
> >
> > ## 🏗️ 项目结构 | Project Structure
> >
> > ```
> > AI-Core-Team-Project/
> > │
> > ├── 📁 AI_CORE/                    # 🤖 AI主干核心区域（永不停止）
> > │   ├── README.md                  # AI运行规范与说明
> > │   ├── running_log.md             # AI运行日志
> > │   └── output/                   # AI输出成果
> > │
> > ├── 📁 team/                       # 👥 团队成员工作区
> > │   ├── AlexYang/                  # 项目负责人 (Owner)
> > │   │   ├── prompts/               # 提交Prompt
> > │   │   ├── requirements/          # 提交需求
> > │   │   └── README.md
> > │   ├── Reinier/                   # 团队成员
> > │   │   ├── prompts/
> > │   │   ├── requirements/
> > │   │   └── README.md
> > │   ├── Mikhail/                   # 团队成员
> > │   │   ├── prompts/
> > │   │   ├── requirements/
> > │   │   └── README.md
> > │   ├── HanBingChen/               # 团队成员
> > │   │   ├── prompts/
> > │   │   ├── requirements/
> > │   │   └── README.md
> > │   └── YueChen/                   # 团队成员
> > │       ├── prompts/
> > │       ├── requirements/
> > │       └── README.md
> > │
> > └── 📁 docs/                       # 📚 项目文档
> >     └── WORKFLOW.md                # 工作流程说明
> > ```
> >
> > ---
> >
> > ## 🌿 分支策略 | Branch Strategy
> >
> > | 分支 | 用途 | 规则 |
> > |------|------|------|
> > | `main` | AI主干，永不停止 🔴 | 受保护，仅通过PR合并 |
> > | `develop` | 集成分支，汇聚所有成员提交 | 定期合并到main |
> > | `feature/AlexYang-*` | AlexYang的工作分支 | 完成后PR到develop |
> > | `feature/Reinier-*` | Reinier的工作分支 | 完成后PR到develop |
> > | `feature/Mikhail-*` | Mikhail的工作分支 | 完成后PR到develop |
> > | `feature/HanBingChen-*` | HanBingChen的工作分支 | 完成后PR到develop |
> > | `feature/YueChen-*` | YueChen的工作分支 | 完成后PR到develop |
> >
> > ---
> >
> > ## 👥 团队成员 | Team Members
> >
> > | 成员 | 角色 | 工作目录 |
> > |------|------|---------|
> > | **AlexYang** | 项目负责人 Owner | `team/AlexYang/` |
> > | **Reinier** | 团队成员 | `team/Reinier/` |
> > | **Mikhail** | 团队成员 | `team/Mikhail/` |
> > | **HanBingChen** | 团队成员 | `team/HanBingChen/` |
> > | **YueChen** | 团队成员 | `team/YueChen/` |
> >
> > ---
> >
> > ## 🚀 快速开始 | Quick Start
> >
> > ### 克隆项目
> > ```bash
> > git clone https://github.com/AlexYang-AgentCode/AI-Core-Team-Project.git
> > cd AI-Core-Team-Project
> > ```
> >
> > ### 创建个人工作分支
> > ```bash
> > # 以 AlexYang 为例
> > git checkout develop
> > git pull origin develop
> > git checkout -b feature/AlexYang-my-task
> > ```
> >
> > ### 提交Prompt
> > ```bash
> > # 在你的 prompts/ 目录下新建文件
> > echo "你的Prompt内容" > team/AlexYang/prompts/2026-03-13-task-name.md
> > git add .
> > git commit -m "feat(AlexYang): add new prompt for task-name"
> > git push origin feature/AlexYang-my-task
> > ```
> >
> > ### 提交需求
> > ```bash
> > # 在你的 requirements/ 目录下新建文件
> > echo "需求描述" > team/AlexYang/requirements/REQ-001-feature-name.md
> > git add .
> > git commit -m "req(AlexYang): add requirement REQ-001"
> > git push origin feature/AlexYang-my-task
> > ```
> >
> > ---
> >
> > ## 📋 提交规范 | Commit Convention
> >
> > ```
> > feat(成员名): 新功能描述
req(成员名): 需求描述
prompt(成员名): Prompt提交
fix(成员名): 修复描述
docs: 文档更新
```

---

## 🤖 AI核心运行状态 | AI Core Status

```
状态: 🟢 RUNNING - AI主干持续运行中
模式: AI主导 + 人类辅助
启动时间: 2026-03-13
永不停止: ✅
```

---

*Built with ❤️ by the AI-Core Team | AlexYang · Reinier · Mikhail · HanBingChen · YueChen*
