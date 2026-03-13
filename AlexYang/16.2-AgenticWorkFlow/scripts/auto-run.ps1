# Auto-run TextClock in DevEco Studio
# Brings DevEco to foreground, waits, then tries to trigger Run

Add-Type -AssemblyName System.Windows.Forms

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
}
"@

$process = Get-Process devecostudio64 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($process) {
    Write-Host "[OK] DevEco Studio found (PID: $($process.Id))"
    [Win32]::ShowWindow($process.MainWindowHandle, 9) # SW_RESTORE
    [Win32]::SetForegroundWindow($process.MainWindowHandle)
    Start-Sleep -Seconds 3
    Write-Host "[OK] DevEco Studio brought to foreground"
    Write-Host ""
    Write-Host "=== Next Steps (in DevEco Studio) ==="
    Write-Host "1. Click 'Previewer' tab on the right panel to preview UI"
    Write-Host "2. Or: File > Project Structure > Signing Configs"
    Write-Host "   - Check 'Automatically generate signature'"
    Write-Host "3. Then: Tools > Device Manager > Create emulator"
    Write-Host "4. Finally: Click Run (green triangle) or Shift+F10"
} else {
    Write-Host "[ERROR] DevEco Studio not running"
    Write-Host "Starting DevEco Studio..."
    Start-Process "D:\Program Files\Huawei\DevEco Studio\bin\devecostudio64.exe" -ArgumentList "D:\ObsidianVault\10-Projects\16-DigitalEmployee\16.1-AndroidToHarmonyOSDemo\harmony-app"
}
