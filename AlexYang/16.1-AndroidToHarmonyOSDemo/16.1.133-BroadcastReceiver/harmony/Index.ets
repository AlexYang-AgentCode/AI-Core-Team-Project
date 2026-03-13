// HarmonyOS ArkTS equivalent of Android BroadcastReceiver battery demo
// Android: BroadcastReceiver + IntentFilter → HarmonyOS: commonEventManager.subscribe

import commonEventManager from '@ohos.commonEventManager';
import batteryInfo from '@ohos.batteryInfo';

@Entry
@Component
struct BroadcastReceiverPage {
  @State batteryText: string = 'Battery: --';
  @State isSubscribed: boolean = false;
  @State statusText: string = '';

  private subscriber: commonEventManager.CommonEventSubscriber | null = null;

  async aboutToAppear(): Promise<void> {
    // Register battery broadcast receiver on page appear (equivalent of onResume)
    await this.registerBatteryReceiver();
    // Also read current battery level immediately
    this.readCurrentBattery();
  }

  aboutToDisappear(): void {
    // Unregister on page disappear (equivalent of onPause)
    this.unregisterBatteryReceiver();
  }

  private readCurrentBattery(): void {
    // Direct battery info read as a supplement
    try {
      const level = batteryInfo.batterySOC;
      this.batteryText = 'Battery: ' + level + '%';
    } catch (err) {
      console.error('Read battery failed: ' + (err as Error).message);
    }
  }

  private async registerBatteryReceiver(): Promise<void> {
    // Equivalent of registerReceiver(batteryReceiver, new IntentFilter(ACTION_BATTERY_CHANGED))
    const subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
      events: [commonEventManager.Support.COMMON_EVENT_BATTERY_CHANGED],
    };

    try {
      this.subscriber = await commonEventManager.createSubscriber(subscribeInfo);
      commonEventManager.subscribe(this.subscriber, (err, data: commonEventManager.CommonEventData) => {
        if (err) {
          console.error('Subscribe callback error: ' + err.message);
          return;
        }
        // Equivalent of intent.getIntExtra(BatteryManager.EXTRA_LEVEL)
        // In HarmonyOS, battery level comes from the event data or batteryInfo API
        const level = data.code; // battery level percentage
        if (level >= 0) {
          this.batteryText = 'Battery: ' + level + '%';
        } else {
          // Fallback to direct API
          this.readCurrentBattery();
        }
      });
      this.isSubscribed = true;
      this.statusText = 'Battery receiver registered';
    } catch (err) {
      this.statusText = 'Register failed: ' + (err as Error).message;
    }
  }

  private unregisterBatteryReceiver(): void {
    // Equivalent of unregisterReceiver(batteryReceiver)
    if (this.subscriber) {
      try {
        commonEventManager.unsubscribe(this.subscriber, (err) => {
          if (err) {
            console.error('Unsubscribe error: ' + err.message);
          }
        });
        this.isSubscribed = false;
        this.subscriber = null;
        this.statusText = 'Battery receiver unregistered';
      } catch (err) {
        this.statusText = 'Unregister failed: ' + (err as Error).message;
      }
    }
  }

  build() {
    Column() {
      Text('Broadcast Receiver Demo')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 24 })

      Text(this.batteryText)
        .fontSize(36)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 24 })

      Row() {
        Button(this.isSubscribed ? 'Unsubscribe' : 'Subscribe')
          .margin({ right: 12 })
          .onClick(() => {
            if (this.isSubscribed) {
              this.unregisterBatteryReceiver();
            } else {
              this.registerBatteryReceiver();
            }
          })

        Button('Refresh')
          .onClick(() => {
            this.readCurrentBattery();
          })
      }

      if (this.statusText) {
        Text(this.statusText)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
