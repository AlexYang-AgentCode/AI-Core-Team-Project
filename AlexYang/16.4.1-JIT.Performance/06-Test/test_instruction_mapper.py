#!/usr/bin/env python3
"""
Instruction Mapper Unit Tests
测试 DEX → IR → ABC 指令映射的正确性
"""

import sys
import os
import struct
import unittest

# 添加模块路径
_impl_dir = os.path.join(os.path.dirname(__file__), '..', '05-Implementation')
sys.path.insert(0, os.path.join(_impl_dir, 'ir'))

from instruction_mapper import InstructionMapper, DexOp, PandaOp, IRInstruction


class TestDexDecoding(unittest.TestCase):
    """测试DEX指令解码"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_nop(self):
        """测试NOP指令"""
        abc, ir = self.mapper.map(bytes([0x00, 0x00]))
        self.assertEqual(len(ir), 1)
        self.assertEqual(ir[0].opcode, "nop")

    def test_return_void(self):
        """测试RETURN_VOID指令"""
        abc, ir = self.mapper.map(bytes([0x0e, 0x00]))
        self.assertEqual(ir[0].opcode, "return_void")
        self.assertEqual(abc[0], PandaOp.RETURN_VOID)

    def test_return(self):
        """测试RETURN指令"""
        abc, ir = self.mapper.map(bytes([0x0f, 0x02]))
        self.assertEqual(ir[0].opcode, "return")
        self.assertEqual(ir[0].src1, 2)

    def test_const_4(self):
        """测试CONST_4指令"""
        # const/4 v0, 5  -> 0x12 0x50
        abc, ir = self.mapper.map(bytes([0x12, 0x50]))
        self.assertEqual(ir[0].opcode, "const")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].imm, 5)

    def test_const_4_negative(self):
        """测试CONST_4负数"""
        # const/4 v0, -1 -> 0x12 0xf0
        # Format: high nibble = value (4-bit signed), low nibble = dst
        # -1 in 4-bit signed = 0xf, dst = 0, so byte = 0xf0
        abc, ir = self.mapper.map(bytes([0x12, 0xf0]))
        # v = (0xf0 >> 4) & 0xf = 0xf = 15, then 15 - 16 = -1
        self.assertEqual(ir[0].imm, -1)

    def test_const_16(self):
        """测试CONST_16指令"""
        # const/16 v0, 1000 -> 0x13 0x00 0xe8 0x03
        abc, ir = self.mapper.map(bytes([0x13, 0x00, 0xe8, 0x03]))
        self.assertEqual(ir[0].opcode, "const")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].imm, 1000)

    def test_move(self):
        """测试MOVE指令"""
        # move v0, v1 -> 0x01 0x10
        abc, ir = self.mapper.map(bytes([0x01, 0x10]))
        self.assertEqual(ir[0].opcode, "move")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].src1, 1)


class TestArithmetic(unittest.TestCase):
    """测试算术运算指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_add_int(self):
        """测试ADD_INT指令"""
        # add-int v0, v1, v2 -> 0x90 0x00 0x01 0x02
        abc, ir = self.mapper.map(bytes([0x90, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "add")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].src1, 1)
        self.assertEqual(ir[0].src2, 2)

    def test_sub_int(self):
        """测试SUB_INT指令"""
        abc, ir = self.mapper.map(bytes([0x91, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "sub")

    def test_mul_int(self):
        """测试MUL_INT指令"""
        abc, ir = self.mapper.map(bytes([0x92, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "mul")

    def test_div_int(self):
        """测试DIV_INT指令"""
        abc, ir = self.mapper.map(bytes([0x93, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "div")

    def test_rem_int(self):
        """测试REM_INT指令"""
        abc, ir = self.mapper.map(bytes([0x94, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "rem")

    def test_and_int(self):
        """测试AND_INT指令"""
        abc, ir = self.mapper.map(bytes([0x95, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "and")

    def test_or_int(self):
        """测试OR_INT指令"""
        abc, ir = self.mapper.map(bytes([0x96, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "or")

    def test_xor_int(self):
        """测试XOR_INT指令"""
        abc, ir = self.mapper.map(bytes([0x97, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "xor")

    def test_shl_int(self):
        """测试SHL_INT指令"""
        abc, ir = self.mapper.map(bytes([0x98, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "shl")

    def test_shr_int(self):
        """测试SHR_INT指令"""
        abc, ir = self.mapper.map(bytes([0x99, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "shr")

    def test_add_int_2addr(self):
        """测试ADD_INT_2ADDR指令"""
        # add-int/2addr v0, v1 -> 0xb0 0x10
        abc, ir = self.mapper.map(bytes([0xb0, 0x10]))
        self.assertEqual(ir[0].opcode, "add")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].src1, 0)  # dst is also src1
        self.assertEqual(ir[0].src2, 1)

    def test_add_long(self):
        """测试ADD_LONG指令"""
        abc, ir = self.mapper.map(bytes([0x9b, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "add")
        self.assertEqual(ir[0].width, 64)


class TestBranchInstructions(unittest.TestCase):
    """测试分支指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_goto(self):
        """测试GOTO指令"""
        # goto +4 -> 0x28 0x02 (offset is 2, multiplied by 2 = 4 bytes)
        abc, ir = self.mapper.map(bytes([0x28, 0x02]))
        self.assertEqual(ir[0].opcode, "goto")
        self.assertEqual(ir[0].imm, 4)

    def test_goto_negative(self):
        """测试GOTO负偏移"""
        # goto -4 -> 0x28 0xfe
        abc, ir = self.mapper.map(bytes([0x28, 0xfe]))
        self.assertEqual(ir[0].imm, -4)

    def test_if_eq(self):
        """测试IF_EQ指令"""
        # if-eq v0, v1, +6 -> 0x32 0x10 0x03 0x00
        abc, ir = self.mapper.map(bytes([0x32, 0x10, 0x03, 0x00]))
        self.assertEqual(ir[0].opcode, "if_eq")
        self.assertEqual(ir[0].src1, 0)
        self.assertEqual(ir[0].src2, 1)
        self.assertEqual(ir[0].imm, 6)

    def test_if_ne(self):
        """测试IF_NE指令"""
        abc, ir = self.mapper.map(bytes([0x33, 0x10, 0x03, 0x00]))
        self.assertEqual(ir[0].opcode, "if_ne")

    def test_if_lt(self):
        """测试IF_LT指令"""
        abc, ir = self.mapper.map(bytes([0x34, 0x10, 0x03, 0x00]))
        self.assertEqual(ir[0].opcode, "if_lt")

    def test_if_ge(self):
        """测试IF_GE指令"""
        abc, ir = self.mapper.map(bytes([0x35, 0x10, 0x03, 0x00]))
        self.assertEqual(ir[0].opcode, "if_ge")

    def test_if_eqz(self):
        """测试IF_EQZ指令"""
        # if-eqz v0, +4 -> 0x38 0x00 0x02 0x00
        abc, ir = self.mapper.map(bytes([0x38, 0x00, 0x02, 0x00]))
        self.assertEqual(ir[0].opcode, "ifz_eq")
        self.assertEqual(ir[0].src1, 0)
        self.assertEqual(ir[0].imm, 4)


class TestFieldAccess(unittest.TestCase):
    """测试字段访问指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_iget(self):
        """测试IGET指令"""
        # iget v0, v1, field@0x1234 -> 0x52 0x10 0x34 0x12
        abc, ir = self.mapper.map(bytes([0x52, 0x10, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "iget")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].src1, 1)
        self.assertEqual(ir[0].field_ref, 0x1234)

    def test_iput(self):
        """测试IPUT指令"""
        # iput v0, v1, field@0x1234 -> 0x59 0x01 0x34 0x12
        # Format: op AA BB CC where AA = (obj<<4)|src, BB CC = field_idx
        # 0x01 = (0<<4)|1 means obj=v0, src=v1
        # Decode: src = b1&0xf = 1, obj = (b1>>4)&0xf = 0
        abc, ir = self.mapper.map(bytes([0x59, 0x01, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "iput")
        self.assertEqual(ir[0].src1, 1)  # src = 0x01 & 0xf = 1
        self.assertEqual(ir[0].src2, 0)  # obj = (0x01 >> 4) & 0xf = 0

    def test_sget(self):
        """测试SGET指令"""
        # sget v0, field@0x1234 -> 0x60 0x00 0x34 0x12
        abc, ir = self.mapper.map(bytes([0x60, 0x00, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "sget")
        self.assertEqual(ir[0].dst, 0)

    def test_sput(self):
        """测试SPUT指令"""
        # sput v0, field@0x1234 -> 0x67 0x00 0x34 0x12
        abc, ir = self.mapper.map(bytes([0x67, 0x00, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "sput")


class TestArrayInstructions(unittest.TestCase):
    """测试数组指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_array_length(self):
        """测试ARRAY_LENGTH指令"""
        # array-length v0, v1 -> 0x21 0x10
        abc, ir = self.mapper.map(bytes([0x21, 0x10]))
        self.assertEqual(ir[0].opcode, "array_length")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].src1, 1)

    def test_new_array(self):
        """测试NEW_ARRAY指令"""
        # new-array v0, v1, type@0x1234 -> 0x23 0x10 0x34 0x12
        abc, ir = self.mapper.map(bytes([0x23, 0x10, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "new_array")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].src1, 1)

    def test_aget(self):
        """测试AGET指令"""
        # aget v0, v1, v2 -> 0x44 0x00 0x01 0x02
        abc, ir = self.mapper.map(bytes([0x44, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "aget")
        self.assertEqual(ir[0].dst, 0)
        self.assertEqual(ir[0].src1, 1)
        self.assertEqual(ir[0].src2, 2)

    def test_aput(self):
        """测试APUT指令"""
        # aput v0, v1, v2 -> 0x4b 0x00 0x01 0x02
        abc, ir = self.mapper.map(bytes([0x4b, 0x00, 0x01, 0x02]))
        self.assertEqual(ir[0].opcode, "aput")


class TestTypeInstructions(unittest.TestCase):
    """测试类型相关指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_new_instance(self):
        """测试NEW_INSTANCE指令"""
        # new-instance v0, type@0x1234 -> 0x22 0x00 0x34 0x12
        abc, ir = self.mapper.map(bytes([0x22, 0x00, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "new_instance")
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
        # instance-of v0, v1, type@0x1234 -> 0x20 0x01 0x34 0x12
        # Format: dst in low 4 bits, src in high 4 bits of second byte
        abc, ir = self.mapper.map(bytes([0x20, 0x01, 0x34, 0x12]))
        self.assertEqual(ir[0].opcode, "instance_of")
        # 0x01: dst = 0x01 & 0x0f = 1, src = (0x01 >> 4) & 0x0f = 0
        self.assertEqual(ir[0].dst, 1)
        self.assertEqual(ir[0].src1, 0)


class TestInvokeInstructions(unittest.TestCase):
    """测试方法调用指令"""

    def setUp(self):
        self.mapper = InstructionMapper()

    def test_invoke_virtual(self):
        """测试INVOKE_VIRTUAL指令"""
        # invoke-virtual {v0, v1}, method@0x1234 -> 0x6e 0x21 0x34 0x12 0x00 0x00
        abc, ir = self.mapper.map(bytes([0x6e, 0x21, 0x34, 0x12, 0x00, 0x00]))
        self.assertEqual(ir[0].opcode, "invoke_virtual")
        self.assertEqual(ir[0].imm, 2)  # arg count
        self.assertEqual(ir[0].method_ref, 0x1234)

    def test_invoke_static(self):
        """测试INVOKE_STATIC指令"""
        abc, ir = self.mapper.map(bytes([0x71, 0x21, 0x34, 0x12, 0x00, 0x00]))
        self.assertEqual(ir[0].opcode, "invoke_static")

    def test_invoke_direct(self):
        """测试INVOKE_DIRECT指令"""
        abc, ir = self.mapper.map(bytes([0x70, 0x21, 0x34, 0x12, 0x00, 0x00]))
        self.assertIn("invoke", ir[0].opcode)


class TestABCGeneration(unittest.TestCase):
    """测试ABC字节码生成"""

    def test_return_void_generates_correct_opcode(self):
        """测试RETURN_VOID生成正确的Panda操作码"""
        mapper = InstructionMapper()
        abc, ir = mapper.map(bytes([0x0e, 0x00]))
        self.assertEqual(abc[0], PandaOp.RETURN_VOID)

    def test_const_generates_panda_instructions(self):
        """测试const生成Panda指令序列"""
        mapper = InstructionMapper()
        abc, ir = mapper.map(bytes([0x12, 0x55]))  # const/4 v0, 5
        # Should generate MOVI_v4_imm4 or similar
        self.assertTrue(len(abc) > 0)

    def test_arithmetic_generates_sequence(self):
        """测试算术运算生成正确的指令序列"""
        mapper = InstructionMapper()
        abc, ir = mapper.map(bytes([0x90, 0x00, 0x01, 0x02]))  # add-int
        # Should generate: LDA, ADD2, STA
        self.assertTrue(len(abc) >= 3)


class TestEdgeCases(unittest.TestCase):
    """测试边界情况"""

    def test_empty_bytecode(self):
        """测试空字节码"""
        mapper = InstructionMapper()
        abc, ir = mapper.map(b'')
        self.assertEqual(len(ir), 0)
        self.assertEqual(len(abc), 0)

    def test_unknown_opcode(self):
        """测试未知操作码"""
        mapper = InstructionMapper()
        abc, ir = mapper.map(bytes([0xff, 0x00]))  # undefined opcode
        # Should handle gracefully (nop or skip)
        self.assertEqual(len(ir), 1)

    def test_truncated_instruction(self):
        """测试截断的指令"""
        mapper = InstructionMapper()
        # 4-byte instruction with only 2 bytes
        abc, ir = mapper.map(bytes([0x90, 0x00]))
        # Should handle gracefully
        self.assertEqual(len(ir), 1)


class TestStats(unittest.TestCase):
    """测试统计功能"""

    def test_stats_collected(self):
        """测试统计数据收集"""
        mapper = InstructionMapper()
        abc, ir = mapper.map(bytes([0x0e, 0x00, 0x0f, 0x00]))
        stats = mapper.get_stats()
        self.assertEqual(stats["total_dex_instructions"], 2)
        self.assertEqual(stats["mapped_instructions"], 2)

    def test_mapping_rate(self):
        """测试映射率计算"""
        mapper = InstructionMapper()
        abc, ir = mapper.map(bytes([0x0e, 0x00]))
        stats = mapper.get_stats()
        self.assertIn("mapping_rate", stats)
        self.assertIn("%", stats["mapping_rate"])


def run_tests():
    """运行所有测试"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # 添加所有测试类
    suite.addTests(loader.loadTestsFromTestCase(TestDexDecoding))
    suite.addTests(loader.loadTestsFromTestCase(TestArithmetic))
    suite.addTests(loader.loadTestsFromTestCase(TestBranchInstructions))
    suite.addTests(loader.loadTestsFromTestCase(TestFieldAccess))
    suite.addTests(loader.loadTestsFromTestCase(TestArrayInstructions))
    suite.addTests(loader.loadTestsFromTestCase(TestTypeInstructions))
    suite.addTests(loader.loadTestsFromTestCase(TestInvokeInstructions))
    suite.addTests(loader.loadTestsFromTestCase(TestABCGeneration))
    suite.addTests(loader.loadTestsFromTestCase(TestEdgeCases))
    suite.addTests(loader.loadTestsFromTestCase(TestStats))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
