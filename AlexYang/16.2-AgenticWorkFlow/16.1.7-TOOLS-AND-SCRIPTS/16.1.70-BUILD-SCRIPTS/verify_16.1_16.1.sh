#!/bin/bash
# verify_131_131.sh - Verify API Extraction (Task 16.1.131)
#
# Purpose: Automated verification that 16.1.131 (API Extraction) was completed successfully
# Status: Checks that api-list.csv exists and contains the claimed 12 APIs
# Returns: exit 0 if PASS, exit 1 if FAIL

PROJECT_ROOT="$(pwd)"
TASK_ID="16.1.131"
API_DIR="$PROJECT_ROOT/10-Projects/16-DigitalEmployee/16.1-AndroidToHarmonyOSDemo/16.1.1-ANDROID-ANALYSIS/16.1.13-API-EXTRACTION"
API_CSV="$API_DIR/api-list.csv"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Verifying Task $TASK_ID - API Extraction"
echo "========================================"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# ==================== CHECK 1: Directory exists ====================
echo "[CHECK 1] API Extraction directory exists"
if [ -d "$API_DIR" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Directory exists at $API_DIR"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}: Directory does not exist at $API_DIR"
    ((CHECKS_FAILED++))
    exit 1
fi

# ==================== CHECK 2: api-list.csv file exists ====================
echo ""
echo "[CHECK 2] api-list.csv file exists"
if [ -f "$API_CSV" ]; then
    echo -e "${GREEN}✅ PASS${NC}: API list file exists at $API_CSV"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}: api-list.csv NOT found at $API_CSV"
    echo "         Expected deliverable: api-list.csv"
    ((CHECKS_FAILED++))
fi

# ==================== CHECK 3: CSV file has content ====================
echo ""
echo "[CHECK 3] CSV file is not empty (has data)"
if [ -f "$API_CSV" ]; then
    size=$(wc -c < "$API_CSV" 2>/dev/null)
    lines=$(wc -l < "$API_CSV" 2>/dev/null)

    if [ "$size" -gt 100 ]; then
        echo -e "${GREEN}✅ PASS${NC}: CSV file has content ($lines lines, $size bytes)"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: CSV file is empty or too small ($size bytes)"
        ((CHECKS_FAILED++))
    fi
else
    echo -e "${YELLOW}⊘ SKIP${NC}: Cannot check - CSV file doesn't exist"
fi

# ==================== CHECK 4: CSV has header and data rows ====================
echo ""
echo "[CHECK 4] CSV has proper structure (header + data rows)"
if [ -f "$API_CSV" ]; then
    lines=$(wc -l < "$API_CSV")
    first_line=$(head -1 "$API_CSV")

    # Check for CSV header indicators
    if echo "$first_line" | grep -q "api\|API\|method\|class"; then
        if [ "$lines" -gt 1 ]; then
            echo -e "${GREEN}✅ PASS${NC}: CSV has header and $((lines - 1)) data rows"
            ((CHECKS_PASSED++))
        else
            echo -e "${RED}❌ FAIL${NC}: CSV only has header, no data rows"
            ((CHECKS_FAILED++))
        fi
    else
        echo -e "${YELLOW}⚠️  WARN${NC}: Cannot identify CSV header format"
        echo "         First line: $first_line"
    fi
else
    echo -e "${YELLOW}⊘ SKIP${NC}: Cannot check - CSV file doesn't exist"
fi

# ==================== CHECK 5: CSV has at least the claimed number of APIs ====================
echo ""
echo "[CHECK 5] CSV contains at least 12 APIs (as claimed)"
if [ -f "$API_CSV" ]; then
    # Count non-header, non-empty lines
    api_count=$(tail -n +2 "$API_CSV" | grep -v '^[[:space:]]*$' | wc -l)

    if [ "$api_count" -ge 12 ]; then
        echo -e "${GREEN}✅ PASS${NC}: CSV contains $api_count APIs (>= 12 required)"
        ((CHECKS_PASSED++))
    elif [ "$api_count" -gt 0 ]; then
        echo -e "${RED}❌ FAIL${NC}: CSV only has $api_count APIs (need >= 12)"
        ((CHECKS_FAILED++))
    else
        echo -e "${RED}❌ FAIL${NC}: CSV has no data rows (need >= 12 APIs)"
        ((CHECKS_FAILED++))
    fi
else
    echo -e "${YELLOW}⊘ SKIP${NC}: Cannot check - CSV file doesn't exist"
fi

# ==================== CHECK 6: CSV contains expected columns ====================
echo ""
echo "[CHECK 6] CSV contains essential columns (class, method, etc)"
if [ -f "$API_CSV" ]; then
    header=$(head -1 "$API_CSV")

    if echo "$header" | grep -q "class\|method\|API\|api"; then
        echo -e "${GREEN}✅ PASS${NC}: CSV has expected structure"
        echo "         Header: $header"
        ((CHECKS_PASSED++))
    else
        echo -e "${YELLOW}⚠️  WARN${NC}: CSV header doesn't contain expected keywords"
        echo "         Header: $header"
    fi
else
    echo -e "${YELLOW}⊘ SKIP${NC}: Cannot check - CSV file doesn't exist"
fi

# ==================== SUMMARY ====================
echo ""
echo "========================================"
echo "VERIFICATION SUMMARY"
echo "========================================"
echo "Checks passed: ${GREEN}$CHECKS_PASSED${NC}"
echo "Checks failed: ${RED}$CHECKS_FAILED${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ VERIFICATION PASSED${NC}"
    echo ""
    echo "Task 16.1.131 is VERIFIED COMPLETE:"
    echo "  ✅ API list file exists at: $API_CSV"
    if [ -f "$API_CSV" ]; then
        api_count=$(tail -n +2 "$API_CSV" | grep -v '^[[:space:]]*$' | wc -l)
        echo "  ✅ Contains $api_count APIs"
    fi
    echo ""
    exit 0
else
    echo -e "${RED}❌ VERIFICATION FAILED${NC}"
    echo ""
    echo "Task 16.1.131 is NOT COMPLETE. Issues found:"
    [ ! -d "$API_DIR" ] && echo "  ❌ Directory missing"
    [ ! -f "$API_CSV" ] && echo "  ❌ api-list.csv missing"
    echo ""
    echo "Action required: Must complete API extraction and create api-list.csv"
    echo ""
    exit 1
fi
