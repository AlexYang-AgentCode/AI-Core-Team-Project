# E2E Multi-Agent Workflow: Android APK → HarmonyOS 无感运行

> **目标**: 按序处理案例 16.1.120~150，让每个 Android APK 无感运行在 HarmonyOS 上
> **策略**: 调度中心 (16.2) 分派 → 各 Agent 独立工作 → E2E 验证 → 错误归因 → 定向修复 → 循环直至通过

---

## 1. Agent 角色定义

### 1.1 Orchestrator (16.2-AgenticWorkFlow) — 本模块

| 属性 | 说明 |
|------|------|
| **定位** | 总调度、总裁判 |
| **职责** | ① 按序取案例 ② 触发分析→适配→编译→E2E 全流程 ③ 收集 E2E 错误 ④ 归因到具体 Agent ⑤ 派发修复任务 ⑥ 判定通过/重试 |
| **不做** | 不写业务代码、不写 Bridge 实现 |

### 1.2 Case Agent (16.1)

| 属性 | 说明 |
|------|------|
| **定位** | 案例供给 + Android 源码分析 |
| **输入** | 案例目录 `16.1.1XX/` (含 `src/`, `apk/`, `harmony/`) |
| **输出** | ① Android API 调用清单 (manifest) ② 行为描述 (what the APK does) ③ 验收标准 (acceptance criteria) |
| **触发** | Orchestrator 指定案例编号 |

### 1.3 Requirement & Design Agent (16.3)

| 属性 | 说明 |
|------|------|
| **定位** | **适配架构师** — 基于全量 API 图谱，为每个 API 设计最合理的适配策略 |
| **输入** | ① 16.1 Agent 产出的 Android API 调用清单 ② 全量 API 知识库（已积累的所有案例 API） |
| **核心职责** | 不是简单的"查表翻译"，而是**设计决策**：综合考虑 API 之间的关联性、HarmonyOS 的能力边界、已有 Bridge 的覆盖范围，给出适配方案 |
| **知识库** | `16.3-API-MASTER-LIST.csv`, `16.3.2-MAPPING-RULES/`, `16.3.1-RESEARCH-ANALYSIS/` |

#### 16.3 Agent 的三种输出决策

```
Decision A: DIRECT_MAP
  → Android API 有直接对应的 HarmonyOS API
  → 示例: SharedPreferences → @ohos.data.preferences
  → 不需要 Bridge，16.4.x 无需介入

Decision B: BRIDGE_EXISTING
  → 需要适配层，但可归入已有的 16.4.x Bridge 模块
  → 示例: Activity.onCreate → 16.4.2 Activity.Bridge 负责
  → 输出: 指定 bridge_agent + 接口需求

Decision C: NEW_MODULE_NEEDED ★ 需人工审批
  → 现有 16.4.x 模块都无法合理承接该 API
  → 16.3 产出深度分析报告 (New Module Proposal)
  → Orchestrator 暂停流水线，进入 PENDING_APPROVAL 状态
  → 人工审核通过后才正式创建模块、继续流水线
```

#### 为什么 16.3 需要看"全局"？

单个 API 的适配方案看似简单，但放到全局视角可能完全不同：

```yaml
# 例子: android.os.Handler
# 局部视角: 直接用 HarmonyOS 的 taskpool 替代 → DIRECT_MAP
# 全局视角: Handler 与 Looper、Message、MessageQueue 深度耦合，
#           且 Service/BroadcastReceiver 都依赖 Handler 机制
#           → 应该由 16.4.6-Concurrency 统一建模，而不是逐个翻译

# 例子: android.content.ContentProvider
# 局部视角: 翻译成 HarmonyOS DataShare
# 全局视角: ContentProvider 依赖 Uri scheme + Cursor + SQLite,
#           跨越了 Storage(16.4.7) 和 Activity(16.4.2) 的边界
#           → 16.3 决定: 由 16.4.7 主导，16.4.2 配合 URI 路由
```

#### 16.3 Agent 的输出结构

```yaml
# 适配设计报告 (per case)
case_id: "16.1.126"
case_name: "Handler-Looper"

design_decisions:
  - api: "android.os.Handler"
    decision: "BRIDGE_EXISTING"
    bridge_agent: "16.4.6"
    rationale: "Handler 是 Android 并发核心原语，与 Looper/MessageQueue 构成整体"
    interface_requirement: |
      需实现 Handler.post(Runnable), Handler.sendMessage(Message),
      Handler.postDelayed(Runnable, long)
      底层映射到 HarmonyOS taskpool 或 EventHandler

  - api: "android.os.Looper"
    decision: "BRIDGE_EXISTING"
    bridge_agent: "16.4.6"
    rationale: "与 Handler 同属并发体系，必须在 16.4.6 内一并实现"
    dependency: "Handler"

  - api: "android.os.Message"
    decision: "BRIDGE_EXISTING"
    bridge_agent: "16.4.6"
    rationale: "Handler-Message 是配对使用的"

# 当发现需要新模块时 → 产出 New Module Proposal (NMP)
# NMP 不会自动执行，必须人工审批后才生效
new_module_proposals:
  - proposal_id: "NMP-2026-001"
    status: "PENDING_APPROVAL"  # 只有人工改为 APPROVED 才继续
    module_id: "16.4.7"
    module_name: "Storage.Bridge"
    # ↓↓↓ 以下为深度分析报告，供人工审核 ↓↓↓
```

#### New Module Proposal (NMP) 深度分析报告模板

16.3 Agent 产出的 NMP 必须包含以下 7 个部分，缺一不可：

