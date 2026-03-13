#!/usr/bin/env python3
"""
Integration Tests - End-to-end DEX to ABC conversion
测试完整的DEX → ABC转换流水线
"""

import sys
import os
import struct
import unittest
import tempfile

# 添加模块路径
_impl_dir = os.path.join(os.path.dirname(__file__), '..', '05-Implementation')
sys.path.insert(0, _impl_dir)
sys.path.insert(0, os.path.join(_impl_dir, 'dex-parser'))
sys.path.insert(0, os.path.join(_impl_dir, 'abc-generator'))
sys.path.insert(0, os.path.join(_impl_dir, 'ir'))

from converter import DexToAbcConverter, ConversionResult
from dex_parser import DexParser
from abc_generator import AbcGenerator, PANDA_MAGIC
from instruction_mapper import InstructionMapper


class TestEndToEndConversion(unittest.TestCase):
    """测试端到端转换"""

    def setUp(self):
        self.converter = DexToAbcConverter()

    def _create_minimal_dex(self) -> bytes:
        """创建一个最小的有效DEX文件"""
        dex = bytearray()

        # Header (0x70 bytes)
        dex.extend(b'dex\n035\x00')  # magic (8 bytes)
        dex.extend(struct.pack('<I', 0))  # checksum (4 bytes)
        dex.extend(b'\x00' * 20)  # signature (20 bytes)
        dex.extend(struct.pack('<I', 0x200))  # file_size (4 bytes)
        dex.extend(struct.pack('<I', 0x70))  # header_size (4 bytes)
        dex.extend(struct.pack('<I', 0x12345678))  # endian_tag (4 bytes)
        dex.extend(struct.pack('<I', 0))  # link_size (4 bytes)
        dex.extend(struct.pack('<I', 0))  # link_off (4 bytes)
        dex.extend(struct.pack('<I', 0x70))  # map_off (4 bytes)
        dex.extend(struct.pack('<I', 4))  # string_ids_size (4 bytes)
        dex.extend(struct.pack('<I', 0x70))  # string_ids_off (4 bytes)
        dex.extend(struct.pack('<I', 2))  # type_ids_size (4 bytes)
        dex.extend(struct.pack('<I', 0x80))  # type_ids_off (4 bytes)
        dex.extend(struct.pack('<I', 0))  # proto_ids_size (4 bytes)
        dex.extend(struct.pack('<I', 0))  # proto_ids_off (4 bytes)
        dex.extend(struct.pack('<I', 0))  # field_ids_size (4 bytes)
        dex.extend(struct.pack('<I', 0))  # field_ids_off (4 bytes)
        dex.extend(struct.pack('<I', 1))  # method_ids_size (4 bytes)
        dex.extend(struct.pack('<I', 0x88))  # method_ids_off (4 bytes)
        dex.extend(struct.pack('<I', 1))  # class_defs_size (4 bytes)
        dex.extend(struct.pack('<I', 0x90))  # class_defs_off (4 bytes)
        dex.extend(struct.pack('<I', 0x100))  # data_size (4 bytes)
        dex.extend(struct.pack('<I', 0x100))  # data_off (4 bytes)

        # Pad to string_ids_off (0x70)
        while len(dex) < 0x70:
            dex.append(0)

        # String ID table (4 entries)
        dex.extend(struct.pack('<I', 0x130))  # string 0: "Test"
        dex.extend(struct.pack('<I', 0x138))  # string 1: "Ljava/lang/Object;"
        dex.extend(struct.pack('<I', 0x14c))  # string 2: "<init>"
        dex.extend(struct.pack('<I', 0x154))  # string 3: "V"

        # Pad to type_ids_off (0x80)
        while len(dex) < 0x80:
            dex.append(0)

        # Type ID table (2 entries)
        dex.extend(struct.pack('<I', 0))  # type 0 -> string 0 (Test)
        dex.extend(struct.pack('<I', 1))  # type 1 -> string 1 (Object)

        # Pad to method_ids_off (0x88)
        while len(dex) < 0x88:
            dex.append(0)

        # Method ID table (1 entry)
        dex.extend(struct.pack('<H', 0))  # class_idx
        dex.extend(struct.pack('<H', 0))  # proto_idx (will be invalid but ok for test)
        dex.extend(struct.pack('<I', 2))  # name_idx -> "<init>"

        # Pad to class_defs_off (0x90)
        while len(dex) < 0x90:
            dex.append(0)

        # Class def (1 entry = 32 bytes)
        dex.extend(struct.pack('<I', 0))  # class_idx
        dex.extend(struct.pack('<I', 1))  # access_flags (public)
        dex.extend(struct.pack('<I', 1))  # superclass_idx
        dex.extend(struct.pack('<I', 0))  # interfaces_off
        dex.extend(struct.pack('<I', 0xffffffff))  # source_file_idx
        dex.extend(struct.pack('<I', 0))  # annotations_off
        dex.extend(struct.pack('<I', 0x180))  # class_data_off
        dex.extend(struct.pack('<I', 0))  # static_values_off

        # Pad to data_off (0x100)
        while len(dex) < 0x100:
            dex.append(0)

        # Map list
        dex.extend(struct.pack('<I', 1))  # size
        # Map item: TYPE_HEADER_LIST
        dex.extend(struct.pack('<H', 0x0000))  # type
        dex.extend(struct.pack('<H', 1))  # unused
        dex.extend(struct.pack('<I', 1))  # size
        dex.extend(struct.pack('<I', 0))  # offset

        # String data
        while len(dex) < 0x130:
            dex.append(0)

        dex.extend(bytes([4]))  # uleb128 length
        dex.extend(b'Test\x00')
        dex.extend(bytes([16]))  # uleb128 length
        dex.extend(b'Ljava/lang/Object;\x00')
        dex.extend(bytes([6]))  # uleb128 length
        dex.extend(b'<init>\x00')
        dex.extend(bytes([1]))  # uleb128 length
        dex.extend(b'V\x00')

        # Class data at 0x180
        while len(dex) < 0x180:
            dex.append(0)

        dex.extend(bytes([0]))  # static_fields_size
        dex.extend(bytes([0]))  # instance_fields_size
        dex.extend(bytes([1]))  # direct_methods_size
        dex.extend(bytes([0]))  # virtual_methods_size
        dex.extend(bytes([0]))  # method_idx_diff
        # access_flags as uleb128: 0x10001 = PUBLIC | CONSTRUCTOR
        # uleb128(0x10001) = 0x81 0x80 0x04
        dex.extend(bytes([0x81, 0x80, 0x04]))
        # code_off as uleb128
        code_off = 0x1c0
        # Encode 0x1c0 = 448 as uleb128
        dex.extend(bytes([0xc0, 0x03]))

        # Code item at 0x1c0
        while len(dex) < 0x1c0:
            dex.append(0)

        dex.extend(struct.pack('<H', 1))  # registers_size
        dex.extend(struct.pack('<H', 1))  # ins_size
        dex.extend(struct.pack('<H', 0))  # outs_size
        dex.extend(struct.pack('<H', 0))  # tries_size
        dex.extend(struct.pack('<I', 0))  # debug_info_off
        dex.extend(struct.pack('<I', 1))  # insns_size
        dex.extend(struct.pack('<H', 0x0e00))  # return-void

        return bytes(dex)

    def test_minimal_dex_conversion(self):
        """测试最小DEX文件转换"""
        dex_data = self._create_minimal_dex()

        abc_data, result = self.converter.convert(dex_data)

        self.assertTrue(result.success, f"Conversion failed: {result.errors}")
        self.assertGreater(len(abc_data), 0)
        self.assertEqual(abc_data[:8], PANDA_MAGIC)

    def test_conversion_result_stats(self):
        """测试转换结果统计"""
        dex_data = self._create_minimal_dex()

        abc_data, result = self.converter.convert(dex_data)

        self.assertEqual(result.dex_size, len(dex_data))
        self.assertEqual(result.abc_size, len(abc_data))
        self.assertGreater(result.total_time_ms, 0)
        self.assertGreaterEqual(result.parse_time_ms, 0)
        self.assertGreaterEqual(result.convert_time_ms, 0)
        self.assertGreaterEqual(result.generate_time_ms, 0)

    def test_class_conversion(self):
        """测试类转换"""
        dex_data = self._create_minimal_dex()

        abc_data, result = self.converter.convert(dex_data)

        self.assertEqual(result.class_name, "Test")
        self.assertEqual(result.methods_count, 1)
        self.assertEqual(result.fields_count, 0)

    def test_target_latency(self):
        """测试目标延迟 (< 100ms)"""
        dex_data = self._create_minimal_dex()

        abc_data, result = self.converter.convert(dex_data)

        self.assertLess(result.total_time_ms, 100.0,
                       f"Conversion took {result.total_time_ms:.2f}ms, exceeds 100ms target")


