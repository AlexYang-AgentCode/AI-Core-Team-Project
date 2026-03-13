@echo off
set DEVECO_SDK_HOME=D:\Program Files\Huawei\DevEco Studio\sdk
set JAVA_HOME=D:\Program Files\Huawei\DevEco Studio\jbr
set NODE_HOME=D:\Program Files\Huawei\DevEco Studio\tools\node
set PATH=%JAVA_HOME%\bin;%PATH%
set HVIGOR_USER_HOME=D:\HvigorHome
cd /d D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app
"D:\Program Files\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.bat" tasks --no-daemon
