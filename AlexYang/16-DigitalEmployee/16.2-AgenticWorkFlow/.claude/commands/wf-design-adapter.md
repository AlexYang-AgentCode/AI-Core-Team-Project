## Design Adapter Strategy

作为 16.3 Requirement & Design Agent，为案例 $ARGUMENTS 设计适配策略。

### 前置条件

读取 `E:/10.Project/16.1-AndroidToHarmonyOSDemo/16.1.$ARGUMENTS-*/analysis/api-manifest.yaml`，如不存在先提示用户执行 `/analyze-case $ARGUMENTS`。

### 执行步骤

1. 读取案例的 api-manifest.yaml
2. 读取全局知识库:
   - `E:/10.Project/16.3-Adapter.Requirement/16.3-API-MASTER-LIST.csv`
   - `E:/10.Project/16.3-Adapter.Requirement/16.3.2-MAPPING-RULES/`
3. 对每个 API 做出设计决策 (A/B/C 三选一):

**Decision A: DIRECT_MAP** — 有直接对应的 HarmonyOS API，写明 harmony_api
**Decision B: BRIDGE_EXISTING** — 归入已有 16.4.x，写明 bridge_agent + interface_requirement
**Decision C: NEW_MODULE_NEEDED** — 需新建模块 → 产出 NMP 深度报告，流水线暂停等人工审批

4. 如果是 Decision C:
   - 在 `16.2-AgenticWorkFlow/proposals/` 下创建 NMP 报告 (7 部分全写)
   - 提醒用户: "新模块提案已生成，请人工审批后再继续"

5. 将设计报告写入案例目录下 `mapping/design-report.yaml`

### 全局视角要求

- 不只看当前案例，要考虑后续案例是否也会用到同类 API
- 如果一个 API 和已有 Bridge 中其他 API 有耦合关系，必须归同一个模块
- 写明 rationale（为什么这么决策），不能只填结论

### 输出格式

```yaml
case_id: "16.1.$ARGUMENTS"
design_decisions:
  - api: "..."
    decision: "DIRECT_MAP | BRIDGE_EXISTING | NEW_MODULE_NEEDED"
    harmony_api: "..." # if DIRECT_MAP
    bridge_agent: "16.4.x" # if BRIDGE_EXISTING
    rationale: "..."
    interface_requirement: "..." # if BRIDGE_EXISTING
new_module_proposals: [] # or NMP details
```
