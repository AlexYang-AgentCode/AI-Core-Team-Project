// === TimeZoneAdapter.ets ===
import { i18n } from '@kit.LocalizationKit';

// Reusable struct for TimeZone functionality
@Component
struct TimeZoneAdapter {
  @State tzInfo: string = '';

  build() {
    Column() {
      Button('Show TimeZone')
        .onClick(() => this.getTimeZone())
        .margin({ top: 20 })

      Text(this.tzInfo)
        .fontSize(18)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  // Function to get TimeZone information
  getTimeZone() {
    let timezone = i18n.getTimeZone();
    let id = timezone.getID();
    let displayName = timezone.getDisplayName();
    this.tzInfo = `TimeZone: ${displayName}, ID: ${id}`;
  }
}