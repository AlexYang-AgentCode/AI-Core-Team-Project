## Test Compare — Android vs HarmonyOS 体验对比 (16.6 Test Agent)

对案例 $ARGUMENTS 执行**真实运行时对比**: 启动仿真器/真机，截屏，录制行为，产出对比报告。

### 前置条件

- Android 环境: Android Emulator 或真机可用
- HarmonyOS 环境: DevEco Studio Previewer / HarmonyOS Emulator / 真机可用
- 案例已有编译产出 (APK + HAP)

### 执行步骤

#### Part 0: 环境就绪检查

检查以下工具是否可用，**缺一不可**:

```bash
# Android 侧
adb devices                    # 检查设备连接
adb shell screencap --help     # 截屏能力

# HarmonyOS 侧
hdc list targets               # 检查鸿蒙设备/仿真器
# 或 DevEco Previewer 是否可用
```

如果环境不就绪:
→ 输出 "16.6 环境未就绪: [缺失项列表]"
→ 不产出对比报告，状态标记为 ENV_NOT_READY
→ Orchestrator 不应将此视为 PASS

#### Part 1: 单元测试检查

1. 检查本案例涉及的每个 Bridge Agent 是否提交了测试报告:
   - 读取 `16.4.x/06-Test/` 目录
   - 查找与本案例相关的测试文件
2. 如果缺少测试:
   - 列出缺失清单
   - 输出: "以下 Bridge Agent 需补充单元测试: [列表]"
   - 可以继续 Part 2，但在报告中标记 `unit_tests_incomplete: true`

#### Part 2: Android 侧运行 + 截屏

对每个验收场景:

1. 安装 APK 到 Android 设备
2. 启动应用
3. 按 acceptance_criteria 逐步操作
4. 每个关键状态截屏，保存到:
   ```
   16.1.$ARGUMENTS-*/e2e/screenshots/android/
   ├── 01-launch.png
   ├── 02-after-click-timezone.png
   └── ...
   ```
5. 记录实际行为文本

#### Part 3: HarmonyOS 侧运行 + 截屏

同样流程:

1. 安装 HAP 到 HarmonyOS 设备 / 启动 Previewer
2. 逐步操作
3. 每个关键状态截屏，保存到:
   ```
   16.1.$ARGUMENTS-*/e2e/screenshots/harmony/
   ├── 01-launch.png
   ├── 02-after-click-timezone.png
   └── ...
   ```
4. 记录实际行为文本

#### Part 4: 产出对比报告

写入 `16.1.$ARGUMENTS-*/e2e/comparison-report.yaml`:

```yaml
comparison_report:
  case_id: "16.1.$ARGUMENTS"
  test_date: "当前日期"
  test_method: "EMULATOR | REAL_DEVICE | PREVIEWER"

  # 环境信息
  environment:
    android:
      device: "Pixel 6 API 33 Emulator"
      os_version: "Android 13"
    harmony:
      device: "DevEco Previewer / HarmonyOS Emulator"
      os_version: "HarmonyOS 5.0"

  # 单元测试状态
  unit_test_status:
    complete: true/false
    details:
      - agent: "16.4.x"
        has_tests: true/false
        coverage: "xx%"

  # 逐场景对比 — 每个场景必须附截屏路径
  scenarios:
    - name: "场景名称"
      android:
        screenshot: "e2e/screenshots/android/01-launch.png"   # 必填
        behavior: "Android 端实际表现"
      harmony:
        screenshot: "e2e/screenshots/harmony/01-launch.png"   # 必填
        behavior: "HarmonyOS 端实际表现"
      diff: "MATCH | MINOR_DIFF | MAJOR_DIFF | BROKEN"
      detail: "差异说明（如有）"
      action: "归因到哪个 Agent（如需修复）"

  # 汇总
  summary:
    total: N
    match: N
    minor_diff: N
    major_diff: N
    broken: N
    screenshot_count:
      android: N
      harmony: N
    verdict: "PASS | CONDITIONAL_PASS | FAIL"
    blocking_issues: []
```

### 交付物完整性要求

16.6 的交付物**必须包含以下全部内容**，否则 Orchestrator 应拒绝接受:

```
e2e/
├── comparison-report.yaml          # 对比报告 (必须)
├── screenshots/                    # 截屏目录 (必须)
│   ├── android/                    # Android 截屏 (必须, ≥1 张)
│   │   ├── 01-launch.png
│   │   └── ...
│   └── harmony/                    # HarmonyOS 截屏 (必须, ≥1 张)
│       ├── 01-launch.png
│       └── ...
└── attempt-N.yaml                  # 尝试记录 (必须)
```

缺少截屏 = 测试未完成 = 不能标记 PASS。

### 注意

- 16.6 只做验证和对比，不修改任何业务代码
- MINOR_DIFF 的最终 accept/reject 由产品专家 (P) 判定
- 如果无法运行仿真器（如当前服务器无 GPU），
  明确输出 "ENV_NOT_READY"，不要伪造对比报告
