#!/bin/bash
# Migrate android.support.* imports to androidx.* in Java/Kotlin source files
# Usage: fix-support-lib.sh <src_dir>

SRC_DIR="$1"

# Common support library to AndroidX mappings
find "$SRC_DIR" -name "*.java" -o -name "*.kt" | while read f; do
    sed -i \
        -e 's/android\.support\.v7\.app\.AppCompatActivity/androidx.appcompat.app.AppCompatActivity/g' \
        -e 's/android\.support\.v7\.app\.AlertDialog/androidx.appcompat.app.AlertDialog/g' \
        -e 's/android\.support\.v7\.widget\.RecyclerView/androidx.recyclerview.widget.RecyclerView/g' \
        -e 's/android\.support\.v7\.widget\.LinearLayoutManager/androidx.recyclerview.widget.LinearLayoutManager/g' \
        -e 's/android\.support\.v7\.widget\.Toolbar/androidx.appcompat.widget.Toolbar/g' \
        -e 's/android\.support\.v4\.app\.ActivityCompat/androidx.core.app.ActivityCompat/g' \
        -e 's/android\.support\.v4\.app\.Fragment/androidx.fragment.app.Fragment/g' \
        -e 's/android\.support\.v4\.app\.FragmentManager/androidx.fragment.app.FragmentManager/g' \
        -e 's/android\.support\.v4\.app\.FragmentTransaction/androidx.fragment.app.FragmentTransaction/g' \
        -e 's/android\.support\.v4\.app\.DialogFragment/androidx.fragment.app.DialogFragment/g' \
        -e 's/android\.support\.v4\.app\.LoaderManager/androidx.loader.app.LoaderManager/g' \
        -e 's/android\.support\.v4\.content\.AsyncTaskLoader/androidx.loader.content.AsyncTaskLoader/g' \
        -e 's/android\.support\.v4\.content\.Loader/androidx.loader.content.Loader/g' \
        -e 's/android\.support\.v4\.content\.ContextCompat/androidx.core.content.ContextCompat/g' \
        -e 's/android\.support\.v4\.content\.FileProvider/androidx.core.content.FileProvider/g' \
        -e 's/android\.support\.v4\.app\.NotificationCompat/androidx.core.app.NotificationCompat/g' \
        -e 's/android\.support\.v4\.app\.NotificationManagerCompat/androidx.core.app.NotificationManagerCompat/g' \
        -e 's/android\.support\.annotation\.NonNull/androidx.annotation.NonNull/g' \
        -e 's/android\.support\.annotation\.Nullable/androidx.annotation.Nullable/g' \
        -e 's/android\.support\.annotation\.IntDef/androidx.annotation.IntDef/g' \
        -e 's/android\.support\.annotation\.Retention/androidx.annotation.Retention/g' \
        -e 's/android\.support\.design\.widget\.FloatingActionButton/com.google.android.material.floatingactionbutton.FloatingActionButton/g' \
        -e 's/android\.support\.design\.widget\.Snackbar/com.google.android.material.snackbar.Snackbar/g' \
        -e 's/android\.support\.design\.widget\.CoordinatorLayout/androidx.coordinatorlayout.widget.CoordinatorLayout/g' \
        "$f"
done

echo "Support library migration done for $SRC_DIR"
