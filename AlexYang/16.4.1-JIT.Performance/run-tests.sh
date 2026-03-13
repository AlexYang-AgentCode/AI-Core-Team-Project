#!/bin/bash
# DEX to ABC Converter 快速测试脚本
# 作者: 16.4.1-JIT.Performance团队
# 日期: 2026-03-11

echo "========================================"
echo "DEX to ABC Converter - 快速测试"
echo "========================================"
echo ""

# 检查Python
echo "[1/5] 检查Python环境..."
if ! command -v python3 &> /dev/null; then
    echo "错误: 未找到Python3"
    exit 1
fi
python3 --version
echo ""

# 设置路径
PROJECT_DIR="/mnt/d/ObsidianVault/10-Projects/16.4.1-JIT.Performance"
IMPL_DIR="$PROJECT_DIR/05-Implementation"
TEST_DIR="$PROJECT_DIR/test-cases"
OUTPUT_DIR="$PROJECT_DIR/output"

mkdir -p "$OUTPUT_DIR"

echo "[2/5] 测试DEX解析器..."
cd "$IMPL_DIR/dex-parser"

# 创建测试DEX（如果有的话）
if [ -f "$TEST_DIR/TestCase1.java" ]; then
    echo "  找到测试Java文件"
    
    # 尝试编译Java文件
    if command -v javac &> /dev/null; then
        echo "  编译Java文件..."
        cd "$TEST_DIR"
        javac TestCase1.java 2>/dev/null || echo "  警告: 编译失败，跳过"
        
        # 尝试转换为DEX
        if command -v dx &> /dev/null; then
            echo "  转换为DEX..."
            dx --dex --output=TestCase1.dex TestCase1.class 2>/dev/null || echo "  警告: dx不可用"
        else
            echo "  警告: 未找到dx工具"
        fi
        
        cd "$IMPL_DIR"
    else
        echo "  警告: 未找到javac"
    fi
fi

echo ""
echo "[3/5] 测试ABC生成器..."
cd "$IMPL_DIR/abc-generator"
python3 abc_generator.py || echo "  警告: ABC生成器测试失败"

echo ""
echo "[4/5] 运行综合测试..."
cd "$IMPL_DIR"

# 如果存在DEX文件，运行转换器
if [ -f "$TEST_DIR/TestCase1.dex" ]; then
    echo "  转换TestCase1.dex..."
    python3 converter.py "$TEST_DIR/TestCase1.dex" -o "$OUTPUT_DIR/TestCase1.abc"
else
    echo "  警告: 未找到TestCase1.dex，跳过转换测试"
fi

echo ""
echo "[5/5] 生成测试报告..."

# 统计生成的文件
echo ""
echo "=== 生成的文件 ==="
ls -lh "$OUTPUT_DIR/" 2>/dev/null || echo "  输出目录为空"

echo ""
echo "=== 代码统计 ==="
echo "DEX解析器:"
wc -l "$IMPL_DIR/dex-parser/dex_parser.py" 2>/dev/null || echo "  文件未找到"

echo ""
echo "ABC生成器:"
wc -l "$IMPL_DIR/abc-generator/abc_generator.py" 2>/dev/null || echo "  文件未找到"

echo ""
echo "主转换器:"
wc -l "$IMPL_DIR/converter.py" 2>/dev/null || echo "  文件未找到"

echo ""
echo "========================================"
echo "测试完成"
echo "========================================"

# 总结
echo ""
echo "=== 状态总结 ==="
if [ -f "$OUTPUT_DIR/SimplePojo.abc" ]; then
    echo "✓ ABC生成器: 工作正常"
else
    echo "✗ ABC生成器: 需要检查"
fi

if [ -f "$TEST_DIR/TestCase1.dex" ] && [ -f "$OUTPUT_DIR/TestCase1.abc" ]; then
    echo "✓ DEX→ABC转换: 工作正常"
elif [ ! -f "$TEST_DIR/TestCase1.dex" ]; then
    echo "⚠ DEX→ABC转换: 等待DEX测试文件"
else
    echo "✗ DEX→ABC转换: 需要检查"
fi

echo ""
echo "下一步:"
echo "  1. 准备DEX测试文件 (编译Java→DEX)"
echo "  2. 完善指令映射"
echo "  3. 性能测试"