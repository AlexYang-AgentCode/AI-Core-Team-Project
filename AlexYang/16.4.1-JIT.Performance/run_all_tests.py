#!/usr/bin/env python3
"""
Test Suite Runner - 运行所有测试

Usage:
  python run_all_tests.py              # 运行所有测试
  python run_all_tests.py unit         # 仅运行单元测试
  python run_all_tests.py integration  # 仅运行集成测试
  python run_all_tests.py benchmark    # 仅运行性能测试
  python run_all_tests.py generate     # 生成测试DEX文件
  python run_all_tests.py convert      # 转换测试DEX文件
"""

import sys
import os
import subprocess

# 测试目录
TEST_DIR = os.path.join(os.path.dirname(__file__), '06-Test')
TEST_CASES_DIR = os.path.join(os.path.dirname(__file__), 'test-cases')
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), 'output')


def run_test_file(test_file: str) -> bool:
    """运行单个测试文件"""
    test_path = os.path.join(TEST_DIR, test_file)
    if not os.path.exists(test_path):
        print(f"  ✗ Test file not found: {test_file}")
        return False

    print(f"  Running {test_file}...")
    result = subprocess.run([sys.executable, test_path], capture_output=True, text=True)

    # Print output
    if result.stdout:
        for line in result.stdout.split('\n'):
            print(f"    {line}")

    if result.returncode != 0:
        print(f"  ✗ {test_file} FAILED")
        if result.stderr:
            print(f"    Error: {result.stderr[:200]}")
        return False
    else:
        print(f"  ✓ {test_file} PASSED")
        return True


def run_unit_tests() -> bool:
    """运行单元测试"""
    print("\n" + "=" * 70)
    print("  UNIT TESTS")
    print("=" * 70)

    tests = [
        'test_dex_parser.py',
        'test_instruction_mapper.py',
    ]

    results = []
    for test in tests:
        results.append(run_test_file(test))

    return all(results)


def run_integration_tests() -> bool:
    """运行集成测试"""
    print("\n" + "=" * 70)
    print("  INTEGRATION TESTS")
    print("=" * 70)

    return run_test_file('test_integration.py')


def run_benchmark() -> bool:
    """运行性能测试"""
    print("\n" + "=" * 70)
    print("  PERFORMANCE BENCHMARK")
    print("=" * 70)

    return run_test_file('benchmark.py')


def generate_test_files() -> bool:
    """生成测试DEX文件"""
    print("\n" + "=" * 70)
    print("  GENERATING TEST DEX FILES")
    print("=" * 70)

    generator_path = os.path.join(TEST_CASES_DIR, 'generate_test_dex.py')
    if not os.path.exists(generator_path):
        print(f"  ✗ Generator not found: {generator_path}")
        return False

    result = subprocess.run([sys.executable, generator_path], capture_output=True, text=True)

    if result.stdout:
        for line in result.stdout.split('\n'):
            print(f"  {line}")

    return result.returncode == 0


def convert_test_files() -> bool:
    """转换测试DEX文件到ABC"""
    print("\n" + "=" * 70)
    print("  CONVERTING TEST DEX FILES")
    print("=" * 70)

    # Ensure output directory exists
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # Find all .dex files in test-cases
    dex_files = [f for f in os.listdir(TEST_CASES_DIR) if f.endswith('.dex')]

    if not dex_files:
        print("  No DEX files found. Run 'generate' first.")
        return False

    converter_path = os.path.join(os.path.dirname(__file__), '05-Implementation', 'converter.py')

    results = []
    for dex_file in sorted(dex_files):
        dex_path = os.path.join(TEST_CASES_DIR, dex_file)
        print(f"\n  Converting {dex_file}...")

        result = subprocess.run(
            [sys.executable, converter_path, dex_path, '-d', OUTPUT_DIR, '--stats'],
            capture_output=True,
            text=True
        )

        if result.stdout:
            for line in result.stdout.split('\n')[-15:]:  # Show last 15 lines
                if line.strip():
                    print(f"    {line}")

        results.append(result.returncode == 0)

    return all(results)


def run_all() -> bool:
    """运行所有测试"""
    print("\n" + "=" * 70)
    print("  JIT PERFORMANCE TEST SUITE")
    print("  DEX to ABC Converter - 16.4.1-JIT.Performance")
    print("=" * 70)

    results = []

    # Generate test files first
    results.append(("Generate Test Files", generate_test_files()))

    # Run unit tests
    results.append(("Unit Tests", run_unit_tests()))

    # Run integration tests
    results.append(("Integration Tests", run_integration_tests()))

    # Run benchmark
    results.append(("Performance Benchmark", run_benchmark()))

    # Convert test files
    results.append(("Convert Test Files", convert_test_files()))

    # Summary
    print("\n" + "=" * 70)
    print("  TEST SUMMARY")
    print("=" * 70)

    all_passed = True
    for name, passed in results:
        status = "✓ PASS" if passed else "✗ FAIL"
        print(f"  {status:8} {name}")
        if not passed:
            all_passed = False

    print("=" * 70)
    if all_passed:
        print("  ALL TESTS PASSED ✓")
    else:
        print("  SOME TESTS FAILED ✗")
    print("=" * 70)

    return all_passed


def main():
    """主函数"""
    if len(sys.argv) < 2:
        # Run all tests
        success = run_all()
    else:
        command = sys.argv[1].lower()

        if command == 'unit':
            success = run_unit_tests()
        elif command == 'integration':
            success = run_integration_tests()
        elif command == 'benchmark':
            success = run_benchmark()
        elif command == 'generate':
            success = generate_test_files()
        elif command == 'convert':
            success = convert_test_files()
        else:
            print(__doc__)
            sys.exit(1)

    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