```yaml
# ═══════════════════════════════════════════════
# New Module Proposal: NMP-2026-001
# 提案模块: 16.4.7-Storage.Bridge
# 提案时间: 2026-03-13
# 触发案例: 16.1.128-FileIO (当前) + 16.1.120/129/142 (关联)
# 状态: PENDING_APPROVAL
# ═══════════════════════════════════════════════

# ── Part 1: 问题陈述 ──
# 为什么现有模块不够？不能硬塞进哪个现有模块？
problem_statement:
  trigger: "案例 16.1.128-FileIO 引入 java.io.File/InputStream/OutputStream"
  why_not_existing_modules:
    - module: "16.4.4-System.Bridge"
      reason: |
        System.Bridge 负责系统服务 (Permission, Sensor, Location 等)。
        文件 I/O 虽然用到系统调用，但其核心语义是"持久化数据"，
        与 Permission/Sensor 的"系统能力调用"本质不同。
        强行塞入会导致 System.Bridge 职责膨胀，后续 SQLite/ContentProvider 更难归类。
    - module: "16.4.2-Activity.Bridge"
      reason: "Activity.Bridge 负责生命周期和组件导航，与数据存储无关"
  what_happens_if_no_new_module: |
    API 被分散到多个不相关模块，导致:
    1. SharedPreferences 在 System.Bridge, FileIO 在另一个模块 → 存储语义碎片化
    2. SQLite(129) 到来时再次面临同样的归属困境
    3. ContentProvider(142) 需要同时依赖 SQLite + URI，跨模块协调成本高

# ── Part 2: API 覆盖范围分析 ──
# 新模块具体要承接哪些 API？来自哪些案例？
api_coverage:
  confirmed_apis:  # 已在案例中出现
    - api: "android.content.SharedPreferences"
      source_case: "16.1.120"
      current_status: "已通过，目前用 DIRECT_MAP"
      migration_impact: "低 — 可保持 DIRECT_MAP，仅组织归属变更"

    - api: "java.io.File / InputStream / OutputStream"
      source_case: "16.1.128"
      current_status: "当前案例，触发本提案"

  projected_apis:  # 预判后续案例会引入
    - api: "android.database.sqlite.*"
      source_case: "16.1.129-SQLite"
      confidence: "HIGH — 案例已存在"

    - api: "android.content.ContentProvider"
      source_case: "16.1.142-ContentProvider"
      confidence: "HIGH — 案例已存在"

  total_api_count: 4 类, 约 35 个具体方法

# ── Part 3: 模块职责边界 ──
# 新模块做什么、不做什么
scope:
  in_scope:
    - "本地键值存储 (SharedPreferences → preferences)"
    - "文件 I/O (File/Stream → @ohos.file.fs)"
    - "关系型数据库 (SQLite → @ohos.data.relationalStore)"
    - "跨应用数据共享 (ContentProvider → DataShareExtensionAbility)"
  out_of_scope:
    - "网络存储/云同步 → 16.4.8-Network.Bridge"
    - "权限检查 → 16.4.4-System.Bridge (Storage.Bridge 调用其接口)"
    - "缓存策略/图片缓存 → 16.4.9-ThirdParty.Adapter (如 Glide)"
  boundary_rule: "凡是把数据写到本地磁盘/读出来的操作归本模块；通过网络传输的不归"

# ── Part 4: 与现有模块的接口关系 ──
# 新模块和谁有交互？接口是什么？
interfaces:
  - with: "16.4.2-Activity.Bridge"
    direction: "双向"
    contract: |
      ContentProvider 需要 Activity.Bridge 提供 URI 路由注册机制。
      Activity.Bridge 在 startActivity 时可能携带文件 URI，需 Storage.Bridge 解析。
    api_surface:
      - "StorageBridge.resolveContentUri(uri: string): DataSource"
      - "ActivityBridge.registerContentProvider(authority: string, provider: StorageProvider)"

  - with: "16.4.4-System.Bridge"
    direction: "Storage → System (单向依赖)"
    contract: |
      FileIO 写入外部存储前需检查 WRITE_EXTERNAL_STORAGE 权限。
      Storage.Bridge 调用 System.Bridge 的权限检查接口。
    api_surface:
      - "SystemBridge.checkPermission(permission: string): boolean"

  - with: "16.4.6-Concurrency"
    direction: "Storage → Concurrency (单向依赖)"
    contract: |
      SQLite 操作可能在子线程执行 (AsyncTask + DB query)。
      Storage.Bridge 使用 Concurrency.Bridge 提供的线程调度。
    api_surface:
      - "ConcurrencyBridge.runOnBackground(task: () => void): void"

# ── Part 5: 成本与风险评估 ──
cost_and_risk:
  implementation_cost:
    estimated_apis: 35
    estimated_effort: "中 — 大部分有 HarmonyOS 对应 API"
    hardest_part: "ContentProvider 的 Cursor 抽象层，HarmonyOS 无直接等价物"

  risk_if_approved:
    - "低: 现有模块需要微调接口以配合 Storage.Bridge"
    - "中: ContentProvider 的 Cursor → ResultSet 转换可能不完整"

  risk_if_rejected:
    - "存储 API 散落在多个模块，后续维护成本递增"
    - "案例 142 (ContentProvider) 可能无法通过 E2E"

# ── Part 6: 替代方案 ──
# 16.3 必须说明"不建新模块"的替代方案是什么，以及为什么不推荐
alternatives:
  - name: "塞入 16.4.4-System.Bridge"
    pros: "不增加模块数"
    cons: "System.Bridge 职责过载，存储与系统服务语义混杂"
    recommendation: "不推荐"

  - name: "按存储类型分散到多个现有模块"
    pros: "不增加模块数"
    cons: "SharedPreferences→System, FileIO→System, SQLite→新模块? 分类标准不一致"
    recommendation: "不推荐"

  - name: "暂时标记 BRIDGE_EXISTING 由 System.Bridge 兜底，后续再拆"
    pros: "短期不阻塞流水线"
    cons: "技术债累积，拆分时迁移成本更高"
    recommendation: "仅在审批周期过长时作为临时方案"

# ── Part 7: 建议与结论 ──
conclusion:
  recommendation: "APPROVE"
  confidence: "HIGH"
  summary: |
    存储类 API 在 Android 中是独立且内聚的子系统 (SharedPreferences/File/SQLite/ContentProvider)，
    在 HarmonyOS 中也有对应的独立模块 (@ohos.data.*)。
    新建 16.4.7-Storage.Bridge 符合两端的架构对称性，
    且案例 120/128/129/142 共 4 个案例直接受益。
```

#### NMP 人工审批流程

```
16.3 产出 NMP 深度分析报告
        │
        ▼
Orchestrator 收到 Decision C: NEW_MODULE_NEEDED
        │
        ├──→ 将 NMP 报告写入 proposals/NMP-2026-001.yaml
        ├──→ 流水线进入 PENDING_APPROVAL 状态
        ├──→ 当前案例标记 WAITING_ON_APPROVAL（不算 BLOCKED）
        ├──→ 通知人工审核（文件 + 邮件/消息）
        │
        ▼
   ┌─── 人工审核 ───┐
   │                 │
   │  审核要点:       │
   │  1. 问题陈述是否成立？能否塞进现有模块？
   │  2. API 覆盖范围是否值得独立模块？
   │  3. 与现有模块的接口是否合理？
   │  4. 替代方案是否被充分考虑？
   │  5. 模块边界是否清晰？
   │                 │
   └────────┬────────┘
            │
   ┌────────┼────────┐
   │        │        │
   ▼        ▼        ▼
APPROVED  REVISE   REJECTED
   │        │        │
   │        │        └──→ Orchestrator 要求 16.3 用替代方案
   │        │             (塞入现有模块 / 拆分 API 归属)
   │        │             → 流水线以 Decision B 继续
   │        │
   │        └──→ 人工标注修改意见
   │             → 16.3 修订 NMP 报告 → 重新提交审核
   │
   └──→ Orchestrator 执行:
        1. 创建模块目录 16.4.x/
        2. 初始化模块 CLAUDE.md (职责边界、API scope)
        3. 将 WAITING_ON_APPROVAL 的案例恢复为 BRIDGING
        4. 将依赖此模块的后续案例解除阻塞
```

**审批期间流水线不停：**

```yaml
# WAITING_ON_APPROVAL 的案例被跳过，但不影响其他案例
orchestrator_behavior:
  on_pending_approval:
    - action: "跳过当前案例，继续处理下一个不依赖新模块的案例"
    - action: "用替代方案临时处理（如果 16.3 提供了 alternative.临时方案）"
    - action: "累积依赖新模块的案例到 waiting_queue"

  on_approved:
    - action: "创建模块、初始化"
    - action: "批量恢复 waiting_queue 中所有案例"

  on_rejected:
    - action: "16.3 按 REVISE/REJECTED 意见重新设计"
    - action: "恢复案例，按修订后的 Decision B 继续"

# 审批文件位置
approval_file: "proposals/NMP-2026-001.yaml"
# 人工只需修改一个字段:
#   status: "PENDING_APPROVAL" → "APPROVED" / "REJECTED" / "REVISE"
#   reviewer_notes: "..."  (审核意见)
```

#### 16.3 Agent 在修复闭环中的角色

当 E2E 失败且错误归因为"**设计层问题**"时，Orchestrator 会把错误回传给 16.3：

```yaml
# 场景: 16.4.6 实现的 Handler Bridge 无法支持 Service 中的跨线程通信
# 原因: 16.3 最初设计时没有考虑 Service 场景下 Handler 的特殊性
fix_request_to_16_3:
  case_id: "16.1.132"
  error: "Handler in Service context needs Looper.getMainLooper() which is not bridged"
  question: "是否需要扩展 16.4.6 的接口？还是 Service 场景的 Handler 应由 16.4.2 处理？"

# 16.3 重新分析后可能的输出:
revised_decision:
  api: "Handler (in Service context)"
  original_decision: "16.4.6 单独处理"
  revised_decision: "16.4.6 提供 Handler 核心实现，16.4.2 负责 Service 生命周期内的 Looper 注入"
  cross_agent_contract:
    "16.4.2 → 16.4.6": "Service.onCreate 时调用 ConcurrencyBridge.prepareLooper()"
```

### 1.4 Bridge Agents (16.4.1~16.4.9) — 每个独立

| Agent | 领域 | 负责的 Android API 范畴 |
|-------|------|------------------------|
| **16.4.1-JIT.Performance** | JIT 编译/性能 | DEX 字节码转译、热代码优化 |
| **16.4.2-Activity.Bridge** | Activity/Lifecycle | Activity, Intent, Bundle, Fragment, Service, BroadcastReceiver |
| **16.4.3-View.Bridge** | View/UI | View, Widget, Layout, Toast, Dialog, RecyclerView, Animation |
| **16.4.4-System.Bridge** | 系统服务 | R class, Permission, Notification, Sensor, Location, Camera, Bluetooth |
| **16.4.5-JNI.Runtime** | JNI/Native | JNI 调用、Native 库加载 |
| **16.4.6-Concurrency** | 并发 | Handler, Looper, AsyncTask, Thread |
| **16.4.7-Storage.Bridge** | 存储 | SharedPreferences, SQLite, FileIO, ContentProvider |
| **16.4.8-Network.Bridge** | 网络 | HttpURLConnection, WebView, OkHttp |
| **16.4.9-ThirdParty.Adapter** | 第三方库 | Retrofit, Glide, Room 等常用库适配 |

每个 Bridge Agent 的统一接口：

```
INPUT:  { api_name, usage_context, error_log? }
OUTPUT: { bridge_code_path, compile_result, changelog }
```

---

## 2. E2E 流程（单案例一轮）

