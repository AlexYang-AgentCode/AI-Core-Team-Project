#!/usr/bin/env python3
"""
api-route-tagger.py — Add 'adapt_route' column to the API master list CSV.

Adaptation routes:
  - adapter:        Pure app-layer translation, no system privilege needed
  - system-bridge:  Needs OS-level bridging or system service support
  - not-feasible:   Cannot be adapted without full Android runtime
  - passthrough:    Standard Java/language feature, works as-is or trivially

Classification logic based on package, class, and API characteristics.
"""

import csv
import os
import sys

# ============================================================
# Route classification rules
# ============================================================

# Classes that require system-level bridging
SYSTEM_BRIDGE_CLASSES = {
    # Telephony
    "TelephonyManager", "SmsManager", "PhoneStateListener",
    "SubscriptionManager", "CellInfo", "CellLocation",
    "TelephonyCallback", "ServiceState",
    # Bluetooth low-level
    "BluetoothAdapter", "BluetoothDevice", "BluetoothSocket",
    "BluetoothGatt", "BluetoothGattServer", "BluetoothGattCallback",
    "BluetoothServerSocket", "BluetoothHeadset", "BluetoothA2dp",
    "BluetoothHealth", "BluetoothManager",
    # NFC
    "NfcAdapter", "Tag", "NdefMessage", "NdefRecord",
    "IsoDep", "Ndef", "NfcA", "NfcB", "NfcF", "NfcV",
    "MifareClassic", "MifareUltralight",
    # Camera hardware
    "CameraManager", "CameraDevice", "CaptureRequest",
    "CaptureSession", "CameraCharacteristics", "CaptureResult",
    "CameraCaptureSession",
    # Audio hardware
    "AudioTrack", "AudioRecord", "AudioManager",
    "AudioFocusRequest", "AudioPlaybackCaptureConfiguration",
    # Location
    "LocationManager", "LocationListener", "Geocoder",
    "GnssStatus", "GnssMeasurement",
    # Sensors
    "SensorManager", "SensorEventListener", "Sensor",
    # Connectivity deep
    "ConnectivityManager", "NetworkCallback", "NetworkRequest",
    "WifiManager", "WifiInfo", "WifiConfiguration",
    # Device admin / security
    "DevicePolicyManager", "DeviceAdminReceiver",
    "KeyStore", "KeyGenerator", "KeyPairGenerator",
    "BiometricPrompt", "FingerprintManager",
    # USB/NFC/hardware
    "UsbManager", "UsbDevice", "UsbDeviceConnection",
    "UsbInterface", "UsbEndpoint",
    # Notifications (system service)
    "NotificationManager", "NotificationChannel",
    "NotificationChannelGroup",
    # Account
    "AccountManager", "Account", "AccountAuthenticatorActivity",
    # Alarm
    "AlarmManager",
    # Download
    "DownloadManager",
    # PowerManager
    "PowerManager", "WakeLock",
    # Vibrator
    "Vibrator", "VibrationEffect",
    # Display
    "DisplayManager",
    # Wallpaper
    "WallpaperManager",
    # Print
    "PrintManager", "PrintJob",
    # Media DRM
    "MediaDrm",
    # MediaProjection
    "MediaProjection", "MediaProjectionManager",
    # TextToSpeech
    "TextToSpeech",
    # SpeechRecognizer
    "SpeechRecognizer",
    # Job scheduler
    "JobScheduler", "JobService", "JobInfo",
    # AppWidget
    "AppWidgetManager", "AppWidgetProvider",
}

# Classes that are not feasible without full Android runtime
NOT_FEASIBLE_CLASSES = {
    # Binder IPC (core Android system mechanism)
    "Binder", "IBinder", "IInterface",
    # Content provider cross-app (requires Android content:// URI scheme)
    "ContentProvider", "ContentResolver",
    # RenderScript (GPU compute, deprecated and Android-specific)
    "RenderScript", "Allocation", "ScriptC",
    "ScriptIntrinsicBlur", "ScriptIntrinsicConvolve3x3",
    # DRM
    "DrmManagerClient",
    # App Ops
    "AppOpsManager",
    # Instrumentation (testing infrastructure)
    "Instrumentation",
    # Android-specific class loading
    "DexClassLoader", "PathClassLoader", "DexFile",
    # Accessibility deep
    "AccessibilityService", "AccessibilityNodeInfo",
    "AccessibilityEvent",
}

# Packages that are passthrough (standard Java, work as-is in ArkTS)
PASSTHROUGH_PACKAGES = [
    "java.lang",
    "java.math",
    "java.text",
    "java.util.regex",
]

# Packages that are adapter-level (pure app layer)
ADAPTER_PACKAGES = [
    "android.widget",
    "android.view",
    "android.graphics",
    "android.text",
    "android.animation",
    "android.transition",
    "android.gesture",
]

# Packages that need system bridge
SYSTEM_BRIDGE_PACKAGES = [
    "android.telephony",
    "android.bluetooth",
    "android.nfc",
    "android.hardware",
    "android.location",
    "android.media",  # most media needs system services
    "android.security",
    "android.app.admin",
    "android.accounts",
    "android.appwidget",
    "android.print",
    "android.speech",
    "android.service",
]

# Packages that are not feasible
NOT_FEASIBLE_PACKAGES = [
    "android.renderscript",
    "android.drm",
    "dalvik",
]


