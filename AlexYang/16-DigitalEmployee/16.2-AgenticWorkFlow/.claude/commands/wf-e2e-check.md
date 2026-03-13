## E2E Check

对案例 $ARGUMENTS 执行 E2E 验证。分两阶段: 先检查 16.6 交付物完整性，再做错误归因。

### Phase 1: 16.6 交付物完整性检查 (Orchestrator 质量闸门)

检查 `16.1.$ARGUMENTS-*/e2e/` 目录，逐项验证:

```
检查项                              │ 缺失时处置
────────────────────────────────────┼───────────────────────────
comparison-report.yaml 存在?        │ REJECT → 要求 16.6 执行 /test-compare
screenshots/android/ 有 ≥1 张 .png? │ REJECT → "缺少 Android 截屏"
screenshots/harmony/ 有 ≥1 张 .png? │ REJECT → "缺少 HarmonyOS 截屏"
report 中每个 scenario 有截屏路径?   │ REJECT → "对比报告不完整"
report 中 test_method 不为空?       │ REJECT → "未说明测试方式"
report 中 environment 不为空?       │ REJECT → "未说明测试环境"
```

如果任何一项缺失:
→ 输出: "16.6 交付物不完整: [缺失清单]"
→ 状态: `DELIVERABLE_INCOMPLETE`
→ 不进入 Phase 2，直接要求 16.6 补充
→ 这是**调度层的质量闸门**，不是 16.6 自检

### Phase 2: 错误归因 (仅当 Phase 1 通过后)

1. 读取 `comparison-report.yaml`
2. 检查 verdict:
   - `PASS` → 案例通过，输出通过信息
   - `CONDITIONAL_PASS` → 列出 blocking_issues，逐条归因
   - `FAIL` → 列出所有 MAJOR_DIFF / BROKEN，逐条归因

3. 对每个需修复的 scenario，执行错误归因:

```
归因规则:
- 截屏显示 UI 布局/样式差异         → 16.4.3 (View.Bridge)
- 截屏显示功能缺失 (按钮无反应等)   → 按 API 归属归因
- 截屏显示崩溃/白屏                  → 按 error log 归因
- Android 和 HarmonyOS 行为逻辑不同 → 先查 mapping/design-report.yaml
- 截屏显示的差异不在代码对比中       → 16.6 漏测，要求补充场景
```

4. 将结果写入 `e2e/attempt-N.yaml`:

```yaml
case_id: "16.1.$ARGUMENTS"
attempt: N
status: "PASS | FAIL | DELIVERABLE_INCOMPLETE"
deliverable_check:
  comparison_report: true/false
  android_screenshots: N  # 数量
  harmony_screenshots: N
  all_scenarios_have_evidence: true/false
errors:
  - signature: "错误签名"
    agent: "16.4.x"
    evidence: "e2e/screenshots/harmony/02-xxx.png"  # 截屏证据
    detail: "..."
```

5. 如果 PASS → 输出通过信息 + bridge_changes 汇总
6. 如果 FAIL → 输出错误列表 + 建议执行 `/triage $ARGUMENTS`
7. 如果 DELIVERABLE_INCOMPLETE → 输出缺失清单 + 建议执行 `/test-compare $ARGUMENTS`
