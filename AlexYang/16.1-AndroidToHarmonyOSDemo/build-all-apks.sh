#!/bin/bash
# Build all test case APKs
# Prerequisites: ANDROID_HOME set, Java 17+, Gradle 8+

set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/android-template"
BUILD_LOG="$SCRIPT_DIR/build-all.log"

echo "=== Android API Test Cases - APK Builder ===" | tee "$BUILD_LOG"
echo "ANDROID_HOME=$ANDROID_HOME" | tee -a "$BUILD_LOG"
echo "" | tee -a "$BUILD_LOG"

# Check prerequisites
if [ -z "$ANDROID_HOME" ]; then
    echo "ERROR: ANDROID_HOME not set. Please set it to your Android SDK path." | tee -a "$BUILD_LOG"
    echo "Example: export ANDROID_HOME=\$HOME/Android/Sdk" | tee -a "$BUILD_LOG"
    exit 1
fi

if ! command -v java &> /dev/null; then
    echo "ERROR: Java not found. Please install JDK 17+." | tee -a "$BUILD_LOG"
    exit 1
fi

SUCCESS=0
FAIL=0
SKIP=0

for dir in "$SCRIPT_DIR"/16.1.1[2-4]*; do
    name=$(basename "$dir")
    apk_dir="$dir/apk"

    # Skip if APK already exists
    if ls "$apk_dir"/*.apk 1>/dev/null 2>&1; then
        echo "SKIP $name (APK already exists)" | tee -a "$BUILD_LOG"
        SKIP=$((SKIP + 1))
        continue
    fi

    echo "BUILD $name ..." | tee -a "$BUILD_LOG"

    # Determine package name from directory
    pkg_suffix=$(echo "$name" | sed 's/16.1.[0-9]*-//' | tr '[:upper:]' '[:lower:]' | tr '-' '.')
    pkg_name="com.demo.$pkg_suffix"
    app_name=$(echo "$name" | sed 's/16.1.[0-9]*-//')

    # Create temp build directory
    BUILD_DIR=$(mktemp -d)
    cp -r "$TEMPLATE_DIR"/* "$BUILD_DIR"/

    # Copy source files
    if [ -d "$dir/src" ]; then
        src_pkg_dir="$BUILD_DIR/app/src/main/java/$(echo $pkg_name | tr '.' '/')"
        mkdir -p "$src_pkg_dir"
        cp "$dir"/src/*.java "$src_pkg_dir"/ 2>/dev/null || true
        cp "$dir"/src/*.kt "$src_pkg_dir"/ 2>/dev/null || true

        # Copy layout XMLs
        layout_dir="$BUILD_DIR/app/src/main/res/layout"
        mkdir -p "$layout_dir"
        cp "$dir"/src/*.xml "$layout_dir"/ 2>/dev/null || true

        # Update package name in Java files
        find "$src_pkg_dir" -name "*.java" -exec sed -i "s/^package .*/package $pkg_name;/" {} \;
        find "$src_pkg_dir" -name "*.kt" -exec sed -i "s/^package .*/package $pkg_name/" {} \;

        # Update AndroidManifest
        sed -i "s/PACKAGE_NAME/$pkg_name/g" "$BUILD_DIR/app/src/main/AndroidManifest.xml"
        sed -i "s/APP_NAME/$app_name/g" "$BUILD_DIR/app/src/main/AndroidManifest.xml"
        sed -i "s/PACKAGE_NAME/$pkg_name/g" "$BUILD_DIR/app/build.gradle"

        # Update strings.xml
        sed -i "s/APP_NAME/$app_name/g" "$BUILD_DIR/app/src/main/res/values/strings.xml"

        # Check for manifest additions
        if [ -f "$dir/src/AndroidManifest_additions.xml" ]; then
            # Insert additions before closing </application> tag
            additions=$(cat "$dir/src/AndroidManifest_additions.xml" | grep -v "^<!--")
            sed -i "s|</application>|$additions\n    </application>|" "$BUILD_DIR/app/src/main/AndroidManifest.xml"
        fi
    fi

    # Migrate support library imports to AndroidX
    bash "$SCRIPT_DIR/build-tools/fix-support-lib.sh" "$BUILD_DIR/app/src/main/java" >> "$BUILD_LOG" 2>&1

    # Fix manifest (register extra Activities/Services/Receivers, fix R imports)
    bash "$SCRIPT_DIR/build-tools/fix-manifest.sh" "$BUILD_DIR" "$pkg_name" >> "$BUILD_LOG" 2>&1

    # Fix missing resources
    bash "$SCRIPT_DIR/build-tools/fix-resources.sh" "$BUILD_DIR" >> "$BUILD_LOG" 2>&1

    # Build
    cd "$BUILD_DIR"
    if ./gradlew assembleRelease -q 2>>"$BUILD_LOG"; then
        mkdir -p "$apk_dir"
        cp "$BUILD_DIR/app/build/outputs/apk/release/app-release-unsigned.apk" "$apk_dir/$app_name.apk"
        echo "  OK -> $apk_dir/$app_name.apk" | tee -a "$BUILD_LOG"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "  FAIL (see $BUILD_LOG)" | tee -a "$BUILD_LOG"
        FAIL=$((FAIL + 1))
    fi

    # Cleanup
    rm -rf "$BUILD_DIR"
    cd "$SCRIPT_DIR"
done

echo "" | tee -a "$BUILD_LOG"
echo "=== Summary: $SUCCESS built, $SKIP skipped, $FAIL failed ===" | tee -a "$BUILD_LOG"
