#!/bin/bash
# APK构建前检查脚本
# 用法: bash check-build-readiness.sh

echo "========================================="
echo "APK构建准备检查"
echo "========================================="
echo ""

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
ERRORS=0

# 检查1: 项目结构
echo "[1/6] 检查项目结构..."
if [ -f "$PROJECT_DIR/build.gradle" ] && [ -f "$PROJECT_DIR/app/build.gradle" ]; then
    echo "  ✓ build.gradle 文件存在"
else
    echo "  ✗ build.gradle 文件缺失"
    ERRORS=$((ERRORS+1))
fi

# 检查2: Java源文件
echo "[2/6] 检查Java源文件..."
JAVA_FILES=(
    "app/src/main/java/com/jit/performance/MainActivity.java"
    "app/src/main/java/com/jit/performance/converter/DexToAbcConverter.java"
    "app/src/main/java/com/jit/performance/model/ConversionResult.java"
    "app/src/main/java/com/jit/performance/model/DexParseResult.java"
    "app/src/main/java/com/jit/performance/model/BenchmarkResult.java"
)
for file in "${JAVA_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file 缺失"
        ERRORS=$((ERRORS+1))
    fi
done

# 检查3: Python模块
echo "[3/6] 检查Python模块..."
PYTHON_FILES=(
    "app/src/main/python/converter.py"
    "app/src/main/python/dex-parser/dex_parser.py"
    "app/src/main/python/abc-generator/abc_generator.py"
    "app/src/main/python/ir/instruction_mapper.py"
)
for file in "${PYTHON_FILES[@]}"; do
    if [ -f "$PROJECT_DIR/$file" ]; then
        echo "  ✓ $file"
    else
        echo "  ✗ $file 缺失"
        ERRORS=$((ERRORS+1))
    fi
done

# 检查4: 资源文件
echo "[4/6] 检查资源文件..."
if [ -f "$PROJECT_DIR/app/src/main/AndroidManifest.xml" ]; then
    echo "  ✓ AndroidManifest.xml"
else
    echo "  ✗ AndroidManifest.xml 缺失"
    ERRORS=$((ERRORS+1))
fi

if [ -f "$PROJECT_DIR/app/src/main/res/layout/activity_main.xml" ]; then
    echo "  ✓ activity_main.xml"
else
    echo "  ✗ activity_main.xml 缺失"
    ERRORS=$((ERRORS+1))
fi

# 检查5: Gradle配置
echo "[5/6] 检查Gradle配置..."
if grep -q "com.chaquo.python" "$PROJECT_DIR/app/build.gradle"; then
    echo "  ✓ Chaquopy插件已配置"
else
    echo "  ✗ Chaquopy插件未配置"
    ERRORS=$((ERRORS+1))
fi

if grep -q "chaquopy" "$PROJECT_DIR/app/build.gradle"; then
    echo "  ✓ Chaquopy配置块存在"
else
    echo "  ✗ Chaquopy配置块缺失"
    ERRORS=$((ERRORS+1))
fi

# 检查6: 外部工具
echo "[6/6] 检查外部工具..."
if command -v java &> /dev/null; then
    echo "  ✓ Java: $(java -version 2>&1 | head -n 1)"
else
    echo "  ⚠ Java未安装（构建必需）"
fi

if command -v gradle &> /dev/null; then
    echo "  ✓ Gradle: $(gradle --version | grep Gradle)"
else
    echo "  ⚠ Gradle未安装（需Android Studio或手动安装）"
fi

echo ""
echo "========================================="
if [ $ERRORS -eq 0 ]; then
    echo "✓ 项目结构完整，可以构建APK"
    echo ""
    echo "下一步:"
    echo "  Windows: 打开Android Studio，导入此项目"
    echo "  或使用: gradle wrapper && ./gradlew assembleDebug"
else
    echo "✗ 发现 $ERRORS 个问题，请修复后再构建"
fi
echo "========================================="

exit $ERRORS
