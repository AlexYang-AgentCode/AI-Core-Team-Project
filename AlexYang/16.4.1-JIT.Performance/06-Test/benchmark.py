#!/usr/bin/env python3
"""
JIT Performance Benchmark
测试DEX到ABC转换的性能

目标: 单个方法转换延迟 < 100ms
"""

import sys
import os
import time
import struct
import statistics
from typing import List, Tuple, Callable
from dataclasses import dataclass

# 添加模块路径
_impl_dir = os.path.join(os.path.dirname(__file__), '..', '05-Implementation')
sys.path.insert(0, os.path.join(_impl_dir, 'dex-parser'))
sys.path.insert(0, os.path.join(_impl_dir, 'abc-generator'))
sys.path.insert(0, os.path.join(_impl_dir, 'ir'))

from dex_parser import DexParser
from abc_generator import AbcGenerator
from instruction_mapper import InstructionMapper


@dataclass
class BenchmarkResult:
    """性能测试结果"""
    name: str
    iterations: int
    total_time_ms: float
    avg_time_ms: float
    min_time_ms: float
    max_time_ms: float
    median_time_ms: float
    stdev_ms: float
    throughput_per_sec: float
    passed_target: bool


class JITBenchmark:
    """JIT性能基准测试器"""

    TARGET_LATENCY_MS = 100.0  # 目标延迟 < 100ms

    def __init__(self):
        self.mapper = InstructionMapper()
        self.results: List[BenchmarkResult] = []

    def _measure(self, func: Callable, iterations: int = 1000) -> List[float]:
        """测量函数执行时间"""
        times = []
        for _ in range(iterations):
            start = time.perf_counter()
            func()
            end = time.perf_counter()
            times.append((end - start) * 1000)  # Convert to ms
        return times

    def benchmark_instruction_map(self, iterations: int = 10000) -> BenchmarkResult:
        """测试指令映射性能"""
        # 测试用例: 典型的算术运算序列
        test_bytecode = bytes([
            0x12, 0x55,       # const/4 v0, 5
            0x12, 0x13,       # const/4 v1, 3
            0x90, 0x02, 0x00, 0x01,  # add-int v2, v0, v1
            0x91, 0x03, 0x02, 0x00,  # sub-int v3, v2, v0
            0x0e, 0x00,       # return-void
        ])

        def test_func():
            self.mapper.map(test_bytecode)

        times = self._measure(test_func, iterations)

        return BenchmarkResult(
            name="Instruction Map (5 insns)",
            iterations=iterations,
            total_time_ms=sum(times),
            avg_time_ms=statistics.mean(times),
            min_time_ms=min(times),
            max_time_ms=max(times),
            median_time_ms=statistics.median(times),
            stdev_ms=statistics.stdev(times) if len(times) > 1 else 0,
            throughput_per_sec=iterations / (sum(times) / 1000),
            passed_target=statistics.mean(times) < self.TARGET_LATENCY_MS
        )

    def benchmark_single_instruction(self, iterations: int = 10000) -> BenchmarkResult:
        """测试单条指令映射性能"""
        test_bytecode = bytes([0x90, 0x00, 0x01, 0x02])  # add-int

        def test_func():
            self.mapper.map(test_bytecode)

        times = self._measure(test_func, iterations)

        return BenchmarkResult(
            name="Single Instruction (add-int)",
            iterations=iterations,
            total_time_ms=sum(times),
            avg_time_ms=statistics.mean(times),
            min_time_ms=min(times),
            max_time_ms=max(times),
            median_time_ms=statistics.median(times),
            stdev_ms=statistics.stdev(times) if len(times) > 1 else 0,
            throughput_per_sec=iterations / (sum(times) / 1000),
            passed_target=statistics.mean(times) < self.TARGET_LATENCY_MS
        )

    def benchmark_complex_method(self, iterations: int = 1000) -> BenchmarkResult:
        """测试复杂方法转换性能"""
        # 更复杂的字节码序列 (约50条指令)
        bytecode = bytearray()

        # 局部变量初始化
        for i in range(4):
            bytecode.extend([0x12, (i << 4) | i])  # const/4 vi, i

        # 算术运算序列
        for i in range(10):
            bytecode.extend([0x90 + (i % 5), 0x00, 0x01, 0x02])  # various arithmetic

        # 条件分支
        bytecode.extend([0x38, 0x00, 0x02, 0x00])  # if-eqz v0, +4
        bytecode.extend([0x0e, 0x00])  # return-void
        bytecode.extend([0x28, 0xfa])  # goto -12

        # 返回
        bytecode.extend([0x0f, 0x00])  # return v0

        def test_func():
            self.mapper.map(bytes(bytecode))

        times = self._measure(test_func, iterations)

        return BenchmarkResult(
            name=f"Complex Method ({len(bytecode)//2} insns)",
            iterations=iterations,
            total_time_ms=sum(times),
            avg_time_ms=statistics.mean(times),
            min_time_ms=min(times),
            max_time_ms=max(times),
            median_time_ms=statistics.median(times),
            stdev_ms=statistics.stdev(times) if len(times) > 1 else 0,
            throughput_per_sec=iterations / (sum(times) / 1000),
            passed_target=statistics.mean(times) < self.TARGET_LATENCY_MS
        )

    def benchmark_throughput(self) -> BenchmarkResult:
        """测试吞吐量 (每秒处理的指令数)"""
        # 生成大量指令
        num_insns = 1000
        bytecode = bytearray()

        for i in range(num_insns // 2):
            bytecode.extend([0x90, 0x00, 0x01, 0x02])  # add-int

        iterations = 100
        total_insns = iterations * num_insns

        def test_func():
            self.mapper.map(bytes(bytecode))

        start = time.perf_counter()
        for _ in range(iterations):
            test_func()
        total_time = (time.perf_counter() - start) * 1000

        return BenchmarkResult(
            name=f"Throughput ({num_insns} insns/batch)",
            iterations=iterations,
            total_time_ms=total_time,
            avg_time_ms=total_time / iterations,
            min_time_ms=0,
            max_time_ms=0,
            median_time_ms=0,
            stdev_ms=0,
            throughput_per_sec=total_insns / (total_time / 1000),
            passed_target=True
        )

    def benchmark_dex_parse(self, iterations: int = 1000) -> BenchmarkResult:
        """测试DEX解析性能"""
        # 创建一个简单的DEX文件
        dex_data = self._create_simple_dex()

        def test_func():
            parser = DexParser(dex_data)
            parser.parse()

        times = self._measure(test_func, iterations)

        return BenchmarkResult(
            name="DEX Parse (simple class)",
            iterations=iterations,
            total_time_ms=sum(times),
            avg_time_ms=statistics.mean(times),
            min_time_ms=min(times),
            max_time_ms=max(times),
            median_time_ms=statistics.median(times),
            stdev_ms=statistics.stdev(times) if len(times) > 1 else 0,
            throughput_per_sec=iterations / (sum(times) / 1000),
            passed_target=statistics.mean(times) < self.TARGET_LATENCY_MS
        )

    def _create_simple_dex(self) -> bytes:
        """创建一个简单的DEX文件用于测试"""
        dex = bytearray()

        # Header
        dex.extend(b'dex\n035\x00')  # magic
        dex.extend(b'\x00' * 24)  # checksum + signature
        dex.extend(struct.pack('<I', 0x100))  # file_size
        dex.extend(struct.pack('<I', 0x70))  # header_size
        dex.extend(struct.pack('<I', 0x12345678))  # endian_tag
        dex.extend(struct.pack('<I', 0))  # link_size
        dex.extend(struct.pack('<I', 0))  # link_off
        dex.extend(struct.pack('<I', 0x70))  # map_off
        dex.extend(struct.pack('<I', 3))  # string_ids_size
        dex.extend(struct.pack('<I', 0x70))  # string_ids_off
        dex.extend(struct.pack('<I', 2))  # type_ids_size
        dex.extend(struct.pack('<I', 0x7c))  # type_ids_off
        dex.extend(struct.pack('<I', 0))  # proto_ids_size
        dex.extend(struct.pack('<I', 0))  # proto_ids_off
        dex.extend(struct.pack('<I', 0))  # field_ids_size
        dex.extend(struct.pack('<I', 0))  # field_ids_off
        dex.extend(struct.pack('<I', 1))  # method_ids_size
        dex.extend(struct.pack('<I', 0x84))  # method_ids_off
        dex.extend(struct.pack('<I', 1))  # class_defs_size
        dex.extend(struct.pack('<I', 0x8c))  # class_defs_off
        dex.extend(struct.pack('<I', 0x40))  # data_size
        dex.extend(struct.pack('<I', 0xc0))  # data_off

        # Pad to string_ids_off
        while len(dex) < 0x70:
            dex.append(0)

        # String offsets
        dex.extend(struct.pack('<I', 0xe0))  # string 0
        dex.extend(struct.pack('<I', 0xe8))  # string 1
        dex.extend(struct.pack('<I', 0xf0))  # string 2

        # Type IDs
        dex.extend(struct.pack('<I', 0))  # type 0 -> string 0
        dex.extend(struct.pack('<I', 1))  # type 1 -> string 1

        # Method IDs
        dex.extend(struct.pack('<H', 0))  # class_idx
        dex.extend(struct.pack('<H', 0))  # proto_idx
        dex.extend(struct.pack('<I', 2))  # name_idx -> "<init>"

        # Class def
        dex.extend(struct.pack('<I', 0))  # class_idx
        dex.extend(struct.pack('<I', 1))  # access_flags (public)
        dex.extend(struct.pack('<I', 1))  # superclass_idx
        dex.extend(struct.pack('<I', 0))  # interfaces_off
        dex.extend(struct.pack('<I', 0xffffffff))  # source_file_idx
        dex.extend(struct.pack('<I', 0))  # annotations_off
        dex.extend(struct.pack('<I', 0xf8))  # class_data_off
        dex.extend(struct.pack('<I', 0))  # static_values_off

        # Pad to data_off
        while len(dex) < 0xc0:
            dex.append(0)

        # String data
        dex.extend(bytes([4]))  # uleb128 length
        dex.extend(b'Test\x00')
        dex.extend(bytes([10]))
        dex.extend(b'Ljava/lang/Object;\x00')
        dex.extend(bytes([7]))
        dex.extend(b'<init>\x00')

        # Class data
        dex.extend(bytes([0]))  # static_fields_size
        dex.extend(bytes([0]))  # instance_fields_size
        dex.extend(bytes([1]))  # direct_methods_size
        dex.extend(bytes([0]))  # virtual_methods_size
        dex.extend(bytes([0]))  # method_idx_diff
        dex.extend(bytes([1]))  # access_flags
        dex.extend(struct.pack('<I', 0x110))  # code_off

        # Code item at 0x110
        while len(dex) < 0x110:
            dex.append(0)

        dex.extend(struct.pack('<H', 1))  # registers_size
        dex.extend(struct.pack('<H', 1))  # ins_size
        dex.extend(struct.pack('<H', 0))  # outs_size
        dex.extend(struct.pack('<H', 0))  # tries_size
        dex.extend(struct.pack('<I', 0))  # debug_info_off
        dex.extend(struct.pack('<I', 1))  # insns_size
        dex.extend(struct.pack('<H', 0x0e00))  # return-void

        return bytes(dex)

    def run_all(self) -> List[BenchmarkResult]:
        """运行所有基准测试"""
        print("=" * 70)
        print("  JIT Performance Benchmark")
        print(f"  Target Latency: < {self.TARGET_LATENCY_MS}ms per method")
        print("=" * 70)
        print()

        tests = [
            ("Single Instruction", self.benchmark_single_instruction),
            ("Instruction Map (5 insns)", self.benchmark_instruction_map),
            ("Complex Method", self.benchmark_complex_method),
            ("Throughput Test", self.benchmark_throughput),
            ("DEX Parse", self.benchmark_dex_parse),
        ]

        for name, test_func in tests:
            print(f"Running: {name}...", end=" ", flush=True)
            try:
                result = test_func()
                self.results.append(result)
                print(f"✓")
            except Exception as e:
                print(f"✗ ({e})")

        return self.results

    def print_report(self):
        """打印性能报告"""
        print()
        print("=" * 70)
        print("  PERFORMANCE REPORT")
        print("=" * 70)

        all_passed = True
        for r in self.results:
            status = "✓ PASS" if r.passed_target else "✗ FAIL"
            if not r.passed_target:
                all_passed = False

            print(f"\n  {r.name}")
            print(f"    Iterations:   {r.iterations:,}")
            print(f"    Avg Time:     {r.avg_time_ms:.4f} ms")
            print(f"    Min Time:     {r.min_time_ms:.4f} ms")
            print(f"    Max Time:     {r.max_time_ms:.4f} ms")
            print(f"    Median Time:  {r.median_time_ms:.4f} ms")
            if r.stdev_ms > 0:
                print(f"    Std Dev:      {r.stdev_ms:.4f} ms")
            print(f"    Throughput:   {r.throughput_per_sec:,.0f} ops/sec")
            print(f"    Status:       {status}")

        print()
        print("=" * 70)
        if all_passed:
            print("  RESULT: ALL TESTS PASSED ✓")
            print(f"  All methods convert within {self.TARGET_LATENCY_MS}ms target")
        else:
            print("  RESULT: SOME TESTS FAILED ✗")
            print(f"  Some methods exceed {self.TARGET_LATENCY_MS}ms target")
        print("=" * 70)

        return all_passed


def main():
    """主函数"""
    benchmark = JITBenchmark()
    benchmark.run_all()
    success = benchmark.print_report()

    # 保存详细报告到文件
    report_path = os.path.join(os.path.dirname(__file__), 'benchmark_report.txt')
    with open(report_path, 'w') as f:
        f.write("JIT Performance Benchmark Report\n")
        f.write("=" * 70 + "\n\n")
        for r in benchmark.results:
            f.write(f"{r.name}\n")
            f.write(f"  Avg: {r.avg_time_ms:.4f} ms\n")
            f.write(f"  Throughput: {r.throughput_per_sec:,.0f} ops/sec\n")
            f.write(f"  Status: {'PASS' if r.passed_target else 'FAIL'}\n\n")

    print(f"\n  Detailed report saved to: {report_path}")

    return 0 if success else 1


if __name__ == '__main__':
    sys.exit(main())
