// HarmonyOS ArkTS equivalent of Android Handler/Looper demo
// Android: Handler(Looper.getMainLooper()) + post() + sendMessage()
// HarmonyOS: @State for UI updates + setTimeout for delayed tasks + taskpool for background work

import { taskpool } from '@kit.ArkTS';
import { emitter } from '@kit.BasicServicesKit';

@Entry
@Component
struct HandlerLooperPage {
  @State logText: string = ''
  private counter: number = 0
  private messageCounter: number = 0

  // Event ID for message handling (equivalent of Handler message)
  private readonly MESSAGE_EVENT_ID: number = 1001

  aboutToAppear(): void {
    // Subscribe to message events (equivalent of Handler.handleMessage)
    emitter.on({ eventId: this.MESSAGE_EVENT_ID }, (eventData: emitter.EventData) => {
      if (eventData.data !== undefined) {
        const msg = eventData.data['message'] as string
        this.logText += msg + '\n'
      }
    })
  }

  aboutToDisappear(): void {
    emitter.off(this.MESSAGE_EVENT_ID)
  }

  // Equivalent of postRunnable: starts a background task that sleeps 5 seconds
  private postRunnable(id: number): void {
    this.logText += `starting #${id}\n`

    // Simulate background work with setTimeout (equivalent of Thread.sleep + runOnUiThread)
    setTimeout(() => {
      this.logText += `finished #${id}\n`
    }, 5000)
  }

  // Equivalent of sendMessage via LooperThread
  private sendMessage(value: string): void {
    const eventData: emitter.EventData = {
      data: {
        message: value
      }
    }
    emitter.emit({ eventId: this.MESSAGE_EVENT_ID }, eventData)
  }

  build() {
    Column() {
      // Post Runnable button
      Button('post runnable')
        .width('100%')
        .onClick(() => {
          this.counter++
          this.postRunnable(this.counter)
        })

      // Send Message button
      Button('send message')
        .width('100%')
        .margin({ top: 8 })
        .onClick(() => {
          this.messageCounter++
          const value = `handled message #${this.messageCounter}`
          this.sendMessage(value)
        })

      // Clear Log button
      Button('clear log')
        .width('100%')
        .margin({ top: 8 })
        .onClick(() => {
          this.logText = ''
        })

      // Scrollable log view
      Scroll() {
        Text(this.logText)
          .fontSize(14)
          .width('100%')
          .padding(8)
      }
      .width('100%')
      .layoutWeight(1)
      .margin({ top: 8 })
      .scrollable(ScrollDirection.Vertical)
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
  }
}
