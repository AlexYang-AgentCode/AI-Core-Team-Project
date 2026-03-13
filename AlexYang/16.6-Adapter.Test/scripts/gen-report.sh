#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# 报告生成器 — 从仿真器验证结果生成 HTML 对比报告
#
# 人格：报告的每一行都必须有仿真器证据支撑。
#   PASS = UI dump 中看到了正确文本
#   FAIL = UI dump 中看到了错误文本
#   NOT_VERIFIED = 当前技术手段无法验证（如 Toast）
#   SKIP = 设备未连接或应用未安装
#
# 用法: bash scripts/gen-report.sh <case_id>
# ═══════════════════════════════════════════════════════════════

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

CASE_ID="${1:?用法: gen-report.sh <case_id>}"
REPORT_DIR="$PROJECT_DIR/reports/16.1.${CASE_ID}"
DEMO_ROOT="/mnt/e/10.Project/16.1-AndroidToHarmonyOSDemo"
DEMO_DIR=$(find "$DEMO_ROOT" -maxdepth 1 -type d -name "16.1.${CASE_ID}-*" | head -1)
DEMO_NAME=$(basename "$DEMO_DIR")

# ── 收集截屏 ─────────────────────────────────────────────────
ANDROID_SHOTS=$(find "$REPORT_DIR/android" -name "*.png" 2>/dev/null | sort)
HARMONY_SHOTS=$(find "$REPORT_DIR/harmony" -name "*.jpeg" -o -name "*.png" 2>/dev/null | sort)

# ── 读取验证结果 JSON ────────────────────────────────────────
ANDROID_VERIFY="$REPORT_DIR/android/verify-result.json"
HARMONY_VERIFY="$REPORT_DIR/harmony/verify-result.json"

# 导出变量供 python3 使用
export CASE_ID REPORT_DIR DEMO_NAME ANDROID_VERIFY HARMONY_VERIFY

# 用 python3 生成 HTML
python3 << 'PYEOF'
import json, os, glob
from datetime import datetime

case_id = os.environ.get('CASE_ID', '')
report_dir = os.environ.get('REPORT_DIR', '')
demo_name = os.environ.get('DEMO_NAME', '')
android_verify = os.environ.get('ANDROID_VERIFY', '')
harmony_verify = os.environ.get('HARMONY_VERIFY', '')

# 加载验证结果
def load_verify(path):
    if os.path.exists(path):
        with open(path) as f:
            return json.load(f)
    return None

android = load_verify(android_verify)
harmony = load_verify(harmony_verify)

# 收集截屏
def find_screenshots(platform_dir, exts=['png', 'jpeg', 'jpg']):
    shots = []
    for ext in exts:
        shots.extend(glob.glob(os.path.join(platform_dir, f'*.{ext}')))
    return sorted(shots)

android_shots = find_screenshots(os.path.join(report_dir, 'android'))
harmony_shots = find_screenshots(os.path.join(report_dir, 'harmony'))

# 计算总体 verdict
def calc_verdict(a, h):
    if a is None and h is None:
        return 'skip', 'SKIP — 无设备连接'

    total_pass = 0
    total_fail = 0
    total_nv = 0

    for r in [a, h]:
        if r:
            total_pass += r.get('passed', 0)
            total_fail += r.get('failed', 0)
            total_nv += r.get('not_verified', 0)

    if total_fail > 0:
        return 'fail', f'FAIL — {total_fail} 个用例失败'
    elif total_pass > 0 and total_fail == 0:
        if total_nv > 0:
            return 'pass', f'PASS — {total_pass} 个用例通过 (仿真器验证), {total_nv} 个待扩展验证手段'
        else:
            return 'pass', f'PASS — 全部 {total_pass} 个用例通过 (仿真器验证)'
    else:
        return 'partial', '部分完成'

verdict_class, verdict_text = calc_verdict(android, harmony)

# 合并测试用例表
def merge_cases(a, h):
    """合并两个平台的测试用例结果"""
    all_ids = set()
    if a and 'test_cases' in a:
        all_ids.update(a['test_cases'].keys())
    if h and 'test_cases' in h:
        all_ids.update(h['test_cases'].keys())

    rows = []
    for tc_id in sorted(all_ids):
        a_status = a['test_cases'].get(tc_id, {}).get('status', '-') if a and 'test_cases' in a else '-'
        a_evidence = a['test_cases'].get(tc_id, {}).get('evidence', '') if a and 'test_cases' in a else ''
        h_status = h['test_cases'].get(tc_id, {}).get('status', '-') if h and 'test_cases' in h else '-'
        h_evidence = h['test_cases'].get(tc_id, {}).get('evidence', '') if h and 'test_cases' in h else ''
        rows.append((tc_id, a_status, a_evidence, h_status, h_evidence))
    return rows

