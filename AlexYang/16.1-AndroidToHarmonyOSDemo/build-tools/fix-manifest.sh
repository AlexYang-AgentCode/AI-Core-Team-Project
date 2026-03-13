#!/bin/bash
# Auto-detect and register extra Activities, Services, Receivers in AndroidManifest
# Also fix R class imports
# Usage: fix-manifest.sh <build_dir> <pkg_name>

BUILD_DIR="$1"
PKG_NAME="$2"
MANIFEST="$BUILD_DIR/app/src/main/AndroidManifest.xml"
SRC_DIR="$BUILD_DIR/app/src/main/java"

# 1. Fix R class imports - replace any com.xxx.R import with correct package (but not android.R)
find "$SRC_DIR" -name "*.java" -exec sed -i \
    -e "s/import com\.[a-zA-Z0-9_.]*\.R;/import ${PKG_NAME}.R;/g" \
    {} \;

# 2. Find extra Activities (classes extending AppCompatActivity or Activity, excluding MainActivity)
extra_activities=""
for f in $(find "$SRC_DIR" -name "*.java" | grep -v "MainActivity.java"); do
    classname=$(basename "$f" .java)
    if grep -q "extends.*Activity" "$f" 2>/dev/null; then
        extra_activities="$extra_activities $classname"
    fi
done

# 3. Find Services
extra_services=""
for f in $(find "$SRC_DIR" -name "*.java"); do
    classname=$(basename "$f" .java)
    if grep -q "extends.*Service" "$f" 2>/dev/null; then
        extra_services="$extra_services $classname"
    fi
done

# 4. Find BroadcastReceivers
extra_receivers=""
for f in $(find "$SRC_DIR" -name "*.java"); do
    classname=$(basename "$f" .java)
    if grep -q "extends.*BroadcastReceiver" "$f" 2>/dev/null; then
        extra_receivers="$extra_receivers $classname"
    fi
done

# 5. Find ContentProviders
extra_providers=""
for f in $(find "$SRC_DIR" -name "*.java"); do
    classname=$(basename "$f" .java)
    if grep -q "extends.*ContentProvider" "$f" 2>/dev/null; then
        extra_providers="$extra_providers $classname"
    fi
done

# 6. Register components in manifest
additions=""
for act in $extra_activities; do
    additions="$additions\n        <activity android:name=\".$act\" android:exported=\"false\" />"
done
for svc in $extra_services; do
    additions="$additions\n        <service android:name=\".$svc\" android:exported=\"false\" />"
done
for rcv in $extra_receivers; do
    additions="$additions\n        <receiver android:name=\".$rcv\" android:exported=\"false\" />"
done
for prv in $extra_providers; do
    additions="$additions\n        <provider android:name=\".$prv\" android:authorities=\"${PKG_NAME}.provider\" android:exported=\"false\" />"
done

if [ -n "$additions" ]; then
    sed -i "s|</application>|$additions\n    </application>|" "$MANIFEST"
fi

# 7. Copy extra layout XMLs (activity_second.xml etc) that the build script may have missed
# (already handled by build script copying all .xml to layout/)

echo "Manifest fixed: activities=[$extra_activities] services=[$extra_services] receivers=[$extra_receivers] providers=[$extra_providers]"