```
┌──────────────────────────────────────────────────────────────┐
│                    ORCHESTRATOR (16.2)                        │
│                                                              │
│  ┌─────────┐    ┌─────────┐    ┌──────────────┐             │
│  │ Step 1   │───→│ Step 2   │───→│ Step 3        │            │
│  │ 取案例   │    │ 分析     │    │ 适配设计     │             │
│  │ (16.1)   │    │ (16.1)   │    │ (16.3 R&D)   │             │
│  └─────────┘    └─────────┘    └──────┬───────┘             │
│                                       │                      │
│                                       ▼                      │
│                              ┌──────────────────┐            │
│                              │ Step 3b (if C)    │            │
│                              │ NEW_MODULE_NEEDED │            │
│                              │ → NMP 深度报告    │            │
│                              │ → PENDING_APPROVAL│            │
│                              │ → 人工审核        │            │
│                              └──────┬───────────┘            │
│                                     │ APPROVED / REJECTED    │
│                                     ▼                        │
│                              ┌──────────────┐                │
│                              │ Step 4        │                │
│                              │ 分派给        │                │
│                              │ Bridge Agents │                │
│                              │ (16.4.x)      │                │
│                              └──────┬───────┘                │
│                                     │                        │
│                                     ▼                        │
│                              ┌──────────────┐                │
│                              │ Step 5        │                │
│                              │ 整合编译      │                │
│                              └──────┬───────┘                │
│                                     │                        │
│                                     ▼                        │
│                              ┌──────────────┐   FAIL         │
│                              │ Step 6        │──────┐        │
│                              │ E2E 验证      │      │        │
│                              └──────┬───────┘      │        │
│                                     │ PASS          │        │
│                                     ▼               ▼        │
│                              ┌──────────┐   ┌────────────┐  │
│                              │ Step 7    │   │ Step 6b     │  │
│                              │ 标记通过  │   │ 错误归因    │  │
│                              │ 下一案例  │   │ → 回到 4    │  │
│                              └──────────┘   └────────────┘  │
└──────────────────────────────────────────────────────────────┘
```

### Step 详解

#### Step 1: 取案例 (Orchestrator → 16.1 Agent)

```yaml
command: LOAD_CASE
payload:
  case_id: "16.1.120"
  path: "E:/10.Project/16.1-AndroidToHarmonyOSDemo/16.1.120-SharedPreferences/"
```

#### Step 2: Android 源码分析 (16.1 Agent)

16.1 Agent 分析 `src/` 目录下所有 Java 文件，产出：

```yaml
# 案例分析报告
case_id: "16.1.120"
case_name: "SharedPreferences"
android_apis_used:
  - api: "android.content.SharedPreferences"
    usage: "getSharedPreferences, getString, putString, contains, remove"
    bridge_owner: "16.4.7"  # Storage.Bridge
  - api: "android.widget.Toast"
    usage: "makeText, show"
    bridge_owner: "16.4.3"  # View.Bridge
  - api: "android.widget.EditText"
    usage: "getText, setText"
    bridge_owner: "16.4.3"
  - api: "android.view.inputmethod.InputMethodManager"
    usage: "hideSoftInputFromWindow"
    bridge_owner: "16.4.4"  # System.Bridge
  - api: "androidx.appcompat.app.AppCompatActivity"
    usage: "onCreate, setContentView, findViewById"
    bridge_owner: "16.4.2"  # Activity.Bridge
acceptance_criteria:
  - "输入文本并 Save 后，数据持久化到本地"
  - "点 Open 可读取已存储的文本"
  - "点 Delete 可清除存储，界面显示 null 提示"
  - "空输入时 Save 弹出 Toast 提示"
```

#### Step 3: 适配设计 (16.3 Requirement & Design Agent)

16.3 收到 API 清单后，不是简单查映射表，而是做**设计决策**：

```yaml
# 适配设计报告
case_id: "16.1.120"
case_name: "SharedPreferences"

# 16.3 首先查全局 API 图谱，判断上下文
global_context:
  total_apis_seen: 47              # 截至目前所有案例累计的 API
  storage_apis_seen: ["SharedPreferences"]  # 首次出现存储类 API
  upcoming_storage_apis:            # 16.3 预判后续案例还会遇到的同类 API
    - "FileIO (case 128)"
    - "SQLite (case 129)"
    - "ContentProvider (case 142)"

# 基于全局分析的设计决策
design_decisions:
  - api: "SharedPreferences"
    decision: "DIRECT_MAP"
    harmony_api: "@ohos.data.preferences"
    rationale: "接口语义高度一致，无需 Bridge"

  - api: "Toast.makeText"
    decision: "DIRECT_MAP"
    harmony_api: "promptAction.showToast"
    rationale: "功能等价，参数可直接适配"

  - api: "AppCompatActivity.onCreate"
    decision: "BRIDGE_EXISTING"
    bridge_agent: "16.4.2"
    rationale: "Activity 生命周期是核心适配需求，16.4.2 已设计承接"
    interface_requirement: |
      onCreate(Bundle) → aboutToAppear()
      setContentView(R.layout.xxx) → build() 方法
      需处理 savedInstanceState 的状态恢复

  - api: "findViewById"
    decision: "BRIDGE_EXISTING"
    bridge_agent: "16.4.3"
    rationale: |
      声明式 UI 无 findViewById 概念。
      但不能逐个翻译，应在 16.4.3 中建立统一的
      "命令式 View 引用 → 声明式 @State 绑定" 转换模式，
      后续 EditText/TextView/Button 等都复用此模式

  - api: "InputMethodManager"
    decision: "BRIDGE_EXISTING"
    bridge_agent: "16.4.4"
    rationale: "系统服务类，归入 System.Bridge"

# 新模块提案（当现有模块不足时）
new_module_proposals: []  # 本案例无需新建模块
# 但 16.3 标注: 当 case 128/129/142 到来时，
# 预计需要正式建立 16.4.7-Storage.Bridge 模块
forward_looking_notes:
  - trigger: "case 16.1.128 (FileIO)"
    action: "评估是否需新建 16.4.7-Storage.Bridge"
    reason: "File/SQLite/ContentProvider 跨越多种存储语义，不宜塞入现有模块"
```

#### Step 4: 分派 Bridge 任务 (Orchestrator → 16.4.x Agents)

Orchestrator 根据 Step 3 的 `bridge_agent` 字段，**并行**分派给对应 Agent：

```yaml
# 发给 16.4.2-Activity.Bridge
task:
  case_id: "16.1.120"
  action: "PROVIDE_BRIDGE"
  apis: ["AppCompatActivity.onCreate", "setContentView"]
  context: "SharedPreferences demo, single activity app"
  current_bridge_version: "v1.2.0"

# 发给 16.4.3-View.Bridge
task:
  case_id: "16.1.120"
  action: "PROVIDE_BRIDGE"
  apis: ["findViewById", "EditText", "TextView", "Button", "Toast"]
  context: "Simple form with 3 buttons and text I/O"

# 发给 16.4.7-Storage.Bridge
task:
  case_id: "16.1.120"
  action: "PROVIDE_BRIDGE"
  apis: ["SharedPreferences.getSharedPreferences", "getString", "putString", "remove"]
  context: "Basic key-value storage"
```

每个 Bridge Agent 独立完成：
1. 检查自己的 Bridge 库是否已支持这些 API
2. 如不支持 → 编写新的 Bridge 代码
3. 编译自己的 Bridge 模块
4. 返回结果给 Orchestrator

#### Step 5: 整合编译 (Orchestrator)

```bash
# 1. 收集各 Bridge Agent 的产出
collect_bridges 16.4.2 16.4.3 16.4.7

# 2. 合并到案例的 harmony/ 目录
merge_to_harmony "16.1.120"

# 3. 执行 HarmonyOS 项目编译
hvigorw assembleHap --no-daemon
```

#### Step 6: E2E 验证 (Orchestrator)

```yaml
e2e_test:
  case_id: "16.1.120"
  steps:
    - action: "launch_app"
      expect: "App launches without crash"
    - action: "input_text('Hello World')"
      expect: "TextInput shows 'Hello World'"
    - action: "click_button('SAVE')"
      expect: "Toast shows 'SharedPreferences Saved'"
    - action: "kill_and_relaunch"
    - action: "click_button('OPEN')"
      expect: "Display shows 'Hello World'"
    - action: "click_button('DELETE')"
      expect: "Display shows 'SharedPreferences is null'"
    - action: "click_button('SAVE') with empty input"
      expect: "Toast shows 'Please set any text'"
```

#### Step 6b: 错误归因 (核心逻辑)

当 E2E 失败时，Orchestrator 执行错误归因：

