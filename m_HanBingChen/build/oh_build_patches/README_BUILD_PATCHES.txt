OH Build System Patches
=======================

These patches fix GN dependency resolution issues in OpenHarmony 6.1-Release
that prevent compilation of system service targets (abilityms, libappms, libwms, libbms)
using the dayu210 product configuration.

Patches are applied by build/apply_oh_patches.sh before compilation
and reverted by build/revert_oh_patches.sh after compilation.

Patch List:
-----------

1. ets2abc_config.gni.patch
   Target: build/config/components/ets_frontend/ets2abc_config.gni
   Issue: generate_static_abc template hardcodes dependency on sdk:ohos_ets_api
          and ace_ets2bundle:ohos_ets_ui_plugins, which are not needed for
          system service compilation.
   Fix: Set sdk/ace_ets2bundle dependency variables to empty strings,
        comment out external_deps references.

2. app_internal.gni.patch
   Target: build/ohos/app/app_internal.gni
   Issue: HAP compilation template references ace_ets2bundle and ace_js2bundle
          for ETS/JS loader paths. Not needed for system service compilation.
   Fix: Comment out ace_ets2bundle/ace_js2bundle deps, use static paths.

3. libjpeg_turbo_BUILD.gn.patch
   Target: third_party/libjpeg-turbo/BUILD.gn
   Issue: dayu210 camera module (camera_pipeline_core) depends on
          turbojpeg_static but is not in its GN visibility list.
   Fix: Add camera_pipeline_core to visibility list.

4. ui_lite_updater_BUILD.gn.patch
   Target: foundation/arkui/ui_lite/ext/updater/BUILD.gn
   Issue: ui_lite updater extension depends on graphic_utils_lite,
          a lite-system-only component not available in standard system.
   Fix: Comment out the dependency.

5. musl_syscall_fix.sh
   Type: Post-GN-gen script (not a patch file)
   Target: out/<product>/obj/third_party/musl/intermidiates/linux/
           musl_src_ported/include/bits/syscall.h (generated file)
   Issue: Generated syscall.h only has __NR_* defines but missing SYS_*
          aliases. musl's internal headers use SYS_futex etc. which fall
          through to undefined SYS_futex_time64 on aarch64.
   Fix: Append SYS_* aliases derived from __NR_* defines.

6. dayu210_config.json
   Type: Modified product configuration (not a diff patch)
   Target: vendor/hihope/dayu210/config.json
   Issue: Original config missing thirdparty components (rust crates,
          libusb, pcre2) that are indirectly required by system services.
   Fix: Full replacement with pre-configured version.

OH Version: OpenHarmony 6.1-Release
Date: 2026-03-20
