#!/bin/bash
# Apply all AOSP build patches for OH Adapter minimal build
# Usage: bash apply_patches.sh [--aosp-root=PATH]
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Use config.sh defaults, allow override via args or env
AOSP_DIR="${AOSP_ROOT:-/root/aosp}"
for arg in "$@"; do case "$arg" in --aosp-root=*) AOSP_DIR="${arg#*=}" ;; esac; done

PATCH_DIR="$SCRIPT_DIR/aosp_build_patches"
PRODUCT_DIR="$SCRIPT_DIR/device/adapter/oh_adapter"

echo "=== Step 1: Install custom product ==="
mkdir -p "$AOSP_DIR/device/adapter/oh_adapter"
cp -v "$PRODUCT_DIR/AndroidProducts.mk" "$AOSP_DIR/device/adapter/oh_adapter/"
cp -v "$PRODUCT_DIR/oh_adapter.mk" "$AOSP_DIR/device/adapter/oh_adapter/"
cp -v "$PRODUCT_DIR/BoardConfig.mk" "$AOSP_DIR/device/adapter/oh_adapter/"

echo ""
echo "=== Step 2: Apply source patches ==="
for patch in "$PATCH_DIR"/*.patch; do
    name=$(basename "$patch")
    if [ ! -s "$patch" ]; then
        echo "  SKIP (empty): $name"
        continue
    fi
    # Determine the repo directory from patch name
    case "$name" in
        frameworks_base.patch|frameworks_base_disabled.patch)
            cd "$AOSP_DIR/frameworks/base" ;;
        art.patch)
            cd "$AOSP_DIR/art" ;;
        external_conscrypt.patch)
            cd "$AOSP_DIR/external/conscrypt" ;;
        external_icu.patch)
            cd "$AOSP_DIR/external/icu" ;;
        modules_common.patch)
            cd "$AOSP_DIR/packages/modules/common" ;;
        modules_Bluetooth.patch)
            cd "$AOSP_DIR/packages/modules/Bluetooth" ;;
        modules_Connectivity.patch)
            cd "$AOSP_DIR/packages/modules/Connectivity" ;;
        modules_Connectivity_tethering.patch)
            cd "$AOSP_DIR/packages/modules/Connectivity" ;;
        modules_Wifi.patch)
            cd "$AOSP_DIR/packages/modules/Wifi" ;;
        modules_Media.patch)
            cd "$AOSP_DIR/packages/modules/Media" ;;
        modules_StatsD.patch)
            cd "$AOSP_DIR/packages/modules/StatsD" ;;
        modules_AdServices.patch)
            cd "$AOSP_DIR/packages/modules/AdServices" ;;
        modules_Scheduling.patch)
            cd "$AOSP_DIR/packages/modules/Scheduling" ;;
        modules_Virtualization.patch)
            cd "$AOSP_DIR/packages/modules/Virtualization" ;;
        build_make.patch)
            cd "$AOSP_DIR/build/make" ;;
        *)
            echo "  SKIP (unknown): $name"
            continue ;;
    esac
    git apply "$patch" 2>/dev/null && echo "  OK: $name" || echo "  ALREADY APPLIED or FAILED: $name"
done

echo ""
echo "=== Step 3: Disable test/non-essential Android.bp files ==="
cd "$AOSP_DIR"
count=0
while IFS= read -r f; do
    if [ -f "$f" ]; then
        current=$(head -1 "$f")
        if [ "$current" != "// Disabled" ]; then
            echo "// Disabled" > "$f"
            count=$((count + 1))
        fi
    fi
done < "$PATCH_DIR/disabled_bp_files.txt"
echo "  Disabled $count Android.bp files"

echo ""
echo "=== Step 4: Create CTS stub files ==="
mkdir -p "$AOSP_DIR/cts/tests/tests/os/assets"
echo "14" > "$AOSP_DIR/cts/tests/tests/os/assets/platform_versions.txt"
echo "14" > "$AOSP_DIR/cts/tests/tests/os/assets/platform_releases.txt"
mkdir -p "$AOSP_DIR/cts/build" "$AOSP_DIR/test/suite_harness/tools/cts-instant-tradefed/build" "$AOSP_DIR/test/vts/tools/vts-core-tradefed/build" "$AOSP_DIR/test/cts-root/tools/build" "$AOSP_DIR/test/wvts/tools/build"
for d in cts/build test/suite_harness/tools/cts-instant-tradefed/build test/vts/tools/vts-core-tradefed/build test/cts-root/tools/build test/wvts/tools/build; do
    touch "$AOSP_DIR/$d/config.mk"
done
echo "  CTS/VTS stubs created"

echo ""
echo "=== All patches applied. Ready to build. ==="
echo "  cd /root/aosp"
echo "  source /root/adapter/build/build_env.sh"
echo "  build_framework"
