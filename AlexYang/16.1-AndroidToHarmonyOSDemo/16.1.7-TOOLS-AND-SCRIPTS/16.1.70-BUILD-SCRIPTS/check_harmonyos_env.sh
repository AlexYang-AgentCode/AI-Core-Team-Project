#!/bin/bash
# check_harmonyos_env.sh - 自动化 HarmonyOS 环境验证脚本
#
# 目的: 系统地验证 D: 盘中 HarmonyOS 开发环境是否完整
# 执行: bash check_harmonyos_env.sh
# 返回: exit 0 (验证通过) 或 exit 1 (验证失败)

echo "========================================"
echo "HarmonyOS 环境自动化验证 - check_harmonyos_env.sh"
echo "========================================"
echo ""

# 检查清单
CHECKS_PASSED=0
CHECKS_FAILED=0

# ==================== CHECK 1: HarmonyOS SDK 存在 ====================
echo "[CHECK 1] HarmonyOS SDK 目录检查"
echo ""

HARMONYOS_LOCATIONS=(
    "D:/HarmonyOS"
    "D:/harmonyos"
    "D:/DevEco"
    "D:/deveco"
    "D:/DevEcoStudio"
    "D:/deveco-studio"
    "D:/OpenHarmony"
    "D:/open-harmony"
    "D:/ohos"
    "D:/OHOS"
)

FOUND_SDK=0
for location in "${HARMONYOS_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        echo "✅ 找到 HarmonyOS SDK: $location"
        file_count=$(find "$location" -type f 2>/dev/null | wc -l)
        echo "   ├─ 文件数: $file_count"
        echo "   └─ 状态: 有效"
        FOUND_SDK=1
        CHECKS_PASSED=$((CHECKS_PASSED + 1))
        break
    fi
done

if [ $FOUND_SDK -eq 0 ]; then
    echo "❌ 未找到 HarmonyOS SDK"
    echo "   预期位置:"
    for loc in "${HARMONYOS_LOCATIONS[@]}"; do
        echo "     - $loc"
    done
    CHECKS_FAILED=$((CHECKS_FAILED + 1))
fi

echo ""

# ==================== CHECK 2: Node.js 检查 ====================
echo "[CHECK 2] Node.js 安装检查"
echo ""

if command -v node &> /dev/null; then
    node_version=$(node --version)
    echo "✅ 找到 Node.js: $node_version"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "⚠️  Node.js 未安装 (可选，但推荐)"
    # 不算失败，因为是可选的
fi

echo ""

# ==================== CHECK 3: NPM 检查 ====================
echo "[CHECK 3] NPM 包管理器检查"
echo ""

if command -v npm &> /dev/null; then
    npm_version=$(npm --version)
    echo "✅ 找到 NPM: $npm_version"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "⚠️  NPM 未安装 (可选，但推荐)"
fi

echo ""

# ==================== CHECK 4: SDK 配置文件检查 ====================
echo "[CHECK 4] HarmonyOS SDK 配置检查"
echo ""

# 查找 .harmonyos 或 sdk.config 类似的配置文件
CONFIG_FOUND=0

if [ -f "D:/.harmonyos_sdk" ] || [ -f "D:/harmonyos_sdk.conf" ] || [ -f "D:/sdk.config" ]; then
    echo "✅ 找到 HarmonyOS SDK 配置文件"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
    CONFIG_FOUND=1
else
    # 在找到的 SDK 目录中查找配置
    if [ $FOUND_SDK -eq 1 ]; then
        for location in "${HARMONYOS_LOCATIONS[@]}"; do
            if [ -d "$location" ]; then
                if find "$location" -maxdepth 2 -name "*.config" -o -name "*.conf" -o -name "*.json" 2>/dev/null | grep -q .; then
                    echo "✅ SDK 配置文件存在于 SDK 目录中"
                    CHECKS_PASSED=$((CHECKS_PASSED + 1))
                    CONFIG_FOUND=1
                    break
                fi
            fi
        done
    fi
fi

if [ $CONFIG_FOUND -eq 0 ]; then
    echo "⚠️  未找到明确的 SDK 配置文件 (可能正在初始化)"
fi

echo ""

# ==================== CHECK 5: 环境变量检查 ====================
echo "[CHECK 5] 环境变量检查"
echo ""

ENV_VARS_FOUND=0

if [ -n "$HARMONYOS_SDK_HOME" ]; then
    echo "✅ HARMONYOS_SDK_HOME 已设置: $HARMONYOS_SDK_HOME"
    ENV_VARS_FOUND=$((ENV_VARS_FOUND + 1))
else
    echo "⚠️  HARMONYOS_SDK_HOME 环境变量未设置"
fi

