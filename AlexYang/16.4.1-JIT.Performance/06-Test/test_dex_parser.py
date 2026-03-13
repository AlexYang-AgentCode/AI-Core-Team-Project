#!/usr/bin/env python3
"""
DEX Parser Unit Tests
测试DEX文件解析器的正确性
"""

import sys
import os
import struct
import unittest

# 添加模块路径
_impl_dir = os.path.join(os.path.dirname(__file__), '..', '05-Implementation')
sys.path.insert(0, os.path.join(_impl_dir, 'dex-parser'))

from dex_parser import DexParser, DexHeader, ClassDef, FieldDef, MethodDef, AccessFlags


class TestDexHeaderParsing(unittest.TestCase):
    """测试DEX文件头解析"""

    def test_valid_dex_header(self):
        """测试有效的DEX文件头"""
        dex = bytearray()
        dex.extend(b'dex\n035\x00')
        dex.extend(struct.pack('<I', 0))  # checksum
        dex.extend(b'\x00' * 20)  # signature
        dex.extend(struct.pack('<I', 0x100))  # file_size
        dex.extend(struct.pack('<I', 0x70))  # header_size
        dex.extend(struct.pack('<I', 0x12345678))  # endian_tag
        dex.extend(struct.pack('<I', 0))  # link_size
        dex.extend(struct.pack('<I', 0))  # link_off
        dex.extend(struct.pack('<I', 0))  # map_off
        dex.extend(struct.pack('<I', 0))  # string_ids_size
        dex.extend(struct.pack('<I', 0))  # string_ids_off
        dex.extend(struct.pack('<I', 0))  # type_ids_size
        dex.extend(struct.pack('<I', 0))  # type_ids_off
        dex.extend(struct.pack('<I', 0))  # proto_ids_size
        dex.extend(struct.pack('<I', 0))  # proto_ids_off
        dex.extend(struct.pack('<I', 0))  # field_ids_size
        dex.extend(struct.pack('<I', 0))  # field_ids_off
        dex.extend(struct.pack('<I', 0))  # method_ids_size
        dex.extend(struct.pack('<I', 0))  # method_ids_off
        dex.extend(struct.pack('<I', 0))  # class_defs_size
        dex.extend(struct.pack('<I', 0))  # class_defs_off
        dex.extend(struct.pack('<I', 0))  # data_size
        dex.extend(struct.pack('<I', 0))  # data_off

        parser = DexParser(bytes(dex))
        result = parser.parse()

        self.assertTrue(result)
        self.assertIsNotNone(parser.header)
        self.assertEqual(parser.header.file_size, 0x100)
        self.assertEqual(parser.header.header_size, 0x70)

    def test_invalid_magic(self):
        """测试无效的Magic"""
        dex = b'invalid!'
        parser = DexParser(dex)
        result = parser.parse()
        self.assertFalse(result)

    def test_truncated_header(self):
        """测试截断的文件头"""
        dex = b'dex\n035\x00' + b'\x00' * 10
        parser = DexParser(dex)
        result = parser.parse()
        self.assertFalse(result)


