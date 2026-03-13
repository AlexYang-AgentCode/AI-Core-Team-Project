#!/bin/bash
# =============================================================================
# 16.2 Integration Validator
# Validates that each upstream project has produced its required outputs
# Writes errors to each project's CLAUDE.md
# =============================================================================

set -euo pipefail

BASE="/mnt/e/10.Project"
REPORT_DIR="$(dirname "$0")/../reports"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
REPORT_FILE="${REPORT_DIR}/validation-$(date '+%Y%m%d-%H%M%S').log"
ERRORS_FOUND=0

mkdir -p "$REPORT_DIR"

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$REPORT_FILE"; }
pass() { log "  ✓ PASS: $1"; }
fail() { log "  ✗ FAIL: $1"; ERRORS_FOUND=1; }

echo "=============================================" | tee "$REPORT_FILE"
echo "16.2 Integration Validation Report" | tee -a "$REPORT_FILE"
echo "Time: $TIMESTAMP" | tee -a "$REPORT_FILE"
echo "=============================================" | tee -a "$REPORT_FILE"

# ---------------------------------------------------------------------------
# 1. 16.1 - APK Output
# ---------------------------------------------------------------------------
log ""
log "=== 16.1-AndroidToHarmonyOSDemo ==="

APK_PATH="$BASE/16.1-AndroidToHarmonyOSDemo/test-elegant/app/release/Calculator.apk"
MAIN_JAVA="$BASE/16.1-AndroidToHarmonyOSDemo/test-elegant/app/src/main/java/com/example/new_sample/MainActivity.java"

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(stat -c %s "$APK_PATH" 2>/dev/null || echo "unknown")
    pass "Calculator.apk exists (${APK_SIZE} bytes)"
else
    fail "Calculator.apk not found at $APK_PATH"
    echo "  → 16.1 needs to build APK: cd test-elegant && ./gradlew assembleRelease"
fi

if [ -f "$MAIN_JAVA" ]; then
    pass "MainActivity.java source exists"
    # Check key APIs used (these must be bridged by 16.4.x)
    APIS_USED=""
    grep -q "AppCompatActivity" "$MAIN_JAVA" 2>/dev/null && APIS_USED="${APIS_USED} AppCompatActivity"
    grep -q "setContentView" "$MAIN_JAVA" 2>/dev/null && APIS_USED="${APIS_USED} setContentView"
    grep -q "findViewById" "$MAIN_JAVA" 2>/dev/null && APIS_USED="${APIS_USED} findViewById"
    grep -q "Button" "$MAIN_JAVA" 2>/dev/null && APIS_USED="${APIS_USED} Button"
    grep -q "TextView" "$MAIN_JAVA" 2>/dev/null && APIS_USED="${APIS_USED} TextView"
    grep -q "setOnClickListener" "$MAIN_JAVA" 2>/dev/null && APIS_USED="${APIS_USED} OnClickListener"
    grep -q "setOnLongClickListener" "$MAIN_JAVA" 2>/dev/null && APIS_USED="${APIS_USED} OnLongClickListener"
    grep -q "Toast" "$MAIN_JAVA" 2>/dev/null && APIS_USED="${APIS_USED} Toast"
    log "  APIs detected in source:${APIS_USED}"
else
    fail "MainActivity.java not found"
fi

# ---------------------------------------------------------------------------
# 2. 16.4.1 - JIT Converter
# ---------------------------------------------------------------------------
log ""
log "=== 16.4.1-JIT.Performance ==="

JIT_DIR="$BASE/16.4.1-JIT.Performance/05-Implementation"

if [ -f "$JIT_DIR/converter.py" ]; then
    pass "converter.py exists"
else
    fail "converter.py not found - JIT converter is required"
fi

if [ -f "$JIT_DIR/dex-parser/dex_parser.py" ]; then
    pass "dex_parser.py exists"
else
    fail "dex_parser.py not found"
fi

if [ -f "$JIT_DIR/ir/instruction_mapper.py" ]; then
    pass "instruction_mapper.py exists"
