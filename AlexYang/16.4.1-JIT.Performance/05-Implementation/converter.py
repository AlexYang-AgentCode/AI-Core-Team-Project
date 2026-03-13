#!/usr/bin/env python3
"""
DEX to ABC Converter - MVP v2

完整流水线: DEX文件 → 解析 → IR → ABC字节码 → ABC文件

支持:
- 完整DEX解析（字段、方法、字节码）
- 25+ 条DEX指令映射
- 结构化ABC文件输出
- 性能统计
"""

import sys
import os
import time
import struct
from pathlib import Path
from typing import List, Optional

# 添加模块路径
_impl_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(_impl_dir, 'dex-parser'))
sys.path.insert(0, os.path.join(_impl_dir, 'abc-generator'))
sys.path.insert(0, os.path.join(_impl_dir, 'ir'))

from dex_parser import DexParser, ClassDef, FieldDef, MethodDef
from abc_generator import AbcGenerator
from instruction_mapper import InstructionMapper


class ConversionResult:
    """转换结果"""

    def __init__(self):
        self.success = False
        self.class_name = ""
        self.dex_size = 0
        self.abc_size = 0
        self.fields_count = 0
        self.methods_count = 0
        self.instructions_mapped = 0
        self.instructions_total = 0
        self.mapping_rate = 0.0
        self.parse_time_ms = 0.0
        self.convert_time_ms = 0.0
        self.generate_time_ms = 0.0
        self.total_time_ms = 0.0
        self.errors: List[str] = []


class DexToAbcConverter:
    """DEX到ABC转换器 v2"""

    def __init__(self, verbose: bool = False):
        self.verbose = verbose
        self.dex_parser: Optional[DexParser] = None
        self.abc_generator: Optional[AbcGenerator] = None
        self.instruction_mapper = InstructionMapper()

    def convert(self, dex_data: bytes) -> tuple:
        """
        转换DEX数据为ABC数据

        Returns:
            (abc_bytes, ConversionResult)
        """
        result = ConversionResult()
        result.dex_size = len(dex_data)
        total_start = time.perf_counter()

        # ===== Phase 1: Parse DEX =====
        t0 = time.perf_counter()
        self.dex_parser = DexParser(dex_data)
        if not self.dex_parser.parse():
            result.errors.append("DEX parse failed")
            return b'', result
        result.parse_time_ms = (time.perf_counter() - t0) * 1000

        if self.verbose:
            self.dex_parser.print_summary()

        # ===== Phase 2: Convert to ABC =====
        t0 = time.perf_counter()
        self.abc_generator = AbcGenerator()

        for class_def in self.dex_parser.class_defs:
            self._convert_class(class_def, result)

        result.convert_time_ms = (time.perf_counter() - t0) * 1000

        # ===== Phase 3: Generate ABC file =====
        t0 = time.perf_counter()
        abc_data = self.abc_generator.generate()
        result.generate_time_ms = (time.perf_counter() - t0) * 1000

        result.abc_size = len(abc_data)
        result.total_time_ms = (time.perf_counter() - total_start) * 1000
        result.success = True

        # Collect mapper stats
        stats = self.instruction_mapper.get_stats()
        result.instructions_total = stats["total_dex_instructions"]
        result.instructions_mapped = stats["mapped_instructions"]
        result.mapping_rate = float(stats["mapping_rate"].rstrip('%'))

        return abc_data, result

    def _convert_class(self, class_def: ClassDef, result: ConversionResult):
        """转换单个类"""
        # Get class name
        class_name = self.dex_parser.get_type(class_def.class_idx)
        if class_name.startswith('L') and class_name.endswith(';'):
            class_name = class_name[1:-1]
        result.class_name = class_name

        # Get super class
        super_class = 'Object'
        if class_def.superclass_idx != 0xffffffff:
            sc = self.dex_parser.get_type(class_def.superclass_idx)
            if sc.startswith('L') and sc.endswith(';'):
                super_class = sc[1:-1]

        self.abc_generator.set_class(class_name, super_class)

        # Convert fields
        for field in class_def.fields:
            self._convert_field(field)
            result.fields_count += 1

        # Convert methods
        for method in class_def.methods:
            self._convert_method(method)
            result.methods_count += 1

    def _convert_field(self, field: FieldDef):
        """转换字段"""
        name = self.dex_parser.get_string(field.name_idx)
        type_name = self.dex_parser.get_type(field.type_idx)
        self.abc_generator.add_field(name, type_name, field.access_flags)

    def _convert_method(self, method: MethodDef):
        """转换方法（含字节码映射）"""
        name = self.dex_parser.get_string(method.name_idx)

        # Extract DEX bytecode from code_off
        dex_bytecode = self._extract_bytecode(method.code_off)

        # Map DEX bytecode → ABC bytecode
        if dex_bytecode:
            abc_bytecode, ir_list = self.instruction_mapper.map(dex_bytecode)
        else:
            # No bytecode, generate stub
            abc_bytecode = bytes([0x08, 0x00])  # RETURN_VOID

        self.abc_generator.add_method(
            name=name,
            access_flags=method.access_flags,
            params=[],
            return_type='V',
            bytecode=abc_bytecode
        )

    def _extract_bytecode(self, code_off: int) -> Optional[bytes]:
        """从DEX code_item中提取字节码"""
        if code_off == 0:
            return None

        try:
            data = self.dex_parser.data
            # code_item structure:
            # ushort registers_size
            # ushort ins_size
            # ushort outs_size
            # ushort tries_size
            # uint debug_info_off
            # uint insns_size (in 2-byte units)
            # ushort[] insns
            pos = code_off
            registers_size = struct.unpack_from("<H", data, pos)[0]
            pos += 2
            ins_size = struct.unpack_from("<H", data, pos)[0]
            pos += 2
            outs_size = struct.unpack_from("<H", data, pos)[0]
            pos += 2
            tries_size = struct.unpack_from("<H", data, pos)[0]
            pos += 2
            debug_info_off = struct.unpack_from("<I", data, pos)[0]
            pos += 4
            insns_size = struct.unpack_from("<I", data, pos)[0]  # in 2-byte units
            pos += 4

            byte_count = insns_size * 2
            bytecode = data[pos:pos + byte_count]
            return bytecode

        except Exception as e:
            if self.verbose:
                print(f"    [WARN] Failed to extract bytecode at offset {code_off}: {e}")
            return None