class TestStringParsing(unittest.TestCase):
    """测试字符串解析"""

    def test_single_string(self):
        """测试单字符串解析"""
        dex = bytearray()

        # Header with 1 string
        dex.extend(b'dex\n035\x00')
        dex.extend(struct.pack('<I', 0))
        dex.extend(b'\x00' * 20)
        dex.extend(struct.pack('<I', 0x100))
        dex.extend(struct.pack('<I', 0x70))
        dex.extend(struct.pack('<I', 0x12345678))
        dex.extend(struct.pack('<I', 0) * 4)
        dex.extend(struct.pack('<I', 1))  # string_ids_size
        dex.extend(struct.pack('<I', 0x70))  # string_ids_off
        dex.extend(struct.pack('<I', 0) * 12)

        # String offset at 0x70
        while len(dex) < 0x70:
            dex.append(0)
        dex.extend(struct.pack('<I', 0x90))  # string data offset

        # String data at 0x90
        while len(dex) < 0x90:
            dex.append(0)
        dex.extend(bytes([5]))  # uleb128 length
        dex.extend(b'hello\x00')

        parser = DexParser(bytes(dex))
        result = parser.parse()

        self.assertTrue(result)
        self.assertEqual(len(parser.strings), 1)
        self.assertEqual(parser.strings[0], 'hello')

    def test_multiple_strings(self):
        """测试多字符串解析"""
        dex = bytearray()

        # Header with 3 strings
        dex.extend(b'dex\n035\x00')
        dex.extend(struct.pack('<I', 0))
        dex.extend(b'\x00' * 20)
        dex.extend(struct.pack('<I', 0x200))
        dex.extend(struct.pack('<I', 0x70))
        dex.extend(struct.pack('<I', 0x12345678))
        dex.extend(struct.pack('<I', 0) * 4)
        dex.extend(struct.pack('<I', 3))  # string_ids_size
        dex.extend(struct.pack('<I', 0x70))  # string_ids_off
        dex.extend(struct.pack('<I', 0) * 12)

        # String offsets
        while len(dex) < 0x70:
            dex.append(0)
        dex.extend(struct.pack('<I', 0x90))
        dex.extend(struct.pack('<I', 0x98))
        dex.extend(struct.pack('<I', 0xa0))

        # String data
        while len(dex) < 0x90:
            dex.append(0)
        dex.extend(bytes([3]))
        dex.extend(b'abc\x00')
        dex.extend(bytes([3]))
        dex.extend(b'def\x00')
        dex.extend(bytes([3]))
        dex.extend(b'ghi\x00')

        parser = DexParser(bytes(dex))
        result = parser.parse()

        self.assertTrue(result)
        self.assertEqual(len(parser.strings), 3)
        self.assertEqual(parser.strings, ['abc', 'def', 'ghi'])


class TestTypeParsing(unittest.TestCase):
    """测试类型解析"""

    def test_single_type(self):
        """测试单类型解析"""
        dex = bytearray()

        # Header with 1 type, 1 string
        dex.extend(b'dex\n035\x00')
        dex.extend(struct.pack('<I', 0))
        dex.extend(b'\x00' * 20)
        dex.extend(struct.pack('<I', 0x200))
        dex.extend(struct.pack('<I', 0x70))
        dex.extend(struct.pack('<I', 0x12345678))
        dex.extend(struct.pack('<I', 0) * 4)
        dex.extend(struct.pack('<I', 1))  # string_ids_size
        dex.extend(struct.pack('<I', 0x70))  # string_ids_off
        dex.extend(struct.pack('<I', 1))  # type_ids_size
        dex.extend(struct.pack('<I', 0x74))  # type_ids_off
        dex.extend(struct.pack('<I', 0) * 10)

        # String offset
        while len(dex) < 0x70:
            dex.append(0)
        dex.extend(struct.pack('<I', 0xa0))

        # Type ID
        while len(dex) < 0x74:
            dex.append(0)
        dex.extend(struct.pack('<I', 0))  # points to string 0

        # String data
        while len(dex) < 0xa0:
            dex.append(0)
        dex.extend(bytes([16]))
        dex.extend(b'Ljava/lang/Object;\x00')

        parser = DexParser(bytes(dex))
        result = parser.parse()

        self.assertTrue(result)
        self.assertEqual(len(parser.types), 1)
        self.assertEqual(parser.get_type(0), 'Ljava/lang/Object;')


