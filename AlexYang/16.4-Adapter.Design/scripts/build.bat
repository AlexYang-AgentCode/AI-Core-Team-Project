@echo off
REM Build script for TextClock HarmonyOS project
REM Sets all required environment variables for hvigorw

set DEVECO_SDK_HOME=D:\Program Files\Huawei\DevEco Studio\sdk
set JAVA_HOME=D:\Program Files\Huawei\DevEco Studio\jbr
set NODE_HOME=D:\Program Files\Huawei\DevEco Studio\tools\node
set PATH=%JAVA_HOME%\bin;%PATH%
set HVIGOR_USER_HOME=D:\HvigorHome

cd /d D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app

echo === Building TextClock HarmonyOS App ===
echo DEVECO_SDK_HOME=%DEVECO_SDK_HOME%
echo JAVA_HOME=%JAVA_HOME%

REM Skip --stop-daemon on first run, it may fail if no daemon exists
"D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p product=default --no-daemon

if %ERRORLEVEL% EQU 0 (
    echo === BUILD SUCCEEDED ===
) else (
    echo === BUILD FAILED ===
    exit /b 1
)