else
    fail "instruction_mapper.py not found"
fi

if [ -f "$JIT_DIR/abc-generator/abc_generator.py" ]; then
    pass "abc_generator.py exists"
else
    fail "abc_generator.py not found"
fi

# Try running converter to see if it works
if command -v python3 &>/dev/null && [ -f "$JIT_DIR/converter.py" ]; then
    if python3 -c "import sys; sys.path.insert(0,'$JIT_DIR'); import converter" 2>/dev/null; then
        pass "converter.py imports successfully"
    else
        fail "converter.py has import errors"
    fi
fi

# ---------------------------------------------------------------------------
# 3. 16.4.2 - Activity Bridge
# ---------------------------------------------------------------------------
log ""
log "=== 16.4.2-Activity.Bridge ==="

AB_DIR="$BASE/16.4.2-Activity.Bridge/05-Implementation"

REQUIRED_ACTIVITY_FILES=(
    "ets/activity/Activity.ets"
    "ets/activity/AppCompatActivity.ets"
    "ets/os/Bundle.ets"
    "ets/view/LayoutInflater.ets"
    "ets/view/View.ets"
    "ets/view/ViewFinder.ets"
    "ets/lifecycle/LifecycleState.ets"
    "ets/content/Context.ets"
)

for f in "${REQUIRED_ACTIVITY_FILES[@]}"; do
    if [ -f "$AB_DIR/$f" ]; then
        pass "$f"
    else
        fail "Missing: $f"
    fi
done

# Check key API implementations
if [ -f "$AB_DIR/ets/activity/Activity.ets" ]; then
    MISSING_APIS=""
    grep -q "onCreate" "$AB_DIR/ets/activity/Activity.ets" 2>/dev/null || MISSING_APIS="${MISSING_APIS} onCreate"
    grep -q "setContentView" "$AB_DIR/ets/activity/Activity.ets" 2>/dev/null || MISSING_APIS="${MISSING_APIS} setContentView"
    grep -q "findViewById" "$AB_DIR/ets/activity/Activity.ets" 2>/dev/null || MISSING_APIS="${MISSING_APIS} findViewById"
    grep -q "finish" "$AB_DIR/ets/activity/Activity.ets" 2>/dev/null || MISSING_APIS="${MISSING_APIS} finish"
    if [ -n "$MISSING_APIS" ]; then
        fail "Activity.ets missing APIs:${MISSING_APIS}"
    else
        pass "Activity.ets has all required APIs"
    fi
fi

# ---------------------------------------------------------------------------
# 4. 16.4.3 - View Bridge
# ---------------------------------------------------------------------------
log ""
log "=== 16.4.3-View.Bridge ==="

VB_DIR="$BASE/16.4.3-View.Bridge/05-Implementation"

REQUIRED_VIEW_FILES=(
    "view/AndroidView.ets"
    "view/AndroidButton.ets"
    "view/AndroidTextView.ets"
    "view/AndroidEditText.ets"
    "layout/AndroidLinearLayout.ets"
    "layout/AndroidRelativeLayout.ets"
    "layout/AndroidFrameLayout.ets"
    "registry/ViewRegistry.ets"
)

for f in "${REQUIRED_VIEW_FILES[@]}"; do
    if [ -f "$VB_DIR/$f" ]; then
        pass "$f"
    else
        fail "Missing: $f"
    fi
done

# Check Button bridge has OnClickListener support
if [ -f "$VB_DIR/view/AndroidButton.ets" ]; then
    if grep -q "setOnClickListener\|onClick" "$VB_DIR/view/AndroidButton.ets" 2>/dev/null; then
        pass "AndroidButton has click listener support"
    else
        fail "AndroidButton missing OnClickListener support"
    fi
fi

# Check View bridge has OnTouchListener support
if [ -f "$VB_DIR/view/AndroidView.ets" ]; then
    if grep -q "setOnTouchListener\|onTouch\|TouchEvent" "$VB_DIR/view/AndroidView.ets" 2>/dev/null; then
        pass "AndroidView has touch listener support"
    else
        fail "AndroidView missing OnTouchListener support"
    fi
