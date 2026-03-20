# Android-OpenHarmony Adapter Project

## Project Overview

This project bridges Android Framework system service IPC calls to OpenHarmony (OH) system services, enabling Android Apps to run on an OH-based system. The adaptation layer intercepts Android Binder IPC calls via class inheritance (extends IXxx.Stub) and routes them to equivalent OH IPC interfaces through JNI.

## Target Hardware

- **Dev board**: HH-SCDAYU600 (DAYU600)
- **SoC**: Unisoc UIS7885 (ums9620), NOT RK3588
- DAYU600 is a Unisoc/Spreadtrum platform; do not use RK3588/Rockchip tools or build targets

## Source Code Locations

- **Adapter project**: `D:\code\adapter\`
- **Android source (AOSP 14)**: `D:\code\android\frameworks\`
- **OpenHarmony source**: `D:\code\ohos\`
- **Design documents**: `D:\code\adapter\doc\`

## Project Structure

Files are organized by feature under `framework/`, each feature having its own `java/` and `jni/` subdirectories.
OH/AOSP patches mirror the target system's source tree structure.

```
D:\code\adapter\
├── framework/                                # Adapter code, organized by feature
│   ├── core/                                 # Shared infrastructure
│   │   ├── java/
│   │   │   ├── OHEnvironment.java            # Static utility: isOHEnvironment() + loadLibrary + native init/shutdown
│   │   │   └── ServiceInterceptor.java       # Runtime reflection fallback for unmodified AOSP
│   │   └── jni/
│   │       ├── adapter_bridge.h/cpp          # JNI bridge, native method registration
│   │       └── oh_callback_handler.h/cpp     # OH -> Android reverse callback dispatch
│   │
│   ├── activity/                             # IActivityManager + IActivityTaskManager adaptation
│   │   ├── java/
│   │   │   ├── ActivityManagerAdapter.java   # extends IActivityManager.Stub, 249 methods
│   │   │   ├── ActivityTaskManagerAdapter.java # extends IActivityTaskManager.Stub, 95 methods
│   │   │   ├── IActivityManagerBridge.java   # Bridge interface for AMS
│   │   │   ├── IActivityTaskManagerBridge.java # Bridge interface for ATMS
│   │   │   ├── ServiceConnectionRegistry.java # Service connection tracking (IServiceConnection ↔ OH)
│   │   │   ├── AppSchedulerBridge.java       # OH IAppScheduler -> IApplicationThread
│   │   │   ├── AbilitySchedulerBridge.java   # OH IAbilityScheduler -> IApplicationThread
│   │   │   ├── AbilityConnectionBridge.java  # OH IAbilityConnection -> IServiceConnection
│   │   │   ├── IntentWantConverter.java      # Android Intent <-> OH Want conversion
│   │   │   └── LifecycleAdapter.java         # Android Activity <-> OH Ability lifecycle mapping
│   │   └── jni/
│   │       ├── oh_ability_manager_client.h/cpp # OH AbilityManager IPC client
│   │       ├── oh_app_mgr_client.h/cpp       # OH AppMgr IPC client
│   │       ├── app_scheduler_adapter.h/cpp   # OH IAppScheduler → IApplicationThread
│   │       ├── ability_scheduler_adapter.h/cpp # OH IAbilityScheduler → IApplicationThread
│   │       ├── ability_connection_adapter.h/cpp # OH IAbilityConnection → ServiceConnectionRegistry
│   │       ├── intent_want_converter.h/cpp   # Android Intent ↔ OH Want conversion (C++)
│   │       └── lifecycle_state_mapper.h/cpp  # Android 6-state ↔ OH 4-state mapping
│   │
│   ├── window/                               # IWindowManager + IWindowSession adaptation
│   │   ├── java/
│   │   │   ├── WindowManagerAdapter.java     # extends IWindowManager.Stub, 144 methods
│   │   │   ├── WindowSessionAdapter.java     # extends IWindowSession.Stub, 42 methods
│   │   │   ├── IWindowManagerBridge.java     # Bridge interface for WMS
│   │   │   ├── IWindowSessionBridge.java     # Bridge interface for WindowSession
│   │   │   ├── WindowCallbackBridge.java     # OH IWindow -> Android IWindow
│   │   │   ├── SessionStageBridge.java       # OH ISessionStage -> Android IWindow
│   │   │   ├── WindowManagerAgentBridge.java # OH IWindowManagerAgent -> internal
│   │   │   └── InputEventBridge.java         # OH MMI → Android InputEvent bridge
│   │   └── jni/
│   │       ├── oh_window_manager_client.h/cpp # OH WindowManager/SceneSession IPC client
│   │       ├── oh_input_bridge.h/cpp         # OH MMI → Android InputChannel bridge
│   │       ├── window_callback_adapter.h/cpp # OH IWindow → Android IWindow
│   │       ├── session_stage_adapter.h/cpp   # OH ISessionStage → Android IWindow
│   │       └── window_manager_agent_adapter.h/cpp # OH IWindowManagerAgent → internal
│   │
│   ├── surface/                              # Graphics / Surface bridging (JNI only)
│   │   └── jni/
│   │       ├── oh_surface_bridge.h/cpp       # OH RSSurfaceNode + RSUIDirector management
│   │       ├── oh_graphic_buffer_producer.h/cpp # Android IGraphicBufferProducer → OH Surface
│   │       └── pixel_format_mapper.h         # Android ↔ OH pixel format/usage conversion
│   │
│   ├── broadcast/                            # Broadcast / CommonEvent adaptation
│   │   ├── java/
│   │   │   ├── BroadcastEventConverter.java  # Android broadcast Action ↔ OH CommonEvent mapping
│   │   │   └── CommonEventReceiverBridge.java # OH CommonEvent -> Android IIntentReceiver
│   │   └── jni/
│   │       ├── oh_common_event_client.h/cpp  # OH CommonEventService IPC client
│   │       └── common_event_subscriber_adapter.h/cpp # OH CommonEventSubscriber → JNI callback
│   │
│   ├── contentprovider/                      # ContentProvider / DataShare adaptation
│   │   ├── java/
│   │   │   ├── ContentProviderBridge.java    # IContentProvider → OH DataShareHelper (Stage)
│   │   │   ├── ContentProviderRegistry.java  # CP registry (local Android + OH DataShare bridges)
│   │   │   └── ContentProviderUriConverter.java # content:// ↔ datashare:// URI mapping
│   │   └── jni/
│   │       └── oh_datashare_client.h/cpp     # OH DataShareHelper client (Stage model)
│   │
│   ├── package-manager/                      # PackageManager / BMS adaptation + APK installation
│   │   ├── java/
│   │   │   ├── PackageManagerAdapter.java    # extends IPackageManager.Stub, routes to OH BMS
│   │   │   ├── PackageInfoBuilder.java       # OH BundleInfo JSON → Android PackageInfo
│   │   │   └── PermissionMapper.java         # Android ↔ OH permission name mapping (Java)
│   │   ├── jni/
│   │   │   ├── oh_bundle_mgr_client.h/cpp    # OH BundleManagerService IPC client
│   │   │   ├── apk_manifest_parser.h/cpp     # AXML binary format parser (AndroidManifest.xml)
│   │   │   ├── apk_bundle_parser.h/cpp       # ManifestData → OH InnerBundleInfo mapping
│   │   │   ├── apk_installer.h/cpp           # File deployment: APK copy, lib extraction, dex2oat
│   │   │   ├── permission_mapper.h/cpp       # Android ↔ OH permission mapping (C++)
│   │   │   └── apk_signature_verifier.h/cpp  # APK V1/V2 signature verification
│   │   └── BUILD.gn                          # OH build config for apk_installer library
│   │
│   ├── appspawn-x/                           # Hybrid spawner (OH appspawn + Android Zygote)
│   │   ├── src/
│   │   │   ├── main.cpp                      # Entry point: 4-phase startup
│   │   │   ├── spawn_msg.h                   # SpawnMsg struct, StartFlags, logging macros
│   │   │   ├── appspawnx_runtime.h/cpp       # ART VM creation, JNI registration, preload
│   │   │   ├── spawn_server.h/cpp            # Unix socket server, poll event loop
│   │   │   └── child_main.h/cpp              # Post-fork: OH security + Android init
│   │   ├── config/
│   │   │   ├── appspawn_x.cfg                # OH init service config (JSON)
│   │   │   └── appspawn_x_sandbox.json       # Android app sandbox mount rules
│   │   ├── java/com/android/internal/os/
│   │   │   └── AppSpawnXInit.java            # Java preload + child init entry
│   │   └── BUILD.gn                          # OH GN build config
│   │
│   └── CMakeLists.txt                        # Unified CMake build (aggregates all features)
│
├── aosp_patches/                             # AOSP source modifications (mirrors Android source tree)
│   ├── README_AOSP_PATCHES.txt
│   └── frameworks/core/java/android/
│       ├── app/ActivityManager.java.patch
│       ├── app/ActivityTaskManager.java.patch
│       ├── app/ActivityThread.java.patch
│       └── view/WindowManagerGlobal.java.patch
│
├── ohos_patches/                             # OH source modifications (mirrors OH source tree)
│   ├── README_OHOS_PATCHES.txt
│   ├── README_BUNDLE_MGR_PATCHES.txt
│   ├── ability_rt/
│   │   ├── interfaces/inner_api/ability_manager/include/ability_manager_interface.h.patch
│   │   ├── services/abilitymgr/include/mission/mission.h
│   │   ├── services/abilitymgr/src/mission/mission.cpp
│   │   ├── services/abilitymgr/src/mission/mission_list_manager_patch.cpp
│   │   ├── services/appmgr/include/remote_client_manager.h.patch
│   │   └── services/appmgr/src/app_mgr_service_inner.cpp.patch
│   └── bundle_framework/
│       ├── interfaces/inner_api/appexecfwk_base/include/bundle_constants.h.patch
│       └── services/bundlemgr/
│           ├── include/installd/installd_interface.h.patch
│           └── src/
│               ├── bundle_installer.cpp.patch
│               └── installd/installd_host_impl_android.cpp
│
├── app/                                      # Hello World test app
│   ├── java/com/example/helloworld/
│   │   ├── HelloWorldApplication.java
│   │   ├── MainActivity.java
│   │   └── SecondActivity.java
│   ├── AndroidManifest.xml
│   └── res/layout/activity_main.xml
├── doc/                                      # Design documents (HTML, Chinese)
└── build/
    └── Android.bp                            # AOSP build config
