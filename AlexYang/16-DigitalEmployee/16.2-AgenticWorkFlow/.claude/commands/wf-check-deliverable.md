## Check Deliverable — 交付物实物验收

Orchestrator 质量闸门: 检查案例 $ARGUMENTS 每个 Agent 的交付物。

### ⚠️ 核心原则: 反幻觉审核

**假定 Agent 汇报的都是幻觉，直到亲眼验证实物。**

不信 yaml 里写的 `status: PASS`，要亲自:
- 用 Glob/ls 检查文件是否真的存在
- 用 Read 打开文件检查内容是否非空、是否合理
- 检查截屏 .png 文件大小 > 0 (不是空文件)
- 检查代码文件的行数是否合理 (不是空壳)
- 检查测试报告中的数字是否和实际测试文件数量匹配

### 执行步骤

1. 确定案例路径: `E:/10.Project/16.1-AndroidToHarmonyOSDemo/16.1.$ARGUMENTS-*/`
2. 确定当前阶段 (按实际文件存在情况判定，不信任何状态文件)
3. 逐 Agent 做**实物检查**:

#### 检查 16.1 (分析阶段)

```bash
# 不是看 status 字段，是实际验证:
ls analysis/api-manifest.yaml           # 文件存在?
wc -l analysis/api-manifest.yaml        # 非空? 行数合理 (>10行)?
grep "bridge_owner" api-manifest.yaml   # 每个 API 有归属?
grep "acceptance_criteria" ...          # 有验收标准?
```

实物检查清单:
- [ ] `analysis/api-manifest.yaml` **文件存在且 >10 行**
- [ ] `android_apis_used` 列表项数 ≥ 1，且每项有 `api`, `usage`, `bridge_owner`
- [ ] `bridge_owner` 的值是合法模块号 (16.4.2~16.4.9)
- [ ] `acceptance_criteria` ≥ 2 条，且内容是人话不是占位符
- [ ] **交叉验证**: API 清单中列出的 API 是否在 src/*.java 中真的出现 (grep 验证)

#### 检查 16.3 (设计阶段)

实物检查清单:
- [ ] `mapping/design-report.yaml` **文件存在且 >15 行**
- [ ] 每个 `design_decisions` 条目有 `decision` + `rationale`
- [ ] `rationale` 不是模板占位文字 (长度 > 20 字符)
- [ ] `DIRECT_MAP` 类型必须填了 `harmony_api` (不能为空)
- [ ] `BRIDGE_EXISTING` 类型必须填了 `bridge_agent` + `interface_requirement`
- [ ] 如有 Decision C → `proposals/` 下的 NMP 文件存在且 7 部分完整
- [ ] **交叉验证**: design_decisions 的 API 列表和 api-manifest.yaml 的 API 列表一致 (没有遗漏)

#### 检查 16.4.x (Bridge 阶段)

对每个涉及的 Bridge Agent:
- [ ] `16.4.x/05-Implementation/` 下有新增或修改的 .ets 文件
- [ ] **文件行数检查**: Bridge 代码 > 20 行 (不是空壳)
- [ ] `16.4.x/06-Test/` 下有对应测试文件
- [ ] **测试文件行数 > 10 行** (不是空壳)
- [ ] 测试文件中有实际 assert/expect 语句 (grep 验证)
- [ ] Bridge 代码中有 api-manifest 中要求的 API 方法名 (grep 验证)
- [ ] **交叉验证**: design-report 中指定的 interface_requirement 在 Bridge 代码中有对应实现

#### 检查 16.6 (测试阶段)

- [ ] `e2e/comparison-report.yaml` **文件存在且 >20 行**
- [ ] `test_method` 为 `EMULATOR` / `REAL_DEVICE` / `PREVIEWER` 之一 (不是空)
- [ ] `environment.android` 和 `environment.harmony` 非空
- [ ] `e2e/screenshots/android/` 目录存在
- [ ] `e2e/screenshots/harmony/` 目录存在
- [ ] **Android 截屏: 至少 1 张 .png，且文件大小 > 1KB** (不是空文件)
- [ ] **HarmonyOS 截屏: 至少 1 张 .png，且文件大小 > 1KB**
- [ ] 截屏数量 == comparison-report 中 scenarios 数量 (每个场景有证据)
- [ ] `summary.verdict` 非空
- [ ] **交叉验证**: scenarios 中引用的截屏路径实际存在

### 输出格式

```
交付物实物验收 — 案例 16.1.122-TextClock
═══════════════════════════════════════════════════════
验收方式: 实物检查 (非信任 Agent 自报)

16.1 Case Agent:
  [x] api-manifest.yaml          存在, 42 行
  [x] android_apis_used          7 个 API (已与 src/ grep 交叉验证)
  [x] bridge_owner               全部合法
  [x] acceptance_criteria        5 条

16.3 R&D Agent:
  [x] design-report.yaml         存在, 68 行
  [x] decision + rationale       7/7 完整, rationale 均 >20 字符
  [x] 交叉验证                   API 列表与 16.1 清单一致 (0 遗漏)

16.4.x Bridge Agents:
  [—] 无 Bridge 任务 (全部 DIRECT_MAP)

16.6 Test Agent:
  [x] comparison-report.yaml     存在, 35 行
  [ ] test_method                ❌ 空
  [ ] android screenshots        ❌ 0 张 (目录不存在)
  [ ] harmony screenshots        ❌ 0 张 (目录不存在)
  [ ] 截屏证据                   ❌ 0/5 场景有截屏

结论: ❌ REJECTED
阻塞方: 16.6 (交付物不完整 — 无运行时证据)
动作: 16.6 需执行 /wf-test-compare 122 (需仿真器环境)
推荐: 此案例阻塞中，建议先推进其他就绪案例 → /wf-pick-case
═══════════════════════════════════════════════════════
```

### 自动推进原则

检查完成后，如果当前案例阻塞:
1. 明确告知阻塞方和所需动作
2. **立即建议下一个可推进的案例** (系统资源不闲置)
3. 输出: "案例 $ARGUMENTS 等待 [Agent]，建议先跑 /wf-run-case [下一个就绪案例]"
