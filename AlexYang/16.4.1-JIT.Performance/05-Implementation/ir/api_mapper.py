#!/usr/bin/env python3
"""
Android API → HarmonyOS API Mapper
M2阶段: 系统服务API映射

将Android系统API调用映射为等效的HarmonyOS API调用
"""

from dataclasses import dataclass
from typing import Dict, Optional, List, Tuple
from enum import Enum


class ApiCategory(Enum):
    """API类别"""
    IO = "io"                    # 输入输出
    DATABASE = "database"        # 数据库
    NETWORK = "network"          # 网络
    UI = "ui"                    # UI组件
    SERVICE = "service"          # 服务
    STORAGE = "storage"          # 存储
    MULTIMEDIA = "multimedia"    # 多媒体
    SYSTEM = "system"            # 系统服务


@dataclass
class ApiMapping:
    """API映射定义"""
    android_class: str           # Android类名
    android_method: str          # Android方法名
    android_sig: str             # Android方法签名
    harmony_class: str           # HarmonyOS类名
    harmony_method: str          # HarmonyOS方法名
    harmony_sig: str             # HarmonyOS方法签名
    category: ApiCategory        # API类别
    notes: str = ""              # 备注


class ApiMapper:
    """
    Android → HarmonyOS API映射器
    """

    def __init__(self):
        self.mappings: Dict[str, ApiMapping] = {}
        self._init_mappings()

    def _init_mappings(self):
        """初始化API映射表"""

        # ===== IO API Mappings =====
        io_mappings = [
            # File operations
            ApiMapping(
                "java/io/File", "<init>", "(Ljava/lang/String;)V",
                "@ohos.file.fs/File", "constructor", "(string): File",
                ApiCategory.IO,
                "文件构造函数"
            ),
            ApiMapping(
                "java/io/File", "exists", "()Z",
                "@ohos.file.fs/File", "access", "(string): boolean",
                ApiCategory.IO,
                "检查文件是否存在"
            ),
            ApiMapping(
                "java/io/FileInputStream", "<init>", "(Ljava/io/File;)V",
                "@ohos.file.fs/File", "openSync", "(string, number): File",
                ApiCategory.IO,
                "文件输入流"
            ),
            ApiMapping(
                "java/io/FileOutputStream", "<init>", "(Ljava/io/File;)V",
                "@ohos.file.fs/File", "openSync", "(string, number): File",
                ApiCategory.IO,
                "文件输出流"
            ),
            ApiMapping(
                "java/io/FileReader", "<init>", "(Ljava/lang/String;)V",
                "@ohos.file.fs/File", "readTextSync", "(string): string",
                ApiCategory.IO,
                "文件字符读取"
            ),
            ApiMapping(
                "java/io/FileWriter", "<init>", "(Ljava/lang/String;)V",
                "@ohos.file.fs/File", "writeTextSync", "(string, string): void",
                ApiCategory.IO,
                "文件字符写入"
            ),
            ApiMapping(
                "java/io/BufferedReader", "readLine", "()Ljava/lang/String;",
                "@ohos.file.fs/File", "readLinesSync", "(string): string[]",
                ApiCategory.IO,
                "按行读取"
            ),
            ApiMapping(
                "java/io/InputStream", "read", "()I",
                "@ohos.file.fs/Stream", "readSync", "(): number",
                ApiCategory.IO,
                "读取字节"
            ),
            ApiMapping(
                "java/io/OutputStream", "write", "(I)V",
                "@ohos.file.fs/Stream", "writeSync", "(ArrayBuffer): void",
                ApiCategory.IO,
                "写入字节"
            ),
            ApiMapping(
                "java/io/Closeable", "close", "()V",
                "@ohos.file.fs/Stream", "closeSync", "(): void",
                ApiCategory.IO,
                "关闭流"
            ),
        ]

        # ===== Database API Mappings =====
        db_mappings = [
            ApiMapping(
                "android/database/sqlite/SQLiteDatabase",
                "openDatabase",
                "(Ljava/lang/String;Landroid/database/sqlite/SQLiteDatabase$CursorFactory;I)Landroid/database/sqlite/SQLiteDatabase;",
                "@ohos.data.relationalStore/RdbStore",
                "getRdbStore",
                "(Context, StoreConfig): RdbStore",
                ApiCategory.DATABASE,
                "打开数据库"
            ),
            ApiMapping(
                "android/database/sqlite/SQLiteDatabase",
                "execSQL",
                "(Ljava/lang/String;)V",
                "@ohos.data.relationalStore/RdbStore",
                "executeSql",
                "(string, Array<ValueType>): void",
                ApiCategory.DATABASE,
                "执行SQL"
            ),
            ApiMapping(
                "android/database/sqlite/SQLiteDatabase",
                "query",
                "(Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;",
                "@ohos.data.relationalStore/RdbStore",
                "query",
                "(RdbPredicates, Array<string>): ResultSet",
                ApiCategory.DATABASE,
                "查询数据"
            ),
            ApiMapping(
                "android/database/sqlite/SQLiteDatabase",
                "insert",
                "(Ljava/lang/String;Ljava/lang/String;Landroid/content/ContentValues;)J",
                "@ohos.data.relationalStore/RdbStore",
                "insert",
                "(string, ValuesBucket): number",
                ApiCategory.DATABASE,
                "插入数据"
            ),
            ApiMapping(
                "android/database/sqlite/SQLiteDatabase",
                "update",
                "(Ljava/lang/String;Landroid/content/ContentValues;Ljava/lang/String;[Ljava/lang/String;)I",
                "@ohos.data.relationalStore/RdbStore",
                "update",
                "(ValuesBucket, RdbPredicates): number",
                ApiCategory.DATABASE,
                "更新数据"
            ),
            ApiMapping(
                "android/database/sqlite/SQLiteDatabase",
                "delete",
                "(Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;)I",
                "@ohos.data.relationalStore/RdbStore",
                "delete",
                "(RdbPredicates): number",
                ApiCategory.DATABASE,
                "删除数据"
            ),
            ApiMapping(
                "android/database/Cursor",
                "moveToFirst",
                "()Z",
                "@ohos.data.relationalStore/ResultSet",
                "goToFirstRow",
                "(): boolean",
                ApiCategory.DATABASE,
                "移动到第一行"
            ),
            ApiMapping(
                "android/database/Cursor",
                "moveToNext",
                "()Z",
                "@ohos.data.relationalStore/ResultSet",
                "goToNextRow",
                "(): boolean",
                ApiCategory.DATABASE,
                "移动到下一行"
            ),
            ApiMapping(
                "android/database/Cursor",
                "getString",
                "(I)Ljava/lang/String;",
                "@ohos.data.relationalStore/ResultSet",
                "getString",
                "(number): string",
                ApiCategory.DATABASE,
                "获取字符串"
            ),
            ApiMapping(
                "android/database/Cursor",
                "getInt",
                "(I)I",
                "@ohos.data.relationalStore/ResultSet",
                "getInt",
                "(number): number",
                ApiCategory.DATABASE,
                "获取整数"
            ),
            ApiMapping(
                "android/database/Cursor",
                "getLong",
                "(I)J",
                "@ohos.data.relationalStore/ResultSet",
                "getLong",
                "(number): number",
                ApiCategory.DATABASE,
                "获取长整数"
            ),
            ApiMapping(
                "android/database/Cursor",
                "close",
                "()V",
                "@ohos.data.relationalStore/ResultSet",
                "close",
                "(): void",
                ApiCategory.DATABASE,
                "关闭Cursor"
            ),
            ApiMapping(
                "android/content/ContentValues",
                "put",
                "(Ljava/lang/String;Ljava/lang/String;)V",
                "@ohos.data.relationalStore/ValuesBucket",
                "putString",
                "(string, string): void",
                ApiCategory.DATABASE,
                "添加字符串值"
            ),
            ApiMapping(
                "android/content/ContentValues",
                "put",
                "(Ljava/lang/String;Ljava/lang/Integer;)V",
                "@ohos.data.relationalStore/ValuesBucket",
                "putInt",
                "(string, number): void",
                ApiCategory.DATABASE,
                "添加整数值"
            ),
        ]

        # ===== Network API Mappings =====
        network_mappings = [
            ApiMapping(
                "java/net/URL",
                "<init>",
                "(Ljava/lang/String;)V",
                "@ohos.net.http/HttpRequest",
                "constructor",
                "(string): HttpRequest",
                ApiCategory.NETWORK,
                "URL构造函数"
            ),
            ApiMapping(
                "java/net/HttpURLConnection",
                "setRequestMethod",
                "(Ljava/lang/String;)V",
                "@ohos.net.http/HttpRequest",
                "method",
                "(string): void",
                ApiCategory.NETWORK,
                "设置请求方法"
            ),
            ApiMapping(
                "java/net/HttpURLConnection",
                "setConnectTimeout",
                "(I)V",
                "@ohos.net.http/HttpRequest",
                "connectTimeout",
                "(number): void",
                ApiCategory.NETWORK,
                "设置连接超时"
            ),
            ApiMapping(
                "java/net/HttpURLConnection",
                "setReadTimeout",
                "(I)V",
                "@ohos.net.http/HttpRequest",
                "readTimeout",
                "(number): void",
                ApiCategory.NETWORK,
                "设置读取超时"
            ),
            ApiMapping(
                "java/net/HttpURLConnection",
                "setDoOutput",
                "(Z)V",
                "@ohos.net.http/HttpRequest",
                "enableOutput",
                "(boolean): void",
                ApiCategory.NETWORK,
                "允许输出"
            ),
            ApiMapping(
                "java/net/HttpURLConnection",
                "getOutputStream",
                "()Ljava/io/OutputStream;",
                "@ohos.net.http/HttpRequest",
                "getOutputStream",
                "(): OutputStream",
                ApiCategory.NETWORK,
                "获取输出流"
            ),
            ApiMapping(
                "java/net/HttpURLConnection",
                "getInputStream",
                "()Ljava/io/InputStream;",
                "@ohos.net.http/HttpRequest",
                "getInputStream",
                "(): InputStream",
                ApiCategory.NETWORK,
                "获取输入流"
            ),
            ApiMapping(
                "java/net/HttpURLConnection",
                "getResponseCode",
                "()I",
                "@ohos.net.http/HttpResponse",
                "getResponseCode",
                "(): number",
                ApiCategory.NETWORK,
                "获取响应码"
            ),
            ApiMapping(
                "java/net/HttpURLConnection",
                "connect",
                "()V",
                "@ohos.net.http/HttpRequest",
                "request",
                "(): Promise<HttpResponse>",
                ApiCategory.NETWORK,
                "发起连接"
            ),
            ApiMapping(
                "java/net/HttpURLConnection",
                "disconnect",
                "()V",
                "@ohos.net.http/HttpRequest",
                "destroy",
                "(): void",
                ApiCategory.NETWORK,
                "断开连接"
            ),
        ]

        # ===== UI API Mappings =====
        ui_mappings = [
            ApiMapping(
                "android/widget/TextView",
                "setText",
                "(Ljava/lang/CharSequence;)V",
                "ohos.agp.components.Text",
                "setText",
                "(string): void",
                ApiCategory.UI,
                "设置文本"
            ),
            ApiMapping(
                "android/widget/TextView",
                "getText",
                "()Ljava/lang/CharSequence;",
                "ohos.agp.components.Text",
                "getText",
                "(): string",
                ApiCategory.UI,
                "获取文本"
            ),
            ApiMapping(
                "android/widget/Button",
                "setOnClickListener",
                "(Landroid/view/View$OnClickListener;)V",
                "ohos.agp.components.Button",
                "setClickedListener",
                "(ClickedListener): void",
                ApiCategory.UI,
                "点击监听"
            ),
            ApiMapping(
                "android/widget/EditText",
                "getText",
                "()Landroid/text/Editable;",
                "ohos.agp.components.TextField",
                "getText",
                "(): string",
                ApiCategory.UI,
                "获取输入文本"
            ),
            ApiMapping(
                "android/widget/LinearLayout",
                "addView",
                "(Landroid/view/View;)V",
                "ohos.agp.components.DirectionalLayout",
                "addComponent",
                "(Component): void",
                ApiCategory.UI,
                "添加子视图"
            ),
            ApiMapping(
                "android/content/Context",
                "setContentView",
                "(I)V",
                "ohos.aafwk.ability.Ability",
                "setUIContent",
                "(Resource): void",
                ApiCategory.UI,
                "设置内容视图"
            ),
            ApiMapping(
                "android/widget/Toast",
                "makeText",
                "(Landroid/content/Context;Ljava/lang/CharSequence;I)Landroid/widget/Toast;",
                "ohos.agp.utils.ToastDialog",
                "constructor",
                "(Context): ToastDialog",
                ApiCategory.UI,
                "Toast显示"
            ),
            ApiMapping(
                "android/widget/Toast",
                "show",
                "()V",
                "ohos.agp.utils.ToastDialog",
                "show",
                "(): void",
                ApiCategory.UI,
                "显示Toast"
            ),
        ]

        # ===== Storage API Mappings (SharedPreferences) =====
        storage_mappings = [
            ApiMapping(
                "android/content/Context",
                "getSharedPreferences",
                "(Ljava/lang/String;I)Landroid/content/SharedPreferences;",
                "@ohos.data.preferences/Preferences",
                "getPreferences",
                "(Context, string): Preferences",
                ApiCategory.STORAGE,
                "获取SharedPreferences"
            ),
            ApiMapping(
                "android/content/SharedPreferences",
                "edit",
                "()Landroid/content/SharedPreferences$Editor;",
                "@ohos.data.preferences/Preferences",
                "edit",
                "(): Editor",
                ApiCategory.STORAGE,
                "获取编辑器"
            ),
            ApiMapping(
                "android/content/SharedPreferences",
                "getString",
                "(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;",
                "@ohos.data.preferences/Preferences",
                "getString",
                "(string, string): string",
                ApiCategory.STORAGE,
                "获取字符串"
            ),
            ApiMapping(
                "android/content/SharedPreferences",
                "getInt",
                "(Ljava/lang/String;I)I",
                "@ohos.data.preferences/Preferences",
                "getInt",
                "(string, number): number",
                ApiCategory.STORAGE,
                "获取整数"
            ),
            ApiMapping(
                "android/content/SharedPreferences",
                "getBoolean",
                "(Ljava/lang/String;Z)Z",
                "@ohos.data.preferences/Preferences",
                "getBoolean",
                "(string, boolean): boolean",
                ApiCategory.STORAGE,
                "获取布尔值"
            ),
            ApiMapping(
                "android/content/SharedPreferences$Editor",
                "putString",
                "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/SharedPreferences$Editor;",
                "@ohos.data.preferences/Preferences",
                "putString",
                "(string, string): void",
                ApiCategory.STORAGE,
                "存储字符串"
            ),
            ApiMapping(
                "android/content/SharedPreferences$Editor",
                "putInt",
                "(Ljava/lang/String;I)Landroid/content/SharedPreferences$Editor;",
                "@ohos.data.preferences/Preferences",
                "putInt",
                "(string, number): void",
                ApiCategory.STORAGE,
                "存储整数"
            ),
            ApiMapping(
                "android/content/SharedPreferences$Editor",
                "putBoolean",
                "(Ljava/lang/String;Z)Landroid/content/SharedPreferences$Editor;",
                "@ohos.data.preferences/Preferences",
                "putBoolean",
                "(string, boolean): void",
                ApiCategory.STORAGE,
                "存储布尔值"
            ),
            ApiMapping(
                "android/content/SharedPreferences$Editor",
                "apply",
                "()V",
                "@ohos.data.preferences/Preferences",
                "flush",
                "(): Promise<void>",
                ApiCategory.STORAGE,
                "应用更改"
            ),
        ]

        # ===== Service API Mappings =====
        service_mappings = [
            ApiMapping(
                "android/app/Service",
                "onCreate",
                "()V",
                "ohos.aafwk.ability.ServiceExtensionAbility",
                "onCreate",
                "(): void",
                ApiCategory.SERVICE,
                "服务创建"
            ),
            ApiMapping(
                "android/app/Service",
                "onStartCommand",
                "(Landroid/content/Intent;II)I",
                "ohos.aafwk.ability.ServiceExtensionAbility",
                "onStart",
                "(Want): void",
                ApiCategory.SERVICE,
                "服务启动"
            ),
            ApiMapping(
                "android/app/Service",
                "onBind",
                "(Landroid/content/Intent;)Landroid/os/IBinder;",
                "ohos.aafwk.ability.ServiceExtensionAbility",
                "onConnect",
                "(Want): void",
                ApiCategory.SERVICE,
                "服务绑定"
            ),
            ApiMapping(
                "android/content/BroadcastReceiver",
                "onReceive",
                "(Landroid/content/Context;Landroid/content/Intent;)V",
                "ohos.aafwk.ability.StaticSubscriber",
                "onReceiveEvent",
                "(CommonEvent): void",
                ApiCategory.SERVICE,
                "广播接收"
            ),
            ApiMapping(
                "android/app/NotificationManager",
                "notify",
                "(ILandroid/app/Notification;)V",
                "ohos.notification.NotificationManager",
                "publish",
                "(Notification): void",
                ApiCategory.SERVICE,
                "发送通知"
            ),
        ]

        # ===== System API Mappings =====
        system_mappings = [
            ApiMapping(
                "android/os/Handler",
                "post",
                "(Ljava/lang/Runnable;)Z",
                "@ohos.worker/ThreadWorker",
                "postMessage",
                "(Object): void",
                ApiCategory.SYSTEM,
                "Handler消息投递"
            ),
            ApiMapping(
                "android/os/Looper",
                "prepare",
                "()V",
                "@ohos.eventLoop/EventLoop",
                "create",
                "(): EventLoop",
                ApiCategory.SYSTEM,
                "准备Looper"
            ),
            ApiMapping(
                "android/os/Looper",
                "loop",
                "()V",
                "@ohos.eventLoop/EventLoop",
                "loop",
                "(): void",
                ApiCategory.SYSTEM,
                "启动消息循环"
            ),
            ApiMapping(
                "android/content/Intent",
                "<init>",
                "(Landroid/content/Context;Ljava/lang/Class;)V",
                "ohos.aafwk.content.Want",
                "constructor",
                "(Context, string): Want",
                ApiCategory.SYSTEM,
                "Intent构造函数"
            ),
            ApiMapping(
                "android/content/Intent",
                "putExtra",
                "(Ljava/lang/String;Ljava/lang/String;)Landroid/content/Intent;",
                "ohos.aafwk.content.Want",
                "setParam",
                "(string, Object): Want",
                ApiCategory.SYSTEM,
                "Intent传参"
            ),
            ApiMapping(
                "android/app/Activity",
                "startActivity",
                "(Landroid/content/Intent;)V",
                "ohos.aafwk.ability.UIAbility",
                "startAbility",
                "(Want): void",
                ApiCategory.SYSTEM,
                "启动Activity"
            ),
            ApiMapping(
                "android/app/Activity",
                "finish",
                "()V",
                "ohos.aafwk.ability.UIAbility",
                "terminateSelf",
                "(): void",
                ApiCategory.SYSTEM,
                "结束Activity"
            ),
            ApiMapping(
                "android/app/Activity",
                "onCreate",
                "(Landroid/os/Bundle;)V",
                "ohos.aafwk.ability.UIAbility",
                "onCreate",
                "(Want): void",
                ApiCategory.SYSTEM,
                "Activity创建"
            ),
        ]

        # Add all mappings to dictionary
        for mapping in (io_mappings + db_mappings + network_mappings +
                       ui_mappings + storage_mappings + service_mappings + system_mappings):
            key = f"{mapping.android_class}.{mapping.android_method}:{mapping.android_sig}"
            self.mappings[key] = mapping

    def lookup(self, class_name: str, method_name: str, signature: str) -> Optional[ApiMapping]:
        """
        查找API映射

        Args:
            class_name: Android类名 (e.g., "java/io/FileInputStream")
            method_name: 方法名 (e.g., "<init>")
            signature: 方法签名 (e.g., "(Ljava/io/File;)V")

        Returns:
            ApiMapping对象或None
        """
        key = f"{class_name}.{method_name}:{signature}"
        return self.mappings.get(key)

    def lookup_by_class_method(self, class_name: str, method_name: str) -> List[ApiMapping]:
        """
        通过类名和方法名查找所有匹配的映射（不考虑签名）

        Args:
            class_name: Android类名
            method_name: 方法名

        Returns:
            匹配的ApiMapping列表
        """
        results = []
        prefix = f"{class_name}.{method_name}:"
        for key, mapping in self.mappings.items():
            if key.startswith(prefix):
                results.append(mapping)
        return results

    def get_mappings_by_category(self, category: ApiCategory) -> List[ApiMapping]:
        """获取指定类别的所有映射"""
        return [m for m in self.mappings.values() if m.category == category]

    def is_mapped(self, class_name: str, method_name: str, signature: str) -> bool:
        """检查是否已映射"""
        return self.lookup(class_name, method_name, signature) is not None

    def get_stats(self) -> Dict[str, int]:
        """获取映射统计信息"""
        stats = {}
        for cat in ApiCategory:
            stats[cat.value] = len(self.get_mappings_by_category(cat))
        stats['total'] = len(self.mappings)
        return stats


# Singleton instance
_api_mapper = None

def get_api_mapper() -> ApiMapper:
    """获取API映射器单例"""
    global _api_mapper
    if _api_mapper is None:
        _api_mapper = ApiMapper()
    return _api_mapper


if __name__ == '__main__':
    # Self-test
    mapper = ApiMapper()

    print("=" * 60)
    print("Android → HarmonyOS API Mapper")
    print("=" * 60)

    # Test lookup
    mapping = mapper.lookup("java/io/FileInputStream", "<init>", "(Ljava/io/File;)V")
    if mapping:
        print(f"\n示例映射:")
        print(f"  Android:  {mapping.android_class}.{mapping.android_method}")
        print(f"  Harmony:  {mapping.harmony_class}.{mapping.harmony_method}")
        print(f"  类别:     {mapping.category.value}")

    # Stats
    print("\n映射统计:")
    stats = mapper.get_stats()
    for cat, count in stats.items():
        print(f"  {cat}: {count}")
