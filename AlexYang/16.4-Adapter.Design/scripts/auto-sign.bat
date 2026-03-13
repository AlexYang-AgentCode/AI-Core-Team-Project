@echo off
chcp 65001 >nul
REM ============================================
REM  Auto-sign HAP for debug - OpenHarmony style
REM ============================================

set JAVA=D:\Program Files\Huawei\DevEco Studio\jbr\bin\java.exe
set SIGN_TOOL="D:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar"
set PROJECT=D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app
set HAP_UNSIGNED=%PROJECT%\entry\build\default\outputs\default\entry-default-unsigned.hap
set HAP_SIGNED=%PROJECT%\entry\build\default\outputs\default\entry-default-signed.hap
set SD=%PROJECT%\sign-config
set KS=%SD%\debug.p12
set KP=123456

echo.
echo ========================================
echo  Auto-Sign TextClock HAP (OpenHarmony)
echo ========================================
echo.

if not exist "%SD%" mkdir "%SD%"

REM Clean previous
del /q "%SD%\*.cer" "%SD%\*.csr" "%SD%\*.p7b" "%SD%\*.p12" 2>nul

REM === Step 1: Root CA keypair + cert ===
echo [1/7] Root CA...
"%JAVA%" -jar %SIGN_TOOL% generate-keypair -keyAlias "rootCA" -keyPwd %KP% -keyAlg ECC -keySize NIST-P-256 -keystoreFile "%KS%" -keystorePwd %KP%
"%JAVA%" -jar %SIGN_TOOL% generate-ca -keyAlias "rootCA" -keyPwd %KP% -subject "C=CN,O=Debug,OU=Debug,CN=Root CA" -validity 3650 -signAlg SHA256withECDSA -keystoreFile "%KS%" -keystorePwd %KP% -outFile "%SD%\rootCA.cer" -keyAlg ECC -keySize NIST-P-256
echo.

REM === Step 2: Sub CA for app signing ===
echo [2/7] App Sub CA...
"%JAVA%" -jar %SIGN_TOOL% generate-keypair -keyAlias "appSubCA" -keyPwd %KP% -keyAlg ECC -keySize NIST-P-256 -keystoreFile "%KS%" -keystorePwd %KP%
"%JAVA%" -jar %SIGN_TOOL% generate-ca -keyAlias "appSubCA" -keyPwd %KP% -keyAlg ECC -keySize NIST-P-256 -issuer "C=CN,O=Debug,OU=Debug,CN=Root CA" -issuerKeyAlias "rootCA" -issuerKeyPwd %KP% -subject "C=CN,O=Debug,OU=Debug,CN=App Sign CA" -validity 3650 -signAlg SHA256withECDSA -keystoreFile "%KS%" -keystorePwd %KP% -outFile "%SD%\appSubCA.cer" -basicConstraintsPathLen 0
echo.

REM === Step 3: Sub CA for profile signing ===
echo [3/7] Profile Sub CA...
"%JAVA%" -jar %SIGN_TOOL% generate-keypair -keyAlias "profileSubCA" -keyPwd %KP% -keyAlg ECC -keySize NIST-P-256 -keystoreFile "%KS%" -keystorePwd %KP%
"%JAVA%" -jar %SIGN_TOOL% generate-ca -keyAlias "profileSubCA" -keyPwd %KP% -keyAlg ECC -keySize NIST-P-256 -issuer "C=CN,O=Debug,OU=Debug,CN=Root CA" -issuerKeyAlias "rootCA" -issuerKeyPwd %KP% -subject "C=CN,O=Debug,OU=Debug,CN=Profile Sign CA" -validity 3650 -signAlg SHA256withECDSA -keystoreFile "%KS%" -keystorePwd %KP% -outFile "%SD%\profileSubCA.cer" -basicConstraintsPathLen 0
echo.

REM === Step 4: App signing key + cert chain ===
echo [4/7] App cert chain...
"%JAVA%" -jar %SIGN_TOOL% generate-keypair -keyAlias "appKey" -keyPwd %KP% -keyAlg ECC -keySize NIST-P-256 -keystoreFile "%KS%" -keystorePwd %KP%
"%JAVA%" -jar %SIGN_TOOL% generate-app-cert -keyAlias "appKey" -keyPwd %KP% -issuer "C=CN,O=Debug,OU=Debug,CN=App Sign CA" -issuerKeyAlias "appSubCA" -issuerKeyPwd %KP% -subject "C=CN,O=Debug,OU=Debug,CN=TextClock Debug" -validity 3650 -signAlg SHA256withECDSA -keystoreFile "%KS%" -keystorePwd %KP% -outForm certChain -rootCaCertFile "%SD%\rootCA.cer" -subCaCertFile "%SD%\appSubCA.cer" -outFile "%SD%\app-debug-cert.cer"
echo.

REM === Step 5: Profile signing key + cert chain ===
echo [5/7] Profile cert chain...
"%JAVA%" -jar %SIGN_TOOL% generate-keypair -keyAlias "profileKey" -keyPwd %KP% -keyAlg ECC -keySize NIST-P-256 -keystoreFile "%KS%" -keystorePwd %KP%
"%JAVA%" -jar %SIGN_TOOL% generate-profile-cert -keyAlias "profileKey" -keyPwd %KP% -issuer "C=CN,O=Debug,OU=Debug,CN=Profile Sign CA" -issuerKeyAlias "profileSubCA" -issuerKeyPwd %KP% -subject "C=CN,O=Debug,OU=Debug,CN=TextClock Profile Debug" -validity 3650 -signAlg SHA256withECDSA -keystoreFile "%KS%" -keystorePwd %KP% -outForm certChain -rootCaCertFile "%SD%\rootCA.cer" -subCaCertFile "%SD%\profileSubCA.cer" -outFile "%SD%\profile-debug-cert.cer"
echo.

REM === Step 6: Sign provision profile ===
echo [6/7] Sign provision profile...
REM Create provision profile JSON
(
echo {
echo   "version-name": "2.0.0",
echo   "version-code": 2,
echo   "uuid": "textclock-debug-20260310",
echo   "type": "debug",
echo   "app-distribution-type": "os_integration",
echo   "bundle-info": {
echo     "developer-id": "debug-dev-001",
echo     "distribution-certificate": "",
echo     "bundle-name": "com.example.textclock",
echo     "apl": "normal",
echo     "app-feature": "hos_normal_app"
echo   },
echo   "acls": {
echo     "allowed-acls": []
echo   },
echo   "permissions": {
echo     "restricted-permissions": []
echo   },
echo   "issuer": "pki_internal",
echo   "validity": {
echo     "not-before": 1577808000,
echo     "not-after": 1893427200
echo   }
echo }
) > "%SD%\provision.json"

"%JAVA%" -jar %SIGN_TOOL% sign-profile -mode localSign -keyAlias "profileKey" -keyPwd %KP% -profileCertFile "%SD%\profile-debug-cert.cer" -inFile "%SD%\provision.json" -signAlg SHA256withECDSA -keystoreFile "%KS%" -keystorePwd %KP% -outFile "%SD%\debug-profile.p7b"
if %ERRORLEVEL% NEQ 0 (
    echo [FAIL] Profile signing failed!
    goto :end
)
echo.

REM === Step 7: Sign HAP ===
echo [7/7] Sign HAP...
if not exist "%HAP_UNSIGNED%" (
    echo [FAIL] Unsigned HAP not found! Run build.bat first.
    goto :end
)

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