cases = merge_cases(android, harmony)

def badge(status):
    cls = {
        'PASS': 'pass-badge',
        'FAIL': 'fail-badge',
        'NOT_VERIFIED': 'nv-badge',
        'SKIP': 'skip-badge',
    }.get(status, 'skip-badge')
    return f'<span class="{cls}">{status}</span>'

# 生成 HTML
html = f'''<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>{demo_name} — 仿真器实机验证报告</title>
<style>
  body {{ font-family: -apple-system, sans-serif; max-width: 1400px; margin: 0 auto; padding: 20px; background: #f5f5f5; }}
  h1 {{ color: #1a1a1a; border-bottom: 3px solid #0066cc; padding-bottom: 10px; }}
  h2 {{ color: #333; margin-top: 30px; }}
  .meta {{ color: #666; font-size: 14px; }}
  .identity {{ background: #e8eaf6; padding: 12px 16px; border-radius: 8px; border-left: 4px solid #3f51b5; margin: 15px 0; font-size: 14px; color: #283593; }}
  .verdict {{ font-size: 22px; font-weight: bold; padding: 15px; border-radius: 8px; text-align: center; margin: 20px 0; }}
  .verdict.pass {{ background: #d4edda; color: #155724; }}
  .verdict.fail {{ background: #f8d7da; color: #721c24; }}
  .verdict.partial {{ background: #fff3cd; color: #856404; }}
  .verdict.skip {{ background: #e2e3e5; color: #383d41; }}
  table {{ border-collapse: collapse; width: 100%; margin: 15px 0; }}
  th, td {{ border: 1px solid #ddd; padding: 8px 12px; text-align: left; }}
  th {{ background: #f0f0f0; }}
  .pass-badge {{ color: #155724; background: #d4edda; padding: 2px 8px; border-radius: 4px; font-weight: bold; }}
  .fail-badge {{ color: #721c24; background: #f8d7da; padding: 2px 8px; border-radius: 4px; font-weight: bold; }}
  .nv-badge {{ color: #856404; background: #fff3cd; padding: 2px 8px; border-radius: 4px; font-weight: bold; }}
  .skip-badge {{ color: #383d41; background: #e2e3e5; padding: 2px 8px; border-radius: 4px; }}
  .evidence {{ font-size: 12px; color: #666; font-family: monospace; }}
  .screenshots {{ display: flex; gap: 15px; flex-wrap: wrap; margin: 15px 0; }}
  .screenshot-card {{ flex: 1; min-width: 250px; max-width: 350px; background: white; border-radius: 8px; padding: 12px; box-shadow: 0 2px 6px rgba(0,0,0,0.1); }}
  .screenshot-card h4 {{ margin: 0 0 8px 0; font-size: 13px; }}
  .screenshot-card img {{ width: 100%; max-height: 500px; object-fit: contain; border: 1px solid #ddd; border-radius: 4px; }}
  .screenshot-card p {{ margin: 6px 0 0 0; font-size: 11px; color: #888; }}
  .platform-tag {{ display: inline-block; padding: 2px 8px; border-radius: 4px; font-size: 11px; font-weight: bold; margin-bottom: 4px; }}
  .platform-tag.android {{ background: #e8f5e9; color: #2e7d32; }}
  .platform-tag.harmony {{ background: #e3f2fd; color: #1565c0; }}
  .stats {{ display: flex; gap: 20px; margin: 15px 0; }}
  .stat-card {{ flex: 1; background: white; padding: 15px; border-radius: 8px; text-align: center; box-shadow: 0 1px 4px rgba(0,0,0,0.1); }}
  .stat-card .number {{ font-size: 28px; font-weight: bold; }}
  .stat-card .label {{ font-size: 12px; color: #666; }}
</style>
</head>
<body>
<h1>{demo_name} — 仿真器实机验证报告</h1>
<p class="meta">生成时间: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")} | 案例 ID: 16.1.{case_id}</p>

<div class="identity">
  <strong>验证身份</strong>：16.6-Adapter.Test 仿真器验证器<br>
  <strong>验证方式</strong>：Android — adb shell uiautomator dump (XML UI 树) | HarmonyOS — hdc shell uitest dumpLayout (JSON 布局)<br>
  <strong>承诺</strong>：所有 PASS/FAIL 均基于仿真器上的真实 UI 状态，不依赖代码比对或 hardcoded 结果。
</div>

<div class="verdict {verdict_class}">{verdict_text}</div>
'''

