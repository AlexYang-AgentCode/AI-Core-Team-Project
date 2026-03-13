#!/usr/bin/env python3
"""
M3 Advanced Features Test
测试M3高级特性：异常处理、反射、泛型、Lambda
"""

import sys
import os
import unittest

_impl_dir = os.path.join(os.path.dirname(__file__), '..', '05-Implementation')
sys.path.insert(0, os.path.join(_impl_dir, 'ir'))

from instruction_mapper import InstructionMapper, DexOp, PandaOp, IRInstruction


class TestExceptionHandling(unittest.TestCase):
    """测试异常处理"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_move_exception(self):
        """测试MOVE_EXCEPTION指令"""
        # move-exception v0 -> 0x0d 0x00
        abc, ir = self.mapper.map(bytes([0x0d, 0x00]))
        self.assertEqual(ir[0].opcode, "move_exception")
        self.assertEqual(ir[0].dst, 0)

    def test_throw(self):
        """测试THROW指令"""
        # throw v0 -> 0x27 0x00
        abc, ir = self.mapper.map(bytes([0x27, 0x00]))
        self.assertEqual(ir[0].opcode, "throw")
        self.assertEqual(ir[0].src1, 0)

    def test_try_catch_processing(self):
        """测试try-catch块处理"""
        # Simple bytecode with try block
        bytecode = bytes([
            0x01, 0x10,  # move v0, v1
            0x90, 0x00, 0x01, 0x02,  # add-int v0, v1, v2
            0x0e, 0x00,  # return-void
        ])

        # Try block: offset 0-6, catches java/lang/Exception at offset 8
        tries = [(0, 6, "Ljava/lang/Exception;", 8)]

        abc, ir_list = self.mapper.map(bytecode, tries)

        # Check that try block info was processed
        has_try_info = any(ir.try_start > 0 or ir.try_end > 0 for ir in ir_list)
        self.assertTrue(has_try_info or len(ir_list) > 3)  # Should have catch instruction added


class TestReflectionSupport(unittest.TestCase):
    """测试反射支持"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_const_class(self):
        """测试CONST_CLASS指令"""
        # const-class v0, type@0x1234 -> 0x1c 0x00 0x34 0x12
        abc, ir = self.mapper.map(bytes([0x1c, 0x00, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "const_class")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].imm, 0x1234)

    def test_check_cast(self):
        """测试CHECK_CAST指令"""
        # check-cast v0, type@0x1234 -> 0x1f 0x00 0x34 0x12
        abc, ir = self.mapper.map(bytes([0x1f, 0x00, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "check_cast")
        self.assertEqual(ir[0].src1, 0)

    def test_instance_of(self):
        """测试INSTANCE_OF指令"""
        # instance-of v0, v1, type@0x1234 -> 0x20 0x10 0x34 0x12 (B=1 in high nibble, A=0 in low nibble)
        abc, ir = self.mapper.map(bytes([0x20, 0x10, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "instance_of")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].src1, 1)


class TestGenericSupport(unittest.TestCase):
    """测试泛型支持 (类型擦除处理)"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_new_array_generic(self):
        """测试泛型数组创建"""
        # new-array v0, v1, type@0x1234 -> 0x23 0x10 0x34 0x12 (B=1 in high nibble, A=0 in low nibble)
        abc, ir = self.mapper.map(bytes([0x23, 0x10, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "new_array")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].src1, 1)

    def test_iget_object(self):
        """测试对象字段获取 (泛型擦除后)"""
        # iget-object v0, v1, field@0x1234 -> 0x54 0x01 0x34 0x12
        abc, ir = self.mapper.map(bytes([0x54, 0x01, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "iget")

    def test_iput_object(self):
        """测试对象字段设置 (泛型擦除后)"""
        # iput-object v0, v1, field@0x1234 -> 0x5b 0x01 0x34 0x12
        abc, ir = self.mapper.map(bytes([0x5b, 0x01, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "iput")


class TestLambdaSupport(unittest.TestCase):
    """测试Lambda表达式支持 (invokedynamic)"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_invoke_static_for_lambda(self):
        """测试用于Lambda的静态方法调用"""
        # Lambda expressions compile to static method invocations
        # invoke-static {v0, v1}, method@0x1234 -> 0x71 0x21 0x34 0x12 0x00 0x00 (6 bytes)
        abc, ir = self.mapper.map(bytes([0x71, 0x21, 0x34, 0x12, 0x00, 0x00]))
        self.assertEqual(ir[0].opcode, "invoke_static")

    def test_new_instance_for_lambda(self):
        """测试Lambda匿名类实例创建"""
        # new-instance v0, type@0x1234 -> 0x22 0x00 0x34 0x12
        abc, ir = self.mapper.map(bytes([0x22, 0x00, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "new_instance")


class TestMonitorSync(unittest.TestCase):
    """测试同步机制"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_monitor_enter(self):
        """测试MONITOR_ENTER指令"""
        # monitor-enter v0 -> 0x1d 0x00
        abc, ir = self.mapper.map(bytes([0x1d, 0x00]))
        self.assertEqual(ir[0].opcode, "monitor_enter")
        self.assertEqual(ir[0].src1, 0)

    def test_monitor_exit(self):
        """测试MONITOR_EXIT指令"""
        # monitor-exit v0 -> 0x1e 0x00
        abc, ir = self.mapper.map(bytes([0x1e, 0x00]))
        self.assertEqual(ir[0].opcode, "monitor_exit")
        self.assertEqual(ir[0].src1, 0)


class TestWideTypeOperations(unittest.TestCase):
    """测试64位宽类型操作"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_const_wide_16(self):
        """测试CONST_WIDE_16指令"""
        # const-wide/16 v0, #long 10 -> 0x16 0x00 0x0a 0x00
        abc, ir = self.mapper.map(bytes([0x16, 0x00, 0x0a, 0x00]))
        self.assertEqual(ir[0].opcode, "const")
        self.assertEqual(ir[0].width, 64)

    def test_const_wide_32(self):
        """测试CONST_WIDE_32指令"""
        # const-wide/32 v0, #long 0x12345678 -> 0x17 0x00 ...
        abc, ir = self.mapper.map(bytes([0x17, 0x00, 0x78, 0x56, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "const")
        self.assertEqual(ir[0].width, 64)

    def test_aget_wide(self):
        """测试AGET_WIDE指令"""
        # aget-wide v0, v1, v2 -> 0x45 0x00 0x01 0x02
        abc, ir = self.mapper.map(bytes([0x45, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "aget")
        self.assertEqual(ir[0].width, 64)

    def test_aput_wide(self):
        """测试APUT_WIDE指令"""
        # aput-wide v0, v1, v2 -> 0x4c 0x00 0x01 0x02
        abc, ir = self.mapper.map(bytes([0x4c, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "aput")
        self.assertEqual(ir[0].width, 64)


class TestInvokeRange(unittest.TestCase):
    """测试range调用指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_invoke_virtual_range(self):
        """测试INVOKE_VIRTUAL_RANGE指令"""
        # invoke-virtual/range {v0..v2}, method@0x1234 -> 0x74 0x03 0x34 0x12 0x00 0x00
        abc, ir = self.mapper.map(bytes([0x74, 0x03, 0x34, 0x12, 0x00, 0x00]))
        self.assertEqual(ir[0].opcode, "invoke_virtual")
        self.assertEqual(ir[0].imm, 3)  # 3 arguments

    def test_invoke_static_range(self):
        """测试INVOKE_STATIC_RANGE指令"""
        # invoke-static/range {v0..v1}, method@0x1234 -> 0x77 0x02 0x34 0x12 0x00 0x00
        abc, ir = self.mapper.map(bytes([0x77, 0x02, 0x34, 0x12, 0x00, 0x00]))
        self.assertEqual(ir[0].opcode, "invoke_static")


def run_tests():
    """运行所有M3特性测试"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    suite.addTests(loader.loadTestsFromTestCase(TestExceptionHandling))
    suite.addTests(loader.loadTestsFromTestCase(TestReflectionSupport))
    suite.addTests(loader.loadTestsFromTestCase(TestGenericSupport))
    suite.addTests(loader.loadTestsFromTestCase(TestLambdaSupport))
    suite.addTests(loader.loadTestsFromTestCase(TestMonitorSync))
    suite.addTests(loader.loadTestsFromTestCase(TestWideTypeOperations))
    suite.addTests(loader.loadTestsFromTestCase(TestInvokeRange))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
