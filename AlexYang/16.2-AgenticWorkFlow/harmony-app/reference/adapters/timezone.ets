// === TimeZoneAdapter.ets ===
import { i18n } from '@kit.LocalizationKit';

@Entry
@Component
struct TimeZoneAdapter {
  @State tzInfo: string = '';

  build() {
    Column() {
      Text('Click the button to get the current timezone')
        .fontSize(18)
        .margin({ top: 20 })

      Button('Get Time Zone')
        .onClick(() => {
          let timezone = i18n.getTimeZone();
          let displayName = timezone.getDisplayName();
          let id = timezone.getID();
          this.tzInfo = `Time Zone: ${displayName}, ID: ${id}`;
        })
        .margin({ top: 20 })

      Text(this.tzInfo)
        .fontSize(18)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}