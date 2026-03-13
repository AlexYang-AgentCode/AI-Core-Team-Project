#!/bin/bash
# =============================================================================
# 16.2 Project Assembler
# Collects bridge outputs from 16.4.1-4 into a single DevEco Studio project
# that can run the Calculator demo on HarmonyOS emulator
# =============================================================================

set -euo pipefail

BASE="/mnt/e/10.Project"
PROJECT_DIR="$(dirname "$0")/../assembled-project"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "============================================="
echo "16.2 Project Assembler"
echo "Time: $TIMESTAMP"
echo "============================================="

# ---------------------------------------------------------------------------
# 1. Clean and prepare
# ---------------------------------------------------------------------------
echo ""
echo "[1/5] Preparing assembled project directory..."

BRIDGES_DIR="$PROJECT_DIR/entry/src/main/ets/bridges"
rm -rf "$BRIDGES_DIR"
mkdir -p "$BRIDGES_DIR/activity"
mkdir -p "$BRIDGES_DIR/view"
mkdir -p "$BRIDGES_DIR/system"
mkdir -p "$BRIDGES_DIR/jit"

# ---------------------------------------------------------------------------
# 2. Copy Activity Bridge (16.4.2)
# ---------------------------------------------------------------------------
echo "[2/5] Copying 16.4.2 Activity Bridge..."

AB_SRC="$BASE/16.4.2-Activity.Bridge/05-Implementation/ets"
if [ -d "$AB_SRC" ]; then
    cp -r "$AB_SRC"/* "$BRIDGES_DIR/activity/" 2>/dev/null || true
    echo "  → Copied $(find "$BRIDGES_DIR/activity" -name '*.ets' | wc -l) .ets files"
else
    echo "  ✗ WARNING: Activity Bridge source not found at $AB_SRC"
fi

# ---------------------------------------------------------------------------
# 3. Copy View Bridge (16.4.3)
# ---------------------------------------------------------------------------
echo "[3/5] Copying 16.4.3 View Bridge..."

VB_SRC="$BASE/16.4.3-View.Bridge/05-Implementation"
if [ -d "$VB_SRC" ]; then
    cp -r "$VB_SRC"/view "$BRIDGES_DIR/view/" 2>/dev/null || true
    cp -r "$VB_SRC"/layout "$BRIDGES_DIR/view/" 2>/dev/null || true
    cp -r "$VB_SRC"/registry "$BRIDGES_DIR/view/" 2>/dev/null || true
    cp -r "$VB_SRC"/widgets "$BRIDGES_DIR/view/" 2>/dev/null || true
    echo "  → Copied $(find "$BRIDGES_DIR/view" -name '*.ets' | wc -l) .ets files"
else
    echo "  ✗ WARNING: View Bridge source not found at $VB_SRC"
fi

# ---------------------------------------------------------------------------
# 4. Copy System Bridge (16.4.4)
# ---------------------------------------------------------------------------
echo "[4/5] Copying 16.4.4 System Bridge..."

SB_SRC="$BASE/16.4.4-System.Bridge/05-Implementation"
if [ -d "$SB_SRC" ]; then
    cp -r "$SB_SRC"/context "$BRIDGES_DIR/system/" 2>/dev/null || true
    cp -r "$SB_SRC"/expr-engine "$BRIDGES_DIR/system/" 2>/dev/null || true
    cp -r "$SB_SRC"/r-mapper "$BRIDGES_DIR/system/" 2>/dev/null || true
    cp -r "$SB_SRC"/java-compat "$BRIDGES_DIR/system/" 2>/dev/null || true
    cp -r "$SB_SRC"/bridges "$BRIDGES_DIR/system/" 2>/dev/null || true
    echo "  → Copied $(find "$BRIDGES_DIR/system" \( -name '*.ets' -o -name '*.ts' \) | wc -l) files"
else
    echo "  ✗ WARNING: System Bridge source not found at $SB_SRC"
fi

# ---------------------------------------------------------------------------
# 5. Copy APK for reference
# ---------------------------------------------------------------------------
echo "[5/5] Linking APK reference..."

APK_PATH="$BASE/16.1-AndroidToHarmonyOSDemo/test-elegant/app/release/Calculator.apk"
if [ -f "$APK_PATH" ]; then
    mkdir -p "$PROJECT_DIR/apk-input"
    cp "$APK_PATH" "$PROJECT_DIR/apk-input/" 2>/dev/null || true
    echo "  → Calculator.apk copied to apk-input/"
else
    echo "  ✗ WARNING: Calculator.apk not found"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================="
echo "Assembly complete!"
echo ""
echo "Bridge files assembled:"
find "$BRIDGES_DIR" \( -name '*.ets' -o -name '*.ts' \) | sort
echo ""
echo "Project location: $PROJECT_DIR"
echo "Next: Open in DevEco Studio with:"
echo "  bash scripts/open-deveco.sh"
echo "============================================="
