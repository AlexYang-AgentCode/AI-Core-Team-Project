---
tags:
  - system/monitoring
  - ai/agent
  - tracking
  - 16-project
date: 2026-03-11
status: active
---

# 📊 项目Agent状态追踪系统

> **目标**: 实时追踪Agent运行状态、任务执行情况、项目进度

---

## 🎯 追踪系统概览

### **核心功能**
1. **Agent状态监控**: 实时监控各AI Agent的运行状态
2. **任务追踪**: 追踪任务从创建到完成的全过程
3. **项目进度**: 监控各项目的实际进度与计划对比
4. **性能分析**: 分析各Agent的执行效率和成本效益

### **监控频率**
- **Agent状态**: 每5分钟检查一次
- **任务进度**: 每10分钟更新一次
- **项目状态**: 每30分钟汇总一次
- **性能报告**: 每日生成

---

## 🤖 Agent状态追踪

### **1. Agent状态监控面板**

```yaml
# agent-status.yaml
agents:
  claude:
    name: "Claude Code"
    status: "active"
    remaining_hours: 4.2
    daily_limit: 5.0
    daily_usage: 0.8
    efficiency: 3.75
    cost_per_task: 0.16
    last_check: "2026-03-11 15:30"
    health: "good"
    warning: false
    
  kimi:
    name: "Kimi"
    status: "active"
    remaining_hours: "unlimited"
    daily_limit: "unlimited"
    daily_usage: 2.5
    efficiency: 3.2
    cost_per_task: 0.02
    last_check: "2026-03-11 15:30"
    health: "good"
    warning: false
    
  glm:
    name: "GLM"
    status: "active"
    remaining_hours: "unlimited"
    daily_limit: "unlimited"
    daily_usage: 1.8
    efficiency: 2.8
    cost_per_task: 0.015
    last_check: "2026-03-11 15:30"
    health: "good"
    warning: false
    
  deepseek:
    name: "DeepSeek"
    status: "active"
    remaining_hours: "unlimited"
    daily_limit: "unlimited"
    daily_usage: 3.2
    efficiency: 3.8
    cost_per_task: 0.01
    last_check: "2026-03-11 15:30"
    health: "good"
    warning: false
```

### **2. Agent健康度指标**

```python
# agent_health_monitor.py
class AgentHealthMonitor:
    def __init__(self):
        self.health_thresholds = {
            'claude': {
                'warning_hours': 1.0,
                'critical_hours': 0.5,
                'max_daily_hours': 1.0
            },
            'kimi': {
                'warning_rate': 0.8,
                'critical_rate': 0.9,
                'max_daily_hours': 8.0
            },
            'glm': {
                'warning_rate': 0.8,
                'critical_rate': 0.9,
                'max_daily_hours': 8.0
            },
            'deepseek': {
                'warning_rate': 0.8,
                'critical_rate': 0.9,
                'max_daily_hours': 8.0
            }
        }
    
    def check_health(self, agent_name, metrics):
        thresholds = self.health_thresholds[agent_name]
        
        # 检查健康状态
        if agent_name == 'claude':
            if metrics['remaining_hours'] < thresholds['critical_hours']:
                return 'critical'
            elif metrics['remaining_hours'] < thresholds['warning_hours']:
                return 'warning'
            else:
                return 'good'
        else:
            if metrics['daily_usage'] / thresholds['max_daily_hours'] > thresholds['critical_rate']:
                return 'critical'
            elif metrics['daily_usage'] / thresholds['max_daily_hours'] > thresholds['warning_rate']:
                return 'warning'
            else:
                return 'good'
```

---

## 📋 任务追踪系统

### **1. 任务状态管理**

