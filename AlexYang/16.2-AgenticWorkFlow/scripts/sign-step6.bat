@echo off
chcp 65001 >nul
set JAVA=D:\Program Files\Huawei\DevEco Studio\jbr\bin\java.exe
set SIGN_TOOL="D:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar"
set SD=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app\sign-config
set KS=%SD%\debug.p12
set KP=123456
set HAP_UNSIGNED=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app\entry\build\default\outputs\default\entry-default-unsigned.hap
set HAP_SIGNED=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app\entry\build\default\outputs\default\entry-default-signed.hap

REM Read app cert and strip PEM headers into single line
setlocal EnableDelayedExpansion
set "CERT_B64="
for /f "usebackq tokens=*" %%a in ("%SD%\app-debug-cert.cer") do (
    set "line=%%a"
    if "!line:BEGIN=!" == "!line!" if "!line:END=!" == "!line!" (
        set "CERT_B64=!CERT_B64!%%a"
    )
)

echo Creating provision profile with embedded cert...

REM Write provision.json with PowerShell to handle the long cert string
powershell -Command "$cert = (Get-Content '%SD%\app-debug-cert.cer' | Where-Object {$_ -notmatch 'BEGIN|END'}) -join ''; $json = @{ 'version-name' = '2.0.0'; 'version-code' = 2; 'uuid' = 'textclock-debug-20260310'; 'type' = 'debug'; 'app-distribution-type' = 'os_integration'; 'bundle-info' = @{ 'developer-id' = 'debug-dev-001'; 'distribution-certificate' = $cert; 'bundle-name' = 'com.example.textclock'; 'apl' = 'normal'; 'app-feature' = 'hos_normal_app' }; 'acls' = @{ 'allowed-acls' = @() }; 'permissions' = @{ 'restricted-permissions' = @() }; 'issuer' = 'pki_internal'; 'validity' = @{ 'not-before' = 1577808000; 'not-after' = 1893427200 } }; $json | ConvertTo-Json -Depth 5 | Set-Content '%SD%\provision.json' -Encoding UTF8"

echo [6/7] Signing provision profile...
"%JAVA%" -jar %SIGN_TOOL% sign-profile -mode localSign -keyAlias "profileKey" -keyPwd %KP% -profileCertFile "%SD%\profile-debug-cert.cer" -inFile "%SD%\provision.json" -signAlg SHA256withECDSA -keystoreFile "%KS%" -keystorePwd %KP% -outFile "%SD%\debug-profile.p7b"
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Profile signing failed!
    goto :end
)

echo [7/7] Signing HAP...
"%JAVA%" -jar %SIGN_TOOL% sign-app -mode localSign -keyAlias "appKey" -keyPwd %KP% -appCertFile "%SD%\app-debug-cert.cer" -profileFile "%SD%\debug-profile.p7b" -profileSigned 1 -inFile "%HAP_UNSIGNED%" -signAlg SHA256withECDSA -keystoreFile "%KS%" -keystorePwd %KP% -outFile "%HAP_SIGNED%" -compatibleVersion 12 -signCode 1

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo [OK] HAP SIGNED SUCCESSFULLY!
    echo ========================================
    echo Signed HAP: %HAP_SIGNED%
    for %%A in ("%HAP_SIGNED%") do echo Size: %%~zA bytes
) else (
    echo [FAIL] HAP signing failed!
)

:end
echo.
pause
