#!/bin/bash
# DevEco Studio 命令行运行脚本

PROJECT_DIR="/mnt/e/10.Project/16.4.1-JIT.Performance/dev-studio-project"
SCREENSHOT_DIR="/mnt/e/10.Project/16.4.1-JIT.Performance/screenshots"

echo "========================================="
echo "  HarmonyOS 项目命令行运行工具"
echo "========================================="
echo ""

# 检查hvigor
check_hvigor() {
    if ! command -v hvigorw &> /dev/null; then
        echo "❌ 未找到 hvigorw 命令"
        echo "请确保已安装 DevEco Studio 并配置了环境变量"
        echo "或者运行: npm install -g @ohos/hvigor"
        exit 1
    fi
    echo "✓ hvigorw 已安装"
}

# 检查hdc
check_hdc() {
    if ! command -v hdc &> /dev/null; then
        echo "❌ 未找到 hdc 命令"
        echo "请确保 DevEco Studio 的 hdc 工具已在 PATH 中"
        exit 1
    fi
    echo "✓ hdc 已安装"
}

# 检查模拟器
check_emulator() {
    echo "检查模拟器状态..."
    devices=$(hdc list targets 2>/dev/null | wc -l)
    if [ "$devices" -eq 0 ]; then
        echo "❌ 未检测到运行中的模拟器"
        echo "请先在 DevEco Studio 中启动模拟器:"
        echo "  Tools → Device Manager → Local Emulator → 启动"
        exit 1
    fi
    echo "✓ 发现 $devices 个连接的设备"
    hdc list targets
}

# 构建项目
build_project() {
    echo ""
    echo "========================================="
    echo "  开始构建项目..."
    echo "========================================="
    cd "$PROJECT_DIR"
    
    # 清理旧构建
    echo "清理旧构建..."
    rm -rf build
    
    # 构建hap包
    echo "编译项目..."
    hvigorw assembleDebug --no-daemon
    
    if [ $? -ne 0 ]; then
        echo "❌ 构建失败"
        exit 1
    fi
    
    echo "✓ 构建成功"
}

# 安装并运行
install_and_run() {
    echo ""
    echo "========================================="
    echo "  安装并运行应用..."
    echo "========================================="
    
    HAP_FILE="$PROJECT_DIR/entry/build/default/outputs/default/entry-default-signed.hap"
    
    if [ ! -f "$HAP_FILE" ]; then
        echo "❌ 未找到hap文件: $HAP_FILE"
        exit 1
    fi
    
    # 安装hap
    echo "安装应用到模拟器..."
    hdc install "$HAP_FILE"
    
    if [ $? -ne 0 ]; then
        echo "❌ 安装失败"
        exit 1
    fi
    
    echo "✓ 安装成功"
    
    # 启动应用
    echo "启动应用..."
    hdc shell aa start -a EntryAbility -b com.jit.performance.integration
    
    if [ $? -ne 0 ]; then
        echo "⚠️ 启动命令失败，但应用可能已安装成功"
        echo "请手动在模拟器中点击应用图标启动"
    else
        echo "✓ 应用已启动"
    fi
}

# 截屏
screenshot() {
    echo ""
    echo "========================================="
    echo "  截取屏幕..."
    echo "========================================="
    
    mkdir -p "$SCREENSHOT_DIR"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    SCREENSHOT_FILE="$SCREENSHOT_DIR/screenshot_$TIMESTAMP.png"
    
    # 使用hdc截屏
    hdc shell snapshot_display -f /data/screen.png
    hdc file recv /data/screen.png "$SCREENSHOT_FILE"
    
    if [ -f "$SCREENSHOT_FILE" ]; then
        echo "✓ 截图已保存: $SCREENSHOT_FILE"
    else
        echo "⚠️ 截图失败"
    fi
}

# 查看日志
show_logs() {
    echo ""
    echo "========================================="
    echo "  应用日志 (按 Ctrl+C 停止)..."
    echo "========================================="
    hdc hilog | grep -E "(JIT|testTag|Performance)"
}

# 主菜单
main_menu() {
    echo ""
    echo "请选择操作:"
    echo "  1) 完整流程: 检查→构建→安装→运行"
    echo "  2) 仅构建项目"
    echo "  3) 仅安装运行"
    echo "  4) 截取屏幕"
    echo "  5) 查看日志"
    echo "  6) 卸载应用"
    echo "  q) 退出"
    echo ""
    read -p "请输入选项 [1-6/q]: " choice
    
    case $choice in
        1)
            check_hvigor
            check_hdc
            check_emulator
            build_project
            install_and_run
            echo ""
            echo "✅ 所有步骤完成！"
            echo "应用已在模拟器中运行"
            ;;
        2)
            check_hvigor
            build_project
            ;;
        3)
            check_hdc
            check_emulator
            install_and_run
            ;;
        4)
            check_hdc
            screenshot
            ;;
        5)
            check_hdc
            show_logs
            ;;
        6)
            check_hdc
            echo "卸载应用..."
            hdc shell pm uninstall com.jit.performance.integration
            echo "✓ 卸载完成"
            ;;
        q|Q)
            echo "退出"
            exit 0
            ;;
        *)
            echo "无效选项"
            ;;
    esac
}

# 如果有参数，直接执行
if [ "$1" == "build" ]; then
    check_hvigor
    build_project
elif [ "$1" == "run" ]; then
    check_hdc
    check_emulator
    install_and_run
elif [ "$1" == "full" ]; then
    check_hvigor
    check_hdc
    check_emulator
    build_project
    install_and_run
elif [ "$1" == "screenshot" ]; then
    check_hdc
    screenshot
else
    main_menu
fi
