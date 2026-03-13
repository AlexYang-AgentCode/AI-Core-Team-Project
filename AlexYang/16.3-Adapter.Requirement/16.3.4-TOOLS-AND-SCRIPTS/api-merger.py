#!/usr/bin/env python3
"""
api-merger.py — Merge hand-annotated CSV with auto-scraped CSV,
and auto-fill empty fields using pattern-based heuristics.

1. Use auto-scraped (6270 entries) as base
2. Merge hand-annotated (469 entries) mappings by (package, class, method)
3. Auto-fill description_cn, harmony_mapping, mapping_difficulty for the rest
"""

import csv
import os
import re
import sys

# ============================================================
# HarmonyOS class-level mapping knowledge base
# Android class → (HarmonyOS equivalent, base difficulty)
# ============================================================
CLASS_MAPPINGS = {
    # M01 - android.app / android.os
    "Activity": ("UIAbility", 3),
    "Fragment": ("NavDestination (Navigation)", 4),
    "Service": ("ServiceExtensionAbility", 3),
    "Application": ("AbilityStage", 2),
    "Dialog": ("CustomDialog", 2),
    "AlertDialog": ("AlertDialog", 2),
    "Notification": ("notificationManager.publish()", 3),
    "NotificationManager": ("notificationManager", 2),
    "NotificationChannel": ("NotificationSlot", 2),
    "PendingIntent": ("Want + WantAgent", 3),
    "AlarmManager": ("reminderAgentManager", 3),
    "DownloadManager": ("request.downloadFile()", 3),
    "Handler": ("TaskDispatcher / EventHandler", 3),
    "Looper": ("EventRunner", 3),
    "Message": ("EventData", 2),
    "Bundle": ("Record / Want.parameters", 2),
    "Parcel": ("MessageSequence", 3),
    "Parcelable": ("Sequenceable", 3),
    "Binder": ("IRemoteObject", 4),
    "IBinder": ("IRemoteObject", 4),
    "Process": ("process", 2),
    "SystemClock": ("systemDateTime", 1),
    "PowerManager": ("power", 2),
    "Vibrator": ("vibrator", 2),
    "Environment": ("Context.filesDir / cacheDir", 2),
    "Build": ("deviceInfo", 1),
    "AsyncTask": ("taskpool.Task", 3),
    "HandlerThread": ("TaskDispatcher", 3),

    # M02 - android.content
    "Intent": ("Want", 3),
    "Context": ("Context (ohos)", 2),
    "ContentProvider": ("DataShareExtensionAbility", 4),
    "ContentResolver": ("DataShareHelper", 3),
    "ContentValues": ("ValuesBucket", 2),
    "BroadcastReceiver": ("CommonEventSubscriber", 3),
    "SharedPreferences": ("preferences (data_preferences)", 2),
    "ClipboardManager": ("pasteboard", 2),
    "ClipData": ("PasteData", 2),
    "PackageManager": ("bundleManager", 2),
    "PackageInfo": ("BundleInfo", 2),
    "ComponentName": ("Want.bundleName + abilityName", 2),
    "IntentFilter": ("CommonEventSubscribeInfo", 3),
    "UriMatcher": ("自定义匹配逻辑", 3),

    # M03 - android.view / android.graphics
    "View": ("Component", 3),
    "ViewGroup": ("Container (Column/Row/Stack)", 3),
    "SurfaceView": ("XComponent", 4),
    "TextureView": ("XComponent", 4),
    "WebView": ("Web", 3),
    "LayoutInflater": ("声明式UI无需inflate", 5),
    "MotionEvent": ("TouchEvent", 2),
    "KeyEvent": ("KeyEvent", 1),
    "GestureDetector": ("GestureEvent", 2),
    "Canvas": ("Canvas (drawing)", 2),
    "Paint": ("Paint (drawing)", 2),
    "Bitmap": ("image.PixelMap", 3),
    "BitmapFactory": ("image.createPixelMap()", 3),
    "Color": ("Color (ArkUI)", 1),
    "Path": ("Path (drawing)", 2),
    "Matrix": ("Matrix4", 2),
    "Rect": ("Rect", 1),
    "RectF": ("Rect (float)", 1),
    "Point": ("Point", 1),
    "PointF": ("Point (float)", 1),
    "Drawable": ("Resource / PixelMap", 3),
    "ColorDrawable": ("Color.xxx", 1),
    "BitmapDrawable": ("PixelMap", 2),
    "TypedArray": ("ResourceManager", 2),
    "Window": ("Window (ohos)", 2),
    "WindowManager": ("window.getLastWindow()", 2),
    "Display": ("display.getDefaultDisplaySync()", 2),
    "InputMethodManager": ("inputMethodController", 2),
    "ViewConfiguration": ("组件属性配置", 2),
    "Gravity": ("Alignment", 1),
    "ViewTreeObserver": ("组件生命周期回调", 3),

    # M04 - android.widget
    "TextView": ("Text", 1),
    "EditText": ("TextInput", 2),
    "Button": ("Button", 1),
    "ImageView": ("Image", 1),
    "ImageButton": ("Button + Image", 2),
    "CheckBox": ("Checkbox", 1),
    "RadioButton": ("Radio", 1),
    "RadioGroup": ("Row + Radio", 2),
    "Switch": ("Toggle", 1),
    "ToggleButton": ("Toggle", 1),
    "ProgressBar": ("Progress", 1),
    "SeekBar": ("Slider", 1),
    "Spinner": ("Select", 2),
    "ListView": ("List", 2),
    "GridView": ("Grid", 2),
    "RecyclerView": ("List / LazyForEach", 3),
    "ScrollView": ("Scroll", 1),
    "HorizontalScrollView": ("Scroll(.horizontal)", 1),
    "LinearLayout": ("Column / Row", 1),
    "RelativeLayout": ("RelativeContainer", 2),
    "FrameLayout": ("Stack", 1),
    "ConstraintLayout": ("RelativeContainer", 2),
    "TableLayout": ("Grid", 2),
    "TabLayout": ("Tabs", 2),
    "ViewPager": ("Swiper", 2),
    "Toolbar": ("Navigation + Toolbar", 2),
    "ActionBar": ("Navigation", 2),
    "SearchView": ("Search", 2),
    "Toast": ("promptAction.showToast()", 1),
    "PopupWindow": ("Popup", 2),
    "DatePicker": ("DatePicker", 1),
    "TimePicker": ("TimePicker", 1),
    "CalendarView": ("CalendarPicker", 2),
    "NumberPicker": ("Counter / TextPicker", 2),
    "RatingBar": ("Rating", 1),
    "TextClock": ("自定义Text+定时器", 3),
    "Chronometer": ("自定义Text+定时器", 3),
    "VideoView": ("Video", 2),
    "MediaController": ("Video控制组件", 2),
    "AutoCompleteTextView": ("TextInput + 自定义建议列表", 3),
    "MultiAutoCompleteTextView": ("TextInput + 自定义建议列表", 3),
    "AdapterView": ("LazyForEach + DataSource", 3),
    "ArrayAdapter": ("LazyForEach + DataSource", 3),
    "BaseAdapter": ("IDataSource", 3),
    "SimpleCursorAdapter": ("IDataSource + RdbStore", 4),

    # M05 - android.net
    "ConnectivityManager": ("connection.getDefaultNet()", 2),
    "NetworkInfo": ("connection.NetHandle", 2),
    "NetworkCapabilities": ("connection.NetCapabilities", 2),
    "NetworkRequest": ("connection.NetSpecifier", 2),
    "Uri": ("uri (ohos)", 1),
    "URL": ("URL (标准)", 1),
    "HttpURLConnection": ("http.createHttp()", 2),
    "WifiManager": ("wifiManager", 2),

    # M06 - android.media
    "MediaPlayer": ("media.AVPlayer", 2),
    "MediaRecorder": ("media.AVRecorder", 3),
    "AudioManager": ("audio.AudioManager", 2),
    "AudioTrack": ("audio.AudioRenderer", 3),
    "AudioRecord": ("audio.AudioCapturer", 3),
    "SoundPool": ("audio.SoundPool (自定义)", 3),
    "Ringtone": ("audio.TonePlayer", 2),
    "RingtoneManager": ("audio资源管理", 3),
    "MediaMetadataRetriever": ("media.AVMetadataExtractor", 2),
    "ThumbnailUtils": ("media.AVImageGenerator", 2),
    "ExifInterface": ("image.ImageSource", 2),
    "CameraManager": ("camera.getCameraManager()", 3),
    "CameraDevice": ("camera.CameraInput", 3),
    "CaptureRequest": ("camera.PhotoOutput", 3),

    # M07 - android.database
    "SQLiteDatabase": ("relationalStore.RdbStore", 3),
    "SQLiteOpenHelper": ("relationalStore.RdbStore (封装)", 3),
    "Cursor": ("relationalStore.ResultSet", 2),
    "ContentProvider": ("DataShareExtensionAbility", 4),
    "ContentUris": ("Uri工具方法", 1),
    "DatabaseUtils": ("RdbStore工具方法", 2),

    # M08 - android.location / hardware
    "LocationManager": ("geoLocationManager", 2),
    "Location": ("geoLocationManager.Location", 1),
    "Geocoder": ("geoLocationManager.getAddressesFromLocation()", 2),
    "LocationListener": ("geoLocationManager.on('locationChange')", 2),
    "SensorManager": ("sensor.on(sensor.SensorId.XXX)", 2),
    "Sensor": ("sensor.SensorId", 1),
    "SensorEvent": ("sensor.Response", 1),
    "SensorEventListener": ("sensor.on() 回调", 2),
    "Camera": ("camera (已废弃→camera2)", 4),

    # M09 - android.bluetooth / nfc
    "BluetoothAdapter": ("bluetoothManager.access", 2),
    "BluetoothDevice": ("bluetoothManager.BLEDevice", 2),
    "BluetoothGatt": ("bluetoothManager.GattClient", 3),
    "BluetoothSocket": ("bluetoothManager.SPPSocket", 3),
    "BluetoothManager": ("bluetoothManager", 2),
    "NfcAdapter": ("nfcController", 2),
    "NdefMessage": ("nfctech.NdefMessage", 2),
    "NdefRecord": ("nfctech.NdefRecord", 2),
    "Tag": ("nfctech.TagInfo", 2),

    # M10 - android.telephony
    "TelephonyManager": ("telephony.call / sim", 2),
    "SmsManager": ("sms.sendShortMessage()", 2),
    "PhoneStateListener": ("telephony.observer.on()", 2),
    "SubscriptionManager": ("sim.getDefaultVoiceSlotId()", 2),
    "CellInfo": ("telephony.radio 信号信息", 3),

    # M11 - android.security
    "KeyStore": ("huks (HUKS密钥管理)", 3),
    "KeyGenerator": ("huks.generateKeyItem()", 3),
    "Cipher": ("huks 加解密", 3),
    "KeyPairGenerator": ("huks.generateKeyItem()", 3),
    "DevicePolicyManager": ("enterpriseDeviceManager (MDM)", 4),
    "FingerprintManager": ("userAuth.getUserAuthInstance()", 3),
    "BiometricPrompt": ("userAuth.getUserAuthInstance()", 3),

    # M12 - android.animation / util
    "ValueAnimator": ("animateTo() / animation", 2),
    "ObjectAnimator": ("animateTo() + 属性动画", 2),
    "AnimatorSet": ("animateTo() 组合", 2),
    "PropertyValuesHolder": ("AnimateParam", 2),
    "Animator": ("Transition / AnimateParam", 2),
    "LayoutTransition": ("transition 布局动画", 3),
    "Log": ("hilog", 1),
    "SparseArray": ("Map / HashMap", 1),
    "ArrayMap": ("Map / HashMap", 1),
    "LruCache": ("自定义LRU或Map", 2),
    "Pair": ("[T1, T2] 元组", 1),
    "Base64": ("util.Base64Helper", 1),
    "Patterns": ("正则表达式", 1),
    "TypedValue": ("资源值转换", 2),
    "DisplayMetrics": ("display.getDefaultDisplaySync()", 1),

    # M13 - java.*
    "String": ("string (ArkTS)", 1),
    "Object": ("Object (ArkTS)", 1),
    "Integer": ("number", 1),
    "Long": ("number / bigint", 1),
    "Float": ("number", 1),
    "Double": ("number", 1),
    "Boolean": ("boolean", 1),
    "Character": ("string (char)", 1),
    "Math": ("Math", 1),
    "System": ("系统调用", 1),
    "Thread": ("taskpool / worker", 2),
    "Runnable": ("() => void 函数", 1),
    "Callable": ("() => T 函数", 1),
    "ArrayList": ("Array<T>", 1),
    "HashMap": ("Map<K,V>", 1),
    "HashSet": ("Set<T>", 1),
    "LinkedList": ("collections.List", 1),
    "TreeMap": ("collections.TreeMap (自定义排序Map)", 2),
    "Collections": ("Array/Map方法", 1),
    "Arrays": ("Array方法", 1),
    "Iterator": ("迭代器协议", 1),
    "Comparator": ("(a,b)=>number 比较函数", 1),
    "Date": ("Date", 1),
    "Calendar": ("Date + Intl.DateTimeFormat", 2),
    "SimpleDateFormat": ("Intl.DateTimeFormat", 2),
    "TimeZone": ("Intl.Locale / 时区", 1),
    "Locale": ("Intl.Locale", 1),
    "File": ("fs.File (fileio)", 2),
    "FileInputStream": ("fs.openSync() + fs.readSync()", 2),
    "FileOutputStream": ("fs.openSync() + fs.writeSync()", 2),
    "BufferedReader": ("fs逐行读取", 2),
    "BufferedWriter": ("fs写入", 2),
    "InputStream": ("ArrayBuffer / Stream", 2),
    "OutputStream": ("ArrayBuffer / Stream", 2),
    "ByteArrayOutputStream": ("ArrayBuffer", 1),
    "ByteArrayInputStream": ("ArrayBuffer", 1),
    "Socket": ("socket.TCPSocket", 2),
    "ServerSocket": ("socket.TCPSocketServer", 2),
    "DatagramSocket": ("socket.UDPSocket", 2),
    "URL": ("URL (标准)", 1),
    "HttpURLConnection": ("http.createHttp()", 2),
    "URLEncoder": ("encodeURIComponent()", 1),
    "URLDecoder": ("decodeURIComponent()", 1),
    "UUID": ("util.generateRandomUUID()", 1),
    "Random": ("Math.random()", 1),
    "Pattern": ("RegExp", 1),
    "Matcher": ("RegExp.exec()", 1),
    "StringBuilder": ("string拼接", 1),
    "StringBuffer": ("string拼接", 1),
    "Charset": ("util.TextEncoder/TextDecoder", 1),
    "BigInteger": ("bigint", 1),
    "BigDecimal": ("自定义精度计算", 3),
    "AtomicInteger": ("Atomics (SharedArrayBuffer)", 2),
    "AtomicLong": ("Atomics (SharedArrayBuffer)", 2),
    "ReentrantLock": ("taskpool 无需显式锁", 3),
    "Semaphore": ("自定义信号量", 3),
    "CountDownLatch": ("Promise.all() 模式", 2),
    "ExecutorService": ("taskpool", 2),
    "ThreadPoolExecutor": ("taskpool", 2),
    "Future": ("Promise<T>", 1),
    "CompletableFuture": ("Promise<T>", 1),
    "ConcurrentHashMap": ("collections.HashMap (线程安全)", 2),
    "CopyOnWriteArrayList": ("collections.List (线程安全)", 2),
    "BlockingQueue": ("taskpool通信机制", 3),
    "Timer": ("setInterval / setTimeout", 1),
    "TimerTask": ("() => void + clearInterval", 1),
    "WeakReference": ("WeakRef<T>", 1),
    "SoftReference": ("WeakRef<T> (无精确等价)", 2),
    "Proxy": ("Proxy (ES6)", 1),
    "InvocationHandler": ("Proxy handler", 1),
    "Annotation": ("装饰器 @Decorator", 2),
    "Class": ("typeof / instanceof", 2),
    "Constructor": ("Reflect.construct()", 2),
    "Method": ("Function", 1),
    "Field": ("属性访问", 1),
    "Throwable": ("Error", 1),
    "Exception": ("Error", 1),
    "RuntimeException": ("Error", 1),
    "IOException": ("Error (IO)", 1),
    "IllegalArgumentException": ("Error", 1),
    "NullPointerException": ("TypeError (null/undefined)", 1),
    "ClassNotFoundException": ("Error (动态加载)", 3),
    "NoSuchMethodException": ("Error (反射)", 3),
}

