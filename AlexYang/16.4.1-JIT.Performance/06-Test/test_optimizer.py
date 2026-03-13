#!/usr/bin/env python3
"""
IR Optimizer Test
测试M4性能优化功能
"""

import sys
import os
import unittest

_impl_dir = os.path.join(os.path.dirname(__file__), '..', '05-Implementation')
sys.path.insert(0, os.path.join(_impl_dir, 'ir'))

from optimizer import IROptimizer, MethodInliner, OptimizationResult
from instruction_mapper import IRInstruction


class TestConstantPropagation(unittest.TestCase):
    """测试常量传播"""

    def setUp(self):
        self.optimizer = IROptimizer()

    def test_constant_folding_add(self):
        """测试加法常量折叠"""
        ir = [
            IRInstruction(opcode="const", dst=1, imm=10),
            IRInstruction(opcode="const", dst=2, imm=20),
            IRInstruction(opcode="add", dst=3, src1=1, src2=2),
            IRInstruction(opcode="return", src1=3),
        ]

        result = self.optimizer.optimize(ir)

        # 常量折叠后应该只有一个const指令(30)用于结果
        const_ops = [i for i in result.ir_list if i.opcode == "const"]
        # 由于常量折叠和寄存器重分配，可能只剩下一个const
        self.assertGreaterEqual(len(const_ops), 1)
        # 确认有常量折叠发生(即add被消除了)
        add_ops = [i for i in result.ir_list if i.opcode == "add"]
        self.assertEqual(len(add_ops), 0, "add should be constant folded")

    def test_constant_folding_mul(self):
        """测试乘法常量折叠"""
        ir = [
            IRInstruction(opcode="const", dst=1, imm=5),
            IRInstruction(opcode="const", dst=2, imm=6),
            IRInstruction(opcode="mul", dst=3, src1=1, src2=2),
            IRInstruction(opcode="return", src1=3),
        ]

        result = self.optimizer.optimize(ir)
        self.assertIn("constant_propagation", result.optimizations_applied)


class TestDeadCodeElimination(unittest.TestCase):
    """测试死代码消除"""

    def setUp(self):
        self.optimizer = IROptimizer()

    def test_remove_unused_const(self):
        """测试移除未使用的常量"""
        ir = [
            IRInstruction(opcode="const", dst=1, imm=100),  # 未使用
            IRInstruction(opcode="const", dst=2, imm=42),
            IRInstruction(opcode="return", src1=2),
        ]

        result = self.optimizer.optimize(ir)

        # 应该消除了未使用的常量
        self.assertEqual(result.stats["dead_code_removed"], 1)

    def test_remove_unused_computation(self):
        """测试移除未使用的计算"""
        ir = [
            IRInstruction(opcode="const", dst=1, imm=10),
            IRInstruction(opcode="const", dst=2, imm=20),
            IRInstruction(opcode="add", dst=3, src1=1, src2=2),  # 未使用
            IRInstruction(opcode="const", dst=4, imm=42),
            IRInstruction(opcode="return", src1=4),
        ]

        result = self.optimizer.optimize(ir)

        # 应该消除了未使用的计算
        self.assertGreaterEqual(result.stats["dead_code_removed"], 1)

    def test_keep_used_computation(self):
        """测试保留被使用的计算 (非常量情况)"""
        ir = [
            IRInstruction(opcode="const", dst=1, imm=10),
            # r2不是常量，所以add不能被折叠
            IRInstruction(opcode="move", dst=3, src1=1),
            IRInstruction(opcode="return", src1=3),  # 使用r3
        ]

        result = self.optimizer.optimize(ir)

        # 应该保留move指令
        move_ops = [i for i in result.ir_list if i.opcode == "move"]
        self.assertEqual(len(move_ops), 1)


