## Run Case — 完整 E2E 流程

对案例 $ARGUMENTS 执行完整流程。

### Orchestrator 三条行为准则

1. **自动化优先**: 能自动跑的不停，不等人。遇到人工节点(NMP审批)立即跳走做下一个。
2. **反幻觉审核**: 每步之间执行 /wf-check-deliverable 实物验证。不信 Agent 自报的 status，亲自检查文件存在、内容合理、截屏非空。
3. **资源不闲置**: 当前案例阻塞时，立即建议并切换到下一个可运行的案例。

### 流程

每步完成后**先验收再继续**:

```
Step 1: /wf-analyze-case $ARGUMENTS
  │
  ├→ 验收: analysis/ 文件实物检查 (交叉验证 API 是否真在源码中出现)
  │   REJECT? → 打回 16.1，指明缺什么
  │
  ▼
Step 2: /wf-design-adapter $ARGUMENTS
  │
  ├→ 验收: mapping/ 文件实物检查 (API 无遗漏? rationale 非占位?)
  │   有 Decision C? → 生成 NMP，暂停本案例，自动 /wf-pick-case 切到下一个
  │   REJECT? → 打回 16.3
  │
  ▼
Step 3: /wf-dispatch $ARGUMENTS
  │
  ├→ 验收: queue/outbox/ 任务文件生成
  │   (此处等待 Bridge Agents 完成 — 实际执行在各自服务器)
  │
  ▼
Step 4: Bridge 完成后 → /wf-check-deliverable $ARGUMENTS
  │
  ├→ 实物检查: 16.4.x 代码存在? 行数>20? 测试存在? 有 assert?
  │   REJECT? → 打回对应 16.4.x，指明: "代码为空壳" 或 "无单元测试"
  │
  ▼
Step 5: /wf-test-compare $ARGUMENTS
  │
  ├→ 验收: 截屏存在? >1KB? 每个场景有双端证据?
  │   ENV_NOT_READY? → 标记等 16.6 环境，自动切下一个案例
  │   REJECT? → 打回 16.6
  │
  ▼
Step 6: /wf-e2e-check $ARGUMENTS
  │
  ├→ PASS → 案例完成，自动 /wf-pick-case 进入下一个
  │  FAIL → /wf-triage 判断 CONTINUE/ESCALATE/BLOCKED
  │         CONTINUE → 派发修复，等 Agent 完成后回到 Step 4
  │         ESCALATE → 回 16.3 重设计，回到 Step 2
  │         BLOCKED → 标记，自动切下一个案例
```

### 自动推进逻辑

每当当前案例无法继续时:

```
输出:
  "案例 $ARGUMENTS 阻塞于 [Agent/原因]"
  "下一个可运行案例: XXX"
  "建议执行: /wf-run-case XXX"
```

如果所有可运行案例均已阻塞:
```
输出:
  "所有可运行案例均已阻塞"
  "瓶颈: [Agent] 积压 N 个任务"
  "等待中..."
```

### 注意

- 每步之间展示实物验收结果，不静默跳过
- 验收失败时明确指出"Agent 交付了什么 vs 缺了什么"
- 不自动无限重试，每次重试需用户触发或 /wf-triage 判定
