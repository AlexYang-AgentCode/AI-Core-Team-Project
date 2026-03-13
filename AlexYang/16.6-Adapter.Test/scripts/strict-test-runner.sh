#!/bin/bash
# strict-test-runner.sh
# 16.6-Adapter.Test - 严格测试执行器
# 基于 The Paranoid Professional 人格设计

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 严格阈值定义
STRICT_THRESHOLDS=(
    "PIXEL_DIFF_TOLERANCE=0"        # 0像素差异容忍
    "COLOR_DIFF_TOLERANCE=1"        # RGB差异容忍
    "RESPONSE_TIME_LIMIT=100"       # 100ms响应时间
    "PASS_RATE_THRESHOLD=100"       # 100%通过率
    "PERFORMANCE_REGRESSION_LIMIT=5" # 5%性能回归限制
)

# 失败计数器
CRITICAL_FAILS=0
HIGH_FAILS=0
MEDIUM_FAILS=0

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 像素级对比函数
pixel_perfect_compare() {
    local img1=$1
    local img2=$2
    local output_diff=$3
    
    if [ ! -f "$img1" ] || [ ! -f "$img2" ]; then
        log_error "Missing image for comparison"
        return 1
    fi
    
    # 使用 ImageMagick 进行像素级对比
    local diff_count=$(compare -metric AE "$img1" "$img2" "$output_diff" 2>&1 | grep -oP '^\d+')
    
    if [ "$diff_count" -gt 0 ]; then
        log_error "PIXEL DIFFERENCE DETECTED: $diff_count pixels different"
        log_error "This is a FAIL - zero tolerance for visual differences"
        return 1
    else
        log_info "Pixel-perfect match ✓"
        return 0
    fi
}

# 性能回归检查
performance_regression_check() {
    local metric=$1
    local baseline=$2
    local actual=$3
    
    local diff_percent=$(echo "scale=2; ($actual - $baseline) / $baseline * 100" | bc)
    
    if (( $(echo "$diff_percent > 5" | bc -l) )); then
        log_error "PERFORMANCE REGRESSION: $metric"
        log_error "Baseline: ${baseline}ms, Actual: ${actual}ms, Regression: ${diff_percent}%"
        log_error "Threshold: 5%, Status: FAIL"
        return 1
    else
        log_info "Performance within tolerance: ${diff_percent}% regression ✓"
        return 0
    fi
}

# 边界测试执行
boundary_test() {
    local test_name=$1
    local test_cmd=$2
    
    log_info "Executing boundary test: $test_name"
    
    # 测试空输入
    if ! eval "${test_cmd} ''"; then
        log_error "EMPTY INPUT TEST FAILED for $test_name"
        ((CRITICAL_FAILS++))
        return 1
    fi
    
    # 测试超长输入 (1MB)
    local long_input=$(python3 -c "print('A' * 1048576)")
    if ! eval "${test_cmd} '$long_input'"; then
        log_error "LONG INPUT TEST FAILED for $test_name"
        ((CRITICAL_FAILS++))
        return 1
    fi
    
    # 测试特殊字符
    local special_chars="';<>{}[]|\\$`~!@#$%^&*()"
    if ! eval "${test_cmd} '$special_chars'"; then
        log_error "SPECIAL CHAR TEST FAILED for $test_name"
        ((CRITICAL_FAILS++))
        return 1
    fi
    
    log_info "All boundary tests passed for $test_name ✓"
    return 0
}

# 内存泄漏检查
memory_leak_check() {
    local app_package=$1
    local duration=${2:-300}  # 默认5分钟
    
    log_info "Starting memory leak check for $app_package (${duration}s)"
    
    # 获取初始内存
    local initial_memory=$(adb shell dumpsys meminfo $app_package | grep "TOTAL" | awk '{print $2}')
    
    # 运行测试负载
    sleep $duration
    
    # 获取最终内存
    local final_memory=$(adb shell dumpsys meminfo $app_package | grep "TOTAL" | awk '{print $2}')
    
    # 计算泄漏
    local leak=$((final_memory - initial_memory))
    
    if [ $leak -gt 1024 ]; then  # >1MB泄漏
        log_error "MEMORY LEAK DETECTED: ${leak}KB"
        log_error "Initial: ${initial_memory}KB, Final: ${final_memory}KB"
        ((CRITICAL_FAILS++))
        return 1
    else
        log_info "No significant memory leak detected ✓"
        return 0
    fi
}

# 帧率稳定性检查
fps_stability_check() {
    local duration=${1:-10}  # 测试10秒
    
    log_info "Checking FPS stability for ${duration}s"
    
    # 使用 dumpsys gfxinfo
    adb shell dumpsys gfxinfo com.example.app framestats > /tmp/fps_data.txt
    
    # 分析帧率
    local total_frames=$(grep -c "Flags" /tmp/fps_data.txt)
    local janky_frames=$(grep -c "janky" /tmp/fps_data.txt || echo "0")
    
    local janky_percent=$(echo "scale=2; $janky_frames / $total_frames * 100" | bc)
    
    if (( $(echo "$janky_percent > 5" | bc -l) )); then
        log_error "FPS INSTABILITY: ${janky_percent}% janky frames"
        log_error "Total: $total_frames, Janky: $janky_frames"
        ((HIGH_FAILS++))
        return 1
    else
        log_info "FPS stable: ${janky_percent}% janky frames ✓"
        return 0
    fi
}

