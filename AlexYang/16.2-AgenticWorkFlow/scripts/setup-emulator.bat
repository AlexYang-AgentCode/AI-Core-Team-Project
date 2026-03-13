@echo off
chcp 65001 >nul
REM ============================================
REM  131 TextClock - Setup Emulator & Run
REM  自动化: 签名配置 + 模拟器创建 + 编译 + 安装 + 运行
REM ============================================

set DEVECO=D:\Program Files\Huawei\DevEco Studio
set HDC="%DEVECO%\sdk\default\openharmony\toolchains\hdc.exe"
set EMULATOR="%DEVECO%\tools\emulator\Emulator.exe"
set PROJECT=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app
set HAP=%PROJECT%\entry\build\default\outputs\default\entry-default-unsigned.hap

echo.
echo ========================================
echo  TextClock HarmonyOS - Setup ^& Run
echo ========================================
echo.

REM Step 1: Check if emulator exists
echo [Step 1] Checking emulator instances...
%EMULATOR% -list
echo.

REM Step 2: Check connected devices
echo [Step 2] Checking connected devices...
%HDC% list targets
echo.

REM Step 3: Build
echo [Step 3] Building HAP...
cd /d %PROJECT%
set DEVECO_SDK_HOME=%DEVECO%\sdk
set JAVA_HOME=%DEVECO%\jbr
set NODE_HOME=%DEVECO%\tools\node
set PATH=%JAVA_HOME%\bin;%PATH%
set HVIGOR_USER_HOME=D:\HvigorHome

"%DEVECO%\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p product=default --no-daemon
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Build failed!
    goto :end
)
echo [OK] Build successful.
echo.

REM Step 4: Check HAP
if exist "%HAP%" (
    echo [OK] HAP found: %HAP%
    for %%A in ("%HAP%") do echo [OK] Size: %%~zA bytes
) else (
    echo [FAIL] HAP not found!
    goto :end
)
echo.

REM Step 5: Try install
echo [Step 5] Attempting to install...
echo.
echo NOTE: If no device is connected, you need to:
echo   1. Open DevEco Studio
echo   2. Tools -^> Device Manager
echo   3. Create a Phone emulator (API 12)
echo   4. Download system image when prompted
echo   5. Start the emulator
echo   6. Then run this script again
echo.

%HDC% list targets >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] No device connected. Opening DevEco Studio...
    start "" "%DEVECO%\bin\devecostudio64.exe" %PROJECT%
    echo.
    echo Please create an emulator in DevEco Studio:
    echo   Tools -^> Device Manager -^> + -^> Phone -^> API 12
    echo.
    echo After emulator starts, run this script again.
    goto :end
)

echo Installing HAP...
%HDC% install "%HAP%"
if %ERRORLEVEL% NEQ 0 (
    echo [WARN] Install failed. HAP may need signing.
    echo Please use DevEco Studio to run with auto-sign.
    goto :end
)

echo Starting app...
%HDC% shell aa start -a EntryAbility -b com.example.textclock
echo.
echo [OK] App should be running!

:end
echo.
pause
