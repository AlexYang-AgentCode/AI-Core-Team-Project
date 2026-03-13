@echo off
set JAVA_HOME=D:\Program Files\Huawei\DevEco Studio\jbr
set SIGN_TOOL="D:\Program Files\Huawei\DevEco Studio\sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar"
"%JAVA_HOME%\bin\java.exe" -jar %SIGN_TOOL% -h
