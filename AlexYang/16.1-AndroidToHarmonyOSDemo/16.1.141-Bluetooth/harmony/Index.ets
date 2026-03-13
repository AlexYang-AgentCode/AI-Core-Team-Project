// HarmonyOS ArkTS equivalent of Android BLE Scanner demo
// Android: BluetoothAdapter + BluetoothLeScanner → HarmonyOS: @ohos.bluetooth.ble + @ohos.bluetooth.access

import { ble } from '@kit.ConnectivityKit';
import { access } from '@kit.ConnectivityKit';
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';

// Device info model — mirrors BluetoothDevice.getName() / getAddress()
interface BleDeviceInfo {
  deviceName: string;
  deviceId: string;
  rssi: number;
}

@Entry
@Component
struct BluetoothPage {
  @State deviceList: BleDeviceInfo[] = [];
  @State scanLog: string = '';
  @State isScanning: boolean = false;
  @State startScanVisible: boolean = true;
  @State stopScanVisible: boolean = false;

  private context: common.UIAbilityContext | undefined = undefined;

  aboutToAppear(): void {
    this.context = getContext(this) as common.UIAbilityContext;
    this.checkBluetoothAndPermissions();
  }

  aboutToDisappear(): void {
    if (this.isScanning) {
      this.stopScanning();
    }
  }

  // Android: btAdapter.isEnabled() check + permission request
  // HarmonyOS: access.getState() + requestPermissionsFromUser
  private async checkBluetoothAndPermissions(): Promise<void> {
    // Android: BluetoothAdapter.isEnabled()
    // HarmonyOS: access.getState()
    try {
      const btState = access.getState();
      if (btState !== access.BluetoothState.STATE_ON) {
        this.scanLog = 'Bluetooth is not enabled. Please turn on Bluetooth.\n';
        return;
      }
    } catch (error) {
      this.scanLog = `Bluetooth state check failed: ${JSON.stringify(error)}\n`;
      return;
    }

    // Android: checkSelfPermission(ACCESS_COARSE_LOCATION) + requestPermissions
    // HarmonyOS: requestPermissionsFromUser(['ohos.permission.ACCESS_BLUETOOTH'])
    const permissions: Permissions[] = ['ohos.permission.ACCESS_BLUETOOTH'];
    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(this.context!, permissions);
      if (result.authResults[0] !== 0) {
        this.scanLog = 'Bluetooth permission denied.\n';
      }
    } catch (error) {
      this.scanLog = `Permission request failed: ${JSON.stringify(error)}\n`;
    }
  }

  // Android: btScanner.startScan(leScanCallback)
  // HarmonyOS: ble.on('BLEDeviceFind') + ble.startBLEScan
  startScanning(): void {
    console.info('start scanning');
    this.scanLog = '';
    this.deviceList = [];
    this.startScanVisible = false;
    this.stopScanVisible = true;
    this.isScanning = true;

    // Android: LeScanCallback.onScanResult → HarmonyOS: ble.on('BLEDeviceFind')
    try {
      ble.on('BLEDeviceFind', (results: Array<ble.ScanResult>) => {
        for (const scanResult of results) {
          // Android: result.getDevice().getName() → scanResult.deviceName
          // Android: result.getDevice().getAddress() → scanResult.deviceId
          // Android: result.getRssi() → scanResult.rssi
          const deviceName = scanResult.deviceName || 'Unknown';
          const deviceId = scanResult.deviceId;
          const rssi = scanResult.rssi;

          // Check for duplicate
          const exists = this.deviceList.some(d => d.deviceId === deviceId);
          if (!exists) {
            const deviceInfo: BleDeviceInfo = {
              deviceName: deviceName,
              deviceId: deviceId,
              rssi: rssi
            };
            this.deviceList = [...this.deviceList, deviceInfo];
          }

          // Mirrors peripheralTextView.append(...)
          this.scanLog += `Device Name: ${deviceName} rssi: ${rssi}\n`;
        }
      });

      // Android: btScanner.startScan(leScanCallback) with empty filter
      ble.startBLEScan(null);
    } catch (error) {
      this.scanLog += `Scan start failed: ${JSON.stringify(error)}\n`;
      this.isScanning = false;
    }
  }

  // Android: btScanner.stopScan(leScanCallback)
  // HarmonyOS: ble.stopBLEScan() + ble.off('BLEDeviceFind')
  stopScanning(): void {
    console.info('stopping scanning');
    this.startScanVisible = true;
    this.stopScanVisible = false;
    this.isScanning = false;

    try {
      ble.stopBLEScan();
      ble.off('BLEDeviceFind');
      this.scanLog += 'Stopped Scanning\n';
    } catch (error) {
      this.scanLog += `Scan stop failed: ${JSON.stringify(error)}\n`;
    }
  }

  build() {
    Column() {
      // Header
      Text('Hello Bluetooth Scanners!')
        .fontSize(16)
        .margin({ bottom: 16 })

      // Scan/Stop buttons — mirrors StartScanButton / StopScanButton
      Row() {
        if (this.startScanVisible) {
          Button('Scan')
            .width(100)
            .height(50)
            .onClick(() => this.startScanning())
        }

        if (this.stopScanVisible) {
          Button('Stop Scanning')
            .height(50)
            .onClick(() => this.stopScanning())
        }
      }
      .margin({ bottom: 16 })

      // Device list — Android: TextView with scrolling → HarmonyOS: List + ForEach
      List({ space: 4 }) {
        ForEach(this.deviceList, (device: BleDeviceInfo) => {
          ListItem() {
            Row() {
              Column() {
                Text(device.deviceName)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                Text(device.deviceId)
                  .fontSize(12)
                  .fontColor('#888888')
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              Text(`${device.rssi} dBm`)
                .fontSize(14)
                .fontColor('#666666')
            }
            .width('100%')
            .padding(8)
          }
        }, (device: BleDeviceInfo) => device.deviceId)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 1, color: '#EEEEEE' })

      // Raw scan log — mirrors peripheralTextView scrollable text
      Scroll() {
        Text(this.scanLog)
          .fontSize(12)
          .fontFamily('monospace')
          .width('100%')
      }
      .height(120)
      .width('100%')
      .margin({ top: 8 })
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .padding(16)
  }
}