```yaml
# task-tracking.yaml
tasks:
  task_001:
    id: "task_001"
    title: "架构设计任务"
    description: "为131项目设计Android→HarmonyOS适配器架构"
    type: "architecture"
    priority: "high"
    assigned_agent: "claude"
    status: "completed"
    created_at: "2026-03-11 09:30"
    started_at: "2026-03-11 09:30"
    completed_at: "2026-03-11 10:00"
    duration: 30
    estimated_duration: 30
    actual_duration: 30
    efficiency: 1.0
    cost: 0.16
    output_files: ["Architecture/Adapter-Design.md"]
    dependencies: []
    blockers: []
    
  task_002:
    id: "task_002"
    title: "文档整理任务"
    description: "Android API文档批量处理"
    type: "documentation"
    priority: "medium"
    assigned_agent: "kimi"
    status: "in_progress"
    created_at: "2026-03-11 11:00"
    started_at: "2026-03-11 11:00"
    estimated_duration: 60
    actual_duration: 45
    remaining_duration: 15
    efficiency: 0.75
    cost: 0.90
    output_files: []
    dependencies: []
    blockers: []
```

### **2. 任务进度追踪**

```python
# task_progress_tracker.py
class TaskProgressTracker:
    def __init__(self):
        self.tasks = {}
        self.task_history = []
    
    def create_task(self, task_data):
        task_id = task_data['id']
        self.tasks[task_id] = {
            **task_data,
            'status': 'created',
            'created_at': datetime.now(),
            'progress': 0
        }
        
        # 记录任务创建
        self.task_history.append({
            'event': 'task_created',
            'task_id': task_id,
            'timestamp': datetime.now()
        })
    
    def update_task_progress(self, task_id, progress, status=None):
        if task_id in self.tasks:
            self.tasks[task_id]['progress'] = progress
            if status:
                self.tasks[task_id]['status'] = status
            
            # 记录进度更新
            self.task_history.append({
                'event': 'progress_updated',
                'task_id': task_id,
                'progress': progress,
                'status': status,
                'timestamp': datetime.now()
            })
    
    def get_task_metrics(self, task_id):
        task = self.tasks.get(task_id)
        if not task:
            return None
        
        # 计算任务指标
        metrics = {
            'efficiency': task['progress'] / 100,
            'time_elapsed': (datetime.now() - task['created_at']).total_seconds(),
            'estimated_vs_actual': task['estimated_duration'] / task['actual_duration'] if task['actual_duration'] > 0 else 1
        }
        
        return metrics
```

---

## 📈 项目进度追踪

### **1. 项目状态监控**

```yaml
# project-tracking.yaml
projects:
  "16.1-AndroidToHarmonyOS":
    name: "16.1-AndroidToHarmonyOS"
    type: "development"
    status: "in_progress"
    phase: "Phase 2 - Adapter Development"
    progress: 45
    planned_progress: 50
    variance: -5
    health: "warning"
    
    milestones:
      - id: "milestone_001"
        name: "Android分析完成"
        status: "completed"
        completed_at: "2026-03-11"
      - id: "milestone_002"
        name: "Adapter架构设计"
        status: "completed"
        completed_at: "2026-03-11"
      - id: "milestone_003"
        name: "Adapter开发"
        status: "in_progress"
        started_at: "2026-03-11"
        estimated_completion: "2026-03-28"
      - id: "milestone_004"
        name: "HarmonyOS集成"
        status: "not_started"
        estimated_start: "2026-03-28"
    
    tasks:
      total: 20
      completed: 9
      in_progress: 3
      blocked: 0
      not_started: 8
    
    resources:
      agents: ["claude", "kimi"]
      estimated_hours: 124
      actual_hours: 56
    
  "16.3-AndroidAPI-Requirement":
    name: "16.3-AndroidAPI-Requirement"
    type: "research"
    status: "in_progress"
    phase: "Phase 2 - Mapping Rules"
    progress: 60
    planned_progress: 55
    variance: +5
    health: "good"
    
    milestones:
      - id: "milestone_001"
        name: "API收集完成"
        status: "completed"
        completed_at: "2026-03-11"
      - id: "milestone_002"
        name: "API分类完成"
        status: "in_progress"
        started_at: "2026-03-11"
        estimated_completion: "2026-03-25"
      - id: "milestone_003"
        name: "映射规则建立"
        status: "not_started"
        estimated_start: "2026-03-25"
    
    tasks:
      total: 20
      completed: 12
      in_progress: 5
      blocked: 0
      not_started: 3
    
    resources:
      agents: ["glm", "deepseek"]
      estimated_hours: 100
      actual_hours: 60
```

