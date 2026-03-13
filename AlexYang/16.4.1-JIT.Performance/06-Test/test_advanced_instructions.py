#!/usr/bin/env python3
"""
Advanced Instructions Test
测试浮点运算、类型转换、switch等高级指令
"""

import sys
import os
import struct
import unittest

_impl_dir = os.path.join(os.path.dirname(__file__), '..', '05-Implementation')
sys.path.insert(0, os.path.join(_impl_dir, 'ir'))

from instruction_mapper import InstructionMapper, DexOp, PandaOp, IRInstruction


class TestFloatOperations(unittest.TestCase):
    """测试浮点运算指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_add_float(self):
        """测试ADD_FLOAT指令"""
        # add-float v0, v1, v2 -> 0xa6 0x00 0x01 0x02
        abc, ir = self.mapper.map(bytes([0xa6, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "fadd")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].src1, 1)
        self.assertEqual(ir[0].src2, 2)
        self.assertTrue(ir[0].is_float)

    def test_sub_float(self):
        """测试SUB_FLOAT指令"""
        abc, ir = self.mapper.map(bytes([0xa7, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "fsub")

    def test_mul_float(self):
        """测试MUL_FLOAT指令"""
        abc, ir = self.mapper.map(bytes([0xa8, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "fmul")

    def test_div_float(self):
        """测试DIV_FLOAT指令"""
        abc, ir = self.mapper.map(bytes([0xa9, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "fdiv")

    def test_add_double(self):
        """测试ADD_DOUBLE指令"""
        # add-double v0, v1, v2 -> 0xab 0x00 0x01 0x02
        abc, ir = self.mapper.map(bytes([0xab, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "dadd")
        self.assertEqual(ir[0].width, 64)
        self.assertTrue(ir[0].is_float)


class TestTypeConversions(unittest.TestCase):
    """测试类型转换指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_int_to_long(self):
        """测试INT_TO_LONG指令"""
        # int-to-long v0, v1 -> 0x81 0x10
        abc, ir = self.mapper.map(bytes([0x81, 0x10]))
        self.assertEqual(ir[0].opcode, "cast")
        self.assertEqual(ir[0].cast_type, "i2l")

    def test_int_to_float(self):
        """测试INT_TO_FLOAT指令"""
        abc, ir = self.mapper.map(bytes([0x82, 0x10]))
        self.assertEqual(ir[0].cast_type, "i2f")

    def test_int_to_double(self):
        """测试INT_TO_DOUBLE指令"""
        abc, ir = self.mapper.map(bytes([0x83, 0x10]))
        self.assertEqual(ir[0].cast_type, "i2d")

    def test_long_to_int(self):
        """测试LONG_TO_INT指令"""
        abc, ir = self.mapper.map(bytes([0x84, 0x10]))
        self.assertEqual(ir[0].cast_type, "l2i")

    def test_float_to_int(self):
        """测试FLOAT_TO_INT指令"""
        abc, ir = self.mapper.map(bytes([0x87, 0x10]))
        self.assertEqual(ir[0].cast_type, "f2i")

    def test_double_to_float(self):
        """测试DOUBLE_TO_FLOAT指令"""
        abc, ir = self.mapper.map(bytes([0x8c, 0x10]))
        self.assertEqual(ir[0].cast_type, "d2f")

    def test_int_to_byte(self):
        """测试INT_TO_BYTE指令"""
        abc, ir = self.mapper.map(bytes([0x8d, 0x10]))
        self.assertEqual(ir[0].cast_type, "i2b")

    def test_int_to_char(self):
        """测试INT_TO_CHAR指令"""
        abc, ir = self.mapper.map(bytes([0x8e, 0x10]))
        self.assertEqual(ir[0].cast_type, "i2c")


class TestSwitchInstructions(unittest.TestCase):
    """测试switch指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_packed_switch(self):
        """测试PACKED_SWITCH指令"""
        # packed-switch v0, +0x100 -> 0x2b 0x00 0x80 0x00 0x00 0x00
        abc, ir = self.mapper.map(bytes([0x2b, 0x00, 0x80, 0x00, 0x00, 0x00]))
        self.assertEqual(ir[0].opcode, "packed_switch")
        self.assertEqual(ir[0].src1, 0)

    def test_sparse_switch(self):
        """测试SPARSE_SWITCH指令"""
        abc, ir = self.mapper.map(bytes([0x2c, 0x00, 0x80, 0x00, 0x00, 0x00]))
        self.assertEqual(ir[0].opcode, "sparse_switch")


class TestArrayFillInstructions(unittest.TestCase):
    """测试数组填充指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_filled_new_array(self):
        """测试FILLED_NEW_ARRAY指令"""
        # filled-new-array {v0, v1}, type@0x1234
        abc, ir = self.mapper.map(bytes([0x24, 0x21, 0x34, 0x12, 0x00, 0x00]))
        self.assertEqual(ir[0].opcode, "filled_new_array")

    def test_filled_new_array_range(self):
        """测试FILLED_NEW_ARRAY_RANGE指令"""
        # filled-new-array/range {v0..v2}, type@0x1234
        abc, ir = self.mapper.map(bytes([0x25, 0x03, 0x34, 0x12, 0x00, 0x00]))
        self.assertEqual(ir[0].opcode, "filled_new_array_range")

    def test_fill_array_data(self):
        """测试FILL_ARRAY_DATA指令"""
        abc, ir = self.mapper.map(bytes([0x26, 0x00, 0x80, 0x00, 0x00, 0x00]))
        self.assertEqual(ir[0].opcode, "fill_array_data")


class TestLongOperations(unittest.TestCase):
    """测试64位长整型运算"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_add_long(self):
        """测试ADD_LONG指令"""
        abc, ir = self.mapper.map(bytes([0x9b, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "add")
        self.assertEqual(ir[0].width, 64)

    def test_sub_long(self):
        """测试SUB_LONG指令"""
        abc, ir = self.mapper.map(bytes([0x9c, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "sub")
        self.assertEqual(ir[0].width, 64)

    def test_mul_long(self):
        """测试MUL_LONG指令"""
        abc, ir = self.mapper.map(bytes([0x9d, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "mul")
        self.assertEqual(ir[0].width, 64)


class TestFloat2AddrOperations(unittest.TestCase):
    """测试浮点2地址运算"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_add_float_2addr(self):
        """测试ADD_FLOAT_2ADDR指令"""
        # add-float/2addr v0, v1 -> 0xc6 0x10
        abc, ir = self.mapper.map(bytes([0xc6, 0x10]))
        self.assertEqual(ir[0].opcode, "fadd")
        self.assertTrue(ir[0].is_float)

    def test_add_double_2addr(self):
        """测试ADD_DOUBLE_2ADDR指令"""
        abc, ir = self.mapper.map(bytes([0xcb, 0x10]))
        self.assertEqual(ir[0].opcode, "dadd")
        self.assertEqual(ir[0].width, 64)


def run_tests():
    """运行所有高级指令测试"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    suite.addTests(loader.loadTestsFromTestCase(TestFloatOperations))
    suite.addTests(loader.loadTestsFromTestCase(TestTypeConversions))
    suite.addTests(loader.loadTestsFromTestCase(TestSwitchInstructions))
    suite.addTests(loader.loadTestsFromTestCase(TestArrayFillInstructions))
    suite.addTests(loader.loadTestsFromTestCase(TestLongOperations))
    suite.addTests(loader.loadTestsFromTestCase(TestFloat2AddrOperations))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