# 统计卡片
def stats_section(label, data):
    if not data:
        return f'<div class="stat-card"><div class="number">-</div><div class="label">{label} 未连接</div></div>'
    return f'''
    <div class="stat-card"><div class="number" style="color:#2e7d32">{data.get("passed",0)}</div><div class="label">{label} PASS</div></div>
    <div class="stat-card"><div class="number" style="color:#c62828">{data.get("failed",0)}</div><div class="label">{label} FAIL</div></div>
    <div class="stat-card"><div class="number" style="color:#f57f17">{data.get("not_verified",0)}</div><div class="label">{label} 待验证</div></div>
    '''

html += '<div class="stats">'
html += stats_section('Android', android)
html += stats_section('HarmonyOS', harmony)
html += '</div>'

# 测试结果表
html += '<h2>逐用例验证结果</h2>'
html += '<table><tr><th>用例 ID</th><th>Android</th><th>证据 (Android)</th><th>HarmonyOS</th><th>证据 (HarmonyOS)</th></tr>'
for tc_id, a_st, a_ev, h_st, h_ev in cases:
    html += f'<tr><td><strong>{tc_id}</strong></td>'
    html += f'<td>{badge(a_st)}</td><td class="evidence">{a_ev}</td>'
    html += f'<td>{badge(h_st)}</td><td class="evidence">{h_ev}</td></tr>'
html += '</table>'

# 截屏对比 — 按测试用例配对
html += '<h2>截屏证据</h2>'

# 提取有相同 TC ID 的截屏配对
tc_screenshots = {}
for shot in android_shots + harmony_shots:
    fname = os.path.basename(shot)
    platform = 'android' if '/android/' in shot else 'harmony'
    # 尝试从文件名提取 TC ID
    for tc_id_candidate in [c[0] for c in cases]:
        if tc_id_candidate.lower() in fname.lower():
            if tc_id_candidate not in tc_screenshots:
                tc_screenshots[tc_id_candidate] = {}
            tc_screenshots[tc_id_candidate][platform] = fname
            break
    else:
        # 不含 TC ID 的截屏（如 initial）
        if 'initial' in fname.lower():
            if '_initial' not in tc_screenshots:
                tc_screenshots['_initial'] = {}
            tc_screenshots['_initial'][platform] = fname

# 先显示配对截屏
for tc_id in sorted(tc_screenshots.keys()):
    pair = tc_screenshots[tc_id]
    label = '初始状态' if tc_id == '_initial' else tc_id
    html += f'<h3>{label}</h3><div class="screenshots">'
    for platform in ['android', 'harmony']:
        if platform in pair:
            fname = pair[platform]
            tag_class = platform
            tag_label = 'Android' if platform == 'android' else 'HarmonyOS'
            html += f'''
            <div class="screenshot-card">
              <span class="platform-tag {tag_class}">{tag_label}</span>
              <h4>{fname}</h4>
              <img src="{platform}/{fname}" alt="{tag_label} {label}">
            </div>'''
    html += '</div>'

# 显示未配对的截屏
shown = set()
for pair in tc_screenshots.values():
    shown.update(pair.values())

remaining_android = [s for s in android_shots if os.path.basename(s) not in shown]
remaining_harmony = [s for s in harmony_shots if os.path.basename(s) not in shown]

if remaining_android or remaining_harmony:
    html += '<h3>其他截屏</h3><div class="screenshots">'
    for shot in remaining_android:
        fname = os.path.basename(shot)
        html += f'<div class="screenshot-card"><span class="platform-tag android">Android</span><h4>{fname}</h4><img src="android/{fname}"></div>'
    for shot in remaining_harmony:
        fname = os.path.basename(shot)
        html += f'<div class="screenshot-card"><span class="platform-tag harmony">HarmonyOS</span><h4>{fname}</h4><img src="harmony/{fname}"></div>'
    html += '</div>'

# 原始 JSON 数据
html += '<h2>原始验证数据</h2>'
for label, data in [('Android', android), ('HarmonyOS', harmony)]:
    if data:
        html += f'<h3>{label}</h3><pre style="background:#1e1e1e;color:#d4d4d4;padding:15px;border-radius:8px;font-size:12px;overflow-x:auto">'
        html += json.dumps(data, indent=2, ensure_ascii=False).replace('<', '&lt;').replace('>', '&gt;')
        html += '</pre>'

html += '</body></html>'

# 写出
output_path = os.path.join(report_dir, 'comparison-report.html')
with open(output_path, 'w', encoding='utf-8') as f:
    f.write(html)
print(f'报告已生成: {output_path}')
PYEOF