### **2. 进度偏差分析**

```python
# progress_analyzer.py
class ProgressAnalyzer:
    def __init__(self):
        self.projects = {}
    
    def analyze_progress_variance(self, project_id):
        project = self.projects.get(project_id)
        if not project:
            return None
        
        variance = project['progress'] - project['planned_progress']
        
        analysis = {
            'variance': variance,
            'variance_percentage': (variance / project['planned_progress']) * 100,
            'status': self._get_variance_status(variance),
            'recommendations': self._get_recommendations(variance, project)
        }
        
        return analysis
    
    def _get_variance_status(self, variance):
        if variance > 10:
            return 'ahead'
        elif variance < -10:
            return 'behind'
        else:
            return 'on_track'
    
    def _get_recommendations(self, variance, project):
        recommendations = []
        
        if variance < -10:
            recommendations.append('增加资源投入')
            recommendations.append('重新评估任务复杂度')
            recommendations.append('考虑调整时间线')
        elif variance > 10:
            recommendations.append('考虑提前开始下一阶段')
            recommendations.append('重新评估资源需求')
        
        return recommendations
```

---

## 📊 性能分析系统

### **1. Agent性能指标**

```python
# performance_analyzer.py
class PerformanceAnalyzer:
    def __init__(self):
        self.metrics = {
            'claude': {'tasks': [], 'total_time': 0, 'total_cost': 0},
            'kimi': {'tasks': [], 'total_time': 0, 'total_cost': 0},
            'glm': {'tasks': [], 'total_time': 0, 'total_cost': 0},
            'deepseek': {'tasks': [], 'total_time': 0, 'total_cost': 0}
        }
    
    def record_task_completion(self, agent, task_data):
        self.metrics[agent]['tasks'].append(task_data)
        self.metrics[agent]['total_time'] += task_data['duration']
        self.metrics[agent]['total_cost'] += task_data['cost']
    
    def get_agent_performance(self, agent):
        tasks = self.metrics[agent]['tasks']
        total_time = self.metrics[agent]['total_time']
        total_cost = self.metrics[agent]['total_cost']
        
        if not tasks:
            return None
        
        return {
            'total_tasks': len(tasks),
            'total_time': total_time,
            'total_cost': total_cost,
            'average_time_per_task': total_time / len(tasks),
            'average_cost_per_task': total_cost / len(tasks),
            'tasks_per_hour': len(tasks) / (total_time / 60),
            'cost_efficiency': len(tasks) / total_cost
        }
    
    def generate_performance_report(self):
        report = {}
        
        for agent in self.metrics:
            performance = self.get_agent_performance(agent)
            if performance:
                report[agent] = performance
        
        return report
```

### **2. 成本效益分析**

```python
# cost_analyzer.py
class CostAnalyzer:
    def __init__(self):
        self.daily_costs = {}
        self.project_costs = {}
    
    def calculate_daily_costs(self, date):
        daily_cost = {
            'claude': 0,
            'kimi': 0,
            'glm': 0,
            'deepseek': 0,
            'total': 0
        }
        
        for agent in daily_cost:
            if agent == 'claude':
                daily_cost[agent] = self.daily_costs.get(date, {}).get(agent, 0) * 20
            else:
                daily_cost[agent] = self.daily_costs.get(date, {}).get(agent, 0)
        
        daily_cost['total'] = sum(daily_cost.values())
        
        return daily_cost
    
    def calculate_project_costs(self, project_id):
        project_cost = {
            'total_cost': 0,
            'agent_breakdown': {},
            'cost_per_task': 0,
            'cost_per_hour': 0
        }
        
        # 计算项目成本
        tasks = self.get_project_tasks(project_id)
        if tasks:
            project_cost['total_cost'] = sum(task['cost'] for task in tasks)
            project_cost['cost_per_task'] = project_cost['total_cost'] / len(tasks)
            project_cost['cost_per_hour'] = project_cost['total_cost'] / sum(task['duration'] for task in tasks)
            
            # 按Agent分类
            for task in tasks:
                agent = task['assigned_agent']
                if agent not in project_cost['agent_breakdown']:
                    project_cost['agent_breakdown'][agent] = 0
                project_cost['agent_breakdown'][agent] += task['cost']
        
        return project_cost
```

