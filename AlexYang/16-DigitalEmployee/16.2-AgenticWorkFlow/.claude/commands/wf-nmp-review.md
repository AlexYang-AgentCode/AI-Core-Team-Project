## NMP Review — 新模块提案审批

列出所有待审批的 New Module Proposal，辅助人工审核决策。

### 执行步骤

1. 扫描 `16.2-AgenticWorkFlow/proposals/NMP-*.yaml`
2. 筛选 `status: PENDING_APPROVAL` 的提案
3. 对每个待审批 NMP，输出摘要:
   - 提案编号、模块名、触发案例
   - 问题陈述 (1 句话)
   - API 覆盖数量
   - 受影响案例数
   - 16.3 的推荐和置信度
   - 替代方案列表

4. 如果 $ARGUMENTS 为具体提案编号 (如 "NMP-2026-001"):
   - 展示完整 7 部分报告
   - 在末尾提示: 请修改 proposals/NMP-2026-001.yaml 中的 status 字段:
     - `APPROVED` — 批准创建模块
     - `REJECTED` — 拒绝，使用替代方案
     - `REVISE` — 需要 16.3 修订 (附 reviewer_notes)

### 输出格式 (列表模式)

```
待审批新模块提案
─────────────────────────────────────────
NMP-2026-001 | 16.4.7-Storage.Bridge
  触发: 16.1.128-FileIO
  覆盖: 4类 API, 35方法, 影响 4 个案例
  推荐: APPROVE (HIGH confidence)
  替代: 塞入 System.Bridge (不推荐)
─────────────────────────────────────────
输入 /nmp-review NMP-2026-001 查看完整报告
```
