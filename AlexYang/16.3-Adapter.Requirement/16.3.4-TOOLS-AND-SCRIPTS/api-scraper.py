#!/usr/bin/env python3
"""
api-scraper.py — Extract Android API surface from AOSP current.txt

Downloads and parses frameworks/base/api/current.txt from AOSP,
extracts all public APIs, assigns module IDs and priorities,
outputs CSV matching the 133 project schema.

Usage:
    python3 api-scraper.py [--local FILE] [--output FILE] [--no-download]

Examples:
    python3 api-scraper.py                          # Download + parse + output to stdout
    python3 api-scraper.py --output ../133-API-MASTER-LIST.csv
    python3 api-scraper.py --local /path/to/current.txt
"""

import argparse
import csv
import io
import os
import re
import sys
import urllib.request
import urllib.error

# AOSP current.txt URL (Android 14 / API 34) — base64-encoded
AOSP_URL = "https://android.googlesource.com/platform/frameworks/base/+/refs/tags/android-14.0.0_r1/core/api/current.txt?format=TEXT"

# Cached local copy (after first download)
LOCAL_CACHE = "/tmp/current.txt"

# Module mapping: package prefix → (module_id, module_name)
MODULE_MAP = [
    # Order matters — more specific prefixes first
    ("android.app.admin", "M11", "Security & Admin"),
    ("android.app", "M01", "App & OS"),
    ("android.os", "M01", "App & OS"),
    ("android.content.pm", "M02", "Content"),
    ("android.content", "M02", "Content"),
    ("android.view", "M03", "View & Graphics"),
    ("android.graphics", "M03", "View & Graphics"),
    ("android.widget", "M04", "Widget"),
    ("android.net", "M05", "Net & WebKit"),
    ("android.webkit", "M05", "Net & WebKit"),
    ("android.media", "M06", "Media & Camera"),
    ("android.hardware.camera2", "M06", "Media & Camera"),
    ("android.database", "M07", "Database & Provider"),
    ("android.provider", "M07", "Database & Provider"),
    ("android.location", "M08", "Location & Sensors"),
    ("android.hardware", "M08", "Location & Sensors"),
    ("android.bluetooth", "M09", "Bluetooth & NFC"),
    ("android.nfc", "M09", "Bluetooth & NFC"),
    ("android.telephony", "M10", "Telephony"),
    ("android.security", "M11", "Security & Admin"),
    ("android.animation", "M12", "Animation & Util"),
    ("android.util", "M12", "Animation & Util"),
    ("java.", "M13", "Java & ART"),
    ("javax.", "M13", "Java & ART"),
    ("dalvik.", "M13", "Java & ART"),
    ("org.json", "M13", "Java & ART"),
    ("org.xml", "M13", "Java & ART"),
    ("org.w3c", "M13", "Java & ART"),
    ("org.apache", "M13", "Java & ART"),
]

# Priority based on module
PRIORITY_MAP = {
    "M01": "P0", "M02": "P0", "M13": "P0",
    "M03": "P1", "M04": "P1",
    "M05": "P2", "M06": "P2", "M07": "P2", "M12": "P2",
    "M08": "P3", "M09": "P3", "M10": "P3", "M11": "P3",
    "M99": "P4",
}

CSV_HEADER = [
    "api_id", "module_id", "package", "class_name", "method_name",
    "api_type", "priority", "android_api_level", "description_cn",
    "harmony_mapping", "mapping_difficulty", "estimated_hours",
    "adapter_project", "status", "notes"
]


def get_module(package: str) -> tuple:
    """Return (module_id, module_name) for a package."""
    for prefix, mid, mname in MODULE_MAP:
        if package.startswith(prefix):
            return mid, mname
    return "M99", "Other"