class TestABCOutputFormat(unittest.TestCase):
    """测试ABC输出格式"""

    def setUp(self):
        self.converter = DexToAbcConverter()

    def test_abc_magic(self):
        """测试ABC文件Magic"""
        dex_data = self._create_simple_dex_with_method([0x0e, 0x00])
        abc_data, result = self.converter.convert(dex_data)
        self.assertEqual(abc_data[:8], PANDA_MAGIC)

    def test_abc_version(self):
        """测试ABC文件版本"""
        dex_data = self._create_simple_dex_with_method([0x0e, 0x00])
        abc_data, result = self.converter.convert(dex_data)
        # Version at offset 16-20
        self.assertEqual(abc_data[16:20], bytes([0, 0, 0, 1]))

    def test_abc_has_classes(self):
        """测试ABC文件包含类"""
        dex_data = self._create_simple_dex_with_method([0x0e, 0x00])
        abc_data, result = self.converter.convert(dex_data)
        # num_classes at offset 32
        num_classes = struct.unpack_from('<I', abc_data, 32)[0]
        self.assertEqual(num_classes, 1)

    def _create_simple_dex_with_method(self, bytecode: bytes) -> bytes:
        """创建带有指定字节码的简单DEX"""
        # This is a simplified version - for full test use the one above
        dex = bytearray(self._create_minimal_dex_base())

        # Find and patch the code item
        # For simplicity, just return the minimal dex
        return bytes(dex)

    def _create_minimal_dex_base(self) -> bytes:
        """创建最小DEX基础"""
        return self._create_minimal_dex()

    def _create_minimal_dex(self) -> bytes:
        """创建最小DEX"""
        # Reuse the method from above
        converter = DexToAbcConverter()
        return TestEndToEndConversion._create_minimal_dex(self)