```

## Design Documents

- `doc/overall_design.html` — **Overall design document (总体设计方案, Chinese)** — comprehensive summary of all subsystem designs
- `doc/overall_design_en.html` — **Overall design document (English)** — English translation, kept in sync with Chinese version
- `doc/aosp_minimal_build_analysis.html` — AOSP 14 minimal build analysis for app-only runtime (module selection, build strategy)
- `doc/aosp_minimal_build_analysis_en.html` — **AOSP 14 minimal build analysis (English)** — English translation, kept in sync with Chinese version
- `doc/oh_system_service_build_analysis.html` — OH system service build analysis for adapter project (OH module compilation, patch integration, build strategy)
- `doc/android_oh_adaptation_report.html` — Feasibility analysis report
- `doc/phase1_design.html` — Phase 1 (Hello World + framework) design doc
- `doc/phase1_hello_world_implementation_design.html` — Phase 1 Hello World implementation design
- `doc/interface_bridge_design.html` — Interface bridging detailed design doc (forward direction)
- `doc/reverse_callback_bridge_design.html` — Reverse callback bridging design doc (backward direction, Chinese)
- `doc/surface_bridging_design.html` — Surface bridging design (Android Surface → OH RenderService, v2.0 source-verified)
- `doc/mission_group_design.html` — Mission Group design (Android Task → OH Mission grouping for recent tasks)
- `doc/broadcast_common_event_design.html` — Broadcast/CommonEvent design (Android BroadcastReceiver → OH CommonEventManager)
- `doc/content_provider_datashare_design.html` — ContentProvider → DataShareExtensionAbility design (Stage model)
- `doc/service_extension_design.html` — Service → ServiceExtensionAbility design (Stage model, 3 scenarios)
- `doc/appspawn_x_design.html` — Android Zygote / OH appspawn analysis & appspawn-x hybrid spawner design (incl. detailed implementation + build setup)
- `doc/apk_installation_design.html` — APK installation on OH design (APK parsing, BMS integration, PackageManager adapter, dex2oat)
- `doc/env_setup/oh_dev_environment_setup_guide.html` — OH system development environment setup guide
- `doc/env_setup/android_dev_environment_setup_guide.html` — Android (AOSP 16) development environment setup guide
- `doc/android_oh_interface_feasibility_report.html` — Interface feasibility report
- `doc/android_oh_interface_feasibility_report_v2.html` — Interface feasibility report v2

## Architecture

### Interface Mapping (Many-to-Many)

| Android Interface (530 methods total) | OH Target Interfaces |
|---|---|
| IActivityManager (249) | IAbilityManager, IAppMgr, IMissionManager |
| IActivityTaskManager (95) | IAbilityManager, IMissionManager, ISceneSessionManager |
| IWindowManager (144) | IWindowManager(OH), ISceneSessionManager, DisplayManager |
| IWindowSession (42) | ISession, ISessionStage, ISceneSessionManager |

### Reverse Callback Mapping (System -> App, 210 OH methods -> 78 Android methods)

| OH Callback Interface | Methods | Android Target |
|---|---|---|
| IAppScheduler (34) | IApplicationThread (process lifecycle, memory) |
| IAbilityScheduler (35) | IApplicationThread (activity/service) + ContentProvider |
| IAbilityConnection (2) | IServiceConnection (1:1 mapping) |
| IWindow-OH (26) | IWindow-Android (window state) |
| ISessionStage (94) | IWindow-Android + IApplicationThread |
| IWindowManagerAgent (19) | Internal handling (no Android equivalent) |

### Forward Bridge Pattern (Class Inheritance)

All 4 forward bridges use class inheritance (`extends IXxx.Stub`) instead of dynamic proxy. Each adapter:
- Extends the AIDL-generated `Stub` class (e.g., `IActivityManager.Stub`)
- Declares its own `native` methods for OH service access (no shared AdaptationLayer)
- Holds a native OH service handle (`long mOhAbilityManager`) obtained via its own JNI call
- Overrides every AIDL method with proper typed signatures (compile-time checked)
- Methods are tagged: **[BRIDGED]**, **[PARTIAL]**, **[STUB]**

### Installation (AOSP Source Modification)

AOSP source modified to check `OHEnvironment.isOHEnvironment()` and return adapters directly:
- `ActivityManager.java`: `IActivityManagerSingleton.create()` → `new ActivityManagerAdapter()`
- `ActivityTaskManager.java`: `IActivityTaskManagerSingleton.create()` → `new ActivityTaskManagerAdapter()`
- `ActivityThread.java`: `getPackageManager()` → `new PackageManagerAdapter()`
- `WindowManagerGlobal.java`: `getWindowManagerService()` → `new WindowManagerAdapter()`
- `WindowManagerGlobal.java`: `getWindowSession()` → `new WindowSessionAdapter()`

All modifications include fallback to original implementation if adapter initialization fails.

`ServiceInterceptor.java` exists as a runtime reflection fallback for unmodified AOSP builds.

### Key Classes

- **`OHEnvironment`** — Static utility: `isOHEnvironment()`, `initialize()`, `shutdown()`, `loadLibrary`. No singleton needed.
- **`LifecycleAdapter`** — Singleton. Maps Android 6 lifecycle states <-> OH 4 lifecycle states. Calls `OHEnvironment.nativeNotifyAppState()`.
- **`IntentWantConverter`** — Stateless converter. Android Intent <-> OH Want field mapping.

## Key Technical Details

- **Intent -> Want conversion**: Action mapping table in `IntentWantConverter.java`, component name splits to bundleName + abilityName, extras serialized to JSON
- **Lifecycle mapping**: Android 6 states (Created/Started/Resumed/Paused/Stopped/Destroyed) <-> OH 4 states (Initial/Inactive/Foreground/Background)
- **JNI bridge**: `liboh_adapter_bridge.so`, loaded via `OHEnvironment` static initializer
- **Native methods**: Each Adapter declares its own `native` methods (e.g., `ActivityManagerAdapter.nativeStartAbility`). C++ side uses helper functions to avoid duplication.
- **OH environment detection**: System property `persist.oh.adapter.enabled` + native fallback `nativeIsOHEnvironment()`
- **Phase 1 mode**: Most BRIDGED methods currently passthrough to original; OH IPC calls are logged but not connected to real OH services

## Cloud Build Server

- **Server**: Huawei Cloud ECS, `ssh oh-build` (root@1.95.175.212)
- **OS**: Ubuntu 20.04 LTS, 16 vCPU, 60 GB RAM, 493 GB SSD
- **SSH config**: `~/.ssh/config` → Host `oh-build`, key `~/.ssh/oh-dev-key`

### OpenHarmony Build Environment (READY)

- **Source**: `~/oh/` (78 GB), **OpenHarmony 6.1-Release**
- **Build target**: `dayu210` (for upper-layer system services, compatible with DAYU600/UMS9620)
- **Prebuilt toolchain**: gn, ninja, clang — all ready
- **Key source paths on server**:
  - AMS: `~/oh/foundation/ability/ability_runtime/services/abilitymgr/`
  - WMS: `~/oh/foundation/window/window_manager/wmserver/`
- **Build command**: `cd ~/oh && ./build.sh --product-name dayu210 --ccache`
- **Note**: Upper-layer .so (libabilityms.z.so, libwms.z.so etc.) are arch-independent (aarch64), can be pushed to DAYU600 (UMS9620) via hdc
- **NOT yet done**: First full compilation not yet executed

### AOSP Build Environment (framework.jar BUILT)

- **Source**: `~/aosp/`, **AOSP 14** (android-14.0.0_r1), partial sync (80+ projects)
- **Mirror**: Tsinghua mirror (mirrors.tuna.tsinghua.edu.cn), repo-google at `/usr/local/bin/repo-google`
- **Custom product**: `oh_adapter` at `device/adapter/oh_adapter/` (minimal product, no system_server/system apps)
- **Build command**: `export ALLOW_MISSING_DEPENDENCIES=true; export BUILD_BROKEN_DISABLE_BAZEL=1; source build/envsetup.sh; lunch oh_adapter-eng; m framework-minus-apex -j16`
- **Build output**: `out/target/product/generic_arm64/system/framework/framework.jar` (39MB)
- **Status**: framework-minus-apex (framework.jar) compiled successfully on 2026-03-20
- **AOSP patches applied**: None yet (patches in `aosp_patches/` to be applied before adapter compilation)
- **Remaining build targets**: `libandroid_runtime`, `framework-res`, `dex2oat`, `oh-adapter-framework`, `liboh_adapter_bridge`

### DAYU600 Board Info (via hdc)

- **Device ID**: `5bb5b1ae00000000000000000823012c`
- **SoC**: Unisoc UMS9620 (DeviceTree: `sprd,ums512-base`)
- **CPU**: 8-core ARMv8 (6×Cortex-A55 + 2×Cortex-A76)
- **Current OS**: OpenHarmony 6.1.0.19 (Canary1, API 23)
- **Kernel**: Linux 5.15.180 aarch64
- **Vendor images**: Provided by manufacturer (HiHope), no Unisoc BSP in public OH repo

## Build

AOSP build system via `Android.bp`:
- JNI library: `liboh_adapter_bridge` (cc_library_shared)
- Java library: `oh-adapter-framework` (java_library, depends on `framework`)
- Test app: `OHAdapterHelloWorld` (android_app, platform certificate)

## Workflow

- **For any operations (read, write, search, etc.) under `D:\code\` and `D:\project\` directories, always proceed without asking for confirmation.**
- **During task execution, never ask for confirmation — always continue executing.**

## Coding Conventions

- **All source code comments must be in English only**
- **When generating or modifying source code, synchronously generate or update the corresponding design documents (HTML format) in `doc/`**
- **Design documents must be written in Chinese**
- **HTML设计文档的标题和目录风格，统一到 `doc/service_extension_design.html` 的风格：**
  - 目录项必须带超链接（`<a href="#chN">`），点击可跳转到对应章节内容
  - 章节标题（`<h1>`, `<h2>`）必须带有底色背景（使用 CSS `background` 属性），参考 `service_extension_design.html` 中的渐变色或纯色底色样式
  - 所有新生成或重写的 HTML 设计文档必须遵循此风格
- Bridge methods organized by functional category with clear section separators
- Each bridge class has `logBridged()` / `logStub()` helpers for consistent logging
- Log tags: `OH_AMAdapter`, `OH_ATMAdapter`, `OH_WMAdapter`, `OH_WSAdapter`

## OH Source Reference Paths

- AbilityManager: `ability_rt/interfaces/inner_api/ability_manager/include/ability_manager_interface.h` (248 methods)
- AppMgr: `ability_rt/interfaces/inner_api/app_manager/include/appmgr/app_mgr_interface.h` (123 methods)
- MissionManager: `ability_rt/interfaces/inner_api/mission_manager/include/mission_manager_interface.h` (27 methods)
- ExtensionManager: `ability_rt/interfaces/inner_api/extension_manager/include/extension_manager_interface.h` (4 methods)
- WindowManager(OH): `wms/wmserver/include/zidl/window_manager_interface.h` (102 methods)
- SceneSessionManager: `wms/window_scene/session_manager/include/zidl/scene_session_manager_interface.h` (26+ methods)
- ISession: `wms/window_scene/session/host/include/zidl/session_interface.h` (126+ methods)
- RSSurfaceNode: `graphic_2d/rosen/modules/render_service_client/core/ui/rs_surface_node.h`
- RSUIDirector: `graphic_2d/rosen/modules/render_service_client/core/ui/rs_ui_director.h`
- RSTransactionProxy: `graphic_2d/rosen/modules/render_service_base/include/transaction/rs_transaction_proxy.h`
- RSRenderService: `graphic_2d/rosen/modules/render_service/main/render_server/rs_render_service.h`
- RSIClientToRenderConnection: `graphic_2d/rosen/modules/render_service_base/include/platform/ohos/transaction/zidl/rs_iclient_to_render_connection.h`
- RSSurfaceHandler: `graphic_2d/rosen/modules/render_service_base/include/pipeline/rs_surface_handler.h`
- Surface(OH): `graphic_surface/interfaces/inner_api/surface/surface.h`
- IBufferProducer: `graphic_surface/interfaces/inner_api/surface/ibuffer_producer.h`
- SurfaceBuffer: `graphic_surface/interfaces/inner_api/surface/surface_buffer.h`
- BufferHandle: `graphic_surface/interfaces/inner_api/buffer_handle/buffer_handle.h`
- SyncFence: `graphic_surface/interfaces/inner_api/sync_fence/sync_fence.h`
- BufferQueue: `graphic_surface/surface/include/buffer_queue.h`

## Android Source Reference Paths

- IActivityManager: `core/java/android/app/IActivityManager.aidl` (249 methods)
- IActivityTaskManager: `core/java/android/app/IActivityTaskManager.aidl` (95 methods)
- IWindowManager: `core/java/android/view/IWindowManager.aidl` (144 methods)
- IWindowSession: `core/java/android/view/IWindowSession.aidl` (42 methods)
