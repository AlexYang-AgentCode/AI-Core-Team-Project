// === TimeZonePage.ets ===
import { i18n } from '@kit.LocalizationKit';

@Entry
@Component
struct TimeZonePage {
  @State tzInfo: string = '';

  build() {
    Column() {
      Text('Click the button to show the time zone information')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100 })

      Button('Show TimeZone')
        .onClick(() => {
          let timezone = i18n.getTimeZone();
          let displayName = timezone.getDisplayName();
          let id = timezone.getID();
          this.tzInfo = `Time Zone : ${displayName}, TimeZone Id: ${id}`;
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
}