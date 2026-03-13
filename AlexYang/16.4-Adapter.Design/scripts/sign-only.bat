@echo off
chcp 65001 >nul
set JAVA=D:\Program Files\Huawei\DevEco Studio\jbr\bin\java.exe
set SIGN_TOOL="D:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar"
set SD=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app\sign-config
set KS=%SD%\debug.p12
set KP=123456
set HAP_UNSIGNED=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app\entry\build\default\outputs\default\entry-default-unsigned.hap
set HAP_SIGNED=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app\entry\build\default\outputs\default\entry-default-signed.hap

echo [Step 6] Sign provision profile...
"%JAVA%" -jar %SIGN_TOOL% sign-profile -mode localSign -keyAlias "profileKey" -keyPwd %KP% -profileCertFile "%SD%\profile-debug-cert.cer" -inFile "%SD%\provision.json" -signAlg SHA256withECDSA -keystoreFile "%KS%" -keystorePwd %KP% -outFile "%SD%\debug-profile.p7b"
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Profile signing failed!
    exit /b 1
)
echo [OK] Profile signed.

echo [Step 7] Sign HAP...
"%JAVA%" -jar %SIGN_TOOL% sign-app -mode localSign -keyAlias "appKey" -keyPwd %KP% -appCertFile "%SD%\app-debug-cert.cer" -profileFile "%SD%\debug-profile.p7b" -profileSigned 1 -inFile "%HAP_UNSIGNED%" -signAlg SHA256withECDSA -keystoreFile "%KS%" -keystorePwd %KP% -outFile "%HAP_SIGNED%" -compatibleVersion 12 -signCode 1
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo [OK] HAP SIGNED SUCCESSFULLY!
    echo ========================================
    for %%A in ("%HAP_SIGNED%") do echo Size: %%~zA bytes
) else (
    echo [FAIL] HAP signing failed!
)
