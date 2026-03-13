# Orchestrator Skill 指令集

当用户输入 `/wf-xxx` 时，按以下对应指令执行。

---

## /wf-pick-case [case_id]

从 16.1 案例队列中选取下一个可运行案例。

**步骤:**
1. 扫描 `E:/10.Project/16.1-AndroidToHarmonyOSDemo/16.1.1*` 所有案例目录
2. 对每个案例判定状态:
   - 有 `e2e/` 且最新 attempt PASS → DONE
   - 有 `e2e/` 且 BLOCKED → BLOCKED
   - 无 `analysis/` → TODO
3. 检查依赖: 无依赖(120,121,122,123,125,126,129,131,138), 依赖121(124), 依赖125(127,132,133,134), 依赖127(128,130,136~141), 依赖129(142), 依赖130(135)
4. 选取规则: 进行中优先 > 依赖满足且序号最小 > 跳过 BLOCKED/WAITING
5. 输出: 案例编号、路径、状态、主要 Bridge Agent

---

## /wf-analyze-case <case_id>

分析案例的 Android 源码，产出 API 调用清单。

**步骤:**
1. 读取 `16.1.<case_id>-*/src/` 下所有 Java/XML 文件
2. 提取所有 Android API 调用
3. 每个 API 标注 bridge_owner (16.4.2~16.4.9)
4. 写验收标准 (acceptance_criteria, ≥2条)
5. 写入 `analysis/api-manifest.yaml`
6. **或**调度 16.1 Agent: `./scripts/invoke-agent.sh 16.1 <case_id>`
7. 完成后实物验证: 文件存在? >10行? API 在源码中 grep 得到?

归属规则:
- Activity/Intent/Fragment/Service/BroadcastReceiver → 16.4.2
- View/Widget/Layout/Toast/Dialog/Animation → 16.4.3
- Permission/Notification/Sensor/Location/Camera/Bluetooth/R class → 16.4.4
- JNI/Native → 16.4.5
- Handler/Looper/AsyncTask/Thread → 16.4.6
- SharedPreferences/File/SQLite/ContentProvider → 16.4.7
- Http/WebView/Network → 16.4.8
- 第三方库 → 16.4.9

---

## /wf-design-adapter <case_id>

作为 16.3 R&D Agent，为案例设计适配策略。

**步骤:**
1. 读取 `analysis/api-manifest.yaml`
2. 读取全局知识库 `E:/10.Project/16.3-Adapter.Requirement/16.3-API-MASTER-LIST.csv`
3. 每个 API 做决策:
   - **DIRECT_MAP**: 填 harmony_api
   - **BRIDGE_EXISTING**: 填 bridge_agent + interface_requirement + rationale(>20字)
   - **NEW_MODULE_NEEDED**: 产出 NMP 到 proposals/，暂停本案例
4. 写入 `mapping/design-report.yaml`
5. **或**调度: `./scripts/invoke-agent.sh 16.3 <case_id>`
6. 实物验证: 文件>15行? API 无遗漏(与 manifest 交叉验证)? rationale 非占位?

---

## /wf-dispatch <case_id>

按设计结果派发给 Bridge Agents。

**步骤:**
1. 读取 `mapping/design-report.yaml`
2. 按 bridge_agent 分组，生成任务文件到 `queue/outbox/to-16.4.X-task-<case_id>.yaml`
3. 调度: `./scripts/dispatch-parallel.sh <case_id>` (并行启动所有 Bridge Agent)
4. 如有 PENDING_APPROVAL 的 NMP → 跳过相关 API，提示

---

## /wf-check-deliverable <case_id>

实物验收各 Agent 交付物。**反幻觉审核：不信 yaml status，亲自检查文件。**

**检查清单:**

16.1: `ls analysis/api-manifest.yaml` 存在? `wc -l` >10? `grep bridge_owner` 每个API有?