```python
def classify_error(error_log: str) -> dict:
    """将 E2E 错误归因到具体 Agent"""

    rules = {
        # 编译期错误
        r"Cannot find module.*Activity|Lifecycle|Intent|Bundle":  "16.4.2",
        r"Cannot find module.*View|Widget|Layout|Toast":          "16.4.3",
        r"Cannot find module.*R\.|Permission|Notification":       "16.4.4",
        r"Cannot find module.*JNI|native":                        "16.4.5",
        r"Cannot find module.*Handler|Looper|Thread":             "16.4.6",
        r"Cannot find module.*SharedPref|SQLite|File":            "16.4.7",
        r"Cannot find module.*Http|WebView|Network":              "16.4.8",

        # 运行时错误
        r"lifecycle.*crash|onCreate.*undefined":                  "16.4.2",
        r"UI.*render.*fail|view.*null":                           "16.4.3",
        r"permission.*denied|sensor.*error":                      "16.4.4",
        r"storage.*fail|preference.*error":                       "16.4.7",

        # 映射/设计层问题 — 回传 16.3 重新设计
        r"API.*not.*mapped|mapping.*missing":                     "16.3",
        r"cross.*module|contract.*missing":                       "16.3",

        # 源码分析遗漏
        r"unexpected.*api|unknown.*import":                       "16.1",
    }

    for pattern, agent in rules.items():
        if re.search(pattern, error_log, re.IGNORECASE):
            return {"agent": agent, "error": error_log}

    return {"agent": "16.2", "error": "Unknown - needs manual triage"}

    # 注意: 升级判断不在这里做。
    # classify_error 只负责"这个错误归谁"（单次归因）。
    # should_escalate 负责"是否需要升级到设计层"（看历史模式）。
    # 两者解耦，避免简单计数导致误判。
```

错误反馈给对应 Agent：

```yaml
# 发给 16.4.7-Storage.Bridge 的修复任务
fix_task:
  case_id: "16.1.120"
  action: "FIX_ERROR"
  error_type: "runtime"
  error_log: |
    TypeError: this.pref.getSync is not a function
    at SharedPreferencesPage.loadPreference (Index.ets:31)
  context: "preferences.getSync API 调用失败"
  previous_attempt: 1
  max_retries: 5
```

#### Step 7: 标记通过 → 下一案例

```yaml
result:
  case_id: "16.1.120"
  status: "PASS"
  attempts: 3
  agents_involved: ["16.4.2", "16.4.3", "16.4.7"]
  bridge_changes:
    - agent: "16.4.7"
      change: "Added SharedPreferences.remove() bridge"
      version: "v1.3.0"

next_case: "16.1.121"  # → Toast-Dialog
```

---

## 3. 错误反馈闭环（重试与升级机制）

### 3.1 重试判断的核心原则

> **早期阶段错误多是正常的。** 关键不是"错了几次"，而是"每次错的是不是同一个问题"。
> 每次修复后出现新的、不同的错误，说明 Agent 在前进；反复撞同一面墙，才需要升级。

### 3.2 每轮错误记录结构

Orchestrator 维护每个案例的完整错误历史，用于判断重试策略：

```yaml
# state/case-120-error-history.yaml
case_id: "16.1.120"
error_history:
  - attempt: 1
    error_signature: "COMPILE::MODULE_MISSING::SharedPreferences"
    agent: "16.4.7"
    resolved: true    # 该错误在下一轮消失了

  - attempt: 2
    error_signature: "COMPILE::TYPE_ERROR::preferences.getSync"
    agent: "16.4.7"
    resolved: true    # 新错误，但也被修了 → 正常推进

  - attempt: 3
    error_signature: "RUNTIME::CRASH::Toast.show_undefined"
    agent: "16.4.3"
    resolved: true    # 又一个新错误，换了模块 → 仍在前进

  - attempt: 4
    error_signature: "RUNTIME::CRASH::Toast.show_undefined"
    agent: "16.4.3"
    resolved: false   # ⚠️ 同一个错误第2次出现，修复无效
```

### 3.3 升级判断算法

```python
def should_escalate(error_history: list) -> dict:
    """
    判断是否需要升级到设计层 (16.3)。
    不是简单看重试次数，而是分析错误模式。
    """

    # ── 指标计算 ──

    total_attempts = len(error_history)
    unique_errors = len(set(e["error_signature"] for e in error_history))

    # 错误签名出现次数
    sig_counts = Counter(e["error_signature"] for e in error_history)
    max_repeat = max(sig_counts.values())  # 单个错误最大重复次数

    # 同一 Agent 连续失败次数
    agent_streak = count_consecutive_same_agent(error_history)

    # 回归率: 已修复的错误又重新出现
    regression_count = count_regressions(error_history)

    # ── 判断逻辑 ──

    # 情况 A: 每次都是新错误 → Agent 在前进，继续
    # 例: attempt 1~8 各不相同 → unique_errors == total_attempts
    if unique_errors == total_attempts:
        return {
            "action": "CONTINUE",
            "reason": f"连续 {total_attempts} 次都是不同错误，Agent 在稳步推进"
        }

    # 情况 B: 同一个错误连续出现 ≥3 次 → 该 Agent 对此问题无能为力
    if max_repeat >= 3:
        stuck_error = [sig for sig, c in sig_counts.items() if c >= 3][0]
        stuck_agent = [e["agent"] for e in error_history
                       if e["error_signature"] == stuck_error][-1]
        return {
            "action": "ESCALATE_TO_DESIGN",
            "reason": f"错误 '{stuck_error}' 已连续出现 {max_repeat} 次，"
                      f"{stuck_agent} 无法自行解决",
            "target": "16.3",
            "context": f"请重新评估该 API 的适配设计，{stuck_agent} 可能不是正确的归属"
        }

    # 情况 C: 修好的错误又回来了 (回归) → 模块间耦合问题
    if regression_count >= 2:
        return {
            "action": "ESCALATE_TO_DESIGN",
            "reason": f"出现 {regression_count} 次回归：修 A 坏 B、修 B 坏 A",
            "target": "16.3",
            "context": "模块间存在未定义的耦合，需要 16.3 设计跨模块 contract"
        }

    # 情况 D: 同一个 Agent 连续失败 ≥4 次（即使错误不同）→ 该 Agent 能力边界
    if agent_streak >= 4:
        stuck_agent = error_history[-1]["agent"]
        return {
            "action": "ESCALATE_TO_DESIGN",
            "reason": f"{stuck_agent} 连续 {agent_streak} 次产出都未通过（错误各异），"
                      f"可能超出该模块能力范围",
            "target": "16.3",
            "context": f"请评估这些 API 是否应拆分到其他模块，或新建模块"
        }

    # 情况 E: 总次数很高但仍在前进 → 给予更多空间但设软上限
    if total_attempts >= 15:
        return {
            "action": "BLOCKED",
            "reason": f"已尝试 {total_attempts} 次，虽然仍有进展但耗时过长",
            "suggestion": "人工介入评估是否值得继续"
        }

    # 默认: 继续重试
    return {
        "action": "CONTINUE",
        "reason": f"第 {total_attempts} 次尝试，错误模式正常"
    }


def count_regressions(history: list) -> int:
    """统计回归次数: 曾被标记 resolved=true 的 error_signature 再次出现"""
    resolved_sigs = set()
    regressions = 0
    for entry in history:
        sig = entry["error_signature"]
        if sig in resolved_sigs:
            regressions += 1
        if entry.get("resolved"):
            resolved_sigs.add(sig)
    return regressions


def count_consecutive_same_agent(history: list) -> int:
    """从尾部往前数，同一个 Agent 连续出现的次数"""
    if not history:
        return 0
    last_agent = history[-1]["agent"]
    streak = 0
    for entry in reversed(history):
        if entry["agent"] == last_agent:
            streak += 1
        else:
            break
    return streak
```

### 3.4 四种处置路径

```
每轮 E2E Fail
    │
    ├──→ Orchestrator 归因到 Agent + 记录 error_signature
    │
    ├──→ should_escalate() 判断
    │
    ├── CONTINUE ───────────→ 派发 FIX_ERROR 给对应 Agent，继续
    │   (每次新错误,               Agent 修复 → 重新编译 → 重新 E2E
    │    正常推进中)
    │
    ├── ESCALATE_TO_DESIGN ─→ 回传 16.3 重新评估
    │   (同错重复≥3 /             16.3 可能: 改归属 / 新建模块 / 设计 contract
    │    回归≥2 /                 → 按新设计重新派发给 16.4.x
    │    同Agent连败≥4)
    │
    ├── BLOCKED ────────────→ 标记 BLOCKED，记录完整 error_history
    │   (总次数≥15,               跳到下一案例，人工介入队列
    │    耗时过长)
    │
    └── 特殊: 16.3 redesign 后仍失败 2 轮 → BLOCKED
        (设计层也无法解决 → 需要人工架构决策)
```

### 3.5 判断示意（对比场景）

