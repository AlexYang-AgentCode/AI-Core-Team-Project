@echo off
chcp 65001 >nul
REM ============================================
REM  Install and Run signed HAP on emulator
REM ============================================

set HDC="D:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe"
set HAP_SIGNED=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app\entry\build\default\outputs\default\entry-default-signed.hap
set BUNDLE=com.example.textclock
set ABILITY=EntryAbility

echo.
echo ========================================
echo  Install ^& Run TextClock HAP
echo ========================================
echo.

REM Check device connection
echo [1/4] Checking device connection...
%HDC% list targets
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] No device connected! Start emulator first.
    goto :end
)

REM Get device UDID for reference
echo.
echo [2/4] Getting device UDID...
%HDC% shell bm get --udid
echo.

REM Install HAP
echo [3/4] Installing HAP...
%HDC% install "%HAP_SIGNED%"
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Installation failed!
    echo.
    echo Possible causes:
    echo   - Device UDID not in provision profile debug-info
    echo   - Need to re-sign with correct device UDID
    goto :end
)
echo [OK] HAP installed successfully.

REM Launch app
echo.
echo [4/4] Launching app...
%HDC% shell aa start -a %ABILITY% -b %BUNDLE%
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo [OK] TextClock app launched!
    echo ========================================
) else (
    echo [FAIL] Failed to launch app.
)

:end
echo.
pause
