#!/bin/bash
# verify_131_113.sh - Verify TextClock APK Build (Task 16.1.113)
#
# Purpose: Automated verification that 16.1.113 (Build APK) was completed successfully
# Status: Checks that APK file exists, has reasonable size, and is valid
# Returns: exit 0 if PASS, exit 1 if FAIL

PROJECT_ROOT="$(pwd)"
TASK_ID="16.1.113"
BUILD_DIR="$PROJECT_ROOT/10-Projects/16-DigitalEmployee/16.1-AndroidToHarmonyOSDemo/16.1.1-ANDROID-ANALYSIS/16.1.11-ANDROID-BUILD"
APK_FILE="$BUILD_DIR/TextClock-debug.apk"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "Verifying Task $TASK_ID - Build TextClock APK"
echo "========================================"
echo ""

CHECKS_PASSED=0
CHECKS_FAILED=0

# ==================== CHECK 1: Directory exists ====================
echo "[CHECK 1] Build directory exists"
if [ -d "$BUILD_DIR" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Directory exists at $BUILD_DIR"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}: Directory does not exist at $BUILD_DIR"
    ((CHECKS_FAILED++))
    exit 1
fi

# ==================== CHECK 2: APK file exists ====================
echo ""
echo "[CHECK 2] APK file exists"
if [ -f "$APK_FILE" ]; then
    echo -e "${GREEN}✅ PASS${NC}: APK file exists at $APK_FILE"
    ((CHECKS_PASSED++))
else
    echo -e "${RED}❌ FAIL${NC}: APK file NOT found at $APK_FILE"
    echo "         Expected: TextClock-debug.apk"
    echo "         Actual: File does not exist"
    ((CHECKS_FAILED++))
fi

# ==================== CHECK 3: APK file size reasonable ====================
echo ""
echo "[CHECK 3] APK file size > 1 MB (must be non-trivial binary)"
if [ -f "$APK_FILE" ]; then
    # Get file size in bytes (handle both macOS and Linux)
    if command -v stat &> /dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            size=$(stat -f%z "$APK_FILE" 2>/dev/null)
        else
            # Linux
            size=$(stat -c%s "$APK_FILE" 2>/dev/null)
        fi
    else
        size=$(ls -lh "$APK_FILE" | awk '{print $5}')
    fi

    size_bytes=$(stat -c%s "$APK_FILE" 2>/dev/null || stat -f%z "$APK_FILE" 2>/dev/null)
    size_mb=$((size_bytes / 1048576))

    if [ "$size_bytes" -gt 1048576 ]; then
        echo -e "${GREEN}✅ PASS${NC}: APK size is $size_mb MB (> 1 MB minimum)"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: APK file too small: $size_bytes bytes (need > 1 MB = 1048576 bytes)"
        ((CHECKS_FAILED++))
    fi
else
    echo -e "${YELLOW}⚠️  SKIP${NC}: Cannot check size - APK file doesn't exist"
fi

# ==================== CHECK 4: APK is valid binary (not text) ====================
echo ""
echo "[CHECK 4] APK is valid binary format (not corrupted)"
if [ -f "$APK_FILE" ]; then
    # APK is a ZIP file, should have magic bytes PK
    first_bytes=$(xxd -l 2 "$APK_FILE" 2>/dev/null | head -c 10 || od -x -N 2 "$APK_FILE" | head -1)

    # More portable check: try to read as ZIP
    if unzip -t "$APK_FILE" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}: APK is valid ZIP/binary format"
        ((CHECKS_PASSED++))
    else
        echo -e "${RED}❌ FAIL${NC}: APK file appears corrupted or is not valid ZIP format"
        ((CHECKS_FAILED++))
    fi
else
    echo -e "${YELLOW}⊘ SKIP${NC}: Cannot validate - APK file doesn't exist"
fi

# ==================== CHECK 5: Build log exists ====================
echo ""
echo "[CHECK 5] Build artifacts (logs/config) exist"
build_log="$BUILD_DIR/build.log"
gradle_config="$BUILD_DIR/gradle-config.md"

if [ -f "$build_log" ] || [ -f "$gradle_config" ]; then
    echo -e "${GREEN}✅ PASS${NC}: Build artifacts found"
    [ -f "$build_log" ] && echo "         - build.log exists"
    [ -f "$gradle_config" ] && echo "         - gradle-config.md exists"
    ((CHECKS_PASSED++))
else
    echo -e "${YELLOW}⚠️  WARN${NC}: No build artifacts found (build.log or gradle-config.md)"
    # Don't count as failure, but as warning
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
    echo "Task 16.1.113 is VERIFIED COMPLETE:"
    echo "  ✅ APK file exists at: $APK_FILE"
    echo "  ✅ File size: $(stat -c%s "$APK_FILE" 2>/dev/null || stat -f%z "$APK_FILE" 2>/dev/null) bytes"
    echo "  ✅ Valid binary format"
    echo ""
    exit 0
else
    echo -e "${RED}❌ VERIFICATION FAILED${NC}"
    echo ""
    echo "Task 16.1.113 is NOT COMPLETE. Issues found:"
    [ ! -d "$BUILD_DIR" ] && echo "  ❌ Build directory missing"
    [ ! -f "$APK_FILE" ] && echo "  ❌ APK file missing (most critical)"
    echo ""
    echo "Action required: Must rebuild APK or verify it was actually built"
    echo ""
    exit 1
fi
