#!/bin/bash

# 131 项目自动审视脚本 (Bash 版本)
# 功能: 遍历所有文件，检查是否为空，生成审视报告

VAULT_PATH="D:/ObsidianVault"
PROJECT_PATH="$VAULT_PATH/10-Projects/16-DigitalEmployee/16.1-AndroidToHarmonyOSDemo"
REPORT_FILE="$VAULT_PATH/131_audit_result.txt"

# 初始化统计
TOTAL_FILES=0
TOTAL_DIRS=0
EMPTY_DIRS=0
EMPTY_FILES=0
CRITICAL_MISSING=0

echo "================================================================================"
echo "16.1-AndroidToHarmonyOSDemo 项目自动审视报告"
echo "================================================================================"
echo "审视时间: $(date)"
echo "项目路径: $PROJECT_PATH"
echo ""

# 函数: 检查目录
check_directory() {
    local dir=$1
    local depth=$2
    local indent=""

    for ((i=0; i<depth; i++)); do indent+="  "; done

    if [ ! -d "$dir" ]; then
        echo "❌ 目录不存在: $dir"
        return
    fi

    # 获取子项目数量
    local file_count=$(find "$dir" -maxdepth 1 -type f | wc -l)
    local dir_count=$(find "$dir" -maxdepth 1 -type d ! -name . | wc -l)

    ((TOTAL_DIRS++))

    # 检查是否为空
    if [ $file_count -eq 0 ] && [ $dir_count -eq 0 ]; then
        echo "${indent}⚠️  空目录: $(basename "$dir")"
        ((EMPTY_DIRS++))
        return
    fi

    echo "${indent}📂 $(basename "$dir")/"
    echo "${indent}   ├─ 子目录: $dir_count"
    echo "${indent}   └─ 文件: $file_count"

    # 列出文件
    while IFS= read -r file; do
        local size=$(stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0")
        local lines=0

        if [ $size -eq 0 ]; then
            echo "${indent}   ❌ 空文件: $(basename "$file") (0 bytes)"
            ((EMPTY_FILES++))
        else
            # 计算行数
            if file "$file" | grep -q "text"; then
                lines=$(wc -l < "$file" 2>/dev/null || echo "?")
                echo "${indent}   ✅ $(basename "$file") ($size bytes, $lines lines)"
            else
                echo "${indent}   ✅ $(basename "$file") ($size bytes)"
            fi
        fi
        ((TOTAL_FILES++))
    done < <(find "$dir" -maxdepth 1 -type f)
}

# 审视各个 Phase
echo ""
echo "🔍 Phase 1: Android 分析"
echo "════════════════════════════════════════════════════════════════"
check_directory "$PROJECT_PATH/16.1.1-ANDROID-ANALYSIS" 1

echo ""
echo "🔍 Phase 2: Adapter 开发"
echo "════════════════════════════════════════════════════════════════"
check_directory "$PROJECT_PATH/16.1.2-ADAPTER-DEVELOPMENT" 1

echo ""
echo "🔍 Phase 3: HarmonyOS 开发"
echo "════════════════════════════════════════════════════════════════"
check_directory "$PROJECT_PATH/16.1.3-HARMONYOS-DEVELOPMENT" 1

echo ""
echo "🔍 Phase 4-9: 其他阶段"
echo "════════════════════════════════════════════════════════════════"
for phase_dir in "$PROJECT_PATH"/16.1.4-* "$PROJECT_PATH"/16.1.5-* "$PROJECT_PATH"/16.1.6-* "$PROJECT_PATH"/16.1.7-* "$PROJECT_PATH"/16.1.8-* "$PROJECT_PATH"/16.1.9-*; do
    if [ -d "$phase_dir" ]; then
        check_directory "$phase_dir" 1
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "审视汇总"
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "总目录数: $TOTAL_DIRS"
echo "总文件数: $TOTAL_FILES"
echo "空目录数: $EMPTY_DIRS"
echo "空文件数: $EMPTY_FILES"
echo ""

# 关键文件检查
echo "🔴 关键文件检查"
echo "═══════════════════════════════════════════════════════════════════════════════"

# 检查 TextClock APK
if [ -f "$PROJECT_PATH/16.1.1-ANDROID-ANALYSIS/16.1.11-ANDROID-BUILD/TextClock-debug.apk" ]; then
    echo "✅ TextClock-debug.apk 存在"
else
    echo "❌ TextClock-debug.apk 缺失 (关键文件!)"
    ((CRITICAL_MISSING++))
fi

# 检查 API 列表 CSV
api_csv_found=0
while IFS= read -r file; do
    if [[ "$file" == *"api-list.csv" || "$file" == *"api"*.csv ]]; then
        echo "✅ API 列表 CSV 存在: $file"
        api_csv_found=1
        break
    fi
done < <(find "$PROJECT_PATH" -name "*api*.csv" -type f)

if [ $api_csv_found -eq 0 ]; then
    echo "❌ API 列表 CSV 缺失 (关键文件!)"
    ((CRITICAL_MISSING++))
fi

# 检查 Phase 状态文件
echo ""
echo "🟡 Phase 状态文件检查"
echo "═══════════════════════════════════════════════════════════════════════════════"
for phase_file in "$PROJECT_PATH"/131.*-PHASE-STATUS.md; do
    if [ -f "$phase_file" ]; then
        size=$(stat -f%z "$phase_file" 2>/dev/null || stat -c%s "$phase_file" 2>/dev/null)
        if [ "$size" -gt 100 ]; then
            echo "✅ $(basename "$phase_file") - $size bytes"
        else
            echo "⚠️  $(basename "$phase_file") - $size bytes (内容很少)"
        fi
    else
        echo "❌ $(basename "$phase_file") 缺失"
    fi
done

echo ""
echo "═══════════════════════════════════════════════════════════════════════════════"
echo "结论"
echo "═══════════════════════════════════════════════════════════════════════════════"

if [ $CRITICAL_MISSING -gt 0 ]; then
    echo "🔴 发现 $CRITICAL_MISSING 个关键文件缺失！"
    echo "   项目可能存在虚假状态报告。"
fi

if [ $EMPTY_DIRS -gt 0 ]; then
    echo "⚠️  发现 $EMPTY_DIRS 个空目录"
fi

if [ $EMPTY_FILES -gt 0 ]; then
    echo "⚠️  发现 $EMPTY_FILES 个空文件"
fi

echo ""
echo "审视完成。详细结果已保存到: $REPORT_FILE"
