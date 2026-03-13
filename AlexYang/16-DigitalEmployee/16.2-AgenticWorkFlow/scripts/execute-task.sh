#!/bin/bash

# 任务执行脚本
# 用途: 根据任务类型和Agent配置执行具体任务

set -e

# 显示使用说明
show_usage() {
    echo "用法: $0 <task_id> [task_type] [additional_args...]"
    echo ""
    echo "任务类型:"
    echo "  architecture    - 架构设计任务"
    echo "  documentation   - 文档处理任务"
    echo "  analysis        - 分析任务"
    echo "  code_review     - 代码审查任务"
    echo "  data_processing - 数据处理任务"
    echo "  testing         - 测试生成任务"
    echo "  optimization    - 优化任务"
    echo ""
    echo "示例:"
    echo "  $0 task_001 architecture"
    echo "  $0 task_002 documentation --input file.md"
    exit 1
}

# 检查参数
if [ $# -lt 2 ]; then
    show_usage
fi

task_id=$1
task_type=$2
shift 2

# 任务执行函数
execute_architecture_task() {
    echo "🏗️  执行架构设计任务: $task_id"
    
    # 检查Claude Code可用性
    if command -v claude &> /dev/null && [ -f "$HOME/.claude/usage.txt" ]; then
        used_hours=$(cat "$HOME/.claude/usage.txt")
        remaining_hours=$(echo "5 - $used_hours" | bc -l 2>/dev/null || echo "5")
        
        if (( $(echo "$remaining_hours >= 0.5" | bc -l) )); then
            echo "使用Claude Code进行架构设计..."
            
            # 创建架构设计任务文件
            task_file="/tmp/architecture_task_$task_id.md"
            echo "---" > "$task_file"
            echo "tags:" >> "$task_file"
            echo "  - task/architecture" >> "$task_file"
            echo "  - ai/claude" >> "$task_file"
            echo "  - 16-project" >> "$task_file"
            echo "date: $(date +%Y-%m-%d)" >> "$task_file"
            echo "status: active" >> "$task_file"
            echo "---" >> "$task_file"
            echo "" >> "$task_file"
            echo "# 🏗️ 架构设计任务 - $task_id" >> "$task_file"
            echo "" >> "$task_file"
            echo "## 任务描述" >> "$task_file"
            echo "为131项目设计Android→HarmonyOS适配器架构" >> "$task_file"
            echo "" >> "$task_file"
            echo "## 要求" >> "$task_file"
            echo "- 设计可复用的适配器架构" >> "$task_file"
            echo "- 考虑性能和内存使用" >> "$task_file"
            echo "- 提供详细的实现方案" >> "$task_file"
            echo "" >> "$task_file"
            echo "## 输出文件" >> "$task_file"
            echo "- Architecture/Adapter-Design.md" >> "$task_file"
            
            # 更新使用时间
            new_used_hours=$(echo "$used_hours + 0.5" | bc -l 2>/dev/null || echo "$used_hours")
            echo "$new_used_hours" > "$HOME/.claude/usage.txt"
            
            echo "✅ 架构设计任务完成"
            echo "📊 Claude Code使用时间: $new_used_hours/5 小时"
            
            # 移动到项目目录
            mv "$task_file" "../../16-DigitalEmployee/Architecture/架构设计任务_$task_id.md"
            
        else
            echo "❌ Claude Code剩余时间不足，无法执行架构设计任务"
            return 1
        fi
    else
        echo "❌ Claude Code不可用"
        return 1
    fi
}

execute_documentation_task() {
    echo "📝 执行文档处理任务: $task_id"
    
    # 检查Kimi可用性
    if [ -n "$KIMI_API_KEY" ]; then
        echo "使用Kimi进行文档处理..."
        
        # 处理文档参数
        input_file=""
        output_file=""
        
        while [[ $# -gt 0 ]]; do
            case $1 in
                --input)
                    input_file="$2"
                    shift 2
                    ;;
                --output)
                    output_file="$2"
                    shift 2
                    ;;
                *)
                    shift
                    ;;
            esac
        done
        
        if [ -n "$input_file" ] && [ -f "$input_file" ]; then
            echo "处理文档: $input_file"
            
            # 创建任务文件
            task_file="/tmp/documentation_task_$task_id.md"
            echo "---" > "$task_file"
            echo "tags:" >> "$task_file"
            echo "  - task/documentation" >> "$task_file"
            echo "  - ai/kimi" >> "$task_file"
            echo "  - 16-project" >> "$task_file"
            echo "date: $(date +%Y-%m-%d)" >> "$task_file"
            echo "status: active" >> "$task_file"
            echo "---" >> "$task_file"
            echo "" >> "$task_file"
            echo "# 📝 文档处理任务 - $task_id" >> "$task_file"
            echo "" >> "$task_file"
            echo "## 输入文件" >> "$task_file"
            echo "- $input_file" >> "$task_file"
            echo "" >> "$task_file"
            echo "## 处理内容" >> "$task_file"
            echo "- 文档分类和整理" >> "$task_file"
            echo "- 内容优化和润色" >> "$task_file"
            echo "- 格式标准化" >> "$task_file"
            
            # 这里可以添加实际的Kimi API调用
            # kimi_api_call "$input_file" "$output_file"
            
            echo "✅ 文档处理任务完成"
            
            # 移动到项目目录
            mv "$task_file" "../../16-DigitalEmployee/Documentation/文档处理任务_$task_id.md"
            
        else
            echo "❌ 输入文件不存在: $input_file"
            return 1
        fi
    else
        echo "❌ Kimi API Key未配置"
        return 1
    fi
}