```
场景 1: 早期 Agent 正常推进 ✅ 不升级
──────────────────────────────────────
attempt 1: COMPILE::MODULE_MISSING::Toast       → 16.4.3 修 → ✓ 消失
attempt 2: COMPILE::TYPE_ERROR::preferences     → 16.4.7 修 → ✓ 消失
attempt 3: RUNTIME::CRASH::lifecycle_null       → 16.4.2 修 → ✓ 消失
attempt 4: RUNTIME::BEHAVIOR::text_not_saved    → 16.4.7 修 → ✓ 消失
attempt 5: RUNTIME::BEHAVIOR::toast_not_shown   → 16.4.3 修 → ✓ 消失
attempt 6: PASS ✅

→ 6次尝试，5个不同错误，每次都在前进。should_escalate() = CONTINUE。
  这就是早期 Agent 努力前进的正常迹象。


场景 2: Agent 卡住 ❌ 升级到 16.3
──────────────────────────────────────
attempt 1: COMPILE::MODULE_MISSING::Handler     → 16.4.6 修 → ✓ 消失
attempt 2: RUNTIME::CRASH::Looper_not_prepared  → 16.4.6 修 → ✗ 未消失
attempt 3: RUNTIME::CRASH::Looper_not_prepared  → 16.4.6 修 → ✗ 未消失
attempt 4: RUNTIME::CRASH::Looper_not_prepared  → 同错第3次!

→ should_escalate() = ESCALATE_TO_DESIGN
  原因: "Looper_not_prepared" 连续出现 3 次，16.4.6 无法自行解决。
  → 16.3 介入: 发现 Looper 在 Service 上下文需要 16.4.2 配合注入。


场景 3: 修 A 坏 B 循环 ❌ 升级到 16.3
──────────────────────────────────────
attempt 1: RUNTIME::CRASH::view_bindingError    → 16.4.3 修 → ✓ 消失
attempt 2: RUNTIME::CRASH::lifecycle_order      → 16.4.2 修 → ✓ 消失
attempt 3: RUNTIME::CRASH::view_bindingError    → 回归! 16.4.2 的修改破坏了 16.4.3
attempt 4: RUNTIME::CRASH::lifecycle_order      → 回归! 16.4.3 的修改破坏了 16.4.2

→ should_escalate() = ESCALATE_TO_DESIGN (regression_count=2)
  原因: View.Bridge 和 Activity.Bridge 互相破坏，缺少 contract。
  → 16.3 介入: 定义 Activity↔View 的初始化顺序 contract。


场景 4: 大量不同错误但持续推进 ⏳ 允许继续
──────────────────────────────────────
attempt 1~10: 每次都是新错误，每次都修好了
attempt 11: 又一个新错误

→ should_escalate() = CONTINUE
  虽然 11 次了，但每次都是不同问题且都解决了。
  这是复杂案例的正常表现（如 ContentProvider 涉及 5 个模块）。
  直到 attempt 15 才触发软上限 BLOCKED。
```

### 3.6 错误分类策略

| 错误类型 | 表现 | 归因 Agent | 修复方式 |
|----------|------|-----------|---------|
| 编译 - 模块缺失 | `Cannot find module 'xxx'` | 对应 16.4.x | Agent 补充 Bridge export |
| 编译 - 类型错误 | `Type 'X' is not assignable` | 对应 16.4.x | Agent 修正 Bridge 接口 |
| 运行 - API 不存在 | `xxx is not a function` | 对应 16.4.x | Agent 实现缺失方法 |
| 运行 - 崩溃 | `Error at xxx.ets:NN` | 按堆栈归因 | Agent 修复逻辑 |
| 行为 - 不一致 | E2E 断言失败 | 可能多个 Agent | Orchestrator 分析后派发 |
| 映射 - 遗漏 | API 未被翻译 | 16.3 → 16.4.x | 16.3 补充映射，16.4.x 实现 |
| 设计 - 职责错配 | Bridge 实现了但语义不对 | 16.3 | 16.3 重新评估该 API 应归哪个模块 |
| 设计 - 模块缺失 | 多个 API 跨模块无人接 | 16.3 | 16.3 提案新建 16.4.x 模块 |
| 设计 - 跨模块接口 | A 模块依赖 B 模块未暴露的能力 | 16.3 | 16.3 设计跨 Agent 协议 (contract) |

---

## 4. 案例执行序列 (16.1.120~142)

按依赖复杂度排序，每个案例主要涉及的 Bridge Agent：

| # | 案例 | 核心 Android API | 主要 Bridge Agent | 依赖 |
|---|------|-----------------|-------------------|------|
| 120 | SharedPreferences | SharedPreferences, Toast | 16.4.7, 16.4.3 | 无 |
| 121 | Toast-Dialog | Toast, AlertDialog | 16.4.3 | 无 |
| 122 | TextClock | TextClock, Handler | 16.4.3, 16.4.6 | 无 |
| 123 | UIWidgets-Calculator | Button, EditText, Layout | 16.4.3 | 无 |
| 124 | RecyclerView | RecyclerView, Adapter | 16.4.3 | 121 |
| 125 | Intent | Intent, startActivity | 16.4.2 | 无 |
| 126 | Handler-Looper | Handler, Looper, Message | 16.4.6 | 无 |
| 127 | RuntimePermission | Permission, ActivityCompat | 16.4.4 | 125 |
| 128 | FileIO | File, InputStream, OutputStream | 16.4.7 | 127 |
| 129 | SQLite | SQLiteDatabase, Cursor | 16.4.7 | 无 |
| 130 | HttpNetwork | HttpURLConnection, AsyncTask | 16.4.8, 16.4.6 | 127 |
| 131 | Notification | NotificationManager, Channel | 16.4.4 | 无 |
| 132 | Service | Service, startService, bindService | 16.4.2 | 125 |
| 133 | BroadcastReceiver | BroadcastReceiver, IntentFilter | 16.4.2 | 125 |
| 134 | Fragment | Fragment, FragmentManager | 16.4.2 | 125 |
| 135 | WebView | WebView, WebViewClient | 16.4.8 | 130 |
| 136 | Sensor | SensorManager, SensorEventListener | 16.4.4 | 127 |
| 137 | Location | LocationManager, GPS | 16.4.4 | 127 |
| 138 | Animation | ObjectAnimator, ValueAnimator | 16.4.3 | 无 |
| 139 | MediaPlayer | MediaPlayer, AudioManager | 16.4.4 | 127 |
| 140 | Camera | Camera2 API, SurfaceView | 16.4.4 | 127 |
| 141 | Bluetooth | BluetoothAdapter, GATT | 16.4.4 | 127 |
| 142 | ContentProvider | ContentProvider, ContentResolver | 16.4.7, 16.4.2 | 129 |

---

## 5. Orchestrator 状态机

```
                    ┌─────────────┐
                    │   IDLE       │
                    └──────┬──────┘
                           │ pick_next_case()
                           ▼
                    ┌─────────────┐
                    │  ANALYZING   │  ← 16.1 Agent working
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  DESIGNING   │  ← 16.3 Agent: 适配设计
                    └──────┬──────┘
                           │
                      Decision A/B → 直接进 BRIDGING
                      Decision C  → 进 PENDING_APPROVAL
                           │
                    ┌──────┴───────────┐
                    │                  │
                    ▼                  ▼
             ┌─────────────┐   ┌────────────────┐
             │  BRIDGING    │   │ PENDING_APPROVAL│ ← 等人工审核
             │              │   │ (跳过此案例,    │
             │              │   │  继续其他案例)  │
             │              │   └───────┬────────┘
             │              │           │ APPROVED → 创建模块
             │              │←──────────┘ REJECTED → 用替代方案
             └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  COMPILING   │
                    └──────┬──────┘
                           │
                           ▼
                    ┌─────────────┐
              ┌─NO──│  E2E_TEST    │──YES─┐
              │     └─────────────┘       │
              ▼                           ▼
     ┌──────────────┐           ┌──────────────┐
     │  ERROR_TRIAGE │           │  CASE_DONE    │
     └──────┬───────┘           └──────┬───────┘
            │                          │
            ├── impl error ──┐         │ all cases done?
            │                ▼         │
            │       ┌──────────────┐   │
            │       │  FIXING       │   │
            │       └──────┬───────┘   │
            │              │           │
            │       should_escalate()  │
            │              │           │
            │     ┌── CONTINUE ──→ COMPILING ──→ E2E_TEST
            │     │                    │
            │     ├── ESCALATE ──→ REDESIGN (16.3)
            │     │                    │
            │     └── BLOCKED ───→ 跳到下一案例
            │                          │
            │                          │
            └── design error ──┐       │
                               ▼       │
                      ┌──────────────┐ │
                      │  REDESIGN     │ │  ← 16.3 重新评估设计
                      │  (16.3)       │ │
                      └──────┬───────┘ │
                             │         │
                             ▼         │
                      ┌──────────────┐ │
                      │  BRIDGING     │─┘  ← 按新设计重新派发
                      └──────────────┘
            ▼                          ▼
     ┌──────────────┐           ┌──────────────┐
     │  BLOCKED      │──────────→│  ALL_DONE     │
     └──────────────┘           └──────────────┘
```

