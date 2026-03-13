/**
 * Activity Bridge Test Page
 * 
 * Demonstrates and tests Activity lifecycle mapping
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { promptAction } from '@kit.ArkUI';
import { globalLifecycleLogger } from '../test/LifecycleLogger';

const TAG = 'IndexPage';

@Entry
@Component
struct Index {
  @State message: string = 'Activity Bridge Test';
  @State lifecycleEvents: string[] = [];
  @State currentState: string = 'INITIALIZED';

  aboutToAppear(): void {
    hilog.info(0x0000, TAG, 'Page aboutToAppear');
    this.refreshEvents();
  }

  onPageShow(): void {
    hilog.info(0x0000, TAG, 'Page onPageShow');
    this.currentState = 'RESUMED';
    globalLifecycleLogger.log('ArkUI.onPageShow');
    this.refreshEvents();
  }

  onPageHide(): void {
    hilog.info(0x0000, TAG, 'Page onPageHide');
    this.currentState = 'STOPPED';
    globalLifecycleLogger.log('ArkUI.onPageHide');
  }

  build() {
    Column() {
      // Header
      Text(this.message)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin(20)
      
      Text(`Current State: ${this.currentState}`)
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 20 })

      // Lifecycle events display
      Column() {
        Text('Lifecycle Events')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin(10)

        List({ space: 8 }) {
          ForEach(this.lifecycleEvents.slice(-20), (event: string, index: number) => {
            ListItem() {
              Text(event)
                .fontSize(12)
                .fontColor(index % 2 === 0 ? '#333333' : '#666666')
                .width('100%')
            }
          })
        }
        .width('100%')
        .height(300)
        .padding(10)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
      }
      .width('95%')
      .margin(10)

      // Test buttons
      Column({ space: 10 }) {
        Button('Refresh Events')
          .width('80%')
          .onClick(() => {
            this.refreshEvents();
            promptAction.showToast({ message: 'Events refreshed' });
          })

        Button('Clear Events')
          .width('80%')
          .onClick(() => {
            globalLifecycleLogger.clear();
            this.refreshEvents();
            promptAction.showToast({ message: 'Events cleared' });
          })

        Button('Test Toast')
          .width('80%')
          .onClick(() => {
            promptAction.showToast({ 
              message: 'Activity Bridge Test Toast',
              duration: 2000 
            });
          })

        Button('Navigate to Test Page')
          .width('80%')
          .onClick(() => {
            // Navigation will be implemented when View Bridge is ready
            promptAction.showToast({ message: 'Navigation test' });
          })
      }
      .width('100%')
      .margin(20)

      // Footer
      Text('16.4.2-Activity.Bridge v1.0.0')
        .fontSize(12)
        .fontColor('#999999')
        .margin(20)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  private refreshEvents(): void {
    this.lifecycleEvents = globalLifecycleLogger.getEvents();
  }
}
