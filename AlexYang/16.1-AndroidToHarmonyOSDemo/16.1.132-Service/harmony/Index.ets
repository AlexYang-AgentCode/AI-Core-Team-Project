// HarmonyOS ArkTS equivalent of Android Service demo (MainActivity)
// Android: startService/bindService → HarmonyOS: startServiceExtensionAbility/connectServiceExtensionAbility

import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import promptAction from '@ohos.promptAction';
import rpc from '@ohos.rpc';

@Entry
@Component
struct ServiceDemoPage {
  @State boundServiceConnected: boolean = false;
  @State bindButtonText: string = 'Bind to BoundService';
  @State statusText: string = '';

  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private connectionId: number = -1;

  // ServiceConnection equivalent: connectServiceExtensionAbility callback
  private serviceConnection: common.ConnectOptions = {
    onConnect: (elementName, remoteProxy) => {
      promptAction.showToast({ message: 'BoundService is connected' });
      this.bindButtonText = 'Disconnect from BoundService';
      this.boundServiceConnected = true;
      this.statusText = 'Connected to BoundService';
    },
    onDisconnect: (elementName) => {
      promptAction.showToast({ message: 'Service is disconnected' });
      this.bindButtonText = 'Bind to BoundService';
      this.boundServiceConnected = false;
      this.statusText = 'Disconnected from BoundService';
    },
    onFailed: (code) => {
      this.statusText = 'Service connection failed, code: ' + code;
    },
  };

  private startOverlayService(): void {
    const want: Want = {
      bundleName: 'com.example.servicedemo',
      abilityName: 'OverlayServiceAbility',
    };
    try {
      this.context.startServiceExtensionAbility(want).then(() => {
        this.statusText = 'OverlayService started';
      }).catch((err: Error) => {
        this.statusText = 'Start OverlayService failed: ' + err.message;
      });
    } catch (err) {
      this.statusText = 'Error: ' + (err as Error).message;
    }
  }

  private startIntentService(): void {
    // IntentService equivalent: start a ServiceExtensionAbility that auto-stops
    const want: Want = {
      bundleName: 'com.example.servicedemo',
      abilityName: 'MyIPServiceAbility',
    };
    try {
      this.context.startServiceExtensionAbility(want).then(() => {
        this.statusText = 'IntentService (IP fetch) started';
      }).catch((err: Error) => {
        this.statusText = 'Start IntentService failed: ' + err.message;
      });
    } catch (err) {
      this.statusText = 'Error: ' + (err as Error).message;
    }
  }

  private toggleBoundService(): void {
    if (!this.boundServiceConnected) {
      // Bind to service
      const want: Want = {
        bundleName: 'com.example.servicedemo',
        abilityName: 'BoundServiceAbility',
      };
      try {
        this.connectionId = this.context.connectServiceExtensionAbility(want, this.serviceConnection);
      } catch (err) {
        this.statusText = 'Bind failed: ' + (err as Error).message;
      }
    } else {
      // Unbind from service
      try {
        this.context.disconnectServiceExtensionAbility(this.connectionId).then(() => {
          this.bindButtonText = 'Bind to BoundService';
          this.boundServiceConnected = false;
          this.statusText = 'Unbound from BoundService';
        });
      } catch (err) {
        this.statusText = 'Unbind failed: ' + (err as Error).message;
      }
    }
  }

  aboutToDisappear(): void {
    // Equivalent of onStop: unbind if still connected
    if (this.boundServiceConnected && this.connectionId >= 0) {
      try {
        this.context.disconnectServiceExtensionAbility(this.connectionId);
      } catch (err) {
        console.error('Disconnect failed: ' + (err as Error).message);
      }
    }
  }

  build() {
    Column() {
      Text('Service Demo')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 24 })

      Button('Start OverlayService')
        .width('80%')
        .margin({ bottom: 12 })
        .onClick(() => {
          this.startOverlayService();
        })

      Button('Start IntentService (Get IP)')
        .width('80%')
        .margin({ bottom: 12 })
        .onClick(() => {
          this.startIntentService();
        })

      Button(this.bindButtonText)
        .width('80%')
        .margin({ bottom: 12 })
        .onClick(() => {
          this.toggleBoundService();
        })

      Button('Finish Activity')
        .width('80%')
        .margin({ bottom: 24 })
        .backgroundColor(Color.Gray)
        .onClick(() => {
          this.context.terminateSelf();
        })

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