---

## 6. Agent 通信协议

### 6.1 消息格式

```typescript
interface AgentMessage {
  id: string                    // UUID
  from: string                  // "16.2" | "16.1" | "16.3" | "16.4.2" | ...
  to: string                    // target agent
  type: "TASK" | "RESULT" | "FIX" | "STATUS"
  case_id: string               // "16.1.120"
  payload: TaskPayload | ResultPayload | FixPayload | StatusPayload
  timestamp: string             // ISO 8601
  attempt: number               // 当前第几次尝试
}

interface TaskPayload {
  action: "ANALYZE" | "MAP" | "BRIDGE" | "COMPILE" | "TEST"
  apis: string[]
  context: string
}

interface ResultPayload {
  status: "OK" | "ERROR"
  output: any                   // 分析报告 / 映射表 / Bridge代码路径
  compile_log?: string
}

interface FixPayload {
  error_type: "COMPILE" | "RUNTIME" | "BEHAVIOR"
  error_log: string
  stack_trace?: string
  suggestion?: string           // Orchestrator 的修复建议
}
```

### 6.2 通信方式

基于文件系统的消息队列（简单可靠）：

```
16.2-AgenticWorkFlow/
├── queue/
│   ├── inbox/                  # Orchestrator 收件箱
│   │   ├── 16.4.2-result-120-001.json
│   │   └── 16.4.3-result-120-001.json
│   ├── outbox/                 # Orchestrator 发件箱
│   │   ├── to-16.1-task-120.json
│   │   ├── to-16.3-task-120.json
│   │   └── to-16.4.2-task-120.json
│   └── archive/                # 已处理的消息
├── proposals/                  # ★ 新模块提案 (NMP)，人工审批区
│   ├── NMP-2026-001.yaml       # 16.3 产出，人工审核
│   └── NMP-2026-002.yaml       # status: APPROVED / REJECTED / REVISE
├── state/
│   ├── current-case.json       # 当前处理的案例
│   ├── case-120-status.json    # 各案例状态
│   ├── case-120-error-history.yaml  # 错误历史 (用于升级判断)
│   └── agent-status.json       # 各 Agent 状态
└── logs/
    ├── e2e-120-attempt-1.log
    └── e2e-120-attempt-2.log
```

---

## 7. 实施 Roadmap

### Phase 0: 基础设施 (Day 1)

- [ ] 建立 `queue/`, `state/`, `logs/` 目录结构
- [ ] 实现 AgentMessage JSON schema 校验
- [ ] 每个 16.4.x Agent 仓库中建立 `CLAUDE.md` 定义其职责边界
- [ ] 实现 Orchestrator 状态机骨架

### Phase 1: 先跑通一个案例 (Day 2-3)

- [ ] 用 16.1.120-SharedPreferences 作为首个端到端测试
- [ ] 手动驱动: 16.1 分析 → 16.3 映射 → 16.4.x Bridge → 编译 → E2E
- [ ] 验证错误归因逻辑
- [ ] 验证修复闭环

### Phase 2: 自动化调度 (Day 4-5)

- [ ] Orchestrator 自动按序取案例
- [ ] 并行派发给多个 Bridge Agent
- [ ] 自动 E2E 验证 + 重试
- [ ] 生成每日进度报告

### Phase 3: 扩展到全部案例 (Day 6+)

- [ ] 从 120 逐步推进到 142
- [ ] Bridge 代码随案例积累而演进
- [ ] 后续案例复用前序案例的 Bridge
- [ ] 每个 Bridge Agent 维护自己的版本号

---

## 8. Test Agent (16.6) 与质量闸门

### 8.1 16.6 Agent 角色定义

| 属性 | 说明 |
|------|------|
| **定位** | **质量守门人** — 不写业务代码，只验证和对比 |
| **双重职责** | ① 单元测试执法: 要求各模块提供测试报告 ② E2E 体验对比: Android 原生 vs HarmonyOS 适配 |

### 8.2 职责一: 单元测试执法

16.6 在 Step 4 (Bridge Agent 交付) 之后、Step 5 (整合编译) 之前介入:

```
Bridge Agent 交付代码
        │
        ▼
   16.6 检查: 该 Agent 是否提交了单元测试报告?
        │
   ┌────┴────┐
   │         │
  有报告   无报告
   │         │
   ▼         ▼
 检查覆盖率  打回: "请补充单元测试后重新提交"
 ≥ 阈值?     → Bridge Agent 补测试 → 重新提交
   │
   ▼
 通过 → 进入 Step 5
```

**单元测试要求:**

```yaml
unit_test_requirement:
  # 每个 Bridge Agent 交付时必须附带
  deliverable:
    code: "16.4.x/05-Implementation/..."   # Bridge 代码
    tests: "16.4.x/06-Test/..."            # 测试代码
    report:
      total_cases: 12
      passed: 12
      failed: 0
      coverage: "85%"          # 行覆盖率
      key_scenarios_covered:   # 核心场景
        - "SharedPreferences.putString → preferences.putSync"
        - "SharedPreferences.remove → preferences.deleteSync"
        - "null/empty 边界情况"

  # 16.6 的检查标准
  acceptance:
    min_coverage: 70%          # 初期 70%，逐步提升
    must_cover:                # 必须覆盖的场景
      - "正常路径"
      - "空值/null 边界"
      - "错误处理路径"
    no_report_action: "REJECT — 打回原 Agent 补充"
```

### 8.3 职责二: E2E 体验对比 (Android vs HarmonyOS)

16.6 驱动两个测试环境，产出**对比报告**:

```
┌─────────────────┐     ┌─────────────────┐
│  Android 原生环境  │     │  HarmonyOS 环境   │
│  (仿真器/真机)    │     │  (DevEco/仿真器)  │
└────────┬────────┘     └────────┬────────┘
         │                       │
         ▼                       ▼
   运行原始 APK              运行适配后的 HAP
         │                       │
         ▼                       ▼
   截图 + 行为日志           截图 + 行为日志
         │                       │
         └───────────┬───────────┘
                     ▼
            16.6 对比报告
```

**对比报告结构:**

```yaml
comparison_report:
  case_id: "16.1.120"
  test_date: "2026-03-13"

  # 逐项对比
  items:
    - scenario: "启动页面"
      android:
        screenshot: "e2e/android/launch.png"
        behavior: "显示标题 + 输入框 + 3 个按钮"
      harmony:
        screenshot: "e2e/harmony/launch.png"
        behavior: "显示标题 + 输入框 + 3 个按钮"
      diff: "MATCH"             # MATCH | MINOR_DIFF | MAJOR_DIFF | BROKEN

    - scenario: "Save 后 Open"
      android:
        behavior: "Toast 显示 'Saved'，Open 后 TextView 显示已存文本"
      harmony:
        behavior: "promptAction.showToast 显示 'Saved'，Text 显示已存文本"
      diff: "MINOR_DIFF"
      detail: "Toast 样式略有差异（圆角 vs 方角），功能等价"

    - scenario: "空输入 Save"
      android:
        behavior: "Toast 提示 'Please set any text'"
      harmony:
        behavior: "无反应"
      diff: "MAJOR_DIFF"        # ← 需要修复
      detail: "空输入校验逻辑未实现"
      action: "→ 归因 16.4.3 (View.Bridge 的输入校验)"

  # 汇总
  summary:
    total_scenarios: 6
    match: 4
    minor_diff: 1    # 可接受
    major_diff: 1    # 需修复
    broken: 0
    verdict: "CONDITIONAL_PASS — 修复 1 个 MAJOR_DIFF 后通过"
```

### 8.4 diff 级别定义

| 级别 | 含义 | 处置 |
|------|------|------|
| **MATCH** | 行为完全一致 | 通过 |
| **MINOR_DIFF** | 视觉/动效微小差异，功能等价 | 通过，记录待优化 |
| **MAJOR_DIFF** | 功能缺失或行为不一致 | 打回对应 Bridge Agent 修复 |
| **BROKEN** | 崩溃、白屏、完全不可用 | 打回，优先级最高 |

---

## 8.5 Orchestrator 交付物验收清单 (所有 Agent)

**Orchestrator 对每个 Agent 的产出都做交付物检查。任何 Agent 交付不完整 → 打回补充，不进入下一步。**

### 16.1 Case Agent 交付物

```
检查项                              │ 缺失处置
────────────────────────────────────┼─────────────────────
analysis/api-manifest.yaml 存在?    │ REJECT → "请完成源码分析"
android_apis_used 列表非空?         │ REJECT → "API 清单为空"
每个 API 有 bridge_owner 字段?      │ REJECT → "未标注归属模块"
acceptance_criteria 至少 2 条?      │ REJECT → "缺少验收标准"
```