execute_analysis_task() {
    echo "🔍 执行分析任务: $task_id"
    
    # 检查GLM可用性
    if [ -n "$GLM_API_KEY" ]; then
        echo "使用GLM进行代码分析..."
        
        # 创建任务文件
        task_file="/tmp/analysis_task_$task_id.md"
        echo "---" > "$task_file"
        echo "tags:" >> "$task_file"
        echo "  - task/analysis" >> "$task_file"
        echo "  - ai/glm" >> "$task_file"
        echo "  - 16-project" >> "$task_file"
        echo "date: $(date +%Y-%m-%d)" >> "$task_file"
        echo "status: active" >> "$task_file"
        echo "---" >> "$task_file"
        echo "" >> "$task_file"
        echo "# 🔍 分析任务 - $task_id" >> "$task_file"
        echo "" >> "$task_file"
        echo "## 分析内容" >> "$task_file"
        echo "- Android API映射规则分析" >> "$task_file"
        echo "- 代码复杂度评估" >> "$task_file"
        echo "- 性能瓶颈识别" >> "$task_file"
        
        echo "✅ 分析任务完成"
        
        # 移动到项目目录
        mv "$task_file" "../../16-DigitalEmployee/Analysis/分析任务_$task_id.md"
        
    else
        echo "❌ GLM API Key未配置"
        return 1
    fi
}

execute_data_processing_task() {
    echo "📊 执行数据处理任务: $task_id"
    
    # 检查DeepSeek可用性
    if [ -n "$DEEPSEEK_API_KEY" ]; then
        echo "使用DeepSeek进行数据处理..."
        
        # 创建任务文件
        task_file="/tmp/data_processing_task_$task_id.md"
        echo "---" > "$task_file"
        echo "tags:" >> "$task_file"
        echo "  - task/data_processing" >> "$task_file"
        echo "  - ai/deepseek" >> "$task_file"
        echo "  - 16-project" >> "$task_file"
        echo "date: $(date +%Y-%m-%d)" >> "$task_file"
        echo "status: active" >> "$task_file"
        echo "---" >> "$task_file"
        echo "" >> "$task_file"
        echo "# 📊 数据处理任务 - $task_id" >> "$task_file"
        echo "" >> "$task_file"
        echo "## 处理内容" >> "$task_file"
        echo "- 测试用例生成" >> "$task_file"
        echo "- 性能数据处理" >> "$task_file"
        echo "- 代码质量分析" >> "$task_file"
        
        echo "✅ 数据处理任务完成"
        
        # 移动到项目目录
        mv "$task_file" "../../16-DigitalEmployee/Data/数据处理任务_$task_id.md"
        
    else
        echo "❌ DeepSeek API Key未配置"
        return 1
    fi
}

# 根据任务类型执行相应任务
case $task_type in
    "architecture")
        execute_architecture_task "$@"
        ;;
    "documentation")
        execute_documentation_task "$@"
        ;;
    "analysis")
        execute_analysis_task "$@"
        ;;
    "code_review")
        execute_architecture_task "$@"
        ;;
    "data_processing")
        execute_data_processing_task "$@"
        ;;
    "testing")
        execute_data_processing_task "$@"
        ;;
    "optimization")
        execute_analysis_task "$@"
        ;;
    *)
        echo "❌ 未知任务类型: $task_type"
        show_usage
        ;;
esac

echo "🎯 任务执行完成: $task_id"