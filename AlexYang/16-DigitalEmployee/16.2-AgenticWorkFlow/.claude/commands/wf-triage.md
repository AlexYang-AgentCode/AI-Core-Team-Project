## Triage — 错误模式分析与升级判断

分析案例 $ARGUMENTS 的完整错误历史，判断应该 CONTINUE / ESCALATE / BLOCKED。

### 执行步骤

1. 读取 `16.2-AgenticWorkFlow/state/case-$ARGUMENTS-error-history.yaml`
   如不存在，读取 `16.1.$ARGUMENTS-*/e2e/` 下所有 attempt 文件重建历史

2. 计算指标:
   - total_attempts: 总尝试次数
   - unique_errors: 不同错误签名数
   - max_repeat: 单个错误最大连续重复次数
   - regression_count: 已修复错误重新出现的次数
   - agent_streak: 尾部同一 Agent 连续失败次数

3. 判断逻辑:

```
IF unique_errors == total_attempts:
  → CONTINUE "每次都是新错误，Agent 在前进"

IF 同一错误连续 ≥3 次:
  → ESCALATE_TO_DESIGN "该 Agent 无法自行解决"

IF regression_count ≥ 2:
  → ESCALATE_TO_DESIGN "修A坏B循环，缺少跨模块 contract"

IF 同一 Agent 连续失败 ≥4 次 (即使错误不同):
  → ESCALATE_TO_DESIGN "超出模块能力边界"

IF total_attempts ≥ 15:
  → BLOCKED "耗时过长，需人工介入"

ELSE:
  → CONTINUE
```

4. 输出判断结果 + 建议的下一步动作:
   - CONTINUE → "建议继续，派发 FIX_ERROR 给 Agent X"
   - ESCALATE → "建议回传 16.3 重新设计，附带上下文"
   - BLOCKED → "建议跳过，人工介入"