### 16.3 R&D Agent 交付物

```
检查项                              │ 缺失处置
────────────────────────────────────┼─────────────────────
mapping/design-report.yaml 存在?    │ REJECT → "请完成适配设计"
每个 API 有 decision + rationale?   │ REJECT → "设计决策不完整"
Decision C 有完整 NMP 7 部分?       │ REJECT → "NMP 报告不完整"
summary.verdict 非空?               │ REJECT → "缺少设计结论"
```

### 16.4.x Bridge Agent 交付物

```
检查项                              │ 缺失处置
────────────────────────────────────┼─────────────────────
Bridge 代码文件存在?                │ REJECT → "未提交 Bridge 代码"
16.4.x/06-Test/ 有对应测试文件?    │ REJECT → "缺少单元测试"
测试全部通过 (passed == total)?     │ REJECT → "测试未通过"
coverage ≥ 70%?                     │ WARN  → "覆盖率不足，建议补充"
compile_result == "OK"?             │ REJECT → "Bridge 编译失败"
changelog 非空?                     │ REJECT → "缺少变更说明"
```

### 16.6 Test Agent 交付物

```
检查项                              │ 缺失处置
────────────────────────────────────┼─────────────────────
e2e/comparison-report.yaml 存在?    │ REJECT → "请执行 /test-compare"
test_method 非空?                   │ REJECT → "未说明测试方式"
environment.android 非空?           │ REJECT → "未说明 Android 测试环境"
environment.harmony 非空?           │ REJECT → "未说明 HarmonyOS 测试环境"
screenshots/android/ ≥1 张 .png?    │ REJECT → "缺少 Android 截屏"
screenshots/harmony/ ≥1 张 .png?    │ REJECT → "缺少 HarmonyOS 截屏"
每个 scenario 有双端截屏路径?       │ REJECT → "对比报告无截屏证据"
summary.verdict 非空?               │ REJECT → "缺少测试结论"
```

### Orchestrator 自身 (16.2) 的检查点

```
每次状态流转前，Orchestrator 检查:
  ANALYZING → DESIGNING:   16.1 交付物完整?
  DESIGNING → BRIDGING:    16.3 交付物完整?
  BRIDGING  → COMPILING:   所有涉及的 16.4.x 交付物完整?
  COMPILING → E2E_TEST:    编译成功?
  E2E_TEST  → CASE_DONE:   16.6 交付物完整 且 verdict == PASS?
```

**这是 Orchestrator 存在的核心价值: 不让不完整的产出流入下一步。**

---

## 9. 代码隔离: 每个 Agent 只改自己的代码

### 9.1 核心规则

```
Agent 只能写入自己的目录，不能修改其他 Agent 的代码。
```

| Agent | 可写目录 | 只读目录 |
|-------|---------|---------|
| 16.1 | `16.1-AndroidToHarmonyOSDemo/16.1.xxx/analysis/` | `src/` (原始源码只读) |
| 16.3 | `16.3-Adapter.Requirement/`, 案例的 `mapping/` | 所有 16.4.x 代码 (只读参考) |
| 16.4.2 | `16.4.2-Activity.Bridge/` | 其他 16.4.x (只读) |
| 16.4.3 | `16.4.3-View.Bridge/` | 其他 16.4.x (只读) |
| ... | 自己的 `16.4.x/` | 其他模块 |
| 16.6 | `16.6-Adapter.Test/`, 案例的 `e2e/` | 所有代码 (只读) |
| 16.2 | `16.2-AgenticWorkFlow/queue/state/logs/` | 所有代码 (只读) |

### 9.2 多案例并行时的隔离

当多个案例同时在跑时，可能多个案例都需要 16.4.3 修改 View.Bridge:

```
案例 120 需要 16.4.3 实现 Toast
案例 123 需要 16.4.3 实现 Calculator 的 Button Layout
  → 如果同时改 16.4.3/05-Implementation/ 会冲突!
```

**解决方案: 串行提交 + 版本递增**

```
16.4.3 的任务队列 (FIFO):
  ┌──────────────────────────────────┐
  │  task-120: Toast bridge          │ ← 先做
  │  task-123: Button Layout bridge  │ ← 120 完成后再做 (基于 120 的代码)
  └──────────────────────────────────┘

每完成一个任务:
  1. 代码提交到 16.4.3/ 目录
  2. 版本号 +1 (v1.0 → v1.1)
  3. 下一个任务基于最新版本开始
```

**关键: Bridge 代码是累积的，不是每个案例独立的。**
案例 123 的 Button Layout 实现是在案例 120 的 Toast 实现之上追加的。

### 9.3 跨模块依赖通过接口文件协调

当 16.4.2 需要调用 16.4.6 的能力时，不直接改 16.4.6 的代码:

```
16.4.2 发现需要: ConcurrencyBridge.prepareLooper()
        │
        ▼
16.4.2 在自己的 contract/ 下声明需求:
  16.4.2/contract/needs-from-16.4.6.yaml:
    - method: "prepareLooper()"
      reason: "Service 启动时需要准备 Looper"
        │
        ▼
Orchestrator 将此需求转发给 16.4.6
        │
        ▼
16.4.6 在自己的代码中实现 prepareLooper() 并导出
16.4.6 在 contract/provides.yaml 中声明:
    - method: "prepareLooper()"
      status: "implemented"
      import_path: "@bridge/concurrency"
```

---

## 10. 软件工厂: 4 人类 + N Agent 的最优分工

### 10.1 人员与自动化定位

**设计原则: 人做决策，机器做执行。人与人之间异步协作，人与机器之间通过文件接口。**

```
┌─────────────────────────────────────────────────────────────┐
│                    决策层 (人类)                               │
│                                                             │
│  产品专家(P)          架构师(A)         开发专家 x2 (D1,D2) │
│  每周2天              全职              全职                  │
│  远程                 远程              远程                  │
│                                                             │
│  ·审批 NMP 提案       ·代码隔离设计     ·值班处理 BLOCKED    │
│  ·定义验收标准        ·跨模块 contract  ·审核 16.6 对比报告  │
│  ·优先级排序          ·设计层 ESCALATE  ·复杂 Bridge 实现指导│
│  ·体验差异 final判定  ·性能架构决策     ·工具链维护          │
└──────────────────────────┬──────────────────────────────────┘
                           │ 文件接口 (proposals/, queue/, state/)
                           │ 异步、不等人
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                    执行层 (Agent 集群)                        │
│                                                             │
│  服务器1: 16.2 Orchestrator (调度)                           │
│  服务器2: 16.1 Case Agent + 16.3 R&D Agent                  │
│  服务器3: 16.4.2 Activity + 16.4.3 View + 16.4.6 Concur.   │
│  服务器4: 16.4.4 System + 16.4.7 Storage + 16.4.8 Network  │
│  服务器5: 16.6 Test Agent (需要仿真器/DevEco)               │
│  服务器6: 16.4.1 JIT + 16.4.5 JNI + 16.4.9 ThirdParty     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 10.2 四个人类的具体分工

#### 产品专家 (P) — 每周二、四在线

```yaml
role: "质量与体验的最终裁判"
async_interface: "proposals/ + e2e/comparison-report/"
tasks:
  周二:
    - 审批积累的 NMP 提案 (修改 status 字段即可)
    - 审阅 16.6 的体验对比报告，对 MINOR_DIFF 做 accept/reject 判定
    - 更新案例优先级 (如果业务需求变化)
  周四:
    - 审阅本周通过的案例，确认"无感运行"标准
    - 对 BLOCKED 案例做产品层面判断: 是否可以降级处理
    - 下周优先级调整

interaction_protocol:
  # P 不需要实时在线，所有交互通过文件
  input_from_agents: "proposals/NMP-*.yaml, e2e/comparison-report-*.yaml"
  output_to_agents: "修改 status 字段, 写 reviewer_notes"
  # Agent 产出堆积在文件夹，P 上线时批量处理
  no_blocking: true  # Agent 不等 P，跳过需审批的案例继续跑其他的
```

#### 架构师 (A) — 全职

```yaml
role: "技术决策者，Agent 做不了的设计判断由 A 兜底"
async_interface: "queue/escalations/ + contract/"
tasks:
  daily:
    - 处理 ESCALATE_TO_DESIGN 中 16.3 也解决不了的问题
    - 审核跨模块 contract 定义 (16.4.x 之间的接口)
    - 复杂案例的 Bridge 架构方向指引
  weekly:
    - 审阅 Bridge 代码累积趋势，判断是否需要重构
    - 评估 Agent 的设计决策质量，调整 16.3 的 CLAUDE.md 指令
    - 与 P 对齐下周重点

