// === TimeZoneAdapter.ets ===
import { i18n } from '@kit.LocalizationKit';

@Entry
@Component
struct TimeZoneAdapter {
  @State tzInfo: string = '';

  build() {
    Column() {
      Text('Click the button to show the time zone information.')
        .fontSize(18)
        .margin({ top: 20 })

      Button('Show TimeZone')
        .onClick(() => {
          this.updateTimeZoneInfo();
        })
        .margin({ top: 20 })

      Text(this.tzInfo)
        .fontSize(18)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  updateTimeZoneInfo() {
    let timezone = i18n.getTimeZone();
    let displayName = timezone.getDisplayName();
    let id = timezone.getID();
    this.tzInfo = `TimeZone: ${displayName}, ID: ${id}`;
  }
}