# Method-level common description templates
METHOD_DESC_CN = {
    "<init>": "构造函数",
    "toString": "转为字符串",
    "equals": "判断相等",
    "hashCode": "获取哈希值",
    "clone": "克隆对象",
    "finalize": "析构/释放资源",
    "compareTo": "比较大小",
    "iterator": "获取迭代器",
    "close": "关闭/释放资源",
    "get": "获取值",
    "set": "设置值",
    "put": "添加/设置",
    "remove": "移除",
    "clear": "清空",
    "size": "获取大小/数量",
    "isEmpty": "判断是否为空",
    "contains": "判断是否包含",
    "containsKey": "判断是否包含键",
    "containsValue": "判断是否包含值",
    "add": "添加元素",
    "addAll": "批量添加",
    "indexOf": "查找索引",
    "toArray": "转为数组",
    "entrySet": "获取键值对集合",
    "keySet": "获取键集合",
    "values": "获取值集合",
    "sort": "排序",
    "notify": "唤醒等待线程",
    "notifyAll": "唤醒所有等待线程",
    "wait": "等待",
    "run": "执行/运行",
    "start": "启动",
    "stop": "停止",
    "pause": "暂停",
    "resume": "恢复",
    "reset": "重置",
    "release": "释放资源",
    "cancel": "取消",
    "execute": "执行",
    "submit": "提交",
    "shutdown": "关闭",
    "interrupt": "中断",
    "join": "等待完成",
    "sleep": "休眠",
    "yield": "让出时间片",
    "read": "读取",
    "write": "写入",
    "flush": "刷新缓冲区",
    "open": "打开",
    "delete": "删除",
    "exists": "判断是否存在",
    "create": "创建",
    "update": "更新",
    "insert": "插入",
    "query": "查询",
    "bind": "绑定",
    "unbind": "解绑",
    "register": "注册",
    "unregister": "注销",
    "subscribe": "订阅",
    "unsubscribe": "取消订阅",
    "listen": "监听",
    "notify": "通知",
    "dispatch": "分发",
    "handle": "处理",
    "process": "处理",
    "parse": "解析",
    "format": "格式化",
    "encode": "编码",
    "decode": "解码",
    "encrypt": "加密",
    "decrypt": "解密",
    "sign": "签名",
    "verify": "验证",
    "connect": "连接",
    "disconnect": "断开连接",
    "send": "发送",
    "receive": "接收",
    "accept": "接受连接",
    "getInputStream": "获取输入流",
    "getOutputStream": "获取输出流",
    "draw": "绘制",
    "measure": "测量",
    "layout": "布局",
    "invalidate": "触发重绘",
    "requestLayout": "请求重新布局",
    "onDraw": "绘制回调",
    "onMeasure": "测量回调",
    "onLayout": "布局回调",
    "onClick": "点击回调",
    "onTouch": "触摸回调",
    "onCreate": "创建回调",
    "onStart": "启动回调",
    "onResume": "恢复回调",
    "onPause": "暂停回调",
    "onStop": "停止回调",
    "onDestroy": "销毁回调",
    "onSaveInstanceState": "保存状态",
    "onRestoreInstanceState": "恢复状态",
    "finish": "结束/关闭",
    "startActivity": "启动Activity",
    "setContentView": "设置内容视图",
    "findViewById": "查找视图",
    "getText": "获取文本",
    "setText": "设置文本",
    "getWidth": "获取宽度",
    "getHeight": "获取高度",
    "setVisibility": "设置可见性",
    "getVisibility": "获取可见性",
    "setEnabled": "设置启用状态",
    "isEnabled": "判断是否启用",
    "setOnClickListener": "设置点击监听",
    "setOnTouchListener": "设置触摸监听",
    "addView": "添加子视图",
    "removeView": "移除子视图",
    "removeAllViews": "移除所有子视图",
    "getChildAt": "获取子视图",
    "getChildCount": "获取子视图数量",
    "setAdapter": "设置适配器",
    "getAdapter": "获取适配器",
    "notifyDataSetChanged": "通知数据更新",
    "setLayoutManager": "设置布局管理器",
    "scrollToPosition": "滚动到位置",
    "setColor": "设置颜色",
    "setTextSize": "设置文字大小",
    "setTextColor": "设置文字颜色",
    "setBackground": "设置背景",
    "setImageResource": "设置图片资源",
    "setImageBitmap": "设置图片位图",
    "setPadding": "设置内边距",
    "setMargin": "设置外边距",
    "setGravity": "设置对齐方式",
    "setOrientation": "设置方向",
    "animate": "执行动画",
    "setDuration": "设置持续时间",
    "setInterpolator": "设置插值器",
}