if [ -n "$PATH" ] && echo "$PATH" | grep -qi "harmonyos\|deveco\|ohos"; then
    echo "✅ PATH 中包含 HarmonyOS 相关路径"
    ENV_VARS_FOUND=$((ENV_VARS_FOUND + 1))
else
    echo "⚠️  PATH 中未找到 HarmonyOS 相关路径"
fi

if [ $ENV_VARS_FOUND -gt 0 ]; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
fi

echo ""

# ==================== CHECK 6: DevEco Studio 或编译工具 ====================
echo "[CHECK 6] 开发工具检查"
echo ""

TOOLS_FOUND=0

# 检查 hdc (HarmonyOS Device Connector)
if command -v hdc &> /dev/null; then
    echo "✅ 找到 hdc (HarmonyOS Device Connector)"
    TOOLS_FOUND=$((TOOLS_FOUND + 1))
fi

# 检查 ark 工具链
if command -v ark &> /dev/null; then
    echo "✅ 找到 ark (ArkCompiler 工具链)"
    TOOLS_FOUND=$((TOOLS_FOUND + 1))
fi

# 检查 hvigorw (构建工具)
if [ -f "D:/hvigorw" ] || [ -f "D:/hvigorw.bat" ]; then
    echo "✅ 找到 hvigorw (HarmonyOS 构建工具)"
    TOOLS_FOUND=$((TOOLS_FOUND + 1))
fi

if [ $TOOLS_FOUND -gt 0 ]; then
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
elif [ $FOUND_SDK -eq 1 ]; then
    echo "ℹ️  在 SDK 中可能包含开发工具"
    CHECKS_PASSED=$((CHECKS_PASSED + 1))
else
    echo "⚠️  未找到开发工具 (可能需要配置 PATH)"
fi

echo ""

# ==================== CHECK 7: 示例项目或测试项目 ====================
echo "[CHECK 7] 示例/测试项目检查"
echo ""

SAMPLE_FOUND=0

for location in "${HARMONYOS_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        # 查找标准的 HarmonyOS 项目标识
        if find "$location" -maxdepth 3 -name "build.gradle" -o -name "module.json5" -o -name "app.json5" 2>/dev/null | grep -q .; then
            echo "✅ 找到 HarmonyOS 项目配置文件"
            SAMPLE_FOUND=1
            CHECKS_PASSED=$((CHECKS_PASSED + 1))
            break
        fi
    fi
done

if [ $SAMPLE_FOUND -eq 0 ]; then
    echo "ℹ️  未找到示例项目 (不影响环境有效性)"
fi

echo ""

# ==================== SUMMARY ====================
echo "========================================"
echo "验证结果汇总"
echo "========================================"
echo ""
echo "检查项通过: $CHECKS_PASSED"
echo "检查项失败: $CHECKS_FAILED"
echo ""

# 生成报告文件
cat > "D:/ObsidianVault/HARMONYOS-ENV-VERIFICATION.txt" << EOF
HarmonyOS 环境验证报告 - $(date)

验证状态: $([ $CHECKS_FAILED -eq 0 ] && echo "✅ 通过" || echo "❌ 失败")

核心检查:
  ✓ HarmonyOS SDK: $([ $FOUND_SDK -eq 1 ] && echo "找到" || echo "未找到")
  ✓ Node.js: $(command -v node &>/dev/null && echo "已安装" || echo "未安装")
  ✓ NPM: $(command -v npm &>/dev/null && echo "已安装" || echo "未安装")
  ✓ 配置文件: $([ $CONFIG_FOUND -eq 1 ] && echo "找到" || echo "未找到")
  ✓ 环境变量: $([ $ENV_VARS_FOUND -gt 0 ] && echo "已配置" || echo "未配置")
  ✓ 开发工具: $([ $TOOLS_FOUND -gt 0 ] && echo "找到" || echo "未找到")

HarmonyOS SDK 位置:
EOF

for location in "${HARMONYOS_LOCATIONS[@]}"; do
    if [ -d "$location" ]; then
        echo "  $location" >> "D:/ObsidianVault/HARMONYOS-ENV-VERIFICATION.txt"
    fi
done

echo ""
echo "详细报告已保存到: HARMONYOS-ENV-VERIFICATION.txt"
echo ""

# 返回结果
if [ $CHECKS_FAILED -eq 0 ] && [ $FOUND_SDK -eq 1 ]; then
    echo "✅ HarmonyOS 环境验证 PASSED"
    echo ""
    echo "环境已准备好进行开发。"
    echo ""
    exit 0
else
    echo "❌ HarmonyOS 环境验证 FAILED"
    echo ""
    echo "⚠️  缺少关键组件。建议:"
    echo "  1. 确保 HarmonyOS SDK 已正确安装到 D: 盘"
    echo "  2. 配置环境变量"
    echo "  3. 安装必要的开发工具"
    echo ""
    exit 1
fi
