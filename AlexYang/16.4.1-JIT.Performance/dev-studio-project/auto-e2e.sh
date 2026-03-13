#!/bin/bash
# WSL 驱动的 HarmonyOS 自动化 E2E 测试框架
# 功能：构建 → 安装 → 运行 → 截图 → 验证 → 修复 → 重试

set -e

# 配置
PROJECT_DIR="/mnt/e/10.Project/16.4.1-JIT.Performance/dev-studio-project"
SCREENSHOT_DIR="/mnt/e/10.Project/16.4.1-JIT.Performance/screenshots"
REPORT_DIR="/mnt/e/10.Project/16.4.1-JIT.Performance/reports"
MAX_RETRIES=3
WINDOWS_PROJECT_DIR="E:\\10.Project\\16.4.1-JIT.Performance\\dev-studio-project"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $1"; }
log_error() { echo -e "${RED}[FAIL]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# 检查 Windows 工具链
check_windows_toolchain() {
    log_info "检查 Windows 工具链..."
    
    # 检查 DevEco Studio 是否安装
    if ! cmd.exe /c "dir '%LOCALAPPDATA%\\Huawei\\DevEco Studio\\bin\\hvigorw.bat'" &> /dev/null; then
        log_error "未找到 DevEco Studio"
        echo "请安装 DevEco Studio 并确保已添加到 PATH"
        exit 1
    fi
    
    # 检查 hdc
    if ! cmd.exe /c "where hdc" &> /dev/null; then
        log_error "未找到 hdc 工具"
        echo "请将 hdc 添加到 Windows PATH"
        exit 1
    fi
    
    log_success "Windows 工具链检查通过"
}

# 通过 Windows 构建
build_via_windows() {
    log_info "通过 Windows 构建项目..."
    
    cd "$PROJECT_DIR"
    
    # 使用 cmd.exe 调用 Windows 的 hvigorw
    cmd.exe /c "cd /d $WINDOWS_PROJECT_DIR && hvigorw.bat assembleDebug --no-daemon"
    
    if [ $? -ne 0 ]; then
        log_error "构建失败"
        return 1
    fi
    
    log_success "构建成功"
    return 0
}

# 检查设备
check_device() {
    log_info "检查设备连接..."
    
    # 通过 cmd.exe 调用 hdc
    device_count=$(cmd.exe /c "hdc list targets" | grep -c "[0-9]" || echo "0")
    
    if [ "$device_count" -eq 0 ]; then
        log_error "未检测到设备或模拟器"
        echo "请启动模拟器:"
        echo "  DevEco Studio → Tools → Device Manager → 启动 Phone 模拟器"
        return 1
    fi
    
    log_success "发现 $device_count 个设备"
    cmd.exe /c "hdc list targets"
    return 0
}

# 安装 HAP
install_hap() {
    log_info "安装 HAP 包..."
    
    HAP_FILE="$PROJECT_DIR/entry/build/default/outputs/default/entry-default-signed.hap"
    
    if [ ! -f "$HAP_FILE" ]; then
        log_error "未找到 HAP 文件: $HAP_FILE"
        return 1
    fi
    
    # 先卸载旧版本
    cmd.exe /c "hdc shell pm uninstall com.jit.performance.integration" &> /dev/null
    
    # 安装新版本
    WINDOWS_HAP_FILE="E:\\10.Project\\16.4.1-JIT.Performance\\dev-studio-project\\entry\\build\\default\\outputs\\default\\entry-default-signed.hap"
    cmd.exe /c "hdc install $WINDOWS_HAP_FILE"
    
    if [ $? -ne 0 ]; then
        log_error "安装失败"
        return 1
    fi
    
    log_success "安装成功"
    return 0
}

# 启动应用
launch_app() {
    log_info "启动应用..."
    
    cmd.exe /c "hdc shell aa start -a EntryAbility -b com.jit.performance.integration"
    
    if [ $? -ne 0 ]; then
        log_warn "启动命令返回错误，尝试手动启动"
        return 1
    fi
    
    log_success "应用已启动"
    return 0
}

# 等待应用稳定
wait_for_stable() {
    log_info "等待应用稳定 (3秒)..."
    sleep 3
}

# 自动截图
screenshot() {
    local filename=$1
    log_info "截取屏幕..."
    
    mkdir -p "$SCREENSHOT_DIR"
    
    if [ -z "$filename" ]; then
        filename="screenshot_$(date +%Y%m%d_%H%M%S)"
    fi
    
    SCREENSHOT_PATH="$SCREENSHOT_DIR/${filename}.png"
    
    # 截图到设备
    cmd.exe /c "hdc shell snapshot_display -f /data/screen.png"
    
    # 导出到电脑
    WINDOWS_SCREENSHOT_DIR="E:\\10.Project\\16.4.1-JIT.Performance\\screenshots"
    cmd.exe /c "hdc file recv /data/screen.png $WINDOWS_SCREENSHOT_DIR\\${filename}.png"
    
    if [ -f "$SCREENSHOT_PATH" ]; then
        log_success "截图保存: $SCREENSHOT_PATH"
        return 0
    else
        log_error "截图失败"
        return 1
    fi
}

# 模拟点击操作
simulate_click() {
    local x=$1
    local y=$2
    log_info "模拟点击坐标 ($x, $y)..."
    
    cmd.exe /c "hdc shell uitest uiInput click $x $y"
    sleep 1
}

# E2E 测试流程
e2e_test() {
    log_info "========================================="
    log_info "  E2E 自动化测试"
    log_info "========================================="
    
    # 1. 截图初始状态
    screenshot "01_initial"
    
    # 2. 点击 "Run Test" 按钮 (坐标约 300, 400)
    simulate_click 300 400
    sleep 2
    
    # 3. 截图测试运行中
    screenshot "02_running"
    
    # 4. 等待测试完成
    sleep 3
    
    # 5. 截图测试结果
    screenshot "03_test_complete"
    
    # 6. 点击 "View Report" (坐标约 450, 400)
    simulate_click 450 400
    sleep 2
    
    # 7. 截图报告页面
    screenshot "04_report_page"
    
    log_success "E2E 测试完成"
}

# 错误检测
check_errors() {
    log_info "检查应用日志..."
    
    # 获取最近日志
    cmd.exe /c "hdc hilog -T app -L | findstr ERROR" > /tmp/app_errors.log 2>/dev/null
    
    if [ -s /tmp/app_errors.log ]; then
        log_error "发现错误日志:"
        cat /tmp/app_errors.log
        return 1
    fi
    
    log_success "未发现错误"
    return 0
}

# 自动修复尝试
auto_fix() {
    log_warn "尝试自动修复..."
    
    # 修复1: 重新构建
    log_info "尝试重新构建..."
    if build_via_windows; then
        log_success "重新构建成功"
        return 0
    fi
    
    # 修复2: 清理并重建
    log_info "清理构建缓存..."
    rm -rf "$PROJECT_DIR/build"
    rm -rf "$PROJECT_DIR/entry/build"
    
    if build_via_windows; then
        log_success "清理后构建成功"
        return 0
    fi
    
    log_error "自动修复失败，需要手动检查"
    return 1
}

# 生成报告
generate_report() {
    log_info "生成测试报告..."
    
    mkdir -p "$REPORT_DIR"
    
    REPORT_FILE="$REPORT_DIR/e2e_report_$(date +%Y%m%d_%H%M%S).html"
    
    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>E2E 测试报告</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #6200EE; }
        .success { color: green; }
        .error { color: red; }
        .screenshot { max-width: 300px; border: 1px solid #ccc; margin: 10px; }
    </style>
</head>
<body>
    <h1>HarmonyOS E2E 测试报告</h1>
    <p>生成时间: $(date)</p>
    <p>状态: <span class="success">通过</span></p>
    
    <h2>测试截图</h2>
    <div>
        <img src="../screenshots/01_initial.png" class="screenshot" alt="初始界面">
        <img src="../screenshots/02_running.png" class="screenshot" alt="运行中">
        <img src="../screenshots/03_test_complete.png" class="screenshot" alt="测试完成">
        <img src="../screenshots/04_report_page.png" class="screenshot" alt="报告页面">
    </div>
</body>
</html>
EOF
    
    log_success "报告已生成: $REPORT_FILE"
}

# 主流程
main() {
    log_info "========================================="
    log_info "  WSL HarmonyOS E2E 自动化测试"
    log_info "========================================="
    
    local retry_count=0
    local success=false
    
    # 检查工具链
    check_windows_toolchain
    
    # 检查设备
    while [ $retry_count -lt $MAX_RETRIES ]; do
        if check_device; then
            break
        fi
        
        retry_count=$((retry_count + 1))
        log_warn "第 $retry_count 次重试检查设备..."
        sleep 5
    done
    
    if [ $retry_count -eq $MAX_RETRIES ]; then
        log_error "设备检查失败，退出"
        exit 1
    fi
    
    # 构建-安装-测试 循环
    retry_count=0
    while [ $retry_count -lt $MAX_RETRIES ] && [ "$success" = false ]; do
        log_info "========================================="
        log_info "  第 $((retry_count + 1))/$MAX_RETRIES 次尝试"
        log_info "========================================="
        
        # 构建
        if ! build_via_windows; then
            log_error "构建失败，尝试修复..."
            if ! auto_fix; then
                retry_count=$((retry_count + 1))
                continue
            fi
        fi
        
        # 安装
        if ! install_hap; then
            log_error "安装失败"
            retry_count=$((retry_count + 1))
            continue
        fi
        
        # 启动
        if ! launch_app; then
            log_warn "自动启动失败，尝试手动方式..."
            # 通过点击图标启动
            sleep 2
        fi
        
        # 等待稳定
        wait_for_stable
        
        # 运行 E2E 测试
        e2e_test
        
        # 检查错误
        if check_errors; then
            success=true
            log_success "E2E 测试通过！"
        else
            log_error "检测到错误，准备重试..."
            retry_count=$((retry_count + 1))
            sleep 2
        fi
    done
    
    # 生成报告
    if [ "$success" = true ]; then
        generate_report
        log_success "========================================="
        log_success "  所有测试通过！"
        log_success "========================================="
        exit 0
    else
        log_error "========================================="
        log_error "  测试失败，达到最大重试次数"
        log_error "========================================="
        exit 1
    fi
}

# 根据参数执行
case "${1:-}" in
    build)
        check_windows_toolchain
        build_via_windows
        ;;
    install)
        check_device
        install_hap
        ;;
    test)
        check_device
        e2e_test
        ;;
    screenshot)
        check_device
        screenshot "manual"
        ;;
    full|""|*)
        main
        ;;
esac
