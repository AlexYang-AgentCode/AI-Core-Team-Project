## Invoke Agent — 调度另一个 Claude Code 执行任务

调用指定 Agent 执行任务。格式: `/wf-invoke-agent <agent_id> <case_id>`

示例:
- `/wf-invoke-agent 16.1 122` — 让 16.1 分析案例 122
- `/wf-invoke-agent 16.4.3 121` — 让 16.4.3 为案例 121 实现 Bridge
- `/wf-invoke-agent 16.6 122` — 让 16.6 执行测试对比

参数: $ARGUMENTS 格式为 `<agent_id> <case_id>`

### 执行步骤

1. 解析参数: agent_id 和 case_id

2. 确定 Agent 的工作目录和任务文件:

```yaml
agent_directories:
  "16.1": "E:/10.Project/16.1-AndroidToHarmonyOSDemo"
  "16.3": "E:/10.Project/16.3-Adapter.Requirement"
  "16.4.1": "E:/10.Project/16.4.1-JIT.Performance"
  "16.4.2": "E:/10.Project/16.4.2-Activity.Bridge"
  "16.4.3": "E:/10.Project/16.4.3-View.Bridge"
  "16.4.4": "E:/10.Project/16.4.4-System.Bridge"
  "16.4.5": "E:/10.Project/16.4.5-JNI.Runtime"
  "16.4.6": "E:/10.Project/16.4.6-Concurrency"
  "16.4.7": # 待 NMP 审批后创建
  "16.4.8": # 待 NMP 审批后创建
  "16.4.9": "E:/10.Project/16.4.9-ThirdParty.Adapter"
  "16.6": "E:/10.Project/16.6-Adapter.Test"
```

3. 读取任务文件 (由 /wf-dispatch 生成):
   `16.2-AgenticWorkFlow/queue/outbox/to-{agent_id}-task-{case_id}.yaml`

4. 构造 prompt 并调用 `claude` CLI:

```bash
claude -p \
  --cwd "{agent_directory}" \
  --system-prompt "你是 {agent_id} Agent。你的职责定义在本目录的 CLAUDE.md 中。严格只修改自己目录下的文件。" \
  --append-system-prompt "任务完成后将结果写入 queue/inbox/ 目录。" \
  --permission-mode "acceptEdits" \
  --model sonnet \
  --max-budget-usd 0.5 \
  --output-format json \
  "{task_prompt}"
```

5. 等待完成后:
   - 检查 inbox 是否有结果文件
   - 对结果做实物验证 (/wf-check-deliverable 的逻辑)
   - 如果验证失败 → 重新调用 Agent 并附带失败原因

### 注意

- 每次调用有预算上限 (--max-budget-usd)，防止 Agent 无限循环
- 使用 --output-format json 捕获结构化结果
- Agent 只能修改自己 --cwd 下的文件 (代码隔离)
- 调用前检查 Agent 目录下是否有 CLAUDE.md (没有 → 报错)
