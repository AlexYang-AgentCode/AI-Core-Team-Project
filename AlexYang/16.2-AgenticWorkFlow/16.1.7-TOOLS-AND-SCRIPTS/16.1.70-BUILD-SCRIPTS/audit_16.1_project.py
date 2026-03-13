#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
131 项目自动审视脚本

功能:
1. 遍历 131 项目的所有目录和文件
2. 验证文件是否存在
3. 检查文件大小和行数
4. 检查是否为虚假报告（空目录/空文件）
5. 生成详细的审视报告

使用方法:
    python audit_131_project.py > 131_audit_result.txt
"""

import os
import json
from pathlib import Path
from datetime import datetime

class ProjectAuditor:
    def __init__(self, base_path):
        self.base_path = Path(base_path)
        self.results = {
            'metadata': {
                'audit_date': datetime.now().isoformat(),
                'base_path': str(self.base_path),
            },
            'summary': {
                'total_files': 0,
                'total_dirs': 0,
                'empty_dirs': 0,
                'empty_files': 0,
                'issues': []
            },
            'phases': {}
        }

    def audit(self):
        """执行审视"""
        print("=" * 80)
        print("16.1-AndroidToHarmonyOSDemo 项目自动审视报告")
        print("=" * 80)
        print(f"审视时间: {self.results['metadata']['audit_date']}")
        print(f"项目路径: {self.base_path}")
        print()

        # 遍历所有子目录
        self._audit_directory(self.base_path, '')

        # 生成总结
        self._print_summary()

        # 生成 JSON 报告
        self._save_json_report()

    def _audit_directory(self, dir_path, phase_name):
        """递归审视目录"""
        if not dir_path.exists():
            print(f"❌ 目录不存在: {dir_path}")
            return

        items = list(dir_path.iterdir())

        # 检查是否为空目录
        if not items:
            self.results['summary']['empty_dirs'] += 1
            print(f"⚠️  空目录: {dir_path.relative_to(self.base_path)}")
            self.results['summary']['issues'].append({
                'type': 'empty_directory',
                'path': str(dir_path.relative_to(self.base_path)),
                'severity': 'high'
            })
            return

        self.results['summary']['total_dirs'] += 1

        # 统计子目录和文件
        subdirs = [item for item in items if item.is_dir()]
        files = [item for item in items if item.is_file()]

        print(f"\n📂 {dir_path.relative_to(self.base_path)}/")
        print(f"   ├─ 子目录: {len(subdirs)}")
        print(f"   └─ 文件: {len(files)}")

        # 审视文件
        for file_path in sorted(files):
            self._audit_file(file_path)

        # 递归审视子目录
        for subdir in sorted(subdirs):
            self._audit_directory(subdir, phase_name)

    def _audit_file(self, file_path):
        """审视单个文件"""
        self.results['summary']['total_files'] += 1

        # 获取文件信息
        size = file_path.stat().st_size
        file_name = file_path.name
        rel_path = file_path.relative_to(self.base_path)

        # 检查是否为空文件
        if size == 0:
            self.results['summary']['empty_files'] += 1
            print(f"   ❌ 空文件: {file_name} (0 bytes)")
            self.results['summary']['issues'].append({
                'type': 'empty_file',
                'path': str(rel_path),
                'size': 0,
                'severity': 'high'
            })
            return

        # 获取行数（仅针对文本文件）
        try:
            if file_path.suffix in ['.md', '.txt', '.csv', '.json', '.py', '.ts', '.js', '.yaml', '.yml']:
                with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                    lines = len(f.readlines())
                status = f"✅ {file_name} ({size} bytes, {lines} lines)"
            else:
                status = f"✅ {file_name} ({size} bytes)"
        except Exception as e:
            status = f"⚠️  {file_name} ({size} bytes, 错误: {str(e)})"

        print(f"   {status}")

    def _print_summary(self):
        """打印总结"""
        print("\n" + "=" * 80)
        print("审视汇总")
        print("=" * 80)
        print(f"总目录数: {self.results['summary']['total_dirs']}")
        print(f"总文件数: {self.results['summary']['total_files']}")
        print(f"空目录数: {self.results['summary']['empty_dirs']}")
        print(f"空文件数: {self.results['summary']['empty_files']}")
        print()

        if self.results['summary']['issues']:
            print(f"⚠️  发现 {len(self.results['summary']['issues'])} 个问题:")
            print()
            for i, issue in enumerate(self.results['summary']['issues'], 1):
                severity = "🔴 HIGH" if issue['severity'] == 'high' else "🟡 MEDIUM"
                print(f"{i}. {severity}: {issue['type']}")
                print(f"   路径: {issue['path']}")
                if 'size' in issue:
                    print(f"   大小: {issue['size']} bytes")
                print()
        else:
            print("✅ 没有发现问题")

    def _save_json_report(self):
        """保存 JSON 报告"""
        json_path = self.base_path / '131_audit_result.json'
        with open(json_path, 'w', encoding='utf-8') as f:
            json.dump(self.results, f, ensure_ascii=False, indent=2)
        print(f"\n📄 JSON 报告已保存到: {json_path}")


class DetailedAuditor(ProjectAuditor):
    """更详细的审视，包括检查关键文件内容"""

    def __init__(self, base_path):
        super().__init__(base_path)
        self.critical_files = {
            '16.1.1-PHASE-STATUS.md': 'Phase 1 状态',
            '16.1.2-PHASE-STATUS.md': 'Phase 2 状态',
            'TextClock-debug.apk': 'Android APK',
            'api-list.csv': '12 个 APIs 清单',
        }

    def audit_critical_files(self):
        """审视关键文件"""
        print("\n" + "=" * 80)
        print("关键文件详细审视")
        print("=" * 80)

        for file_name, description in self.critical_files.items():
            self._find_and_audit(file_name, description)

    def _find_and_audit(self, file_name, description):
        """查找并审视特定文件"""
        print(f"\n🔍 查找: {file_name} ({description})")

        for root, dirs, files in os.walk(self.base_path):
            if file_name in files:
                file_path = Path(root) / file_name
                print(f"✅ 找到: {file_path.relative_to(self.base_path)}")

                # 读取内容摘要
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        lines = content.split('\n')

                    print(f"   大小: {len(content)} 字符")
                    print(f"   行数: {len(lines)} 行")

                    # 显示前几行
                    if lines:
                        print(f"   首行: {lines[0][:100]}")

                        # 检查是否为虚假报告
                        if '✅ COMPLETE' in content or '✅ Complete' in content:
                            # 检查是否有实际内容
                            if len(lines) < 20:
                                print("   ⚠️  警告: 声称完成但内容很少")

                except Exception as e:
                    print(f"   ❌ 错误: {str(e)}")

                return

        print(f"❌ 未找到: {file_name}")
        self.results['summary']['issues'].append({
            'type': 'missing_critical_file',
            'file': file_name,
            'description': description,
            'severity': 'high'
        })


def main():
    """主函数"""
    base_path = Path('D:/ObsidianVault/10-Projects/16-DigitalEmployee/16.1-AndroidToHarmonyOSDemo')

    # 执行基本审视
    auditor = DetailedAuditor(base_path)
    auditor.audit()
    auditor.audit_critical_files()


if __name__ == '__main__':
    main()
