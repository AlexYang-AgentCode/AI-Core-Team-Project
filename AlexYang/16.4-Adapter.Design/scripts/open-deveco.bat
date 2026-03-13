@echo off
REM ============================================
REM  Open TextClock project in DevEco Studio
REM ============================================

set DEVECO="D:\Program Files\Huawei\DevEco Studio\bin\devecostudio64.exe"
set PROJECT=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app

echo.
echo ========================================
echo  Opening TextClock in DevEco Studio
echo ========================================
echo.
echo Project: %PROJECT%
echo.

if exist %DEVECO% (
    start "" %DEVECO% %PROJECT%
    echo [OK] DevEco Studio is starting...
    echo.
    echo Next steps:
    echo   1. Wait for project sync to complete
    echo   2. File ^> Project Structure ^> Signing Configs
    echo      - Check "Automatically generate signature"
    echo      - Sign in with Huawei account if needed
    echo   3. Tools ^> Device Manager ^> Start emulator
    echo   4. Click Run (green triangle) or Shift+F10
) else (
    echo [ERROR] DevEco Studio not found at:
    echo   %DEVECO%
    echo.
    echo Please install DevEco Studio first.
)
echo.
pause