class TestClassDefParsing(unittest.TestCase):
    """测试类定义解析"""

    def test_empty_class(self):
        """测试空类解析"""
        dex = bytearray()

        # Header with 1 class def
        dex.extend(b'dex\n035\x00')
        dex.extend(struct.pack('<I', 0))
        dex.extend(b'\x00' * 20)
        dex.extend(struct.pack('<I', 0x200))
        dex.extend(struct.pack('<I', 0x70))
        dex.extend(struct.pack('<I', 0x12345678))
        dex.extend(struct.pack('<I', 0) * 12)
        dex.extend(struct.pack('<I', 1))  # class_defs_size
        dex.extend(struct.pack('<I', 0x70))  # class_defs_off
        dex.extend(struct.pack('<I', 0) * 2)

        # Class def at 0x70
        while len(dex) < 0x70:
            dex.append(0)
        dex.extend(struct.pack('<I', 0))  # class_idx
        dex.extend(struct.pack('<I', AccessFlags.PUBLIC))  # access_flags
        dex.extend(struct.pack('<I', 0xffffffff))  # superclass_idx
        dex.extend(struct.pack('<I', 0))  # interfaces_off
        dex.extend(struct.pack('<I', 0xffffffff))  # source_file_idx
        dex.extend(struct.pack('<I', 0))  # annotations_off
        dex.extend(struct.pack('<I', 0))  # class_data_off (no data)
        dex.extend(struct.pack('<I', 0))  # static_values_off

        parser = DexParser(bytes(dex))
        result = parser.parse()

        self.assertTrue(result)
        self.assertEqual(len(parser.class_defs), 1)
        cls = parser.class_defs[0]
        self.assertEqual(cls.class_idx, 0)
        self.assertEqual(cls.access_flags, AccessFlags.PUBLIC)


class TestMethodParsing(unittest.TestCase):
    """测试方法解析"""

    def test_method_with_code(self):
        """测试带代码的方法解析"""
        dex = bytearray()

        # Header with 1 method, 1 class
        dex.extend(b'dex\n035\x00')
        dex.extend(struct.pack('<I', 0))
        dex.extend(b'\x00' * 20)
        dex.extend(struct.pack('<I', 0x300))
        dex.extend(struct.pack('<I', 0x70))
        dex.extend(struct.pack('<I', 0x12345678))
        dex.extend(struct.pack('<I', 0) * 8)
        dex.extend(struct.pack('<I', 1))  # method_ids_size
        dex.extend(struct.pack('<I', 0x70))  # method_ids_off
        dex.extend(struct.pack('<I', 1))  # class_defs_size
        dex.extend(struct.pack('<I', 0x78))  # class_defs_off
        dex.extend(struct.pack('<I', 0) * 2)

        # Method ID
        while len(dex) < 0x70:
            dex.append(0)
        dex.extend(struct.pack('<H', 0))  # class_idx
        dex.extend(struct.pack('<H', 0))  # proto_idx
        dex.extend(struct.pack('<I', 0))  # name_idx

        # Class def
        while len(dex) < 0x78:
            dex.append(0)
        dex.extend(struct.pack('<I', 0))  # class_idx
        dex.extend(struct.pack('<I', AccessFlags.PUBLIC))
        dex.extend(struct.pack('<I', 0xffffffff))
        dex.extend(struct.pack('<I', 0))
        dex.extend(struct.pack('<I', 0xffffffff))
        dex.extend(struct.pack('<I', 0))
        dex.extend(struct.pack('<I', 0x150))  # class_data_off
        dex.extend(struct.pack('<I', 0))

        # Class data
        while len(dex) < 0x150:
            dex.append(0)
        dex.extend(bytes([0]))  # static_fields_size
        dex.extend(bytes([0]))  # instance_fields_size
        dex.extend(bytes([1]))  # direct_methods_size
        dex.extend(bytes([0]))  # virtual_methods_size
        dex.extend(bytes([0]))  # method_idx_diff
        dex.extend(bytes([AccessFlags.PUBLIC]))  # access_flags
        dex.extend(struct.pack('<I', 0x180))  # code_off

        # Code item
        while len(dex) < 0x180:
            dex.append(0)
        dex.extend(struct.pack('<H', 2))  # registers_size
        dex.extend(struct.pack('<H', 1))  # ins_size
        dex.extend(struct.pack('<H', 0))  # outs_size
        dex.extend(struct.pack('<H', 0))  # tries_size
        dex.extend(struct.pack('<I', 0))  # debug_info_off
        dex.extend(struct.pack('<I', 1))  # insns_size
        dex.extend(struct.pack('<H', 0x0e00))  # return-void

        parser = DexParser(bytes(dex))
        result = parser.parse()

        self.assertTrue(result)
        self.assertEqual(len(parser.class_defs), 1)
        cls = parser.class_defs[0]
        self.assertEqual(len(cls.methods), 1)
        method = cls.methods[0]
        self.assertEqual(method.code_off, 0x180)


