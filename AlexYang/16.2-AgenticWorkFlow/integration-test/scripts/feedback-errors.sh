#!/bin/bash
# =============================================================================
# 16.2 Error Feedback
# Reads validation report, appends integration errors to each project's CLAUDE.md
# Each project's Claude instance can then pick up and fix the issues
# =============================================================================

set -euo pipefail

BASE="/mnt/e/10.Project"
REPORT_DIR="$(dirname "$0")/../reports"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Find latest validation report
LATEST_REPORT=$(ls -t "$REPORT_DIR"/validation-*.log 2>/dev/null | head -1)
if [ -z "$LATEST_REPORT" ]; then
    echo "No validation report found. Run validate-outputs.sh first."
    exit 1
fi

echo "Reading report: $LATEST_REPORT"
echo ""

# ---------------------------------------------------------------------------
# Extract errors per project and write to CLAUDE.md
# ---------------------------------------------------------------------------

append_feedback() {
    local project_dir="$1"
    local project_name="$2"
    local claude_md="$project_dir/CLAUDE.md"

    # Extract FAIL lines for this project from the report
    local section_errors=""
    local in_section=0

    while IFS= read -r line; do
        if echo "$line" | grep -q "=== ${project_name}"; then
            in_section=1
            continue
        fi
        if [ $in_section -eq 1 ] && echo "$line" | grep -q "^.*==="; then
            in_section=0
            continue
        fi
        if [ $in_section -eq 1 ] && echo "$line" | grep -q "FAIL:"; then
            local err_msg=$(echo "$line" | sed 's/.*FAIL: //')
            section_errors="${section_errors}\n- ${err_msg}"
        fi
    done < "$LATEST_REPORT"

    # Also check Cross-Project section for this project
    in_section=0
    while IFS= read -r line; do
        if echo "$line" | grep -q "=== Cross-Project"; then
            in_section=1
            continue
        fi
        if [ $in_section -eq 1 ] && echo "$line" | grep -q "^.*==="; then
            in_section=0
            continue
        fi
        if [ $in_section -eq 1 ] && echo "$line" | grep -q "FAIL:" && echo "$line" | grep -qi "${project_name}\|$(basename "$project_dir")"; then
            local err_msg=$(echo "$line" | sed 's/.*FAIL: //')
            section_errors="${section_errors}\n- [Cross-Project] ${err_msg}"
        fi
    done < "$LATEST_REPORT"

    if [ -z "$section_errors" ]; then
        echo "  ✓ ${project_name}: No errors to report"
        return
    fi

    echo "  ✗ ${project_name}: Appending errors to CLAUDE.md"

    # Ensure CLAUDE.md exists
    if [ ! -f "$claude_md" ]; then
        echo "# ${project_name}" > "$claude_md"
        echo "" >> "$claude_md"
    fi

    # Check if there's already an integration feedback section
    if grep -q "## 16.2 Integration Feedback" "$claude_md" 2>/dev/null; then
        # Replace existing section
        # Use a temp file to rebuild
        local tmp_file=$(mktemp)
        local skip=0
        while IFS= read -r line; do
            if echo "$line" | grep -q "## 16.2 Integration Feedback"; then
                skip=1
                continue
            fi
            if [ $skip -eq 1 ] && echo "$line" | grep -q "^## "; then
                skip=0
            fi
            if [ $skip -eq 0 ]; then
                echo "$line" >> "$tmp_file"
            fi
        done < "$claude_md"
        cp "$tmp_file" "$claude_md"
        rm "$tmp_file"
    fi

    # Append new feedback section
    cat >> "$claude_md" << FEEDBACK

## 16.2 Integration Feedback
**Last run**: ${TIMESTAMP}
**Status**: ERRORS FOUND - please fix and re-run integration

### Issues to fix:
$(echo -e "$section_errors")

### How to verify:
Run from 16.2: \`bash integration-test/scripts/validate-outputs.sh\`
FEEDBACK

    echo "    → Written to: $claude_md"
}

# ---------------------------------------------------------------------------
# Process each project
# ---------------------------------------------------------------------------

echo "Distributing integration errors to project CLAUDE.md files..."
echo ""

append_feedback "$BASE/16.1-AndroidToHarmonyOSDemo" "16.1-AndroidToHarmonyOSDemo"
append_feedback "$BASE/16.4.1-JIT.Performance" "16.4.1-JIT.Performance"
append_feedback "$BASE/16.4.2-Activity.Bridge" "16.4.2-Activity.Bridge"
append_feedback "$BASE/16.4.3-View.Bridge" "16.4.3-View.Bridge"
append_feedback "$BASE/16.4.4-System.Bridge" "16.4.4-System.Bridge"

echo ""
echo "Done. Each project's Claude instance will see the errors in CLAUDE.md."
