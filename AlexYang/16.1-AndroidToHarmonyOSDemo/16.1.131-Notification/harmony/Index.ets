// HarmonyOS ArkTS equivalent of Android Notification demo
// Android: NotificationManager + NotificationCompat.Builder → HarmonyOS: @ohos.notificationManager

import notificationManager from '@ohos.notificationManager';
import wantAgent from '@ohos.app.ability.wantAgent';
import promptAction from '@ohos.promptAction';

const NOTIFICATION_ID: number = 1;
const DEFAULT_TIMER_DURATION: number = 2000;

@Entry
@Component
struct NotificationPage {
  @State secondsInput: string = '';
  @State statusText: string = '';

  async createNotification(): Promise<void> {
    let seconds = DEFAULT_TIMER_DURATION / 1000;
    if (this.secondsInput && this.secondsInput.trim() !== '') {
      seconds = parseInt(this.secondsInput);
    }
    const millis = seconds * 1000;

    promptAction.showToast({ message: 'Timer started!' });
    this.statusText = `Notification in ${seconds} seconds...`;

    // Wait for the timer duration
    await new Promise<void>((resolve) => {
      setTimeout(() => { resolve(); }, millis);
    });

    // Build WantAgent for notification tap action
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [
        {
          bundleName: 'com.example.notification',
          abilityName: 'EntryAbility',
          parameters: {
            message: 'This is my awesome text for notification!',
          },
        },
      ],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
    };

    let agent: object | undefined;
    try {
      agent = await wantAgent.getWantAgent(wantAgentInfo);
    } catch (err) {
      console.error('getWantAgent failed: ' + (err as Error).message);
    }

    // Publish notification
    const notificationRequest: notificationManager.NotificationRequest = {
      id: NOTIFICATION_ID,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_LONG_TEXT,
        longText: {
          title: 'Notification',
          text: 'Ping!',
          longText: 'This is my awesome text for notification!',
          briefText: 'Notification',
          expandedTitle: 'Notification Details',
        },
      },
      wantAgent: agent,
    };

    try {
      await notificationManager.publish(notificationRequest);
      this.statusText = 'Notification published!';
    } catch (err) {
      this.statusText = 'Publish failed: ' + (err as Error).message;
    }
  }

  async dismissNotification(): Promise<void> {
    try {
      await notificationManager.cancel(NOTIFICATION_ID);
      this.statusText = 'Notification dismissed.';
    } catch (err) {
      this.statusText = 'Dismiss failed: ' + (err as Error).message;
    }
  }

  async snoozeNotification(): Promise<void> {
    try {
      await notificationManager.cancel(NOTIFICATION_ID);
      this.statusText = 'Snoozing... will re-notify in 20s';
      await new Promise<void>((resolve) => {
        setTimeout(() => { resolve(); }, 20000);
      });
      await this.createNotification();
    } catch (err) {
      this.statusText = 'Snooze failed: ' + (err as Error).message;
    }
  }

  build() {
    Column() {
      Text('Simple Notification')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      TextInput({ placeholder: 'Seconds before notification', text: this.secondsInput })
        .type(InputType.Number)
        .width('100%')
        .margin({ bottom: 12 })
        .onChange((value: string) => {
          this.secondsInput = value;
        })

      Button('Create Notification')
        .width('100%')
        .margin({ bottom: 8 })
        .onClick(() => {
          this.createNotification();
        })

      Button('Dismiss Notification')
        .width('100%')
        .margin({ bottom: 8 })
        .onClick(() => {
          this.dismissNotification();
        })

      Button('Snooze Notification')
        .width('100%')
        .margin({ bottom: 16 })
        .onClick(() => {
          this.snoozeNotification();
        })

      if (this.statusText) {
        Text(this.statusText)
          .fontSize(14)
          .fontColor('#666666')
      }
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Center)
  }
}