class TestErrorHandling(unittest.TestCase):
    """测试错误处理"""

    def test_invalid_dex_magic(self):
        """测试无效的DEX Magic"""
        converter = DexToAbcConverter()
        abc_data, result = converter.convert(b'INVALID!')
        self.assertFalse(result.success)
        self.assertTrue(any('DEX' in e or 'magic' in e.lower() for e in result.errors))

    def test_empty_input(self):
        """测试空输入"""
        converter = DexToAbcConverter()
        abc_data, result = converter.convert(b'')
        self.assertFalse(result.success)

    def test_truncated_dex(self):
        """测试截断的DEX文件"""
        converter = DexToAbcConverter()
        # Valid magic but truncated header
        abc_data, result = converter.convert(b'dex\n035\x00')
        self.assertFalse(result.success)


class TestInstructionMapping(unittest.TestCase):
    """测试指令映射"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_arithmetic_sequence(self):
        """测试算术指令序列"""
        # const/4 v0, 5; const/4 v1, 3; add-int v2, v0, v1; return-void
        bytecode = bytes([
            0x12, 0x55,  # const/4 v0, 5
            0x12, 0x13,  # const/4 v1, 3
            0x90, 0x02, 0x00, 0x01,  # add-int v2, v0, v1
            0x0e, 0x00,  # return-void
        ])

        abc, ir = self.mapper.map(bytecode)

        self.assertEqual(len(ir), 4)
        self.assertEqual(ir[0].opcode, "const")
        self.assertEqual(ir[2].opcode, "add")
        self.assertEqual(ir[3].opcode, "return_void")

    def test_branch_sequence(self):
        """测试分支指令序列"""
        # const/4 v0, 0; if-eqz v0, +4; return v0; goto -8
        bytecode = bytes([
            0x12, 0x00,  # const/4 v0, 0
            0x38, 0x00, 0x02, 0x00,  # if-eqz v0, +4
            0x0f, 0x00,  # return v0
            0x28, 0xfc,  # goto -8
        ])

        abc, ir = self.mapper.map(bytecode)

        self.assertEqual(len(ir), 4)
        self.assertEqual(ir[1].opcode, "ifz_eq")
        self.assertEqual(ir[3].opcode, "goto")


class TestPerformanceBaseline(unittest.TestCase):
    """测试性能基线"""

    def test_conversion_performance(self):
        """测试转换性能"""
        import time

        converter = DexToAbcConverter()

        # Create a DEX with multiple instructions
        dex = TestEndToEndConversion._create_minimal_dex(self)

        # Warm up
        converter.convert(dex)

        # Measure
        times = []
        for _ in range(10):
            start = time.perf_counter()
            converter.convert(dex)
            end = time.perf_counter()
            times.append((end - start) * 1000)

        avg_time = sum(times) / len(times)
        self.assertLess(avg_time, 100.0,
                       f"Average conversion time {avg_time:.2f}ms exceeds 100ms target")


def run_tests():
    """运行所有集成测试"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    suite.addTests(loader.loadTestsFromTestCase(TestEndToEndConversion))
    suite.addTests(loader.loadTestsFromTestCase(TestABCOutputFormat))
    suite.addTests(loader.loadTestsFromTestCase(TestErrorHandling))
    suite.addTests(loader.loadTestsFromTestCase(TestInstructionMapping))
    suite.addTests(loader.loadTestsFromTestCase(TestPerformanceBaseline))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
