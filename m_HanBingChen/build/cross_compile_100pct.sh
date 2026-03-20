#!/bin/bash
# Cross-compile ALL layers to 100% using OH Clang
# Usage: cross_compile_100pct.sh [--oh-root=PATH] [--aosp-root=PATH]
#
# Override paths via env vars or arguments:
#   OH_ROOT=/path/to/oh AOSP_ROOT=/path/to/aosp ./cross_compile_100pct.sh
set -o pipefail

# Parse args
for arg in "$@"; do case "$arg" in --oh-root=*) OH_ROOT="${arg#*=}";; --aosp-root=*) AOSP_ROOT="${arg#*=}";; esac; done

OH="${OH_ROOT:-/root/oh}"
A="${AOSP_ROOT:-/root/aosp}"
ADAPTER_ROOT="${ADAPTER_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
O="$ADAPTER_ROOT/out/native"

CXX=$OH/prebuilts/clang/ohos/linux-x86_64/llvm/bin/clang++
CC=$OH/prebuilts/clang/ohos/linux-x86_64/llvm/bin/clang

# Detect OH output dir (rk3588 or dayu210)
if [ -d "$OH/out/rk3588" ]; then OH_OUT="$OH/out/rk3588"
elif [ -d "$OH/out/dayu210" ]; then OH_OUT="$OH/out/dayu210"
else echo "ERROR: OH output dir not found"; exit 1; fi

SR=$OH_OUT/obj/third_party/musl/usr
ML=$SR/lib/aarch64-linux-ohos
BC=$ADAPTER_ROOT/framework/appspawn-x/bionic_compat/include

COMMON="--target=aarch64-linux-ohos --sysroot=$SR -I$SR/include/aarch64-linux-ohos -fPIC -O2 -D__OHOS__ -D_GNU_SOURCE -D_POSIX_SOURCE -Wno-unused-parameter -Wno-format -Wno-sign-compare -Wno-missing-field-initializers -include $BC/libcxx_compat.h -I$BC"
CXXF="$CXX $COMMON -std=c++17"
CF="$CC $COMMON -std=c11"
LNK="$CXX --target=aarch64-linux-ohos -B$ML -L$ML -L$O -shared -fPIC"

ART_DEFS="-DANDROID_HOST_MUSL -DART_STACK_OVERFLOW_GAP_arm=8192 -DART_STACK_OVERFLOW_GAP_arm64=8192 -DART_STACK_OVERFLOW_GAP_riscv64=8192 -DART_STACK_OVERFLOW_GAP_x86=8192 -DART_STACK_OVERFLOW_GAP_x86_64=8192 -DART_TARGET -DART_TARGET_LINUX -DART_BASE_ADDRESS=0x70000000 -DART_DEFAULT_GC_TYPE_IS_CMS -DIMT_SIZE=43"
ART_INC="-I$A/art -I$A/art/libdexfile -I$A/art/libartbase -I$A/art/runtime -I$A/art/libartpalette/include -I$A/art/libdexfile/external/include -I$A/art/libprofile -I$A/libnativehelper/include_jni -I$A/libnativehelper/include -I$A/system/logging/liblog/include -I$A/system/libbase/include -I$A/system/core/include -I$A/system/core/libcutils/include -I$A/system/core/libutils/include -I$A/external/fmtlib/include -I$A/external/lz4/lib -I$A/external/zlib -I$A/system/libziparchive/include -I$A/external/vixl/src -I$A/frameworks/native/include -I$A/external/tinyxml2"

mkdir -p $O
REPORT=""