def format_result(result: ConversionResult) -> str:
    """格式化转换结果"""
    lines = []
    lines.append(f"  Class:        {result.class_name}")
    lines.append(f"  Fields:       {result.fields_count}")
    lines.append(f"  Methods:      {result.methods_count}")
    lines.append(f"  DEX size:     {result.dex_size} bytes")
    lines.append(f"  ABC size:     {result.abc_size} bytes")
    lines.append(f"  Size ratio:   {result.abc_size / max(1, result.dex_size) * 100:.1f}%")
    lines.append(f"  Instructions: {result.instructions_mapped}/{result.instructions_total} mapped ({result.mapping_rate:.0f}%)")
    lines.append(f"  Timing:")
    lines.append(f"    Parse:      {result.parse_time_ms:.2f} ms")
    lines.append(f"    Convert:    {result.convert_time_ms:.2f} ms")
    lines.append(f"    Generate:   {result.generate_time_ms:.2f} ms")
    lines.append(f"    Total:      {result.total_time_ms:.2f} ms")
    return "\n".join(lines)


def main():
    """主函数 - CLI入口"""
    import argparse

    parser = argparse.ArgumentParser(
        description='DEX to ABC Converter (MVP v2)',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python converter.py test.dex                  # Convert test.dex → test.abc
  python converter.py test.dex -o output.abc    # Specify output path
  python converter.py test.dex -v               # Verbose output
  python converter.py *.dex --batch             # Batch convert
        """
    )
    parser.add_argument('input', nargs='+', help='Input DEX file(s)')
    parser.add_argument('-o', '--output', help='Output ABC file path')
    parser.add_argument('-d', '--output-dir', help='Output directory for batch mode', default='output')
    parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')
    parser.add_argument('--batch', action='store_true', help='Batch convert multiple files')
    parser.add_argument('--stats', action='store_true', help='Show detailed statistics')

    args = parser.parse_args()

    print("=" * 60)
    print("  DEX → ABC Converter (MVP v2)")
    print("  16.4.1-JIT.Performance Project")
    print("=" * 60)

    results = []

    for input_path in args.input:
        if not os.path.exists(input_path):
            print(f"\n  [ERROR] File not found: {input_path}")
            continue

        with open(input_path, 'rb') as f:
            dex_data = f.read()

        print(f"\n{'─' * 50}")
        print(f"  Converting: {input_path} ({len(dex_data)} bytes)")
        print(f"{'─' * 50}")

        converter = DexToAbcConverter(verbose=args.verbose)
        abc_data, result = converter.convert(dex_data)

        if result.success:
            # Determine output path
            if args.output and len(args.input) == 1:
                out_path = args.output
            else:
                os.makedirs(args.output_dir, exist_ok=True)
                base = os.path.splitext(os.path.basename(input_path))[0]
                out_path = os.path.join(args.output_dir, base + '.abc')

            with open(out_path, 'wb') as f:
                f.write(abc_data)

            print(f"\n  ✓ SUCCESS")
            print(format_result(result))
            print(f"  Output:       {out_path}")
        else:
            print(f"\n  ✗ FAILED: {', '.join(result.errors)}")

        results.append(result)

    # Summary
    if len(results) > 1 or args.stats:
        print(f"\n{'=' * 60}")
        print(f"  SUMMARY")
        print(f"{'=' * 60}")
        success = sum(1 for r in results if r.success)
        failed = len(results) - success
        total_dex = sum(r.dex_size for r in results)
        total_abc = sum(r.abc_size for r in results if r.success)
        total_time = sum(r.total_time_ms for r in results)
        total_insns = sum(r.instructions_total for r in results)
        mapped_insns = sum(r.instructions_mapped for r in results)

        print(f"  Files:          {success} success, {failed} failed")
        print(f"  Total DEX:      {total_dex} bytes")
        print(f"  Total ABC:      {total_abc} bytes")
        print(f"  Total time:     {total_time:.2f} ms")
        print(f"  Avg time/file:  {total_time / max(1, len(results)):.2f} ms")
        print(f"  Instructions:   {mapped_insns}/{total_insns} mapped ({mapped_insns / max(1, total_insns) * 100:.0f}%)")
        print(f"{'=' * 60}")


if __name__ == '__main__':
    main()