def download_current_txt(url: str = None) -> str:
    """Download current.txt from AOSP (with local cache)."""
    # Check local cache first
    if os.path.exists(LOCAL_CACHE) and os.path.getsize(LOCAL_CACHE) > 100000:
        print(f"Using cached file: {LOCAL_CACHE}", file=sys.stderr)
        with open(LOCAL_CACHE, 'r', encoding='utf-8') as f:
            return f.read()

    if url is None:
        url = AOSP_URL
    print(f"Downloading from {url} ...", file=sys.stderr)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "api-scraper/1.0"})
        with urllib.request.urlopen(req, timeout=120) as resp:
            data = resp.read()
            # googlesource returns base64-encoded content
            if url.endswith("format=TEXT"):
                import base64
                data = base64.b64decode(data)
            text = data.decode("utf-8")
            # Cache locally
            with open(LOCAL_CACHE, 'w', encoding='utf-8') as f:
                f.write(text)
            print(f"Cached to {LOCAL_CACHE}", file=sys.stderr)
            return text
    except urllib.error.URLError as e:
        print(f"Failed to download: {e}", file=sys.stderr)
        raise


def parse_current_txt(content: str) -> list:
    """Parse AOSP current.txt format and extract APIs.

    Format:
        package android.app {
          public class Activity extends ... {
            ctor public Activity();
            method public void finish();
            field public static final int RESULT_OK = -1;
          }
        }
    """
    apis = []
    current_package = None
    current_class = None
    class_type = None  # "class", "interface", "enum", "annotation"

    # Patterns
    pkg_pattern = re.compile(r'^package\s+([\w.]+)\s*\{')
    cls_pattern = re.compile(
        r'^\s*(?:public\s+)?(?:abstract\s+)?(?:static\s+)?(?:final\s+)?'
        r'(class|interface|enum|@interface)\s+'
        r'([\w<>?,\s]+?)(?:\s+extends\s+\S+)?(?:\s+implements\s+.+?)?\s*\{'
    )
    method_pattern = re.compile(
        r'^\s*method\s+.*?(\S+)\s*\(([^)]*)\)\s*;'
    )
    ctor_pattern = re.compile(
        r'^\s*ctor\s+.*?([\w.]+)\s*\(([^)]*)\)\s*;'
    )
    field_pattern = re.compile(
        r'^\s*field\s+.*?(\S+)\s+([\w]+)\s*(?:=\s*[^;]+)?\s*;'
    )
    close_pattern = re.compile(r'^\s*\}')

    depth = 0
    for line in content.split('\n'):
        line_stripped = line.rstrip()

        # Package
        m = pkg_pattern.match(line_stripped)
        if m:
            current_package = m.group(1)
            depth = 1
            continue

        # Class/Interface
        m = cls_pattern.match(line_stripped)
        if m and current_package:
            class_type = m.group(1)
            raw_name = m.group(2).strip()
            # Clean generic parameters
            current_class = re.sub(r'<.*>', '', raw_name).strip()
            # Remove any remaining spaces
            current_class = current_class.split()[0] if ' ' in current_class else current_class
            depth = 2
            continue

        if not current_package or not current_class:
            if '}' in line_stripped:
                depth -= 1
                if depth <= 0:
                    current_package = None
                    current_class = None
                    depth = 0
                elif depth <= 1:
                    current_class = None
            continue

        # Method
        m = method_pattern.match(line_stripped)
        if m:
            method_name = m.group(1)
            params = m.group(2).strip()
            apis.append({
                "package": current_package,
                "class_name": current_class,
                "method_name": method_name,
                "api_type": "method",
                "params": params,
            })
            continue

        # Constructor
        m = ctor_pattern.match(line_stripped)
        if m:
            params = m.group(2).strip()
            apis.append({
                "package": current_package,
                "class_name": current_class,
                "method_name": "<init>",
                "api_type": "ctor",
                "params": params,
            })
            continue

        # Field
        m = field_pattern.match(line_stripped)
        if m:
            field_type = m.group(1)
            field_name = m.group(2)
            apis.append({
                "package": current_package,
                "class_name": current_class,
                "method_name": field_name,
                "api_type": "field",
                "params": "",
            })
            continue

        # Closing brace
        if '}' in line_stripped:
            depth -= 1
            if depth <= 1:
                current_class = None
            if depth <= 0:
                current_package = None
                depth = 0

    return apis


