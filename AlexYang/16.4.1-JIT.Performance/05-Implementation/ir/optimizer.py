#!/usr/bin/env python3
"""
IR Optimizer - M4阶段性能优化

优化策略：
1. 常量传播 (Constant Propagation)
2. 死代码消除 (Dead Code Elimination)
3. 寄存器分配优化 (Register Allocation)
4. 方法内联 (Method Inlining)
"""

from typing import List, Dict, Set, Optional, Tuple
from dataclasses import dataclass
from instruction_mapper import IRInstruction


@dataclass
class OptimizationResult:
    """优化结果"""
    ir_list: List[IRInstruction]
    optimizations_applied: List[str]
    stats: Dict[str, int]


class IROptimizer:
    """IR优化器"""

    def __init__(self):
        self.optimizations_applied = []
        self.stats = {
            "constants_folded": 0,
            "dead_code_removed": 0,
            "registers_reallocated": 0,
            "instructions_inlined": 0,
        }

    def optimize(self, ir_list: List[IRInstruction]) -> OptimizationResult:
        """
        执行完整的优化流程

        Args:
            ir_list: 原始IR指令列表

        Returns:
            OptimizationResult: 优化后的结果
        """
        self.optimizations_applied = []
        optimized = ir_list.copy()

        # Phase 1: 常量传播
        optimized = self._constant_propagation(optimized)

        # Phase 2: 死代码消除
        optimized = self._dead_code_elimination(optimized)

        # Phase 3: 寄存器分配优化
        optimized = self._optimize_registers(optimized)

        return OptimizationResult(
            ir_list=optimized,
            optimizations_applied=self.optimizations_applied,
            stats=self.stats.copy()
        )

    def _constant_propagation(self, ir_list: List[IRInstruction]) -> List[IRInstruction]:
        """常量传播优化"""
        result = []
        const_regs: Dict[int, int] = {}  # register -> constant value

        for ir in ir_list:
            # 记录常量赋值
            if ir.opcode == "const" and ir.imm is not None:
                const_regs[ir.dst] = ir.imm
                result.append(ir)
            # 替换使用常量的寄存器
            elif ir.opcode in ("add", "sub", "mul", "div"):
                # 如果两个操作数都是常量，进行常量折叠
                if ir.src1 in const_regs and ir.src2 in const_regs:
                    val1 = const_regs[ir.src1]
                    val2 = const_regs[ir.src2]

                    if ir.opcode == "add":
                        result_val = val1 + val2
                    elif ir.opcode == "sub":
                        result_val = val1 - val2
                    elif ir.opcode == "mul":
                        result_val = val1 * val2
                    elif ir.opcode == "div" and val2 != 0:
                        result_val = val1 // val2
                    else:
                        result_val = 0

                    # 替换为常量赋值
                    folded = IRInstruction(
                        opcode="const",
                        dst=ir.dst,
                        imm=result_val
                    )
                    const_regs[ir.dst] = result_val
                    result.append(folded)
                    self.stats["constants_folded"] += 1
                else:
                    result.append(ir)
                    # 清除非常量结果
                    if ir.dst in const_regs:
                        del const_regs[ir.dst]
            else:
                result.append(ir)
                # 清除可能被修改的寄存器记录
                if ir.dst in const_regs and ir.opcode not in ("const",):
                    del const_regs[ir.dst]

        if self.stats["constants_folded"] > 0:
            self.optimizations_applied.append("constant_propagation")

        return result

    def _dead_code_elimination(self, ir_list: List[IRInstruction]) -> List[IRInstruction]:
        """死代码消除"""
        # 找到所有被使用的寄存器
        used_regs: Set[int] = set()

        # 反向遍历找到所有被使用的寄存器
        for ir in reversed(ir_list):
            # 标记使用的源寄存器
            if ir.src1 > 0:
                used_regs.add(ir.src1)
            if ir.src2 > 0:
                used_regs.add(ir.src2)

            # 如果是返回值相关指令，标记返回寄存器
            if ir.opcode.startswith("return"):
                if ir.src1 > 0:
                    used_regs.add(ir.src1)

            # 如果是条件跳转，标记条件寄存器
            if ir.opcode.startswith("if_"):
                if ir.src1 > 0:
                    used_regs.add(ir.src1)
                if ir.src2 > 0:
                    used_regs.add(ir.src2)

        # 正向遍历，消除死代码
        result = []
        defined_regs: Set[int] = set()

        for ir in ir_list:
            # 检查是否是死代码
            is_dead = False

            # 纯计算指令且结果未被使用
            if ir.opcode in ("add", "sub", "mul", "div", "and", "or", "xor",
                           "shl", "shr", "ushr", "neg", "not"):
                if ir.dst not in used_regs and ir.dst > 0:
                    is_dead = True
                    self.stats["dead_code_removed"] += 1

            # 常量赋值但结果未被使用
            elif ir.opcode == "const":
                if ir.dst not in used_regs and ir.dst > 0:
                    is_dead = True
                    self.stats["dead_code_removed"] += 1

            # 移动指令但结果未被使用
            elif ir.opcode == "move":
                if ir.dst not in used_regs and ir.dst > 0:
                    is_dead = True
                    self.stats["dead_code_removed"] += 1

            if not is_dead:
                result.append(ir)
                if ir.dst > 0:
                    defined_regs.add(ir.dst)

        if self.stats["dead_code_removed"] > 0:
            self.optimizations_applied.append("dead_code_elimination")

        return result

    def _optimize_registers(self, ir_list: List[IRInstruction]) -> List[IRInstruction]:
        """寄存器分配优化 - 简单的寄存器重命名"""
        # 找到实际使用的寄存器并重新分配
        reg_map: Dict[int, int] = {}
        next_reg = 0

        result = []
        for ir in ir_list:
            new_ir = IRInstruction(
                opcode=ir.opcode,
                imm=ir.imm,
                field_ref=ir.field_ref,
                method_ref=ir.method_ref,
                original_offset=ir.original_offset,
                width=ir.width,
                is_float=ir.is_float,
                cast_type=ir.cast_type
            )

            # 映射源寄存器
            if ir.src1 > 0:
                if ir.src1 not in reg_map:
                    reg_map[ir.src1] = next_reg
                    next_reg += 1
                new_ir.src1 = reg_map[ir.src1]

            if ir.src2 > 0:
                if ir.src2 not in reg_map:
                    reg_map[ir.src2] = next_reg
                    next_reg += 1
                new_ir.src2 = reg_map[ir.src2]

            # 映射目标寄存器
            if ir.dst > 0:
                if ir.dst not in reg_map:
                    reg_map[ir.dst] = next_reg
                    next_reg += 1
                new_ir.dst = reg_map[ir.dst]

            result.append(new_ir)

        if len(reg_map) < max((ir.dst for ir in ir_list if ir.dst > 0), default=0):
            self.stats["registers_reallocated"] = len(reg_map)
            self.optimizations_applied.append("register_allocation")

        return result

    def get_optimization_summary(self) -> str:
        """获取优化摘要"""
        lines = ["Optimization Summary:", "-" * 40]
        lines.append(f"Optimizations applied: {', '.join(self.optimizations_applied) or 'none'}")
        lines.append(f"Constants folded: {self.stats['constants_folded']}")
        lines.append(f"Dead code removed: {self.stats['dead_code_removed']}")
        lines.append(f"Registers reallocated: {self.stats['registers_reallocated']}")
        return "\n".join(lines)


