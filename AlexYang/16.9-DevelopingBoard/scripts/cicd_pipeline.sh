#!/bin/bash
# P7885 完整 CI/CD 自动化流水线脚本
# 
# 该脚本整合了整个开发测试流程：
# 1. 自动编译 OpenHarmony
# 2. 自动烧录镜像到 P7885 开发板
# 3. 自动执行功能测试
# 4. 生成测试报告
#
# Usage:
#   ./cicd_pipeline.sh [options]
#
# Options:
#   --compile-only    只执行编译
#   --flash-only      只执行烧录（需先完成编译）
#   --test-only       只执行测试（需先完成烧录）
#   --full            执行完整流程（默认）
#   --clean           清理编译缓存
#   --help            显示帮助

set -e  # 遇到错误立即退出

# ============================================
# 配置变量
# ============================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="${HOME}/ohos-p7885"
OUTPUT_DIR="/opt/ohos-images"
LOG_DIR="/var/log/p7885-cicd"
TEST_CONFIG="${SCRIPT_DIR}/test_config.json"

# 设备连接配置
DEVICE_IP="192.168.1.100"
DEVICE_SERIAL="/dev/ttyUSB0"
FLASH_METHOD="fel"  # 可选: fel, tf, fastboot

# 编译配置
PRODUCT="hihope_p7885"
JOBS=8
CCACHE=true

# 时间戳
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="${LOG_DIR}/pipeline-${TIMESTAMP}.log"

# ============================================
# 颜色定义
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# 日志函数
# ============================================
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

# ============================================
# 初始化
# ============================================
init() {
    mkdir -p "$LOG_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    log_info "========================================"
    log_info "P7885 CI/CD Pipeline Started"
    log_info "Timestamp: $TIMESTAMP"
    log_info "========================================"
}

# ============================================
# 编译阶段
# ============================================
stage_compile() {
    log_info "========================================"
    log_info "Stage 1: Compile OpenHarmony"
    log_info "========================================"
    
    local start_time=$(date +%s)
    
    # 检查源码目录
    if [[ ! -d "$SOURCE_DIR" ]]; then
        log_error "Source directory not found: $SOURCE_DIR"
        return 1
    fi
    
    cd "$SOURCE_DIR"
    
    # 加载编译环境
    log_info "Loading build environment..."
    source build/envsetup.sh
    lunch ${PRODUCT}-userdebug
    
    # 执行编译
    log_info "Starting build (jobs=$JOBS, ccache=$CCACHE)..."
    
    local build_cmd="./build.sh --product $PRODUCT --jobs $JOBS"
    if [[ "$CCACHE" == "true" ]]; then
        build_cmd="$build_cmd --ccache"
    fi
    
    if $build_cmd 2>&1 | tee -a "$LOG_FILE"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "Build completed in ${duration}s"
        
        # 打包镜像
        package_images
        return 0
    else
        log_error "Build failed!"
        return 1
    fi
}