def gen_description(class_name: str, method_name: str, api_type: str, package: str) -> str:
    """Generate Chinese description from class/method name."""
    # Direct match
    if method_name in METHOD_DESC_CN:
        if api_type == "ctor":
            return f"{class_name} {METHOD_DESC_CN[method_name]}"
        return METHOD_DESC_CN[method_name]

    # Getter/Setter patterns
    if method_name.startswith("get") and len(method_name) > 3:
        prop = method_name[3:]
        return f"获取{prop}"
    if method_name.startswith("set") and len(method_name) > 3:
        prop = method_name[3:]
        return f"设置{prop}"
    if method_name.startswith("is") and len(method_name) > 2:
        prop = method_name[2:]
        return f"判断是否{prop}"
    if method_name.startswith("has") and len(method_name) > 3:
        prop = method_name[3:]
        return f"判断是否有{prop}"
    if method_name.startswith("on") and len(method_name) > 2:
        prop = method_name[2:]
        return f"{prop}回调"
    if method_name.startswith("create") and len(method_name) > 6:
        prop = method_name[6:]
        return f"创建{prop}"
    if method_name.startswith("remove") and len(method_name) > 6:
        prop = method_name[6:]
        return f"移除{prop}"
    if method_name.startswith("add") and len(method_name) > 3:
        prop = method_name[3:]
        return f"添加{prop}"
    if method_name.startswith("find") and len(method_name) > 4:
        prop = method_name[4:]
        return f"查找{prop}"
    if method_name.startswith("to") and len(method_name) > 2:
        prop = method_name[2:]
        return f"转换为{prop}"
    if method_name.startswith("from") and len(method_name) > 4:
        prop = method_name[4:]
        return f"从{prop}创建"

    # Field
    if api_type == "field":
        return f"{class_name}.{method_name} 常量/字段"

    # Constructor
    if api_type == "ctor":
        return f"{class_name} 构造函数"

    # Fallback
    return f"{class_name}.{method_name}()"


