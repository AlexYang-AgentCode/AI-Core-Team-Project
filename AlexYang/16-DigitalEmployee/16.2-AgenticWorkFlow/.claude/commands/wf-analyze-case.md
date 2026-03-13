## Analyze Android Case

分析案例 $ARGUMENTS 的 Android 源码，产出 API 调用清单。

### 执行步骤

1. 读取案例目录 `E:/10.Project/16.1-AndroidToHarmonyOSDemo/16.1.$ARGUMENTS-*/src/` 下所有 Java/XML 文件
2. 提取所有 Android API 调用，按以下格式输出:

```yaml
case_id: "16.1.$ARGUMENTS"
android_apis_used:
  - api: "完整类名"
    usage: "使用了哪些方法"
    bridge_owner: "16.4.x"  # 预判归属模块
```

3. 分析 APK 的用户可见行为，产出验收标准 (acceptance_criteria)
4. 将报告写入案例目录下 `analysis/api-manifest.yaml`

### 归属规则

- Activity/Intent/Fragment/Service/BroadcastReceiver → 16.4.2
- View/Widget/Layout/Toast/Dialog/Animation → 16.4.3
- Permission/Notification/Sensor/Location/Camera/Bluetooth/R class → 16.4.4
- JNI/Native → 16.4.5
- Handler/Looper/AsyncTask/Thread → 16.4.6
- SharedPreferences/File/SQLite/ContentProvider → 16.4.7
- Http/WebView/Network → 16.4.8
- 第三方库 (Retrofit/Glide/Room) → 16.4.9

### 注意

- 只读不写源码
- 包括 XML layout 中引用的 widget 类型
- 如果案例依赖其他案例的 API（如 Intent 依赖 Activity），标注 dependency