16.3: `ls mapping/design-report.yaml` 存在? >15行? `grep rationale` 每个>20字?

16.4.x: `ls 16.4.x/05-Implementation/*.ets` 存在? >20行? `ls 06-Test/*.test.ets` 存在? >10行? `grep -c "expect\|assert" 06-Test/` >0?

16.6: `ls e2e/comparison-report.yaml` 存在? `ls e2e/screenshots/android/*.png` ≥1且>1KB? `ls e2e/screenshots/harmony/*.png` ≥1且>1KB? `grep test_method` 非空?

**结果:** PASS 进下一步 / REJECT 打回并指明缺什么 / 阻塞时建议 `/wf-pick-case`

---

## /wf-test-compare <case_id>

调度 16.6 执行 Android vs HarmonyOS 体验对比。

**步骤:**
1. 调度: `./scripts/invoke-agent.sh 16.6 <case_id>`
2. 完成后实物验证:
   - `e2e/screenshots/android/` 有 ≥1 张 .png 且 >1KB
   - `e2e/screenshots/harmony/` 有 ≥1 张 .png 且 >1KB
   - `comparison-report.yaml` 有 test_method + environment
3. 如果 16.6 报 ENV_NOT_READY → 标记，跳到下一案例

---

## /wf-e2e-check <case_id>

E2E 验证 + 错误归因。

**Phase 1: 交付物检查** (同 /wf-check-deliverable)
任何缺失 → DELIVERABLE_INCOMPLETE，打回

**Phase 2: 错误归因** (仅 Phase 1 通过后)
读 comparison-report.yaml 的 verdict:
- PASS → 案例完成
- CONDITIONAL_PASS → 逐条归因 MAJOR_DIFF
- FAIL → 按错误类型归因到 16.4.x / 16.3 / 16.1

归因规则: 编译错误按模块关键词，运行时错误按堆栈，行为差异按 API 归属。

---

## /wf-triage <case_id>

分析错误历史，判断 CONTINUE / ESCALATE / BLOCKED。

**判断逻辑:**
- 每次都是新错误 → **CONTINUE** (Agent 在前进)
- 同一错误连续 ≥3 次 → **ESCALATE** → 16.3 重设计
- 回归 ≥2 次 (修A坏B) → **ESCALATE** → 16.3 定义 contract
- 同一 Agent 连续失败 ≥4 → **ESCALATE** → 16.3 评估模块边界
- 总次数 ≥15 → **BLOCKED** → 人工介入

---

## /wf-nmp-review [NMP-id]

查看待审批新模块提案。

扫描 `proposals/NMP-*.yaml`，列出 PENDING_APPROVAL 的提案摘要。
指定 NMP-id 时展示完整 7 部分报告。
人工审批: 修改 proposals/ 文件中的 status 字段。

---

## /wf-case-status [case_id | --blocked | --load]

**视图 1 — 流水线:** 每个案例走到哪步 (16.1→16.3→16.4.x→编译→16.6→DONE)
**视图 2 — 阻塞热力图:** 按阻塞模块分组，显示瓶颈和最大杠杆点
**视图 3 — 模块负载:** 各 Agent 进行中/排队/完成数量
**视图 4 — 单案例详情:** 指定 case_id 时的详细交付物状态

---

## /wf-run-case <case_id>

串联完整流程。每步之间做实物验收。

```
analyze → 验收 → design → 验收 → dispatch → 等Bridge完成 → 验收 → test-compare → 验收 → e2e-check
                                                                                          ↓
                                                              PASS → pick-case 下一个
                                                              FAIL → triage → CONTINUE/ESCALATE/BLOCKED
```

阻塞时自动建议下一个可运行案例。

---

## /wf-invoke-agent <agent_id> <case_id>

直接调用指定 Agent: `./scripts/invoke-agent.sh <agent_id> <case_id>`

Agent 映射: 16.1, 16.3, 16.4.2~16.4.6, 16.4.9, 16.6