bld() {
    local N=$1 I=$2; shift 2
    local D=/tmp/cc100/$N; mkdir -p $D
    local ok=0 fl=0 fails=""
    for s in "$@"; do
        local b=$(basename $s); b=${b%.*}; local ext=${s##*.}
        local comp=$CXXF; [ "$ext" = "c" ] && comp=$CF
        if $comp $I -c -o $D/$b.o $s 2>/dev/null; then
            ok=$((ok+1))
        else
            fl=$((fl+1))
            fails="$fails $b"
        fi
    done
    local total=$((ok+fl))
    local OB=$(ls $D/*.o 2>/dev/null | tr "\n" " ")
    $LNK -o $O/lib$N.so $OB -lc -lbionic_compat 2>/dev/null || \
    $LNK -o $O/lib$N.so $OB -lc -lbionic_compat -Wl,--unresolved-symbols=ignore-in-shared-libs 2>/dev/null
    local sz=$(ls -lh $O/lib$N.so 2>/dev/null | awk '{print $5}')
    if [ $fl -eq 0 ]; then
        echo "  ✅ lib$N: $ok/$total ($sz)"
        REPORT="$REPORT\n  ✅ lib$N: $ok/$total ($sz)"
    else
        echo "  ⚠️  lib$N: $ok/$total ($sz) [FAIL:$fails]"
        REPORT="$REPORT\n  ⚠️  lib$N: $ok/$total ($sz) [FAIL:$fails]"
    fi
}

rm -rf /tmp/cc100 && mkdir -p /tmp/cc100
echo "=========================================="
echo "  Full Cross-Compilation (target: 100%)"
echo "=========================================="

# === Layer 1 ===
echo ""
echo "--- Layer 1: bionic_compat ---"
bld bionic_compat "-I$OH/base/startup/init/interfaces/innerkits/include/syspara -DPARAM_VALUE_LEN_MAX=96 -nostdinc++ -Wno-constant-conversion" \
    $BC/../src/system_properties.cpp $BC/../src/malloc_compat.cpp $BC/../src/fdsan_stubs.cpp $BC/../src/misc_compat.cpp

# === Layer 2 ===
echo ""
echo "--- Layer 2: AOSP base libs ---"
bld log "-I$A/system/logging/liblog/include -I$A/system/libbase/include -I$A/system/core/libcutils/include -I$A/system/core/include -DLIBLOG_LOG_TAG=1006 -DSNET_EVENT_LOG_TAG=1397638484" \
    $A/system/logging/liblog/log_event_list.cpp $A/system/logging/liblog/log_event_write.cpp $A/system/logging/liblog/logger_name.cpp $A/system/logging/liblog/logger_read.cpp $A/system/logging/liblog/logger_write.cpp $A/system/logging/liblog/logprint.cpp $A/system/logging/liblog/properties.cpp $A/system/logging/liblog/event_tag_map.cpp $A/system/logging/liblog/log_time.cpp

bld base "-I$A/system/libbase/include -I$A/system/logging/liblog/include -I$A/system/core/include -I$A/system/core/libcutils/include -I$A/external/fmtlib/include -DANDROID_BASE_UNIQUE_FD_DISABLE_FDSAN" \
    $A/system/libbase/abi_compatibility.cpp $A/system/libbase/chrono_utils.cpp $A/system/libbase/cmsg.cpp $A/system/libbase/errors_unix.cpp $A/system/libbase/file.cpp $A/system/libbase/hex.cpp $A/system/libbase/logging.cpp $A/system/libbase/mapped_file.cpp $A/system/libbase/parsebool.cpp $A/system/libbase/parsenetaddress.cpp $A/system/libbase/posix_strerror_r.cpp $A/system/libbase/process.cpp $A/system/libbase/properties.cpp $A/system/libbase/stringprintf.cpp $A/system/libbase/strings.cpp $A/system/libbase/threads.cpp

bld cutils "-I$A/system/core/libcutils/include -I$A/system/logging/liblog/include -I$A/system/libbase/include -I$A/system/core/include -I$A/external/fmtlib/include" \
    $A/system/core/libcutils/config_utils.cpp $A/system/core/libcutils/hashmap.cpp $A/system/core/libcutils/iosched_policy.cpp $A/system/core/libcutils/load_file.cpp $A/system/core/libcutils/native_handle.cpp $A/system/core/libcutils/properties.cpp $A/system/core/libcutils/record_stream.cpp $A/system/core/libcutils/socket_inaddr_any_server_unix.cpp $A/system/core/libcutils/socket_local_client_unix.cpp $A/system/core/libcutils/socket_local_server_unix.cpp $A/system/core/libcutils/socket_network_client_unix.cpp $A/system/core/libcutils/sockets_unix.cpp $A/system/core/libcutils/sockets.cpp $A/system/core/libcutils/str_parms.cpp $A/system/core/libcutils/threads.cpp

bld utils "-I$A/system/core/libutils/include -I$A/system/core/libcutils/include -I$A/system/logging/liblog/include -I$A/system/libbase/include -I$A/system/core/include -I$A/system/core/libprocessgroup/include -I$A/system/core/libvndksupport/include -I$A/external/fmtlib/include" \
    $A/system/core/libutils/Errors.cpp $A/system/core/libutils/FileMap.cpp $A/system/core/libutils/JenkinsHash.cpp $A/system/core/libutils/LightRefBase.cpp $A/system/core/libutils/Looper.cpp $A/system/core/libutils/NativeHandle.cpp $A/system/core/libutils/Printer.cpp $A/system/core/libutils/RefBase.cpp $A/system/core/libutils/SharedBuffer.cpp $A/system/core/libutils/StopWatch.cpp $A/system/core/libutils/String8.cpp $A/system/core/libutils/String16.cpp $A/system/core/libutils/StrongPointer.cpp $A/system/core/libutils/SystemClock.cpp $A/system/core/libutils/Threads.cpp $A/system/core/libutils/Timers.cpp $A/system/core/libutils/Tokenizer.cpp $A/system/core/libutils/Unicode.cpp $A/system/core/libutils/VectorImpl.cpp

bld nativehelper "-I$A/libnativehelper/include -I$A/libnativehelper/include_jni -I$A/libnativehelper/header_only_include -I$A/system/logging/liblog/include -I$A/system/libbase/include -I$A/system/core/include" \
    $A/libnativehelper/JNIHelp.c $A/libnativehelper/JniInvocation.c $A/libnativehelper/JniConstants.c $A/libnativehelper/JNIPlatformHelp.c

# === Layer 3: ART ===
echo ""
echo "--- Layer 3: ART sub-libraries ---"
bld sigchain "$ART_DEFS $ART_INC -fno-rtti" $A/art/sigchainlib/sigchain.cc

bld dexfile "$ART_DEFS $ART_INC -fno-rtti" $(ls $A/art/libdexfile/dex/*.cc | grep -v test)

bld artbase "$ART_DEFS $ART_INC -fno-rtti" $(ls $A/art/libartbase/base/*.cc | grep -v test | grep -v windows | grep -v fuchsia)

bld artpalette "$ART_DEFS $ART_INC -fno-rtti" $A/art/libartpalette/apex/palette.cc

# === Layer 3: ART Runtime ===
echo ""
echo "--- Layer 3: ART Runtime (largest) ---"
# Compile all non-test, non-android-specific runtime files
RUNTIME_FILES=$(find $A/art/runtime -name "*.cc" -not -name "*test*" -not -path "*/test/*" -not -name "*gtest*" \
    -not -name "*_android.cc" \
    -not -path "*/arch/arm/*" -not -path "*/arch/x86/*" -not -path "*/arch/x86_64/*" -not -path "*/arch/riscv64/*" \
    | sort)
bld art "$ART_DEFS $ART_INC -fno-rtti" $RUNTIME_FILES /tmp/cc100/asm_stubs.S

echo ""
echo "=========================================="
echo "  FINAL REPORT"
echo "=========================================="
echo -e "$REPORT"
echo ""
echo "Output:"
ls -lh $O/lib*.so | awk '{print $5, $NF}'
echo ""
du -sh $O/