interaction_protocol:
  # A 是唯一可能需要"较快响应"的人，但仍然异步
  input_from_agents: "queue/escalations/arch-*.yaml"
  output_to_agents: "修改 escalation 文件 + 写设计指引文档"
  sla: "4 小时内响应 ESCALATE（工作时间内）"
  # 如果 A 不在线，流水线跳过该案例，不阻塞
```

#### 开发专家 D1 — 全职

```yaml
role: "Bridge 实现专家 + BLOCKED 问题消解"
focus_area: "16.4.2 Activity, 16.4.3 View, 16.4.6 Concurrency"
async_interface: "queue/blocked/ + 16.4.x/escalations/"
tasks:
  daily:
    - 处理自己负责的 Bridge 模块中 Agent 解决不了的 BLOCKED 问题
    - 审阅 Agent 的 Bridge 代码质量 (抽查)
    - 为复杂 API 编写 Bridge 实现思路 (Agent 参考执行)
  on_blocked:
    - 分析 BLOCKED 案例的 error_history
    - 判断: Agent 的实现方向是否正确? 还是需要换思路?
    - 写入指导文件 → Agent 下一轮参考

interaction_protocol:
  input_from_agents: "queue/blocked/d1-*.yaml"
  output_to_agents: "16.4.x/guidance/human-hint-case-NNN.md"
  # D1 的指导以"提示文件"形式放入模块目录
  # Agent 下次运行时读取提示文件，按指导修改
```

#### 开发专家 D2 — 全职

```yaml
role: "系统/存储/网络 Bridge 专家 + 工具链维护"
focus_area: "16.4.4 System, 16.4.7 Storage, 16.4.8 Network"
async_interface: "queue/blocked/ + 16.4.x/escalations/"
tasks:
  daily:
    - 与 D1 相同，但负责不同模块
    - 维护编译工具链、仿真器环境
    - 维护 16.6 Test Agent 的测试基础设施
  infrastructure:
    - DevEco Studio 环境更新
    - Android 仿真器维护
    - CI/CD 流水线维护 (如果有)

interaction_protocol:
  # 同 D1
  input_from_agents: "queue/blocked/d2-*.yaml"
  output_to_agents: "16.4.x/guidance/human-hint-case-NNN.md"
```

### 10.3 最小化人机交互瓶颈

**核心原则: Agent 永远不等人。**

```
问题: 人不在线时 Agent 怎么办?
答案: 跳过需要人的任务，继续做其他任务。

具体策略:
┌─────────────────────────────────────────────────────────┐
│ 场景                    │ Agent 行为                      │
├─────────────────────────────────────────────────────────┤
│ NMP 待审批              │ 跳过此案例，做下一个不依赖的案例 │
│ ESCALATE 到架构师       │ 跳过此案例，做下一个              │
│ BLOCKED 需人工          │ 放入 blocked 队列，做下一个       │
│ 体验对比需 P 判定       │ 标记 CONDITIONAL_PASS，继续       │
│ 人写了 guidance 文件    │ 下一轮自动读取并应用              │
└─────────────────────────────────────────────────────────┘

结果: 23 个案例中，即使 5 个被人工阻塞，
      Agent 仍在并行处理其余 18 个。
      人上线后批量处理积压 → Agent 立即恢复被阻塞的案例。
```

### 10.4 人类的交互全部通过文件

**没有群聊、没有会议、没有即时消息依赖。**

```yaml
# 人 → Agent: 写文件
- "proposals/NMP-001.yaml" 中改 status → Agent 自动检测到 APPROVED
- "16.4.3/guidance/human-hint-case-121.md" → Agent 下次运行时读取
- "e2e/comparison-report-120.yaml" 中加 reviewer_verdict → 16.6 读取

# Agent → 人: 写文件 + 汇总邮件
- 每日 18:00 自动生成 daily-digest.md:
    "今日通过 3 案例，新增 2 BLOCKED，1 NMP 待审批"
- 人上线时只看 digest + 处理积压文件

# 人 → 人: 异步文档
- A 的架构决策写入 Architecture/ 目录，D1/D2 自行阅读
- P 的优先级决策写入 state/priorities.yaml
- 每周五 30 分钟同步会 (唯一的同步交互)
```

### 10.5 服务器部署与 Agent 分配

```yaml
servers:
  server-1:  # 调度节点 (轻量)
    agents: ["16.2-Orchestrator"]
    role: "状态管理、任务调度、错误归因"
    spec: "2C4G 足够"

  server-2:  # 分析节点
    agents: ["16.1-Case", "16.3-R&D"]
    role: "源码分析、适配设计"
    spec: "4C8G (需要大量代码阅读)"

  server-3:  # Bridge 集群 A (UI + 生命周期)
    agents: ["16.4.2-Activity", "16.4.3-View", "16.4.6-Concurrency"]
    role: "核心 Bridge 实现"
    spec: "8C16G (编译密集)"
    isolation: "每个 Agent 独立工作目录，通过 git worktree 隔离"

  server-4:  # Bridge 集群 B (系统 + 存储 + 网络)
    agents: ["16.4.4-System", "16.4.7-Storage", "16.4.8-Network"]
    role: "系统级 Bridge 实现"
    spec: "8C16G"

  server-5:  # 测试节点
    agents: ["16.6-Test"]
    role: "E2E 验证、体验对比"
    spec: "8C16G + GPU (仿真器需要)"
    requires: "Android Emulator + HarmonyOS Emulator/DevEco"

  server-6:  # 辅助 Bridge
    agents: ["16.4.1-JIT", "16.4.5-JNI", "16.4.9-ThirdParty"]
    role: "低频模块，按需启动"
    spec: "4C8G"
```

---

## 11. Skill 模块索引

以下 slash command 在 `.claude/commands/` 中实现:

| Skill | 用途 | 流程位置 |
|-------|------|---------|
| `/wf-pick-case` | 从 16.1 案例队列中选取下一个（考虑依赖和阻塞） | Step 1 |
| `/wf-analyze-case 120` | 分析案例 Android API 清单 | Step 2 |
| `/wf-design-adapter 120` | 16.3 适配设计决策 | Step 3 |
| `/wf-dispatch 120` | 按设计派发给 Bridge Agents | Step 4 |
| `/wf-check-deliverable 120` | 检查各 Agent 交付物完整性 | 每步之间 |
| `/wf-test-compare 120` | 16.6 Android vs HarmonyOS 体验对比 + 截屏 | Step 5→6 |
| `/wf-e2e-check 120` | E2E 验证 + 错误归因 | Step 6 |
| `/wf-triage 120` | 错误模式分析，判断 CONTINUE/ESCALATE | Step 6b |
| `/wf-nmp-review [id]` | 列出/查看待审批的新模块提案 | Step 3b |
| `/wf-case-status [120]` | 查看案例状态仪表板（4 个视图） | 任意 |
| `/wf-run-case 120` | 串联完整 E2E 流程 | Step 1→7 |

---

## 12. 关键设计决策

### Q: 为什么不是一个大 Agent 做所有事？

**分离关注点**。每个 16.4.x Agent 只需理解自己领域的 Android API 和对应的 HarmonyOS 实现。当出错时，错误范围明确，修复不会影响其他模块。

### Q: 为什么用文件系统而不是 API 通信？

**简单可观测**。JSON 文件可以直接用编辑器查看、手动修改、git 追踪。在 Agent 是 Claude Code session 的场景下，文件系统是最自然的接口。

### Q: Bridge 代码累积效应？

每通过一个案例，对应 Bridge Agent 的代码就增长。案例 125-Intent 通过后，16.4.2 的 Activity Bridge 就有了 Intent 支持。后续案例 132-Service、133-BroadcastReceiver 都基于已有的 16.4.2 代码继续扩展，**不会重写**。

### Q: 5 次重试还过不了怎么办？

标记 BLOCKED，记录详细错误日志，跳到下一个案例。BLOCKED 案例单独建 issue 由人工介入判断是 Bridge 架构问题还是需求理解偏差。

---

## 附录: 案例目录结构约定

```
16.1.120-SharedPreferences/
├── src/                        # Android 源码 (只读，由 16.1 Agent 分析)
│   ├── MainActivity.java
│   └── activity_main.xml
├── apk/                        # Android APK (参考用)
│   └── BUILD-INSTRUCTIONS.md
├── harmony/                    # HarmonyOS 目标代码 (由 Bridge Agents 生产)
│   └── Index.ets
├── analysis/                   # 16.1 Agent 产出
│   └── api-manifest.yaml
├── mapping/                    # 16.3 Agent 产出
│   └── api-mapping.yaml
└── e2e/                        # E2E 验证
    ├── test-spec.yaml
    └── results/
        ├── attempt-1.log
        └── attempt-2.log       # PASS
```
