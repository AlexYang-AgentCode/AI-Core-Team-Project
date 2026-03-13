#!/bin/bash

# 监控脚本
# 用途: 持续监控Agent状态和任务执行情况

set -e

echo "🔍 启动监控 - $(date)"
echo "=================================="

# 创建监控日志
log_file="/tmp/agent_monitor_$(date +%Y%m%d).log"

# 监控函数
monitor_agents() {
    while true; do
        timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
        
        echo "[$timestamp] 开始监控..." >> "$log_file"
        
        # 检查Claude Code状态
        if command -v claude &> /dev/null; then
            if [ -f "$HOME/.claude/usage.txt" ]; then
                used_hours=$(cat "$HOME/.claude/usage.txt")
                remaining_hours=$(echo "5 - $used_hours" | bc -l 2>/dev/null || echo "5")
                
                echo "[$timestamp] Claude Code - 使用: $used_hours小时, 剩余: $remaining_hours小时" >> "$log_file"
                
                # 检查是否需要警告
                if (( $(echo "$remaining_hours < 1" | bc -l) )); then
                    echo "[$timestamp] ⚠️  警告: Claude Code剩余时间不足1小时" >> "$log_file"
                    # 可以在这里添加通知逻辑
                fi
                
                if (( $(echo "$remaining_hours < 0.5" | bc -l) )); then
                    echo "[$timestamp] 🚨 紧急: Claude Code剩余时间不足30分钟" >> "$log_file"
                    # 可以在这里添加紧急通知逻辑
                fi
            fi
        else
            echo "[$timestamp] ❌ Claude Code不可用" >> "$log_file"
        fi
        
        # 检查其他Agent状态
        if [ -n "$KIMI_API_KEY" ]; then
            echo "[$timestamp] ✅ Kimi - 配置正常" >> "$log_file"
        else
            echo "[$timestamp] ❌ Kimi - API Key未配置" >> "$log_file"
        fi
        
        if [ -n "$GLM_API_KEY" ]; then
            echo "[$timestamp] ✅ GLM - 配置正常" >> "$log_file"
        else
            echo "[$timestamp] ❌ GLM - API Key未配置" >> "$log_file"
        fi
        
        if [ -n "$DEEPSEEK_API_KEY" ]; then
            echo "[$timestamp] ✅ DeepSeek - 配置正常" >> "$log_file"
        else
            echo "[$timestamp] ❌ DeepSeek - API Key未配置" >> "$log_file"
        fi
        
        # 检查项目状态
        project_131_docs=$(find "../../16.1-AndroidToHarmonyOS" -name "*.md" | wc -l)
        project_133_docs=$(find "../../16.3-AndroidAPI-Requirement" -name "*.md" | wc -l)
        
        echo "[$timestamp] 131项目文档数: $project_131_docs" >> "$log_file"
        echo "[$timestamp] 133项目文档数: $project_133_docs" >> "$log_file"
        
        # 检查待处理任务
        if [ -d "../../16-DigitalEmployee" ]; then
            pending_tasks=$(find "../../16-DigitalEmployee" -name "*待处理*" -o -name "*waiting*" | wc -l)
            echo "[$timestamp] 待处理任务数: $pending_tasks" >> "$log_file"
        fi
        
        echo "[$timestamp] 监控完成，等待下次检查..." >> "$log_file"
        echo "" >> "$log_file"
        
        # 等待5分钟
        sleep 300
    done
}

# 监控任务执行
monitor_tasks() {
    echo "[$(date)] 启动任务监控..."
    
    while true; do
        timestamp=$(date +%Y-%m-%d\ %H:%M:%S)
        
        # 检查是否有长时间运行的任务
        if [ -d "/tmp" ]; then
            running_tasks=$(find /tmp -name "task_*" -mmin +30 2>/dev/null | wc -l)
            if [ "$running_tasks" -gt 0 ]; then
                echo "[$timestamp] ⚠️  发现 $running_tasks 个长时间运行的任务" >> "$log_file"
            fi
        fi
        
        # 检查任务完成情况
        if [ -d "../../16-DigitalEmployee" ]; then
            completed_tasks=$(find "../../16-DigitalEmployee" -name "*已完成*" -o -name "*completed*" | wc -l)
            echo "[$timestamp] 已完成任务数: $completed_tasks" >> "$log_file"
        fi
        
        sleep 600  # 10分钟检查一次
    done
}

# 显示监控状态
show_status() {
    echo "📊 监控状态"
    echo "=================================="
    echo "监控日志: $log_file"
    echo "开始时间: $(date)"
    echo ""
    echo "按 Ctrl+C 停止监控"
    echo ""
    
    # 显示最近的日志
    if [ -f "$log_file" ]; then
        echo "最近监控记录:"
        tail -10 "$log_file"
    fi
}

# 主函数
main() {
    show_status
    
    # 在后台运行监控
    monitor_agents &
    monitor_tasks &
    
    # 等待用户中断
    wait
    
    echo "监控已停止"
}

# 如果直接运行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi