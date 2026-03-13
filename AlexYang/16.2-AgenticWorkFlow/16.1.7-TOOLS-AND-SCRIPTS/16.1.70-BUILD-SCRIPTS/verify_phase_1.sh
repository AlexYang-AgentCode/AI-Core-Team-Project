#!/bin/bash
# verify_phase_1.sh - Comprehensive Phase 1 Verification
#
# Purpose: Run all Phase 1 task verifications and generate a report
# Returns: exit 0 if all pass, exit 1 if any fail

PROJECT_ROOT="$(pwd)"
REPORT_FILE="$PROJECT_ROOT/16.1.1-PHASE-VERIFICATION-REPORT.md"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "========================================"
echo "PHASE 1 - Comprehensive Verification"
echo "========================================"
echo ""
echo "Running all Phase 1 task verification scripts..."
echo ""

# Initialize report
cat > "$REPORT_FILE" << 'EOF'
---
title: "16.1.1 Phase Verification Report (Automated)"
date: 2026-03-09
tags: [verification, automated, phase-1]
---

# Phase 16.1.1 - Verification Report (Auto-Generated)

> **Generated**: 2026-03-09
> **Method**: Automated verification scripts
> **Purpose**: Verify actual completion vs claimed completion

---

## Task Verification Results

EOF

# Track overall results
TOTAL_TASKS=0
PASSED_TASKS=0
FAILED_TASKS=0
SKIPPED_TASKS=0

# ==================== TASK 16.1.113: Build APK ====================
echo "Running: verify_131_113.sh (Build APK)..."
echo ""
TASK_NAME="16.1.113 - Build TextClock APK"

if bash verify_131_113.sh > /tmp/verify_131_113.log 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}: $TASK_NAME"
    STATUS="✅ PASS"
    ((PASSED_TASKS++))
else
    echo -e "${RED}❌ FAIL${NC}: $TASK_NAME"
    STATUS="❌ FAIL"
    ((FAILED_TASKS++))
fi
((TOTAL_TASKS++))

# Append to report
cat >> "$REPORT_FILE" << EOF

### Task $TASK_NAME
- **Status**: $STATUS
- **Details**: See verification script output below
\`\`\`
$(cat /tmp/verify_131_113.log | tail -30)
\`\`\`

---

EOF

echo ""

# ==================== TASK 16.1.131: API Extraction ====================
echo "Running: verify_131_131.sh (API Extraction)..."
echo ""
TASK_NAME="16.1.131 - API Extraction"

if bash verify_131_131.sh > /tmp/verify_131_131.log 2>&1; then
    echo -e "${GREEN}✅ PASS${NC}: $TASK_NAME"
    STATUS="✅ PASS"
    ((PASSED_TASKS++))
else
    echo -e "${RED}❌ FAIL${NC}: $TASK_NAME"
    STATUS="❌ FAIL"
    ((FAILED_TASKS++))
fi
((TOTAL_TASKS++))

# Append to report
cat >> "$REPORT_FILE" << EOF

### Task $TASK_NAME
- **Status**: $STATUS
- **Details**: See verification script output below
\`\`\`
$(cat /tmp/verify_131_131.log | tail -30)
\`\`\`

---

EOF

echo ""

# ==================== SUMMARY ====================
echo "========================================"
echo "PHASE 1 VERIFICATION SUMMARY"
echo "========================================"
echo ""
echo "Total tasks verified: $TOTAL_TASKS"
echo -e "Passed: ${GREEN}$PASSED_TASKS${NC}"
echo -e "Failed: ${RED}$FAILED_TASKS${NC}"
echo ""

# Calculate percentage
if [ $TOTAL_TASKS -gt 0 ]; then
    PASS_PERCENT=$((PASSED_TASKS * 100 / TOTAL_TASKS))
    echo "Completion: $PASS_PERCENT% ($PASSED_TASKS/$TOTAL_TASKS)"
else
    PASS_PERCENT=0
fi

# Append summary to report
cat >> "$REPORT_FILE" << EOF

## Summary

| Metric | Value |
|--------|-------|
| Total Tasks | $TOTAL_TASKS |
| Passed | $PASSED_TASKS |
| Failed | $FAILED_TASKS |
| **Real Completion** | **$PASS_PERCENT%** |

### Critical Issues

EOF

if [ $FAILED_TASKS -gt 0 ]; then
    echo ""
    echo -e "${RED}❌ PHASE 1 VERIFICATION FAILED${NC}"
    echo ""
    echo "Failed tasks:"
    bash verify_131_113.sh >/dev/null 2>&1 || echo "  ❌ 16.1.113 - Build APK"
    bash verify_131_131.sh >/dev/null 2>&1 || echo "  ❌ 16.1.131 - API Extraction"
    echo ""

    cat >> "$REPORT_FILE" << EOF

- **16.1.113 (Build APK)**: APK file missing - task not actually completed
- Other tasks: Require verification scripts before marking complete

### Action Required

1. Must rebuild APK for 16.1.113 or determine why not attempted
2. Create verification scripts for other Phase 1 tasks
3. Re-run this verification after fixes

---

**Phase Status**: 🔴 BLOCKED - Cannot proceed to Phase 2 until critical issues resolved

EOF

    echo ""
    exit 1
else
    echo ""
    echo -e "${GREEN}✅ PHASE 1 VERIFICATION PASSED${NC}"
    echo ""

    cat >> "$REPORT_FILE" << EOF

- No critical issues found
- All verified tasks passed

### Action Available

1. Can proceed to Phase 2 (Adapter Development)
2. Continue verifying remaining Phase 1 tasks (111, 112, etc)
3. Establish automated daily verification

---

**Phase Status**: ✅ READY FOR PHASE 2

EOF

    exit 0
fi
