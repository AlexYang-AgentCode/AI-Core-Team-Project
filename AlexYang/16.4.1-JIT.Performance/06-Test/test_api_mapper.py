#!/usr/bin/env python3
"""
API Mapper Test
测试Android到HarmonyOS的API映射
"""

import sys
import os
import unittest

_impl_dir = os.path.join(os.path.dirname(__file__), '..', '05-Implementation')
sys.path.insert(0, os.path.join(_impl_dir, 'ir'))

from api_mapper import ApiMapper, ApiCategory, get_api_mapper


class TestApiMapper(unittest.TestCase):
    """测试API映射器"""

    def setUp(self):
        self.mapper = ApiMapper()

    def test_io_mapping_fileinputstream(self):
        """测试FileInputStream映射"""
        mapping = self.mapper.lookup(
            "java/io/FileInputStream",
            "<init>",
            "(Ljava/io/File;)V"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.IO)
        self.assertIn("file.fs", mapping.harmony_class)

    def test_io_mapping_fileoutputstream(self):
        """测试FileOutputStream映射"""
        mapping = self.mapper.lookup(
            "java/io/FileOutputStream",
            "<init>",
            "(Ljava/io/File;)V"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.IO)

    def test_database_mapping_query(self):
        """测试数据库查询映射"""
        mapping = self.mapper.lookup(
            "android/database/sqlite/SQLiteDatabase",
            "query",
            "(Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.DATABASE)
        self.assertIn("RdbStore", mapping.harmony_class)

    def test_database_mapping_insert(self):
        """测试数据库插入映射"""
        mapping = self.mapper.lookup(
            "android/database/sqlite/SQLiteDatabase",
            "insert",
            "(Ljava/lang/String;Ljava/lang/String;Landroid/content/ContentValues;)J"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.DATABASE)

    def test_network_mapping_httpurlconnection(self):
        """测试HTTP连接映射"""
        mapping = self.mapper.lookup(
            "java/net/HttpURLConnection",
            "setRequestMethod",
            "(Ljava/lang/String;)V"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.NETWORK)

    def test_ui_mapping_textview(self):
        """测试TextView映射"""
        mapping = self.mapper.lookup(
            "android/widget/TextView",
            "setText",
            "(Ljava/lang/CharSequence;)V"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.UI)
        self.assertIn("Text", mapping.harmony_class)

    def test_storage_mapping_sharedpreferences(self):
        """测试SharedPreferences映射"""
        mapping = self.mapper.lookup(
            "android/content/Context",
            "getSharedPreferences",
            "(Ljava/lang/String;I)Landroid/content/SharedPreferences;"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.STORAGE)

    def test_service_mapping_service(self):
        """测试Service映射"""
        mapping = self.mapper.lookup(
            "android/app/Service",
            "onCreate",
            "()V"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.SERVICE)

    def test_system_mapping_handler(self):
        """测试Handler映射"""
        mapping = self.mapper.lookup(
            "android/os/Handler",
            "post",
            "(Ljava/lang/Runnable;)Z"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.SYSTEM)

    def test_lookup_by_class_method(self):
        """测试通过类名和方法名查找"""
        results = self.mapper.lookup_by_class_method(
            "java/io/FileInputStream",
            "<init>"
        )
        self.assertGreater(len(results), 0)

    def test_get_mappings_by_category(self):
        """测试按类别获取映射"""
        io_mappings = self.mapper.get_mappings_by_category(ApiCategory.IO)
        self.assertGreater(len(io_mappings), 0)

        db_mappings = self.mapper.get_mappings_by_category(ApiCategory.DATABASE)
        self.assertGreater(len(db_mappings), 0)

    def test_is_mapped(self):
        """测试映射检查"""
        self.assertTrue(self.mapper.is_mapped(
            "java/io/File",
            "exists",
            "()Z"
        ))
        self.assertFalse(self.mapper.is_mapped(
            "com/example/UnknownClass",
            "unknownMethod",
            "()V"
        ))

    def test_get_stats(self):
        """测试统计信息"""
        stats = self.mapper.get_stats()
        self.assertIn('total', stats)
        self.assertIn('io', stats)
        self.assertIn('database', stats)
        self.assertIn('network', stats)
        self.assertIn('ui', stats)
        self.assertGreater(stats['total'], 0)

    def test_cursor_mappings(self):
        """测试Cursor相关映射"""
        mappings = [
            ("moveToFirst", "()Z"),
            ("moveToNext", "()Z"),
            ("getString", "(I)Ljava/lang/String;"),
            ("getInt", "(I)I"),
            ("close", "()V"),
        ]
        for method, sig in mappings:
            mapping = self.mapper.lookup(
                "android/database/Cursor",
                method,
                sig
            )
            self.assertIsNotNone(mapping, f"Cursor.{method} should be mapped")

    def test_contentvalues_mappings(self):
        """测试ContentValues映射"""
        mapping = self.mapper.lookup(
            "android/content/ContentValues",
            "put",
            "(Ljava/lang/String;Ljava/lang/String;)V"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.DATABASE)

    def test_notification_mapping(self):
        """测试通知映射"""
        mapping = self.mapper.lookup(
            "android/app/NotificationManager",
            "notify",
            "(ILandroid/app/Notification;)V"
        )
        self.assertIsNotNone(mapping)
        self.assertEqual(mapping.category, ApiCategory.SERVICE)


class TestApiMapperSingleton(unittest.TestCase):
    """测试API映射器单例"""

    def test_singleton(self):
        """测试单例模式"""
        mapper1 = get_api_mapper()
        mapper2 = get_api_mapper()
        self.assertIs(mapper1, mapper2)


def run_tests():
    """运行所有API映射测试"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    suite.addTests(loader.loadTestsFromTestCase(TestApiMapper))
    suite.addTests(loader.loadTestsFromTestCase(TestApiMapperSingleton))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
