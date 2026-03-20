#!/bin/bash
# config.sh - Shared build configuration for Android-OH Adapter project
#
# Source this file from other build scripts:
#   source "$(dirname "$0")/config.sh"

# ============================================================
# Paths (can be overridden by environment or command-line args)
# ============================================================

# Adapter project root (auto-detected from this script's location)
ADAPTER_ROOT="${ADAPTER_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Source roots (default: cloud server layout)
OH_ROOT="${OH_ROOT:-/root/oh}"
AOSP_ROOT="${AOSP_ROOT:-/root/aosp}"

# OH product configuration
OH_PRODUCT_NAME="dayu210"

# OH output directory (may be rk3588 or dayu210 depending on device config)
detect_oh_output_dir() {
    # dayu210 product maps to rk3588 output dir in current OH config
    for dir in "$OH_ROOT/out/rk3588" "$OH_ROOT/out/$OH_PRODUCT_NAME"; do
        if [ -d "$dir" ]; then
            echo "$dir"
            return
        fi
    done
    # Default: use product name, will be created by build
    echo "$OH_ROOT/out/rk3588"
}

# Adapter output directory
ADAPTER_OUT="$ADAPTER_ROOT/out"

# ============================================================
# OH build targets
# ============================================================

# System service ninja targets
OH_SERVICE_TARGETS=(abilityms libappms libwms libbms)

# GN args
OH_GN_ARGS="allow_sanitize_debug=true"

# Artifact paths (relative to OH output dir)
declare -A OH_ARTIFACTS
OH_ARTIFACTS[libabilityms.z.so]="ability/ability_runtime/libabilityms.z.so"
OH_ARTIFACTS[libappms.z.so]="ability/ability_runtime/libappms.z.so"
OH_ARTIFACTS[libwms.z.so]="window/window_manager/libwms.z.so"
OH_ARTIFACTS[libbms.z.so]="bundlemanager/bundle_framework/libbms.z.so"

# Unstripped artifact paths
declare -A OH_ARTIFACTS_UNSTRIPPED
OH_ARTIFACTS_UNSTRIPPED[libabilityms.z.so]="lib.unstripped/ability/ability_runtime/libabilityms.z.so"
OH_ARTIFACTS_UNSTRIPPED[libappms.z.so]="lib.unstripped/ability/ability_runtime/libappms.z.so"
OH_ARTIFACTS_UNSTRIPPED[libwms.z.so]="lib.unstripped/window/window_manager/libwms.z.so"
OH_ARTIFACTS_UNSTRIPPED[libbms.z.so]="lib.unstripped/bundlemanager/bundle_framework/libbms.z.so"

# ============================================================
# Patch file mappings
# ============================================================

# Build system patches: patch_file -> target_path (relative to OH_ROOT)
declare -A OH_BUILD_PATCHES
OH_BUILD_PATCHES["ets2abc_config.gni.patch"]="build/config/components/ets_frontend/ets2abc_config.gni"
OH_BUILD_PATCHES["app_internal.gni.patch"]="build/ohos/app/app_internal.gni"
OH_BUILD_PATCHES["libjpeg_turbo_BUILD.gn.patch"]="third_party/libjpeg-turbo/BUILD.gn"
OH_BUILD_PATCHES["ui_lite_updater_BUILD.gn.patch"]="foundation/arkui/ui_lite/ext/updater/BUILD.gn"

# Product config (full file replacement)
OH_CONFIG_FILE="dayu210_config.json"
OH_CONFIG_TARGET="vendor/hihope/dayu210/config.json"

# Functional patches directory mappings
declare -A OH_FUNC_PATCH_DIRS
OH_FUNC_PATCH_DIRS["ability_rt"]="foundation/ability/ability_runtime"
OH_FUNC_PATCH_DIRS["bundle_framework"]="foundation/bundlemanager/bundle_framework"

# Full file replacements (source in ohos_patches/ -> target relative to OH component root)
OH_FULL_FILE_REPLACEMENTS=(
    "ability_rt/services/abilitymgr/include/mission/mission.h"
    "ability_rt/services/abilitymgr/src/mission/mission.cpp"
    "bundle_framework/services/bundlemgr/src/installd/installd_host_impl_android.cpp"
)

# Diff patches (applied with patch -p1)
OH_DIFF_PATCHES=(
    "ability_rt/interfaces/inner_api/ability_manager/include/ability_manager_interface.h.patch"
    "ability_rt/services/appmgr/include/remote_client_manager.h.patch"
    "ability_rt/services/appmgr/src/app_mgr_service_inner.cpp.patch"
    "bundle_framework/interfaces/inner_api/appexecfwk_base/include/bundle_constants.h.patch"
    "bundle_framework/services/bundlemgr/include/installd/installd_interface.h.patch"
    "bundle_framework/services/bundlemgr/src/bundle_installer.cpp.patch"
)

# Patch applied marker file
PATCH_MARKER="$OH_ROOT/.adapter_patches_applied"

# ============================================================
# Logging utilities
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $*"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ============================================================
# Prerequisite checks
# ============================================================

check_oh_source() {
    if [ ! -d "$OH_ROOT/build" ] || [ ! -f "$OH_ROOT/build.sh" ]; then
        log_error "OH source not found at $OH_ROOT"
        log_error "Set OH_ROOT or pass --oh-root=PATH"
        return 1
    fi
    log_ok "OH source found at $OH_ROOT"
}

check_disk_space() {
    local avail_gb
    avail_gb=$(df -BG "$OH_ROOT" | awk 'NR==2{print $4}' | tr -d 'G')
    if [ "$avail_gb" -lt 50 ]; then
        log_warn "Low disk space: ${avail_gb}GB available (recommend >50GB)"
    else
        log_ok "Disk space: ${avail_gb}GB available"
    fi
}

check_prerequisites() {
    check_oh_source || return 1
    check_disk_space

    if ! command -v ccache &>/dev/null; then
        log_warn "ccache not found - build will be slower"
    fi

    # Check OH Python has pyyaml
    local oh_python="$OH_ROOT/prebuilts/python/linux-x86/3.11.4/bin/python3"
    if [ -x "$oh_python" ]; then
        if ! "$oh_python" -c "import yaml" 2>/dev/null; then
            log_warn "pyyaml not installed in OH Python - installing..."
            "$oh_python" -m pip install pyyaml -q
        fi
    fi

    # Check autotools (needed by libnl)
    if ! command -v autoreconf &>/dev/null; then
        log_warn "autotools not found - installing..."
        apt-get install -y autoconf automake libtool -q 2>/dev/null || true
    fi

    # Create prebuilt SDK dir to skip SDK build
    mkdir -p "$OH_ROOT/prebuilts/ohos-sdk/linux/23"
}