# 安全扫描
security_scan() {
    local apk_path=$1
    
    log_info "Starting security scan on $apk_path"
    
    # 检查硬编码密钥
    if strings "$apk_path" | grep -iE "(password|secret|key|token)" | grep -v "^$"; then
        log_error "HARDCODED SECRETS DETECTED"
        ((CRITICAL_FAILS++))
        return 1
    fi
    
    # 检查调试标志
    if aapt dump badging "$apk_path" | grep -q "debuggable=\"true\""; then
        log_error "DEBUGGABLE FLAG IS TRUE - SECURITY RISK"
        ((CRITICAL_FAILS++))
        return 1
    fi
    
    # 检查明文存储
    if apktool d -f "$apk_path" -o /tmp/apk_analysis 2>/dev/null; then
        if grep -r "SharedPreferences" /tmp/apk_analysis/smali 2>/dev/null | grep -v "MODE_PRIVATE"; then
            log_warn "SharedPreferences without MODE_PRIVATE detected"
            ((MEDIUM_FAILS++))
        fi
    fi
    
    log_info "Security scan completed ✓"
    return 0
}

# 证据链完整性检查
evidence_integrity_check() {
    local evidence_dir=$1
    local required_files=("screenshots" "logs" "metrics.json" "timestamp.txt")
    
    log_info "Checking evidence integrity in $evidence_dir"
    
    for file in "${required_files[@]}"; do
        if [ ! -e "$evidence_dir/$file" ]; then
            log_error "MISSING EVIDENCE: $file"
            return 1
        fi
    done
    
    # 检查时间戳合理性
    local evidence_time=$(cat "$evidence_dir/timestamp.txt")
    local current_time=$(date +%s)
    local time_diff=$((current_time - evidence_time))
    
    if [ $time_diff -gt 3600 ]; then  # 超过1小时
        log_warn "Evidence is older than 1 hour - may be stale"
    fi
    
    log_info "Evidence integrity verified ✓"
    return 0
}

# 主执行函数
main() {
    local case_id=$1
    local platform=$2
    
    log_info "========================================"
    log_info "STRICT TEST EXECUTION - 16.6 Adapter.Test"
    log_info "Case: $case_id | Platform: $platform"
    log_info "Mode: PARANOID PROFESSIONAL"
    log_info "========================================"
    
    # 1. 环境验证
    log_info "Phase 1: Environment Verification"
    if ! environment_check; then
        log_error "Environment check FAILED - aborting"
        exit 1
    fi
    
    # 2. 安装被测应用
    log_info "Phase 2: Application Installation"
    if ! install_app; then
        log_error "Installation FAILED"
        exit 1
    fi
    
    # 3. 安全扫描
    log_info "Phase 3: Security Scan"
    security_scan "$APK_PATH"
    
    # 4. 功能测试（带边界测试）
    log_info "Phase 4: Functional Testing with Boundary Cases"
    for tc in "${TEST_CASES[@]}"; do
        if ! execute_test_case "$tc"; then
            log_error "Test case FAILED: $tc"
            ((CRITICAL_FAILS++))
        fi
        
        # 每个用例后执行边界测试
        boundary_test "$tc" "test_function"
    done
    
    # 5. 性能测试
    log_info "Phase 5: Performance Testing"
    fps_stability_check 30
    performance_regression_check "startup" "$BASELINE_STARTUP" "$ACTUAL_STARTUP"
    
    # 6. 内存泄漏检查
    log_info "Phase 6: Memory Leak Detection"
    memory_leak_check "$PACKAGE_NAME" 300
    
    # 7. 截图对比（像素级）
    log_info "Phase 7: Pixel-Perfect Visual Comparison"
    pixel_perfect_compare "expected.png" "actual.png" "diff.png"
    
    # 8. 证据收集
    log_info "Phase 8: Evidence Collection"
    collect_evidence
    
    # 9. 证据完整性检查
    log_info "Phase 9: Evidence Integrity Verification"
    evidence_integrity_check "$EVIDENCE_DIR"
    
    # 10. 生成报告
    log_info "Phase 10: Report Generation"
    generate_strict_report
    
    # 最终判定
    log_info "========================================"
    log_info "TEST EXECUTION COMPLETE"
    log_info "Critical Fails: $CRITICAL_FAILS"
    log_info "High Fails: $HIGH_FAILS"
    log_info "Medium Fails: $MEDIUM_FAILS"
    log_info "========================================"
    
    if [ $CRITICAL_FAILS -gt 0 ]; then
        log_error "❌ OVERALL RESULT: FAIL (Critical issues found)"
        exit 1
    elif [ $HIGH_FAILS -gt 0 ]; then
        log_error "❌ OVERALL RESULT: FAIL (High severity issues found)"
        exit 1
    elif [ $MEDIUM_FAILS -gt 3 ]; then
        log_warn "⚠️ OVERALL RESULT: PARTIAL (Too many medium issues)"
        exit 2
    else
        log_info "✅ OVERALL RESULT: PASS (All strict criteria met)"
        exit 0
    fi
}

# 使用示例
if [ $# -lt 2 ]; then
    echo "Usage: $0 <case_id> <platform>"
    echo "Example: $0 120 harmony"
    exit 1
fi

main "$@"