class TestAccessFlags(unittest.TestCase):
    """测试访问标志"""

    def test_public_flag(self):
        """测试PUBLIC标志"""
        self.assertEqual(AccessFlags.PUBLIC, 0x1)

    def test_static_flag(self):
        """测试STATIC标志"""
        self.assertEqual(AccessFlags.STATIC, 0x8)

    def test_combined_flags(self):
        """测试组合标志"""
        flags = AccessFlags.PUBLIC | AccessFlags.STATIC
        self.assertTrue(flags & AccessFlags.PUBLIC)
        self.assertTrue(flags & AccessFlags.STATIC)


class TestEdgeCases(unittest.TestCase):
    """测试边界情况"""

    def test_uleb128_decoding(self):
        """测试uleb128解码"""
        parser = DexParser(b'')
        parser.data = bytes([0x7f])
        parser.position = 0
        value, count = parser._read_uleb128()
        self.assertEqual(value, 0x7f)
        self.assertEqual(count, 1)

    def test_uleb128_multi_byte(self):
        """测试多字节uleb128"""
        parser = DexParser(b'')
        parser.data = bytes([0x80, 0x01])  # 128 in uleb128
        parser.position = 0
        value, count = parser._read_uleb128()
        self.assertEqual(value, 128)
        self.assertEqual(count, 2)

    def test_large_uleb128(self):
        """测试大数值uleb128"""
        parser = DexParser(b'')
        parser.data = bytes([0x80, 0x80, 0x01])  # 16384 in uleb128
        parser.position = 0
        value, count = parser._read_uleb128()
        self.assertEqual(value, 16384)
        self.assertEqual(count, 3)

    def test_get_invalid_string(self):
        """测试获取无效字符串"""
        dex = bytearray()
        dex.extend(b'dex\n035\x00')
        dex.extend(struct.pack('<I', 0))
        dex.extend(b'\x00' * 20)
        dex.extend(struct.pack('<I', 0x100))
        dex.extend(struct.pack('<I', 0x70))
        dex.extend(struct.pack('<I', 0x12345678))
        dex.extend(struct.pack('<I', 0) * 18)

        parser = DexParser(bytes(dex))
        parser.parse()

        # Access invalid index
        result = parser.get_string(999)
        self.assertIn('invalid', result)

    def test_get_invalid_type(self):
        """测试获取无效类型"""
        dex = bytearray()
        dex.extend(b'dex\n035\x00')
        dex.extend(struct.pack('<I', 0))
        dex.extend(b'\x00' * 20)
        dex.extend(struct.pack('<I', 0x100))
        dex.extend(struct.pack('<I', 0x70))
        dex.extend(struct.pack('<I', 0x12345678))
        dex.extend(struct.pack('<I', 0) * 18)

        parser = DexParser(bytes(dex))
        parser.parse()

        # Access invalid index
        result = parser.get_type(999)
        self.assertIn('invalid', result)


def run_tests():
    """运行所有测试"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    suite.addTests(loader.loadTestsFromTestCase(TestDexHeaderParsing))
    suite.addTests(loader.loadTestsFromTestCase(TestStringParsing))
    suite.addTests(loader.loadTestsFromTestCase(TestTypeParsing))
    suite.addTests(loader.loadTestsFromTestCase(TestClassDefParsing))
    suite.addTests(loader.loadTestsFromTestCase(TestMethodParsing))
    suite.addTests(loader.loadTestsFromTestCase(TestAccessFlags))
    suite.addTests(loader.loadTestsFromTestCase(TestEdgeCases))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