def assign_ids_and_metadata(apis: list) -> list:
    """Assign api_id, module_id, priority, and adapter_project."""
    # Group by priority for ID assignment
    counters = {}
    rows = []

    for api in apis:
        pkg = api["package"]
        module_id, module_name = get_module(pkg)
        priority = PRIORITY_MAP.get(module_id, "P4")

        # Generate ID
        if priority not in counters:
            counters[priority] = 0
        counters[priority] += 1
        api_id = f"{priority}-{counters[priority]:04d}"

        # Adapter project
        adapter_map = {
            "M01": "13X-01", "M02": "13X-02", "M03": "13X-03",
            "M04": "131", "M05": "13X-05", "M06": "13X-06",
            "M07": "13X-07", "M08": "13X-08", "M09": "13X-09",
            "M10": "13X-10", "M11": "13X-11", "M12": "13X-12",
            "M13": "13X-00", "M99": "TBD",
        }

        rows.append({
            "api_id": api_id,
            "module_id": module_id,
            "package": pkg,
            "class_name": api["class_name"],
            "method_name": api["method_name"],
            "api_type": api["api_type"],
            "priority": priority,
            "android_api_level": "",
            "description_cn": "",
            "harmony_mapping": "",
            "mapping_difficulty": "",
            "estimated_hours": "",
            "adapter_project": adapter_map.get(module_id, "TBD"),
            "status": "scraped",
            "notes": "",
        })

    return rows


def print_summary(rows: list):
    """Print summary statistics."""
    total = len(rows)
    print(f"\n{'='*50}", file=sys.stderr)
    print(f"API Scraper Summary", file=sys.stderr)
    print(f"{'='*50}", file=sys.stderr)
    print(f"Total APIs extracted: {total}", file=sys.stderr)

    # By module
    modules = {}
    for r in rows:
        mid = r["module_id"]
        modules[mid] = modules.get(mid, 0) + 1

    print(f"\nBy Module:", file=sys.stderr)
    for mid in sorted(modules.keys()):
        print(f"  {mid}: {modules[mid]:>6} APIs", file=sys.stderr)

    # By priority
    priorities = {}
    for r in rows:
        p = r["priority"]
        priorities[p] = priorities.get(p, 0) + 1

    print(f"\nBy Priority:", file=sys.stderr)
    for p in sorted(priorities.keys()):
        print(f"  {p}: {priorities[p]:>6} APIs", file=sys.stderr)

    # By type
    types = {}
    for r in rows:
        t = r["api_type"]
        types[t] = types.get(t, 0) + 1

    print(f"\nBy Type:", file=sys.stderr)
    for t in sorted(types.keys()):
        print(f"  {t}: {types[t]:>6}", file=sys.stderr)

    print(f"{'='*50}\n", file=sys.stderr)


def write_csv(rows: list, output_path: str = None):
    """Write rows to CSV."""
    if output_path:
        f = open(output_path, 'w', newline='', encoding='utf-8')
    else:
        f = sys.stdout

    writer = csv.DictWriter(f, fieldnames=CSV_HEADER)
    writer.writeheader()
    writer.writerows(rows)

    if output_path:
        f.close()
        print(f"Output written to {output_path}", file=sys.stderr)


def main():
    parser = argparse.ArgumentParser(
        description="Extract Android API surface from AOSP current.txt"
    )
    parser.add_argument(
        "--local", metavar="FILE",
        help="Use local current.txt file instead of downloading"
    )
    parser.add_argument(
        "--output", "-o", metavar="FILE",
        help="Output CSV file path (default: stdout)"
    )
    parser.add_argument(
        "--url", metavar="URL",
        help="Custom URL to download current.txt from"
    )
    args = parser.parse_args()

    # Get content
    if args.local:
        print(f"Reading local file: {args.local}", file=sys.stderr)
        with open(args.local, 'r', encoding='utf-8') as f:
            content = f.read()
    else:
        content = download_current_txt(args.url)

    print(f"File size: {len(content):,} bytes", file=sys.stderr)

    # Parse
    print("Parsing API surface...", file=sys.stderr)
    apis = parse_current_txt(content)
    print(f"Parsed {len(apis)} raw API entries", file=sys.stderr)

    # Assign metadata
    rows = assign_ids_and_metadata(apis)

    # Summary
    print_summary(rows)

    # Output
    write_csv(rows, args.output)


if __name__ == "__main__":
    main()