---

## 🔔 报警与通知系统

### **1. 报警规则**

```python
# alert_system.py
class AlertSystem:
    def __init__(self):
        self.alert_rules = {
            'claude_low_hours': {
                'condition': lambda m: m['remaining_hours'] < 1,
                'severity': 'warning',
                'message': 'Claude Code剩余时间不足1小时'
            },
            'claude_critical_hours': {
                'condition': lambda m: m['remaining_hours'] < 0.5,
                'severity': 'critical',
                'message': 'Claude Code剩余时间不足30分钟'
            },
            'project_delays': {
                'condition': lambda p: p['variance'] < -10,
                'severity': 'warning',
                'message': '项目进度落后超过10%'
            },
            'task_blockers': {
                'condition': lambda t: t['blockers'],
                'severity': 'warning',
                'message': '任务存在阻塞因素'
            }
        }
    
    def check_alerts(self, metrics):
        alerts = []
        
        for rule_name, rule in self.alert_rules.items():
            if rule['condition'](metrics):
                alerts.append({
                    'rule': rule_name,
                    'severity': rule['severity'],
                    'message': rule['message'],
                    'timestamp': datetime.now()
                })
        
        return alerts
    
    def send_alert(self, alert):
        # 发送通知
        print(f"🚨 {alert['severity'].upper()}: {alert['message']}")
        
        # 可以扩展为邮件、Slack等通知方式
        if alert['severity'] == 'critical':
            self.send_critical_alert(alert)
```

---

## 📊 数据可视化

### **1. 仪表板界面**

```html
<!-- dashboard.html -->
<!DOCTYPE html>
<html>
<head>
    <title>Agent状态追踪仪表板</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <div class="dashboard">
        <h1>Agent状态追踪仪表板</h1>
        
        <div class="agent-status">
            <h2>Agent状态</h2>
            <div class="agent-card">
                <h3>Claude Code</h3>
                <p>状态: <span id="claude-status">Active</span></p>
                <p>剩余时间: <span id="claude-hours">4.2</span>小时</p>
                <p>今日使用: <span id="claude-usage">0.8</span>小时</p>
            </div>
        </div>
        
        <div class="project-progress">
            <h2>项目进度</h2>
            <canvas id="progress-chart"></canvas>
        </div>
        
        <div class="performance-metrics">
            <h2>性能指标</h2>
            <canvas id="performance-chart"></canvas>
        </div>
    </div>
</body>
</html>
```

---

## 🔧 实施指南

### **1. 系统部署**

```bash
# 部署追踪系统
mkdir -p /opt/agent-tracker
cp agent-tracker.py /opt/agent-tracker/
cp config.yaml /opt/agent-tracker/
chmod +x /opt/agent-tracker/agent-tracker.py

# 设置定时任务
echo "*/5 * * * * /opt/agent-tracker/agent-tracker.py check" | crontab -
echo "*/10 * * * * /opt/agent-tracker/agent-tracker.py update" | crontab -
echo "0 18 * * * /opt/agent-tracker/agent-tracker.py report" | crontab -
```

### **2. 配置文件**

```yaml
# config.yaml
tracker:
  data_dir: "/var/lib/agent-tracker"
  log_dir: "/var/log/agent-tracker"
  backup_dir: "/backup/agent-tracker"
  
  alerts:
    email: "admin@example.com"
    slack_webhook: "https://hooks.slack.com/..."
    
  metrics:
    retention_days: 30
    update_interval: 300  # 5分钟
    
  projects:
    "16.1-AndroidToHarmonyOS":
      enabled: true
      alert_threshold: -10
    "16.3-AndroidAPI-Requirement":
      enabled: true
      alert_threshold: -10
```

---

## 🔗 相关文档

- [[项目状态仪表板]] - 实时监控界面
- [[AI-Agent协作机制]] - Agent协作配置
- [[scripts/]] - 自动化脚本集合

---

**维护者**: Claude Code  
**创建日期**: 2026-03-11  
**最后更新**: 2026-03-11