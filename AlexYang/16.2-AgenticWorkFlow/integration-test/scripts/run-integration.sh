#!/bin/bash
# =============================================================================
# 16.2 Full Integration Pipeline
# 1. Validate all project outputs
# 2. Assemble DevEco Studio project
# 3. Feed errors back if any
# 4. Open in DevEco Studio
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "╔═══════════════════════════════════════════╗"
echo "║   16.2 AgenticWorkFlow - Integration      ║"
echo "║   APK → Bridge → HarmonyOS Pipeline       ║"
echo "╚═══════════════════════════════════════════╝"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Validate
# ---------------------------------------------------------------------------
echo "━━━ Step 1/4: Validating project outputs ━━━"
echo ""

VALIDATION_OK=true
if ! bash "$SCRIPT_DIR/validate-outputs.sh"; then
    VALIDATION_OK=false
fi

echo ""

# ---------------------------------------------------------------------------
# Step 2: Feed errors back (if validation failed)
# ---------------------------------------------------------------------------
if [ "$VALIDATION_OK" = false ]; then
    echo "━━━ Step 2/4: Feeding errors to project CLAUDE.md files ━━━"
    echo ""
    bash "$SCRIPT_DIR/feedback-errors.sh"
    echo ""
    echo "⚠  Errors found. Fix them in each project and re-run."
    echo "   Each project's CLAUDE.md now has the error details."
    echo ""
    read -p "Continue with assembly anyway? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Fix errors and re-run."
        exit 1
    fi
else
    echo "━━━ Step 2/4: No errors to feed back ━━━"
fi

echo ""

# ---------------------------------------------------------------------------
# Step 3: Assemble
# ---------------------------------------------------------------------------
echo "━━━ Step 3/4: Assembling DevEco Studio project ━━━"
echo ""
bash "$SCRIPT_DIR/assemble-project.sh"
echo ""

# ---------------------------------------------------------------------------
# Step 4: Open in DevEco Studio
# ---------------------------------------------------------------------------
echo "━━━ Step 4/4: Opening in DevEco Studio ━━━"
echo ""
bash "$SCRIPT_DIR/open-deveco.sh"

echo ""
echo "╔═══════════════════════════════════════════╗"
echo "║   Integration pipeline complete!           ║"
echo "╚═══════════════════════════════════════════╝"
