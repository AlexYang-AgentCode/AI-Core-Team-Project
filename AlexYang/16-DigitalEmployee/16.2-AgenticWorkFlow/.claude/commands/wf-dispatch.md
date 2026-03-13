## Dispatch to Bridge Agents

根据案例 $ARGUMENTS 的适配设计，生成给各 Bridge Agent 的任务文件。

### 前置条件

读取 `E:/10.Project/16.1-AndroidToHarmonyOSDemo/16.1.$ARGUMENTS-*/mapping/design-report.yaml`

### 执行步骤

1. 解析 design-report.yaml 中所有 `decision: BRIDGE_EXISTING` 的条目
2. 按 bridge_agent 分组
3. 为每个 bridge_agent 生成任务文件到 `16.2-AgenticWorkFlow/queue/outbox/`:

```yaml
# to-16.4.X-task-$ARGUMENTS.yaml
task:
  case_id: "16.1.$ARGUMENTS"
  action: "PROVIDE_BRIDGE"
  target_agent: "16.4.X"
  apis: [...]
  interface_requirements: [...]
  context: "..."
```

4. 检查是否有 `decision: NEW_MODULE_NEEDED` 且状态为 PENDING_APPROVAL
   - 如果有 → 提示用户该案例等待审批，跳过这些 API
   - 如果已 APPROVED → 正常生成任务

5. 输出汇总: 哪些 Agent 收到了任务，各自负责哪些 API

### 关键规则

每个任务文件只包含**该 Agent 自己模块范围内的 API**。
Agent 只修改自己 16.4.x/ 目录下的代码，不跨模块修改。