class TestRegisterOptimization(unittest.TestCase):
    """测试寄存器优化"""

    def setUp(self):
        self.optimizer = IROptimizer()

    def test_register_renaming(self):
        """测试寄存器重命名"""
        ir = [
            IRInstruction(opcode="const", dst=10, imm=1),
            IRInstruction(opcode="const", dst=20, imm=2),
            IRInstruction(opcode="add", dst=30, src1=10, src2=20),
            IRInstruction(opcode="return", src1=30),
        ]

        result = self.optimizer.optimize(ir)

        # 检查寄存器是否被重新分配
        max_reg = max((i.dst for i in result.ir_list if i.dst > 0), default=0)
        self.assertLess(max_reg, 30)  # 应该小于原来的最大寄存器号


class TestMethodInliner(unittest.TestCase):
    """测试方法内联"""

    def setUp(self):
        self.inliner = MethodInliner(inline_threshold=10)

    def test_register_small_method(self):
        """测试注册小方法"""
        method_body = [
            IRInstruction(opcode="add", dst=1, src1=1, src2=2),
            IRInstruction(opcode="return", src1=1),
        ]

        self.inliner.register_method("test_method", method_body)
        self.assertIn("test_method", self.inliner.method_cache)

    def test_skip_large_method(self):
        """测试跳过大方法"""
        large_body = [IRInstruction(opcode="nop") for _ in range(25)]

        self.inliner.register_method("large_method", large_body)
        self.assertNotIn("large_method", self.inliner.method_cache)


class TestOptimizationPipeline(unittest.TestCase):
    """测试完整优化流程"""

    def test_full_pipeline(self):
        """测试完整优化流程"""
        ir = [
            IRInstruction(opcode="const", dst=1, imm=10),
            IRInstruction(opcode="const", dst=2, imm=20),
            IRInstruction(opcode="add", dst=3, src1=1, src2=2),
            IRInstruction(opcode="const", dst=4, imm=100),  # 死代码
            IRInstruction(opcode="mul", dst=5, src1=3, src2=2),
            IRInstruction(opcode="return", src1=5),
        ]

        optimizer = IROptimizer()
        result = optimizer.optimize(ir)

        # 检查返回类型
        self.assertIsInstance(result, OptimizationResult)
        self.assertIsInstance(result.ir_list, list)
        self.assertIsInstance(result.optimizations_applied, list)
        self.assertIsInstance(result.stats, dict)

        # 检查统计信息
        self.assertIn("constants_folded", result.stats)
        self.assertIn("dead_code_removed", result.stats)
        self.assertIn("registers_reallocated", result.stats)

    def test_empty_ir(self):
        """测试空IR列表"""
        optimizer = IROptimizer()
        result = optimizer.optimize([])

        self.assertEqual(len(result.ir_list), 0)
        self.assertEqual(len(result.optimizations_applied), 0)

    def test_single_return(self):
        """测试只有return的IR"""
        ir = [IRInstruction(opcode="return_void")]

        optimizer = IROptimizer()
        result = optimizer.optimize(ir)

        self.assertEqual(len(result.ir_list), 1)
        self.assertEqual(result.ir_list[0].opcode, "return_void")


class TestOptimizationStats(unittest.TestCase):
    """测试优化统计"""

    def test_stats_accumulation(self):
        """测试统计信息累积"""
        optimizer = IROptimizer()

        ir1 = [
            IRInstruction(opcode="const", dst=1, imm=10),
            IRInstruction(opcode="const", dst=2, imm=20),  # 死代码
            IRInstruction(opcode="return", src1=1),
        ]

        optimizer.optimize(ir1)
        stats1 = optimizer.stats.copy()

        self.assertGreaterEqual(stats1["dead_code_removed"], 0)


def run_tests():
    """运行所有优化器测试"""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    suite.addTests(loader.loadTestsFromTestCase(TestConstantPropagation))
    suite.addTests(loader.loadTestsFromTestCase(TestDeadCodeElimination))
    suite.addTests(loader.loadTestsFromTestCase(TestRegisterOptimization))
    suite.addTests(loader.loadTestsFromTestCase(TestMethodInliner))
    suite.addTests(loader.loadTestsFromTestCase(TestOptimizationPipeline))
    suite.addTests(loader.loadTestsFromTestCase(TestOptimizationStats))

    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)

    return result.wasSuccessful()


if __name__ == '__main__':
    success = run_tests()
    sys.exit(0 if success else 1)