fi

# ---------------------------------------------------------------------------
# 5. 16.4.4 - System Bridge
# ---------------------------------------------------------------------------
log ""
log "=== 16.4.4-System.Bridge ==="

SB_DIR="$BASE/16.4.4-System.Bridge/05-Implementation"

REQUIRED_SYSTEM_FILES=(
    "context/LogBridge.ets"
    "context/ToastBridge.ets"
    "context/ContextBridge.ets"
    "expr-engine/ExpressionEvaluator.ets"
    "expr-engine/DecimalBridge.ets"
    "r-mapper/RClass.ets"
    "r-mapper/ResourceConverter.ets"
    "java-compat/TextUtils.ets"
)

for f in "${REQUIRED_SYSTEM_FILES[@]}"; do
    if [ -f "$SB_DIR/$f" ]; then
        pass "$f"
    else
        fail "Missing: $f"
    fi
done

# Check ExpressionEvaluator can handle calculator operations
if [ -f "$SB_DIR/expr-engine/ExpressionEvaluator.ets" ]; then
    MISSING_OPS=""
    grep -q "add\|plus\|+" "$SB_DIR/expr-engine/ExpressionEvaluator.ets" 2>/dev/null || MISSING_OPS="${MISSING_OPS} add"
    grep -q "subtract\|minus\|-" "$SB_DIR/expr-engine/ExpressionEvaluator.ets" 2>/dev/null || MISSING_OPS="${MISSING_OPS} subtract"
    grep -q "multiply\|×\|\*" "$SB_DIR/expr-engine/ExpressionEvaluator.ets" 2>/dev/null || MISSING_OPS="${MISSING_OPS} multiply"
    grep -q "divide\|÷\|/" "$SB_DIR/expr-engine/ExpressionEvaluator.ets" 2>/dev/null || MISSING_OPS="${MISSING_OPS} divide"
    if [ -n "$MISSING_OPS" ]; then
        fail "ExpressionEvaluator missing operations:${MISSING_OPS}"
    else
        pass "ExpressionEvaluator has all calculator operations"
    fi
fi

# ---------------------------------------------------------------------------
# 6. Cross-project interface checks
# ---------------------------------------------------------------------------
log ""
log "=== Cross-Project Interface Validation ==="

# Check that Activity Bridge exports what View Bridge needs
if [ -f "$AB_DIR/ets/view/View.ets" ] && [ -f "$VB_DIR/view/AndroidView.ets" ]; then
    pass "Activity→View interface: both sides have View definitions"
else
    fail "Activity→View interface gap: missing View definitions on one side"
fi

# Check that System Bridge's RClass covers Calculator's R.id references
if [ -f "$SB_DIR/r-mapper/RClass.ets" ]; then
    if grep -q "textViewInputNumbers\|button0\|buttonEquals\|buttonClear" "$SB_DIR/r-mapper/RClass.ets" 2>/dev/null; then
        pass "RClass has Calculator R.id mappings"
    else
        fail "RClass missing Calculator-specific R.id mappings (textViewInputNumbers, button0, etc.)"
    fi
fi

# Check ViewRegistry consistency between 16.4.2 and 16.4.3
if [ -f "$AB_DIR/activity-bridge/ViewRegistry.ets" ] && [ -f "$VB_DIR/registry/ViewRegistry.ets" ]; then
    log "  ⚠ WARNING: ViewRegistry exists in both 16.4.2 AND 16.4.3 - potential conflict"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
log ""
echo "=============================================" | tee -a "$REPORT_FILE"
if [ $ERRORS_FOUND -eq 0 ]; then
    log "RESULT: ALL VALIDATIONS PASSED ✓"
else
    log "RESULT: SOME VALIDATIONS FAILED ✗"
    log "Run: bash scripts/feedback-errors.sh to push errors to project CLAUDE.md files"
fi
echo "=============================================" | tee -a "$REPORT_FILE"
echo ""
echo "Report saved to: $REPORT_FILE"

exit $ERRORS_FOUND
