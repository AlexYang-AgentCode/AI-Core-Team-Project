@echo off
chcp 65001 >nul
REM ============================================
REM  131 TextClock - Build + Verify + Run
REM  One-click: build HAP, check result, show next step
REM ============================================

set DEVECO_SDK_HOME=D:\Program Files\Huawei\DevEco Studio\sdk
set JAVA_HOME=D:\Program Files\Huawei\DevEco Studio\jbr
set NODE_HOME=D:\Program Files\Huawei\DevEco Studio\tools\node
set PATH=%JAVA_HOME%\bin;%PATH%
set HVIGOR_USER_HOME=D:\HvigorHome

set PROJECT=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app
set HAP=%PROJECT%\entry\build\default\outputs\default\entry-default-unsigned.hap

echo.
echo ========================================
echo  Step 1: Build HAP
echo ========================================
cd /d %PROJECT%
"D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" assembleHap --mode module -p product=default --no-daemon

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [FAIL] BUILD FAILED - check errors above
    pause
    exit /b 1
)

echo.
echo ========================================
echo  Step 2: Verify HAP
echo ========================================
if exist "%HAP%" (
    echo [OK] HAP file exists: %HAP%
    for %%A in ("%HAP%") do echo [OK] Size: %%~zA bytes
) else (
    echo [FAIL] HAP not found!
    pause
    exit /b 1
)

echo.
echo ========================================
echo  Step 3: Install to Emulator
echo ========================================
echo.
echo Option A: Use DevEco Studio
echo   1. Open DevEco Studio
echo   2. File ^> Open ^> select harmony-app folder
echo   3. Click Run (green triangle) or Shift+F10
echo   4. Select emulator device
echo.
echo Option B: Command line (if hdc available)
echo   hdc install "%HAP%"
echo   hdc shell aa start -a EntryAbility -b com.example.textclock
echo.
echo ========================================
echo  BUILD SUCCEEDED - HAP ready
echo ========================================
echo.
echo HAP location:
echo   %HAP%
echo.
pause
