#!/usr/bin/env python3
"""
api-classifier.py — Generate per-module docs and classification summary from CSV

Reads the API master list CSV and generates:
1. Per-module markdown files in by-module/ directory
2. A classification-mapping.json summary

Usage:
    python3 api-classifier.py --input ../133-API-MASTER-LIST.csv
    python3 api-classifier.py --input data.csv --output-dir ../133.1-RESEARCH-ANALYSIS/133.11-CLASSIFICATION/by-module/
"""

import argparse
import csv
import json
import os
import sys
from collections import defaultdict

MODULE_NAMES = {
    "M01": "android.app & android.os",
    "M02": "android.content",
    "M03": "android.view & android.graphics",
    "M04": "android.widget",
    "M05": "android.net & android.webkit",
    "M06": "android.media & android.hardware.camera2",
    "M07": "android.database & android.provider",
    "M08": "android.location & android.hardware (sensors)",
    "M09": "android.bluetooth & android.nfc",
    "M10": "android.telephony",
    "M11": "android.security & android.app.admin",
    "M12": "android.animation & android.util",
    "M13": "java.* & dalvik.* (ART/libcore)",
    "M99": "Other",
}

PRIORITY_NAMES = {
    "P0": "运行时核心",
    "P1": "UI & 渲染",
    "P2": "应用框架",
    "P3": "系统服务",
    "P4": "完整覆盖",
}


def read_csv(path: str) -> list:
    """Read API CSV file."""
    rows = []
    with open(path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(row)
    return rows


def generate_module_docs(rows: list, output_dir: str):
    """Generate per-module markdown files."""
    os.makedirs(output_dir, exist_ok=True)

    # Group by module
    by_module = defaultdict(list)
    for row in rows:
        mid = row.get("module_id", "M99")
        by_module[mid].append(row)

    for mid in sorted(by_module.keys()):
        apis = by_module[mid]
        module_name = MODULE_NAMES.get(mid, "Unknown")
        filename = f"{mid}-{module_name.split('(')[0].strip().replace(' & ', '-').replace('.', '').replace(' ', '-')}.md"
        filepath = os.path.join(output_dir, filename)

        # Group by class within module
        by_class = defaultdict(list)
        for api in apis:
            key = f"{api['package']}.{api['class_name']}"
            by_class[key].append(api)

        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(f"---\ntags:\n  - 133-project\n  - api-classification\n  - {mid}\ndate: 2026-03-11\n---\n\n")
            f.write(f"# {mid} — {module_name}\n\n")
            f.write(f"> API 数量: {len(apis)} | 优先级: {apis[0].get('priority', '?')}\n\n")
            f.write(f"---\n\n")

            # Summary table
            f.write(f"## 概览\n\n")
            f.write(f"| 包 | 类 | API 数 |\n")
            f.write(f"|---|---|---|\n")
            for cls_key in sorted(by_class.keys()):
                cls_apis = by_class[cls_key]
                pkg = cls_apis[0]['package']
                cls = cls_apis[0]['class_name']
                f.write(f"| {pkg} | {cls} | {len(cls_apis)} |\n")

            f.write(f"\n---\n\n")

            # Detailed listing
            f.write(f"## 详细 API 列表\n\n")
            for cls_key in sorted(by_class.keys()):
                cls_apis = by_class[cls_key]
                pkg = cls_apis[0]['package']
                cls = cls_apis[0]['class_name']
                f.write(f"### {cls} (`{pkg}`)\n\n")
                f.write(f"| 方法/字段 | 类型 | 难度 | 映射 |\n")
                f.write(f"|---|---|---|---|\n")
                for api in sorted(cls_apis, key=lambda x: x['method_name']):
                    name = api['method_name']
                    atype = api['api_type']
                    diff = api.get('mapping_difficulty', '')
                    mapping = api.get('harmony_mapping', '')
                    f.write(f"| {name} | {atype} | {diff} | {mapping} |\n")
                f.write(f"\n")

        print(f"  Written: {filepath} ({len(apis)} APIs)", file=sys.stderr)

    return by_module


def generate_json_summary(rows: list, by_module: dict, output_path: str):
    """Generate classification-mapping.json."""
    summary = {
        "total_apis": len(rows),
        "generated": "2026-03-11",
        "modules": {},
        "priorities": {},
    }

    # Module stats
    for mid in sorted(by_module.keys()):
        apis = by_module[mid]
        packages = set(a['package'] for a in apis)
        classes = set(a['class_name'] for a in apis)
        summary["modules"][mid] = {
            "name": MODULE_NAMES.get(mid, "Unknown"),
            "api_count": len(apis),
            "package_count": len(packages),
            "class_count": len(classes),
            "packages": sorted(packages),
        }

    # Priority stats
    by_priority = defaultdict(int)
    for row in rows:
        by_priority[row.get("priority", "?")] += 1
    for p in sorted(by_priority.keys()):
        summary["priorities"][p] = {
            "name": PRIORITY_NAMES.get(p, "Unknown"),
            "api_count": by_priority[p],
        }

    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)

    print(f"  Written: {output_path}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description="Generate per-module docs and classification summary from CSV"
    )
    parser.add_argument(
        "--input", "-i", required=True, metavar="FILE",
        help="Input CSV file (133-API-MASTER-LIST.csv)"
    )
    parser.add_argument(
        "--output-dir", "-d", metavar="DIR",
        default="../133.1-RESEARCH-ANALYSIS/133.11-CLASSIFICATION/by-module",
        help="Output directory for module markdown files"
    )
    parser.add_argument(
        "--json", "-j", metavar="FILE",
        default="../133.1-RESEARCH-ANALYSIS/133.11-CLASSIFICATION/classification-mapping.json",
        help="Output path for classification-mapping.json"
    )
    args = parser.parse_args()

    # Read
    print(f"Reading {args.input} ...", file=sys.stderr)
    rows = read_csv(args.input)
    print(f"Loaded {len(rows)} API entries", file=sys.stderr)

    # Generate module docs
    print(f"\nGenerating module docs in {args.output_dir}/", file=sys.stderr)
    by_module = generate_module_docs(rows, args.output_dir)

    # Generate JSON summary
    json_dir = os.path.dirname(args.json)
    if json_dir:
        os.makedirs(json_dir, exist_ok=True)
    generate_json_summary(rows, by_module, args.json)

    # Print summary
    print(f"\n{'='*50}", file=sys.stderr)
    print(f"Classification Summary", file=sys.stderr)
    print(f"{'='*50}", file=sys.stderr)
    print(f"Total APIs: {len(rows)}", file=sys.stderr)
    print(f"Modules: {len(by_module)}", file=sys.stderr)
    for mid in sorted(by_module.keys()):
        name = MODULE_NAMES.get(mid, "?")
        print(f"  {mid} ({name}): {len(by_module[mid])} APIs", file=sys.stderr)
    print(f"{'='*50}", file=sys.stderr)


if __name__ == "__main__":
    main()
