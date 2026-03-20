Adapter Project Build System
============================

Directory Structure:
  /root/adapter/build/
  ├── config.sh                       # Shared config (paths, targets, patch mappings)
  ├── Android.bp                      # AOSP Java/APK build definition
  │
  ├── OH System Services Build:
  │   ├── oh_build.sh                 # OH build orchestration (patch→build→collect→revert)
  │   ├── apply_oh_patches.sh         # Apply OH patches (build + functional)
  │   ├── revert_oh_patches.sh        # Revert OH patches
  │   ├── collect_oh_artifacts.sh     # Collect .z.so to adapter/out/
  │   ├── dayu210_config.json         # OH product config (added rust crates etc.)
  │   ├── fix_and_build.py            # Auto-fix OH GN errors iteratively
  │   └── fix_oh_build.py             # OH component auto-fix
  │
  ├── OH Build Patches:
  │   └── oh_build_patches/           # GN/gni patches for dayu210 compilation
  │       ├── ets2abc_config.gni.patch
  │       ├── app_internal.gni.patch
  │       ├── libjpeg_turbo_BUILD.gn.patch
  │       ├── ui_lite_updater_BUILD.gn.patch
  │       └── musl_syscall_fix.sh
  │
  ├── AOSP Framework Build:
  │   ├── build_env.sh                # AOSP build environment (source this)
  │   ├── apply_patches.sh            # Apply AOSP patches
  │   ├── auto_build.sh               # AOSP iterative build with auto-sync
  │   ├── save_build_config.sh        # Export current build config
  │   ├── synced_repos.txt            # 115 synced AOSP repos
  │   ├── device/adapter/oh_adapter/  # Custom AOSP product definition
  │   │   ├── AndroidProducts.mk
  │   │   ├── oh_adapter.mk
  │   │   └── BoardConfig.mk
  │   └── aosp_build_patches/         # AOSP source patches (17 files)
  │       ├── frameworks_base.patch
  │       ├── art.patch
  │       ├── modules_*.patch
  │       ├── external_*.patch
  │       ├── build_make.patch
  │       └── disabled_bp_files.txt   # 1309 disabled test Android.bp files
  │
  ├── Cross-Compilation:
  │   ├── cross_compile_100pct.sh     # Cross-compile AOSP native (OH Clang → musl)
  │   └── cross_compile_layer2.sh     # Layer 2 base libraries
  │
  └── Deployment:
      └── deploy.sh                   # Deploy to DAYU600 via hdc


Build Outputs (/root/adapter/out/):
  ├── oh-services/                    # OH system services (.z.so)
  ├── java/                           # AOSP Java (framework.jar, dex)
  ├── res/                            # AOSP resources (framework-res)
  └── native/                         # Cross-compiled native (.so, musl-linked)


Quick Start:
  # OH system services
  cd /root/adapter
  ./build.sh --target=oh-services --oh-root=/root/oh

  # AOSP framework.jar
  ./build.sh --target=aosp-framework --aosp-root=/root/aosp

  # Cross-compile native
  ./build.sh --target=cross-compile --oh-root=/root/oh --aosp-root=/root/aosp

  # All targets
  ./build.sh --target=all --oh-root=/root/oh --aosp-root=/root/aosp

Fresh AOSP Setup:
  1. cd /root/aosp
     repo-google sync $(cat /root/adapter/build/synced_repos.txt | tr '\n' ' ') -c --no-tags -j8
  2. bash /root/adapter/build/apply_patches.sh --aosp-root=/root/aosp
  3. source /root/adapter/build/build_env.sh && build_framework
