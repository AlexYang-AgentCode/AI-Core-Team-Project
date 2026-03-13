// HarmonyOS ArkTS equivalent of Android Service classes
// Android: Service/IntentService/BoundService → HarmonyOS: ServiceExtensionAbility

import ServiceExtensionAbility from '@ohos.app.ability.ServiceExtensionAbility';
import Want from '@ohos.app.ability.Want';
import rpc from '@ohos.rpc';
import http from '@ohos.net.http';
import notificationManager from '@ohos.notificationManager';
import wantAgent from '@ohos.app.ability.wantAgent';

// ============================================================
// BoundServiceAbility - equivalent of Android BoundService
// Android: extends Service with onBind returning IBinder
// ============================================================
export class BoundServiceAbility extends ServiceExtensionAbility {
  onCreate(want: Want): void {
    console.info('BoundServiceAbility onCreate');
  }

  onRequest(want: Want, startId: number): void {
    console.info('BoundServiceAbility onRequest, startId: ' + startId);
  }

  onConnect(want: Want): rpc.RemoteObject {
    console.info('BoundServiceAbility onConnect');
    // Return a RemoteObject for IPC communication
    // Equivalent of returning IBinder / LocalBinder in Android
    return new BoundServiceStub('BoundServiceAbility');
  }

  onDisconnect(want: Want): void {
    console.info('BoundServiceAbility onDisconnect');
  }

  onDestroy(): void {
    console.info('BoundServiceAbility onDestroy');
  }
}

class BoundServiceStub extends rpc.RemoteObject {
  constructor(descriptor: string) {
    super(descriptor);
  }

  onRemoteMessageRequest(code: number, data: rpc.MessageSequence,
    reply: rpc.MessageSequence, option: rpc.MessageOption): boolean | Promise<boolean> {
    // Handle IPC messages here, equivalent of Binder methods
    console.info('BoundServiceStub onRemoteMessageRequest, code: ' + code);
    return true;
  }
}

// ============================================================
// MyIPServiceAbility - equivalent of Android MyIPIntentService
// Android: extends IntentService, auto-stops after onHandleIntent
// ============================================================
export class MyIPServiceAbility extends ServiceExtensionAbility {
  private readonly NOTIFICATION_ID: number = 96;
  private readonly IP_URL: string = 'http://ip.jsontest.com';

  onCreate(want: Want): void {
    console.info('MyIPServiceAbility onCreate');
  }

  onRequest(want: Want, startId: number): void {
    console.info('MyIPServiceAbility onRequest, startId: ' + startId);
    // Equivalent of IntentService.onHandleIntent - runs task then self-stops
    this.fetchIPAndNotify();
  }

  private async fetchIPAndNotify(): Promise<void> {
    let ipAddress = "couldn't get IP";
    const httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(this.IP_URL, {
        method: http.RequestMethod.GET,
        connectTimeout: 10000,
        readTimeout: 10000,
      });

      if (response.responseCode === http.ResponseCode.OK) {
        const result = JSON.parse(response.result as string) as Record<string, string>;
        ipAddress = result['ip'] || ipAddress;
      }
    } catch (err) {
      console.error('IP fetch failed: ' + (err as Error).message);
    } finally {
      httpRequest.destroy();
    }

    // Show notification with IP address
    await this.showNotification('My IP Address: ', ipAddress);

    // IntentService auto-stops: equivalent of stopSelf()
    this.context.terminateSelf();
  }

  private async showNotification(title: string, text: string): Promise<void> {
    const wantAgentInfo: wantAgent.WantAgentInfo = {
      wants: [{
        bundleName: 'com.example.servicedemo',
        abilityName: 'EntryAbility',
      }],
      operationType: wantAgent.OperationType.START_ABILITY,
      requestCode: 0,
    };

    let agent: object | undefined;
    try {
      agent = await wantAgent.getWantAgent(wantAgentInfo);
    } catch (err) {
      console.error('getWantAgent failed');
    }

    const request: notificationManager.NotificationRequest = {
      id: this.NOTIFICATION_ID,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: title,
          text: text,
        },
      },
      wantAgent: agent,
    };

    try {
      await notificationManager.publish(request);
    } catch (err) {
      console.error('Notification publish failed: ' + (err as Error).message);
    }
  }

  onConnect(want: Want): rpc.RemoteObject | null {
    return null;
  }

  onDisconnect(want: Want): void {
    console.info('MyIPServiceAbility onDisconnect');
  }

  onDestroy(): void {
    console.info('MyIPServiceAbility onDestroy');
  }
}

// ============================================================
// OverlayServiceAbility - equivalent of Android OverlayService
// Android: Service with WindowManager overlay, START_STICKY
// ============================================================
export class OverlayServiceAbility extends ServiceExtensionAbility {
  onCreate(want: Want): void {
    console.info('OverlayServiceAbility onCreate');
    // Note: HarmonyOS does not support direct overlay windows from services
    // in the same way Android does with WindowManager.TYPE_PHONE.
    // Use a floating window ability or dialog instead.
  }

  onRequest(want: Want, startId: number): void {
    console.info('OverlayServiceAbility onRequest, startId: ' + startId);
    // Equivalent of onStartCommand returning START_STICKY
    // HarmonyOS services are kept alive by the system based on priority
  }

  onConnect(want: Want): rpc.RemoteObject | null {
    return null;
  }

  onDisconnect(want: Want): void {
    console.info('OverlayServiceAbility onDisconnect');
  }

  onDestroy(): void {
    console.info('OverlayServiceAbility onDestroy');
  }
}
