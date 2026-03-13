// === TimeZoneAdapter.ets ===
import { i18n } from '@kit.LocalizationKit';

@Entry
@Component
struct TimeZoneAdapter {
  @State tzInfo: string = '';

  build() {
    Column() {
      Button('Show TimeZone')
        .onClick(() => {
          this.fetchTimeZoneInfo();
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

  private fetchTimeZoneInfo() {
    let timezone = i18n.getTimeZone();
    let displayName = timezone.getDisplayName();
    let id = timezone.getID();
    this.tzInfo = `TimeZone: ${displayName}, ID: ${id}`;
  }
}