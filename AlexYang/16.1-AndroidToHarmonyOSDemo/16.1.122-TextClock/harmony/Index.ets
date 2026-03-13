// HarmonyOS ArkTS equivalent of Android TextClock demo
// Android: TextClock + TimeZone.getDefault() → HarmonyOS: TextClock + i18n.System.getSystemTimezone()

import { i18n } from '@kit.LocalizationKit';

@Entry
@Component
struct TextClockPage {
  @State timeZoneInfo: string = 'TimeZone'
  @State accumulateTime: number = 0

  // TextClock controller for the clock display
  private controller: TextClockController = new TextClockController()

  build() {
    Column() {
      // "Get Time Zone" button at top
      Button('Get Time Zone')
        .width('100%')
        .onClick(() => {
          const tzId: string = i18n.System.getSystemTimezone()
          const tz: i18n.TimeZone = i18n.getTimeZone(tzId)
          const displayName: string = tz.getDisplayName() ?? tzId
          this.timeZoneInfo = 'Time Zone : ' + displayName + ' TimeZone Id: ' + tzId
        })

      // TimeZone display text
      Text(this.timeZoneInfo)
        .fontSize(16)
        .margin({ top: 40 })

      // TextClock in the center area - equivalent of Android TextClock widget
      // Use system timezone dynamically instead of hardcoded offset
      TextClock({ controller: this.controller })
        .format('hh:mm:ss')
        .fontSize(35)
        .fontColor('#FF4081')
        .margin({ top: 80 })
        .onDateChange((value: number) => {
          this.accumulateTime = value
        })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 16, right: 16, top: 16 })
  }
}
