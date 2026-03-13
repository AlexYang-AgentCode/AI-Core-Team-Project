#!/bin/bash
# 16.6-Adapter.Test 环境配置
# source 此文件后即可使用 adb / hdc / java 等工具

DOC_ROOT="/mnt/e/10.Project/19.Document"
DEVECO_ROOT="/mnt/d/Program Files/Huawei/DevEco Studio"

# JDK (Linux)
export JAVA_HOME="$DOC_ROOT/19.5.JDK/jdk-17.0.2"

# Android SDK
export ANDROID_HOME="$DOC_ROOT/19.4.AndroidSDK"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"

# HarmonyOS (Windows exe, callable from WSL)
export HDC="$DEVECO_ROOT/sdk/default/openharmony/toolchains/hdc.exe"
export HVIGOR_NODE="$DEVECO_ROOT/tools/node/node.exe"
export HVIGOR_JS="$DEVECO_ROOT/tools/hvigor/bin/hvigorw.js"
export DEVECO_JBR="$DEVECO_ROOT/jbr"
export DEVECO_SDK="$DEVECO_ROOT/sdk"
export DEVECO_OHPM="$DEVECO_ROOT/tools/ohpm/bin"

# 16.1 source directory
export DEMO_ROOT="/mnt/e/10.Project/16.1-AndroidToHarmonyOSDemo"
export HARMONY_APP="$DEMO_ROOT/harmony-app"

echo "=== 16.6-Adapter.Test 环境已加载 ==="
echo "  adb:  $(which adb 2>/dev/null || echo 'NOT FOUND')"
echo "  hdc:  $HDC"
echo "  java: $(java -version 2>&1 | head -1)"
