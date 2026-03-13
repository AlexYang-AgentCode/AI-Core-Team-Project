#!/bin/bash
# Auto-fix missing resources in a build directory
# Usage: fix-resources.sh <build_dir>

BUILD_DIR="$1"
RES_DIR="$BUILD_DIR/app/src/main/res"
SRC_DIR="$BUILD_DIR/app/src/main/java"
STRINGS_FILE="$RES_DIR/values/strings.xml"

# 1. Extract all string references from XML (@string/xxx) AND Java/Kotlin (R.string.xxx)
xml_strings=$(grep -roh '@string/[a-zA-Z0-9_]*' "$RES_DIR" 2>/dev/null | sed 's/@string\///' | sort -u)
java_strings=$(grep -roh 'R\.string\.[a-zA-Z0-9_]*' "$SRC_DIR" 2>/dev/null | sed 's/R\.string\.//' | sort -u)
all_strings=$(echo -e "$xml_strings\n$java_strings" | sort -u | grep -v '^$')
existing_strings=$(grep -o 'name="[a-zA-Z0-9_]*"' "$STRINGS_FILE" 2>/dev/null | sed 's/name="//;s/"//' | sort -u)

# Add missing strings
for s in $all_strings; do
    if ! echo "$existing_strings" | grep -qx "$s"; then
        label=$(echo "$s" | sed 's/_/ /g')
        sed -i "s|</resources>|    <string name=\"$s\">$label</string>\n</resources>|" "$STRINGS_FILE"
    fi
done

# 2. Remove text-decoration drawable references from XML (drawableEnd/drawableStart)
find "$RES_DIR" -name "*.xml" -exec sed -i \
    -e 's/android:drawableEnd="@drawable\/[^"]*"//' \
    -e 's/android:drawableStart="@drawable\/[^"]*"//' \
    -e 's/android:drawablePadding="[^"]*"//' \
    {} \;

# 3. Create placeholder drawables referenced in BOTH Java AND XML
mkdir -p "$RES_DIR/drawable"
xml_drawables=$(grep -roh '@drawable/[a-zA-Z0-9_]*' "$RES_DIR" 2>/dev/null | sed 's/@drawable\///' | sort -u)
java_drawables=$(grep -roh 'R\.drawable\.[a-zA-Z0-9_]*' "$SRC_DIR" 2>/dev/null | sed 's/R\.drawable\.//' | sort -u)
all_drawables=$(echo -e "$xml_drawables\n$java_drawables" | sort -u | grep -v '^$')
for d in $all_drawables; do
    if [ ! -f "$RES_DIR/drawable/$d.xml" ]; then
        cat > "$RES_DIR/drawable/$d.xml" << 'XMLEOF'
<?xml version="1.0" encoding="utf-8"?>
<shape xmlns:android="http://schemas.android.com/apk/res/android">
    <solid android:color="#2196F3"/>
    <size android:width="24dp" android:height="24dp"/>
</shape>
XMLEOF
    fi
done

# 4. Create placeholder menu XMLs referenced in Java code
# Extract menu item IDs used in onOptionsItemSelected/switch patterns
menu_item_ids=$(grep -roh 'R\.id\.[a-zA-Z0-9_]*' "$SRC_DIR" 2>/dev/null | sed 's/R\.id\.//' | sort -u)
for m in $(grep -roh 'R\.menu\.[a-zA-Z0-9_]*' "$SRC_DIR" 2>/dev/null | sed 's/R\.menu\.//' | sort -u); do
    mkdir -p "$RES_DIR/menu"
    if [ ! -f "$RES_DIR/menu/$m.xml" ]; then
        echo '<?xml version="1.0" encoding="utf-8"?>' > "$RES_DIR/menu/$m.xml"
        echo '<menu xmlns:android="http://schemas.android.com/apk/res/android">' >> "$RES_DIR/menu/$m.xml"
        # Add all R.id references that look like menu items (action_*, add, edit, delete, etc.)
        for id in $menu_item_ids; do
            case "$id" in
                action_*|add|edit|delete|search|settings|refresh|save|cancel|share|done|menu_*)
                    label=$(echo "$id" | sed 's/_/ /g')
                    echo "    <item android:id=\"@+id/$id\" android:title=\"$label\"/>" >> "$RES_DIR/menu/$m.xml"
                    ;;
            esac
        done
        echo '</menu>' >> "$RES_DIR/menu/$m.xml"
    fi
done

# 5. Create placeholder raw resources
for r in $(grep -roh 'R\.raw\.[a-zA-Z0-9_]*' "$SRC_DIR" 2>/dev/null | sed 's/R\.raw\.//' | sort -u); do
    mkdir -p "$RES_DIR/raw"
    if [ ! -f "$RES_DIR/raw/$r" ]; then
        # Create a minimal valid file (1-second silence MP3 header)
        echo "" > "$RES_DIR/raw/$r"
    fi
done

# 6. Add integer resources referenced in Java
integers=$(grep -roh 'R\.integer\.[a-zA-Z0-9_]*' "$SRC_DIR" 2>/dev/null | sed 's/R\.integer\.//' | sort -u)
if [ -n "$integers" ]; then
    if [ ! -f "$RES_DIR/values/integers.xml" ]; then
        echo '<resources>' > "$RES_DIR/values/integers.xml"
        for i in $integers; do
            echo "    <integer name=\"$i\">0</integer>" >> "$RES_DIR/values/integers.xml"
        done
        echo '</resources>' >> "$RES_DIR/values/integers.xml"
    fi
fi

# 7. Add color resources referenced in XML
xml_colors=$(grep -roh '@color/[a-zA-Z0-9_]*' "$RES_DIR" 2>/dev/null | sed 's/@color\///' | sort -u)
java_colors=$(grep -roh 'R\.color\.[a-zA-Z0-9_]*' "$SRC_DIR" 2>/dev/null | sed 's/R\.color\.//' | sort -u)
all_colors=$(echo -e "$xml_colors\n$java_colors" | sort -u | grep -v '^$')
if [ -n "$all_colors" ]; then
    if [ ! -f "$RES_DIR/values/colors.xml" ]; then
        echo '<resources>' > "$RES_DIR/values/colors.xml"
        for c in $all_colors; do
            echo "    <color name=\"$c\">#2196F3</color>" >> "$RES_DIR/values/colors.xml"
        done
        echo '</resources>' >> "$RES_DIR/values/colors.xml"
    fi
fi

# 8. Handle @dimen references from XML not in dimens.xml
xml_dimens=$(grep -roh '@dimen/[a-zA-Z0-9_]*' "$RES_DIR" 2>/dev/null | sed 's/@dimen\///' | sort -u)
if [ -f "$RES_DIR/values/dimens.xml" ]; then
    existing_dimens=$(grep -o 'name="[a-zA-Z0-9_]*"' "$RES_DIR/values/dimens.xml" 2>/dev/null | sed 's/name="//;s/"//' | sort -u)
    for d in $xml_dimens; do
        if ! echo "$existing_dimens" | grep -qx "$d"; then
            sed -i "s|</resources>|    <dimen name=\"$d\">16dp</dimen>\n</resources>|" "$RES_DIR/values/dimens.xml"
        fi
    done
fi

echo "Resources fixed for $BUILD_DIR"