def gen_mapping(class_name: str, method_name: str, api_type: str, package: str) -> tuple:
    """Generate (harmony_mapping, difficulty) from known patterns."""
    # Check class-level mapping
    if class_name in CLASS_MAPPINGS:
        harmony_cls, base_diff = CLASS_MAPPINGS[class_name]

        if api_type == "ctor":
            return f"new {harmony_cls}() 或声明式创建", base_diff
        if api_type == "field":
            return f"{harmony_cls} 对应常量", max(1, base_diff - 1)

        # Method-level: adjust based on method complexity
        if method_name.startswith("get") or method_name.startswith("is"):
            return f"{harmony_cls} 对应属性读取", max(1, base_diff - 1)
        if method_name.startswith("set"):
            return f"{harmony_cls} 对应属性设置", max(1, base_diff - 1)
        if method_name.startswith("on"):
            return f"{harmony_cls} 对应事件回调", base_diff
        return f"{harmony_cls}.{method_name}() 对应方法", base_diff

    # Package-level heuristics
    if package.startswith("java.lang"):
        return "ArkTS 内置类型/方法", 1
    if package.startswith("java.util"):
        return "ArkTS 集合/工具类", 1
    if package.startswith("java.io"):
        return "fs (fileio) 文件操作", 2
    if package.startswith("java.net"):
        return "http/socket 网络操作", 2
    if package.startswith("java.nio"):
        return "ArrayBuffer / buffer", 2
    if package.startswith("java.text"):
        return "Intl 国际化API", 2
    if package.startswith("java.math"):
        return "number / bigint", 1
    if package.startswith("java.security"):
        return "huks 安全API", 3
    if package.startswith("java.crypto") or package.startswith("javax.crypto"):
        return "huks 加解密", 3
    if package.startswith("android.text"):
        return "ArkUI Text 属性", 2
    if package.startswith("android.transition"):
        return "transition 动画API", 2
    if package.startswith("android.print"):
        return "print 打印服务", 3
    if package.startswith("android.appwidget"):
        return "FormExtensionAbility 卡片", 3
    if package.startswith("android.accounts"):
        return "账户管理 (自定义)", 3
    if package.startswith("android.accessibilityservice"):
        return "accessibility 无障碍", 3
    if package.startswith("android.gesture"):
        return "GestureEvent 手势", 2
    if package.startswith("android.speech"):
        return "语音识别 (自定义)", 4
    if package.startswith("android.renderscript"):
        return "GPU计算 (无直接对应)", 5
    if package.startswith("android.drm"):
        return "DRM (无直接对应)", 5
    if package.startswith("android.icu"):
        return "Intl 国际化", 1
    if package.startswith("android.service"):
        return "系统服务扩展", 3

    # Default by module
    module_defaults = {
        "android.app": ("UIAbility/ServiceAbility 相关", 3),
        "android.os": ("系统功能 (ohos)", 2),
        "android.content": ("应用上下文/通信", 2),
        "android.view": ("ArkUI 组件", 3),
        "android.graphics": ("drawing/Canvas 绘制", 2),
        "android.widget": ("ArkUI 内置组件", 2),
        "android.net": ("网络连接管理", 2),
        "android.webkit": ("Web 组件", 3),
        "android.media": ("media 多媒体", 2),
        "android.hardware": ("设备硬件API", 3),
        "android.database": ("RdbStore 数据库", 3),
        "android.provider": ("DataShare 数据共享", 3),
        "android.location": ("geoLocationManager", 2),
        "android.bluetooth": ("bluetoothManager", 2),
        "android.nfc": ("nfcController", 2),
        "android.telephony": ("telephony 通信", 2),
        "android.security": ("huks 安全", 3),
        "android.animation": ("ArkUI 动画", 2),
        "android.util": ("工具类", 1),
    }
    for prefix, (mapping, diff) in module_defaults.items():
        if package.startswith(prefix):
            return mapping, diff

    return "待分析", 3


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.dirname(script_dir)

    hand_csv = os.path.join(base_dir, "133-API-MASTER-LIST.csv")
    auto_csv = os.path.join(base_dir, "133.1-RESEARCH-ANALYSIS", "133.10-ANDROID-SDK-ANALYSIS", "api-scraped-full.csv")
    output_csv = os.path.join(base_dir, "133-API-MASTER-LIST-MERGED.csv")

    # Parse args
    import argparse
    parser = argparse.ArgumentParser(description="Merge and fill API CSVs")
    parser.add_argument("--hand", default=hand_csv, help="Hand-annotated CSV")
    parser.add_argument("--auto", default=auto_csv, help="Auto-scraped CSV")
    parser.add_argument("--output", "-o", default=output_csv, help="Output merged CSV")
    args = parser.parse_args()

    # Read hand-annotated
    print(f"Reading hand-annotated: {args.hand}", file=sys.stderr)
    hand_rows = {}
    with open(args.hand, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            key = (row['package'], row['class_name'], row['method_name'])
            hand_rows[key] = row
    print(f"  {len(hand_rows)} hand-annotated entries", file=sys.stderr)

    # Read auto-scraped
    print(f"Reading auto-scraped: {args.auto}", file=sys.stderr)
    auto_rows = []
    with open(args.auto, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            auto_rows.append(row)
    print(f"  {len(auto_rows)} auto-scraped entries", file=sys.stderr)

    # Merge
    merged = []
    matched = 0
    filled = 0

    for row in auto_rows:
        key = (row['package'], row['class_name'], row['method_name'])

        if key in hand_rows:
            # Use hand-annotated data (preserve all fields)
            hand = hand_rows[key]
            for field in ['description_cn', 'harmony_mapping', 'mapping_difficulty',
                         'estimated_hours', 'notes']:
                if hand.get(field):
                    row[field] = hand[field]
            row['status'] = hand.get('status', 'annotated')
            matched += 1
            hand_rows.pop(key)  # Remove from hand to track unmatched
        else:
            # Auto-fill
            desc = gen_description(row['class_name'], row['method_name'],
                                  row['api_type'], row['package'])
            mapping, diff = gen_mapping(row['class_name'], row['method_name'],
                                       row['api_type'], row['package'])
            row['description_cn'] = desc
            row['harmony_mapping'] = mapping
            row['mapping_difficulty'] = str(diff)
            row['estimated_hours'] = ''  # Leave for future
            row['status'] = 'auto-filled'
            filled += 1

        merged.append(row)

    # Add remaining hand-annotated entries not in auto-scraped
    # (these are entries that exist in hand CSV but not in AOSP current.txt)
    extra = 0
    for key, hand in hand_rows.items():
        # Auto-fill any empty fields
        if not hand.get('description_cn'):
            hand['description_cn'] = gen_description(
                hand['class_name'], hand['method_name'],
                hand['api_type'], hand['package'])
        if not hand.get('harmony_mapping'):
            mapping, diff = gen_mapping(
                hand['class_name'], hand['method_name'],
                hand['api_type'], hand['package'])
            hand['harmony_mapping'] = mapping
            if not hand.get('mapping_difficulty'):
                hand['mapping_difficulty'] = str(diff)
        hand['status'] = hand.get('status', 'hand-only')
        merged.append(hand)
        extra += 1

    # Re-assign IDs
    # Sort by priority then module then package then class then method
    def sort_key(r):
        p_order = {'P0': 0, 'P1': 1, 'P2': 2, 'P3': 3, 'P4': 4}
        return (
            p_order.get(r.get('priority', 'P4'), 9),
            r.get('module_id', 'M99'),
            r.get('package', ''),
            r.get('class_name', ''),
            r.get('method_name', ''),
        )

    merged.sort(key=sort_key)

    # Reassign IDs
    counters = {}
    for row in merged:
        p = row.get('priority', 'P4')
        if p not in counters:
            counters[p] = 0
        counters[p] += 1
        row['api_id'] = f"{p}-{counters[p]:04d}"

    # Write output
    fieldnames = [
        "api_id", "module_id", "package", "class_name", "method_name",
        "api_type", "priority", "android_api_level", "description_cn",
        "harmony_mapping", "mapping_difficulty", "estimated_hours",
        "adapter_project", "status", "notes"
    ]

    with open(args.output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(merged)

    # Summary
    print(f"\n{'='*50}", file=sys.stderr)
    print(f"Merge Summary", file=sys.stderr)
    print(f"{'='*50}", file=sys.stderr)
    print(f"Auto-scraped base:    {len(auto_rows)}", file=sys.stderr)
    print(f"Hand-annotated:       {matched} matched + {extra} extra", file=sys.stderr)
    print(f"Auto-filled:          {filled}", file=sys.stderr)
    print(f"Total merged:         {len(merged)}", file=sys.stderr)
    print(f"Output: {args.output}", file=sys.stderr)

    # Stats
    by_status = {}
    by_diff = {}
    for r in merged:
        s = r.get('status', '?')
        by_status[s] = by_status.get(s, 0) + 1
        d = r.get('mapping_difficulty', '?')
        by_diff[d] = by_diff.get(d, 0) + 1

    print(f"\nBy Status:", file=sys.stderr)
    for s, c in sorted(by_status.items()):
        print(f"  {s}: {c}", file=sys.stderr)

    print(f"\nBy Difficulty:", file=sys.stderr)
    for d, c in sorted(by_diff.items()):
        print(f"  Level {d}: {c}", file=sys.stderr)

    print(f"{'='*50}", file=sys.stderr)


if __name__ == "__main__":
    main()
