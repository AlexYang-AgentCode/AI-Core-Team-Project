#!/bin/bash
# =============================================================================
# Open assembled project in DevEco Studio (Windows)
# =============================================================================

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/../assembled-project" && pwd)"
WIN_PATH=$(echo "$PROJECT_DIR" | sed 's|/mnt/\(.\)|\U\1:|; s|/|\\|g')

echo "============================================="
echo "Opening in DevEco Studio"
echo "============================================="
echo ""
echo "Project: $WIN_PATH"
echo ""

# Try to find DevEco Studio executable
DEVECO_PATHS=(
    "/mnt/c/Program Files/Huawei/DevEco Studio/bin/devecostudio64.exe"
    "/mnt/c/Program Files (x86)/Huawei/DevEco Studio/bin/devecostudio64.exe"
)

DEVECO_EXE=""
for p in "${DEVECO_PATHS[@]}"; do
    if [ -f "$p" ]; then
        DEVECO_EXE="$p"
        break
    fi
done

# Also check via Start Menu shortcut
if [ -z "$DEVECO_EXE" ]; then
    # Look for DevEco Studio in common locations
    FOUND=$(find /mnt/c -maxdepth 5 -name "devecostudio*.exe" -type f 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        DEVECO_EXE="$FOUND"
    fi
fi

if [ -n "$DEVECO_EXE" ]; then
    echo "Found DevEco Studio: $DEVECO_EXE"
    echo "Launching..."
    "$DEVECO_EXE" "$PROJECT_DIR" &
    echo "DevEco Studio opened."
else
    echo "DevEco Studio executable not found automatically."
    echo ""
    echo "Please open manually:"
    echo "  1. Open DevEco Studio 6.0"
    echo "  2. File → Open Project"
    echo "  3. Navigate to: $WIN_PATH"
    echo "  4. Click Open"
    echo ""
    echo "Then to run on emulator:"
    echo "  5. Tools → Device Manager → Create Emulator (Phone)"
    echo "  6. Start the emulator"
    echo "  7. Click Run (▶) or Shift+F10"
fi

echo ""
echo "============================================="
echo "Manual steps in DevEco Studio:"
echo "  1. Wait for project sync to complete"
echo "  2. Tools → Device Manager → Start emulator"
echo "  3. Click Run (▶) to deploy to emulator"
echo "  4. On emulator: tap 'Run Integration Test'"
echo "  5. Tap 'View Calculator' to see the Calculator UI"
echo "============================================="