def classify_route(package: str, class_name: str, method_name: str,
                   api_type: str, difficulty: str) -> str:
    """Determine the adaptation route for an API entry."""

    # 1. Check class-level overrides first (most specific)
    if class_name in NOT_FEASIBLE_CLASSES:
        return "not-feasible"
    if class_name in SYSTEM_BRIDGE_CLASSES:
        return "system-bridge"

    # 2. Check package-level rules
    for pkg in NOT_FEASIBLE_PACKAGES:
        if package.startswith(pkg):
            return "not-feasible"

    for pkg in PASSTHROUGH_PACKAGES:
        if package.startswith(pkg):
            return "passthrough"

    for pkg in SYSTEM_BRIDGE_PACKAGES:
        if package.startswith(pkg):
            return "system-bridge"

    for pkg in ADAPTER_PACKAGES:
        if package.startswith(pkg):
            return "adapter"

    # 3. Heuristic rules
    # java.io / java.nio — mostly passthrough with minor adaptation
    if package.startswith("java.io") or package.startswith("java.nio"):
        return "adapter"
    if package.startswith("java.net"):
        return "adapter"
    if package.startswith("java.util"):
        return "passthrough"
    if package.startswith("java.") or package.startswith("javax."):
        return "passthrough"

    # android.content — mixed: some adapter, some system-bridge
    if package.startswith("android.content"):
        if class_name in ("ContentProvider", "ContentResolver"):
            return "not-feasible"
        if class_name in ("Intent", "Context", "SharedPreferences",
                         "ComponentName", "IntentFilter",
                         "BroadcastReceiver", "ClipboardManager"):
            return "adapter"
        return "adapter"

    # android.app — mixed
    if package.startswith("android.app"):
        if class_name in ("Activity", "Fragment", "Dialog",
                         "AlertDialog", "Application", "Service"):
            return "adapter"
        if class_name in ("Notification", "NotificationManager",
                         "PendingIntent", "AlarmManager"):
            return "system-bridge"
        return "adapter"

    # android.os — mixed
    if package.startswith("android.os"):
        if class_name in ("Handler", "Looper", "Message", "Bundle",
                         "Parcel", "Parcelable", "AsyncTask",
                         "HandlerThread", "SystemClock", "Build",
                         "Environment", "Process"):
            return "adapter"
        if class_name in ("Binder", "IBinder"):
            return "not-feasible"
        if class_name in ("PowerManager", "Vibrator"):
            return "system-bridge"
        return "adapter"

    # android.net — mostly system-bridge
    if package.startswith("android.net"):
        if class_name == "Uri":
            return "adapter"
        return "system-bridge"

    # android.webkit
    if package.startswith("android.webkit"):
        return "adapter"

    # android.database
    if package.startswith("android.database"):
        return "adapter"
    if package.startswith("android.provider"):
        return "system-bridge"

    # android.util
    if package.startswith("android.util"):
        return "passthrough"

    # Difficulty-based fallback
    try:
        diff = int(difficulty)
        if diff <= 1:
            return "passthrough"
        elif diff <= 3:
            return "adapter"
        elif diff <= 4:
            return "system-bridge"
        else:
            return "not-feasible"
    except (ValueError, TypeError):
        pass

    return "adapter"


def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.dirname(script_dir)
    default_input = os.path.join(base_dir, "133-API-MASTER-LIST.csv")

    import argparse
    parser = argparse.ArgumentParser(description="Add adapt_route column to CSV")
    parser.add_argument("--input", "-i", default=default_input)
    parser.add_argument("--output", "-o", default=None,
                       help="Output file (default: overwrite input)")
    args = parser.parse_args()

    output = args.output or args.input

    # Read
    print(f"Reading {args.input} ...", file=sys.stderr)
    rows = []
    with open(args.input, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        original_fields = reader.fieldnames
        for row in reader:
            rows.append(row)
    print(f"  {len(rows)} entries", file=sys.stderr)

    # Add route column
    fieldnames = list(original_fields)
    if "adapt_route" not in fieldnames:
        # Insert after mapping_difficulty
        idx = fieldnames.index("mapping_difficulty") + 1
        fieldnames.insert(idx, "adapt_route")

    stats = {"adapter": 0, "system-bridge": 0, "not-feasible": 0, "passthrough": 0}

    for row in rows:
        route = classify_route(
            row.get("package", ""),
            row.get("class_name", ""),
            row.get("method_name", ""),
            row.get("api_type", ""),
            row.get("mapping_difficulty", ""),
        )
        row["adapt_route"] = route
        stats[route] = stats.get(route, 0) + 1

    # Write
    with open(output, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
        writer.writeheader()
        writer.writerows(rows)

    print(f"\nOutput: {output}", file=sys.stderr)
    print(f"\n{'='*50}", file=sys.stderr)
    print(f"Adaptation Route Summary", file=sys.stderr)
    print(f"{'='*50}", file=sys.stderr)
    total = len(rows)
    for route in ["passthrough", "adapter", "system-bridge", "not-feasible"]:
        count = stats.get(route, 0)
        pct = count / total * 100
        print(f"  {route:16s}: {count:>5} ({pct:5.1f}%)", file=sys.stderr)
    print(f"  {'total':16s}: {total:>5}", file=sys.stderr)
    print(f"{'='*50}", file=sys.stderr)

    # Show feasibility summary
    feasible = stats["passthrough"] + stats["adapter"]
    bridgeable = stats["system-bridge"]
    infeasible = stats["not-feasible"]
    print(f"\n适配层可覆盖:     {feasible:>5} ({feasible/total*100:.1f}%)  ← 131/13X 项目直接可做", file=sys.stderr)
    print(f"需系统级桥接:     {bridgeable:>5} ({bridgeable/total*100:.1f}%)  ← 需要 OS 厂商配合", file=sys.stderr)
    print(f"不可行:           {infeasible:>5} ({infeasible/total*100:.1f}%)  ← 需完整 Android 运行时", file=sys.stderr)


if __name__ == "__main__":
    main()
