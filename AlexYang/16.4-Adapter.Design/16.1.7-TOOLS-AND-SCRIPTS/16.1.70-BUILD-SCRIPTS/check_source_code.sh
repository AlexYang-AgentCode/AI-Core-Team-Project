#!/bin/bash
# check_source_code.sh - 自动化源码位置检查脚本
#
# 目的: 系统地检查 D: 盘中 HarmonyOS 和 Android 源码的位置
# 执行: bash check_source_code.sh
# 返回: exit 0 (找到源码) 或 exit 1 (未找到)

echo "========================================"
echo "自动化源码位置检查 - check_source_code.sh"
echo "========================================"
echo ""

# 源码检查清单
declare -a SOURCE_LOCATIONS=(
    "D:/TextClock"
    "D:/textclock"
    "D:/AndroidToHarmonyOS"
    "D:/harmonyos"
    "D:/HarmonyOS"
    "D:/atos"
    "D:/ATOS"
    "D:/Projects/TextClock"
    "D:/Projects/Android"
    "D:/Sources/TextClock"
    "D:/Sources/HarmonyOS"
)

FOUND_SOURCES=0
MISSING_SOURCES=0

echo "检查预期的源码位置..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for location in "${SOURCE_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        FOUND_SOURCES=$((FOUND_SOURCES + 1))
        echo "✅ 找到: $location"

        # 显示目录信息
        file_count=$(find "$location" -type f 2>/dev/null | wc -l)
        dir_count=$(find "$location" -type d 2>/dev/null | wc -l)
        size=$(du -sh "$location" 2>/dev/null | cut -f1)

        echo "   ├─ 文件数: $file_count"
        echo "   ├─ 目录数: $dir_count"
        echo "   └─ 大小: $size"
        echo ""
    else
        MISSING_SOURCES=$((MISSING_SOURCES + 1))
        # 不显示缺失的位置，以保持输出简洁
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 扫描 D: 盘根目录查找源码
echo "扫描 D: 盘根目录查找可能的源码目录..."
echo ""

if [ -d "D:/" ]; then
    # 查找包含源码特征的目录
    echo "可能的源码相关目录:"
    echo ""

    # 查找包含 src, source, code 等关键字的目录
    for pattern in "src" "source" "android" "harmonyos" "text" "clock"; do
        results=$(find "D:/" -maxdepth 3 -type d -iname "*$pattern*" 2>/dev/null | head -5)
        if [ -n "$results" ]; then
            echo "关键字 '$pattern' 匹配的目录:"
            echo "$results" | while read dir; do
                echo "  • $dir"
            done
            echo ""
        fi
    done
else
    echo "⚠️  无法访问 D: 盘"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 生成报告
echo "📊 检查结果总结"
echo ""
echo "找到的源码位置: $FOUND_SOURCES"
echo "预期位置总数: ${#SOURCE_LOCATIONS[@]}"
echo ""

if [ $FOUND_SOURCES -gt 0 ]; then
    echo "✅ 源码位置检查成功"
    echo ""
    echo "后续步骤:"
    echo "  1. 验证找到的源码是否完整"
    echo "  2. 记录源码位置到项目配置"
    echo "  3. 继续 Phase 1 分析"
    echo ""

    # 创建报告文件
    cat > "D:/ObsidianVault/SOURCE-CODE-LOCATIONS.txt" << EOF
自动化源码检查报告 - $(date)

检查状态: ✅ 成功

找到的源码位置:
EOF

    for location in "${SOURCE_LOCATIONS[@]}"; do
        if [ -d "$location" ]; then
            echo "$location" >> "D:/ObsidianVault/SOURCE-CODE-LOCATIONS.txt"
        fi
    done

    echo ""
    echo "报告已保存到: SOURCE-CODE-LOCATIONS.txt"
    echo ""
    exit 0
else
    echo "❌ 源码位置检查失败"
    echo ""
    echo "⚠️  未在预期位置找到源码"
    echo ""
    echo "建议:"
    echo "  1. 手动检查 D: 盘并确认源码位置"
    echo "  2. 将实际位置记录到 SOURCE-CODE-LOCATIONS.txt"
    echo "  3. 更新项目配置文件"
    echo ""
    exit 1
fi