# ============================================
# 打包镜像
# ============================================
package_images() {
    log_info "Packaging images..."
    
    local image_dir="${SOURCE_DIR}/out/${PRODUCT}/packages/phone/images"
    local build_name="${PRODUCT}-${TIMESTAMP}"
    local package_dir="${OUTPUT_DIR}/${build_name}"
    
    if [[ ! -d "$image_dir" ]]; then
        log_error "Image directory not found: $image_dir"
        return 1
    fi
    
    mkdir -p "$package_dir"
    
    # 复制镜像
    cp -v "$image_dir"/*.img "$package_dir/" 2>&1 | tee -a "$LOG_FILE"
    
    # 生成构建信息
    cat > "${package_dir}/build_info.txt" <<EOF
Build Time: $(date -Iseconds)
Product: $PRODUCT
Source: $SOURCE_DIR
Git Commit: $(cd "$SOURCE_DIR" && git log -1 --oneline 2>/dev/null || echo "N/A")
Build Host: $(hostname)
EOF
    
    log_success "Images packaged to: $package_dir"
    
    # 创建软链接到最新版本
    ln -sfn "$package_dir" "${OUTPUT_DIR}/latest"
}

# ============================================
# 烧录阶段
# ============================================
stage_flash() {
    log_info "========================================"
    log_info "Stage 2: Flash Images to Device"
    log_info "========================================"
    
    local start_time=$(date +%s)
    local image_dir="${OUTPUT_DIR}/latest"
    
    if [[ ! -d "$image_dir" ]]; then
        log_error "Image directory not found: $image_dir"
        return 1
    fi
    
    # 等待设备连接
    log_info "Waiting for device..."
    if ! wait_for_device; then
        log_error "Device not found!"
        return 1
    fi
    
    # 执行烧录
    log_info "Flashing images using method: $FLASH_METHOD"
    
    local python_cmd="python3 ${SCRIPT_DIR}/flash_p7885.py"
    python_cmd="$python_cmd --method $FLASH_METHOD"
    python_cmd="$python_cmd --image-dir $image_dir"
    python_cmd="$python_cmd --serial $DEVICE_SERIAL"
    python_cmd="$python_cmd --wait 30"
    
    if $python_cmd 2>&1 | tee -a "$LOG_FILE"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "Flash completed in ${duration}s"
        
        # 等待系统启动
        log_info "Waiting for system boot..."
        sleep 30
        return 0
    else
        log_error "Flash failed!"
        return 1
    fi
}

# ============================================
# 等待设备
# ============================================
wait_for_device() {
    local timeout=60
    local elapsed=0
    
    while [[ $elapsed -lt $timeout ]]; do
        # 检查USB设备
        if lsusb 2>/dev/null | grep -q "1f3a"; then
            log_success "Device found (FEL mode)"
            return 0
        fi
        
        # 检查串口
        if [[ -e "$DEVICE_SERIAL" ]]; then
            log_success "Device found (Serial)"
            return 0
        fi
        
        sleep 1
        ((elapsed++))
    done
    
    return 1
}

# ============================================
# 测试阶段
# ============================================
stage_test() {
    log_info "========================================"
    log_info "Stage 3: Run Automated Tests"
    log_info "========================================"
    
    local start_time=$(date +%s)
    local image_dir="${OUTPUT_DIR}/latest"
    local report_file="${image_dir}/test_report.json"
    
    # 等待设备网络就绪
    log_info "Waiting for device network..."
    if ! wait_for_network "$DEVICE_IP"; then
        log_warn "Network not ready, trying serial connection"
        TEST_METHOD="serial"
    else
        TEST_METHOD="ssh"
    fi
    
    # 执行测试
    log_info "Running tests via $TEST_METHOD..."
    
    local python_cmd="python3 ${SCRIPT_DIR}/remote_test.py"
    python_cmd="$python_cmd --method $TEST_METHOD"
    
    if [[ "$TEST_METHOD" == "ssh" ]]; then
        python_cmd="$python_cmd --host $DEVICE_IP"
    elif [[ "$TEST_METHOD" == "serial" ]]; then
        python_cmd="$python_cmd --serial-port $DEVICE_SERIAL"
    fi
    
    python_cmd="$python_cmd --report $report_file"
    
    if $python_cmd 2>&1 | tee -a "$LOG_FILE"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "Tests completed in ${duration}s"
        
        # 分析测试结果
        analyze_test_results "$report_file"
        return 0
    else
        log_error "Tests failed!"
        return 1
    fi
}

# ============================================
# 等待网络
# ============================================
wait_for_network() {
    local host=$1
    local timeout=120
    local elapsed=0
    
    while [[ $elapsed -lt $timeout ]]; do
        if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
        ((elapsed++))
    done
    
    return 1
}

# ============================================
# 分析测试结果
# ============================================
analyze_test_results() {
    local report_file=$1
    
    if [[ ! -f "$report_file" ]]; then
        log_warn "Test report not found: $report_file"
        return 1
    fi
    
    # 使用Python解析报告
    python3 <<EOF
import json
import sys

try:
    with open('$report_file', 'r') as f:
        report = json.load(f)
    
    summary = report.get('summary', {})
    
    print("\n" + "="*60)
    print("Test Results Summary")
    print("="*60)
    print(f"Total:    {summary.get('total', 0)}")
    print(f"Passed:   {summary.get('passed', 0)}")
    print(f"Failed:   {summary.get('failed', 0)}")
    print(f"Skipped:  {summary.get('skipped', 0)}")
    print(f"Duration: {summary.get('total_duration', 0):.2f}s")
    print("="*60)
    
    # 显示失败的测试
    failed_tests = [r for r in report.get('results', []) if r['status'] == 'FAIL']
    if failed_tests:
        print("\nFailed Tests:")
        for test in failed_tests:
            print(f"  - {test['test_name']}: {test.get('error', 'Unknown error')}")
    
    # 如果有失败，退出码设为1
    if summary.get('failed', 0) > 0:
        sys.exit(1)
        
except Exception as e:
    print(f"Error analyzing report: {e}")
    sys.exit(1)
EOF
}

# ============================================
# 生成最终报告
# ============================================
generate_final_report() {
    log_info "========================================"
    log_info "Generating Final Report"
    log_info "========================================"
    
    local report_file="${LOG_DIR}/pipeline-report-${TIMESTAMP}.html"
    
    cat > "$report_file" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>P7885 CI/CD Report - ${TIMESTAMP}</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        h1 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        pre { background-color: #f4f4f4; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>P7885 CI/CD Pipeline Report</h1>
    <p>Build Time: $(date -Iseconds)</p>
    <p>Build ID: ${TIMESTAMP}</p>
    
    <h2>Summary</h2>
    <table>
        <tr>
            <th>Stage</th>
            <th>Status</th>
            <th>Log</th>
        </tr>
        <tr>
            <td>Compile</td>
            <td class="${COMPILE_STATUS:-warning}">${COMPILE_STATUS:-PENDING}</td>
            <td><a href="${LOG_FILE}">View Log</a></td>
        </tr>
        <tr>
            <td>Flash</td>
            <td class="${FLASH_STATUS:-warning}">${FLASH_STATUS:-PENDING}</td>
            <td>-</td>
        </tr>
        <tr>
            <td>Test</td>
            <td class="${TEST_STATUS:-warning}">${TEST_STATUS:-PENDING}</td>
            <td><a href="${OUTPUT_DIR}/latest/test_report.json">View Report</a></td>
        </tr>
    </table>
    
    <h2>Build Information</h2>
    <pre>
Product: $PRODUCT
Source: $SOURCE_DIR
Output: $OUTPUT_DIR/latest
    </pre>
    
    <h2>Raw Log</h2>
    <pre>$(tail -100 "$LOG_FILE" | sed 's/</\&lt;/g; s/>/\&gt;/g')</pre>
</body>
</html>
EOF
    
    log_success "Report generated: $report_file"
}

# ============================================
# 清理函数
# ============================================
cleanup() {
    log_info "Cleaning up..."
    # 保留最近的10个构建
    cd "$OUTPUT_DIR"
    ls -t | tail -n +11 | xargs -r rm -rf
}

# ============================================
# 显示帮助
# ============================================
show_help() {
    cat <<EOF
P7885 CI/CD Pipeline

Usage: $0 [options]

Options:
    --compile-only    只执行编译阶段
    --flash-only      只执行烧录阶段（需先完成编译）
    --test-only       只执行测试阶段（需先完成烧录）
    --full            执行完整流程（默认）
    --clean           清理编译缓存
    --help            显示此帮助

Environment Variables:
    SOURCE_DIR        源码目录 (默认: ~/ohos-p7885)
    OUTPUT_DIR        输出目录 (默认: /opt/ohos-images)
    DEVICE_IP         设备IP地址 (默认: 192.168.1.100)
    DEVICE_SERIAL     串口设备 (默认: /dev/ttyUSB0)

Examples:
    # 完整流程
    $0 --full

    # 只编译
    $0 --compile-only

    # 清理并重新编译
    $0 --clean --compile-only

EOF
}

# ============================================
# 主函数
# ============================================
main() {
    local mode="full"
    local do_clean=false
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --compile-only)
                mode="compile"
                shift
                ;;
            --flash-only)
                mode="flash"
                shift
                ;;
            --test-only)
                mode="test"
                shift
                ;;
            --full)
                mode="full"
                shift
                ;;
            --clean)
                do_clean=true
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 初始化
    init
    
    # 清理（如果需要）
    if [[ "$do_clean" == "true" ]]; then
        cd "$SOURCE_DIR" && rm -rf out/
        log_success "Cleaned build directory"
    fi
    
    # 执行相应阶段
    local exit_code=0
    
    case $mode in
        compile)
            stage_compile || exit_code=1
            COMPILE_STATUS=$([[ $exit_code -eq 0 ]] && echo "success" || echo "error")
            ;;
        flash)
            stage_flash || exit_code=1
            FLASH_STATUS=$([[ $exit_code -eq 0 ]] && echo "success" || echo "error")
            ;;
        test)
            stage_test || exit_code=1
            TEST_STATUS=$([[ $exit_code -eq 0 ]] && echo "success" || echo "error")
            ;;
        full)
            COMPILE_STATUS="pending"
            FLASH_STATUS="pending"
            TEST_STATUS="pending"
            
            stage_compile && COMPILE_STATUS="success" || COMPILE_STATUS="error"
            if [[ "$COMPILE_STATUS" == "success" ]]; then
                stage_flash && FLASH_STATUS="success" || FLASH_STATUS="error"
                if [[ "$FLASH_STATUS" == "success" ]]; then
                    stage_test && TEST_STATUS="success" || TEST_STATUS="error"
                fi
            fi
            
            [[ "$COMPILE_STATUS" == "error" ]] && exit_code=1
            ;;
    esac
    
    # 生成报告
    generate_final_report
    
    # 清理旧构建
    cleanup
    
    log_info "========================================"
    if [[ $exit_code -eq 0 ]]; then
        log_success "Pipeline completed successfully!"
    else
        log_error "Pipeline failed!"
    fi
    log_info "Log: $LOG_FILE"
    log_info "========================================"
    
    exit $exit_code
}

# 运行主函数
main "$@"