class MethodInliner:
    """方法内联优化器"""

    def __init__(self, inline_threshold: int = 20):
        """
        Args:
            inline_threshold: 内联阈值，方法体小于此值才考虑内联
        """
        self.inline_threshold = inline_threshold
        self.method_cache: Dict[str, List[IRInstruction]] = {}

    def register_method(self, method_name: str, ir_list: List[IRInstruction]):
        """注册可内联的方法"""
        if len(ir_list) <= self.inline_threshold:
            self.method_cache[method_name] = ir_list

    def try_inline(self, ir: IRInstruction) -> Optional[List[IRInstruction]]:
        """
        尝试内联方法调用

        Args:
            ir: 调用指令

        Returns:
            内联后的IR列表，如果无法内联则返回None
        """
        if not ir.opcode.startswith("invoke"):
            return None

        # 查找方法缓存
        method_key = f"method_{ir.method_ref}"
        if method_key not in self.method_cache:
            return None

        method_body = self.method_cache[method_key]

        # 创建内联副本（调整寄存器）
        inlined = []
        base_reg = ir.imm  # 使用参数数量作为基础寄存器

        for method_ir in method_body:
            cloned = IRInstruction(
                opcode=method_ir.opcode,
                dst=method_ir.dst + base_reg if method_ir.dst > 0 else 0,
                src1=method_ir.src1 + base_reg if method_ir.src1 > 0 else 0,
                src2=method_ir.src2 + base_reg if method_ir.src2 > 0 else 0,
                imm=method_ir.imm,
                field_ref=method_ir.field_ref,
                method_ref=method_ir.method_ref,
                width=method_ir.width,
                is_float=method_ir.is_float,
                cast_type=method_ir.cast_type
            )
            inlined.append(cloned)

        return inlined


def demo():
    """演示优化器"""
    print("=" * 60)
    print("IR Optimizer Demo")
    print("=" * 60)

    # 创建测试IR
    test_ir = [
        IRInstruction(opcode="const", dst=1, imm=10),
        IRInstruction(opcode="const", dst=2, imm=20),
        IRInstruction(opcode="add", dst=3, src1=1, src2=2),  # 可常量折叠: 30
        IRInstruction(opcode="const", dst=4, imm=100),  # 死代码: 未使用
        IRInstruction(opcode="mul", dst=5, src1=3, src2=2),  # 使用r3和r2
        IRInstruction(opcode="return", src1=5),
    ]

    print("\nOriginal IR:")
    for i, ir in enumerate(test_ir):
        print(f"  {i}: {ir}")

    optimizer = IROptimizer()
    result = optimizer.optimize(test_ir)

    print("\nOptimized IR:")
    for i, ir in enumerate(result.ir_list):
        print(f"  {i}: {ir}")

    print(f"\n{optimizer.get_optimization_summary()}")


if __name__ == '__main__':
    demo()
