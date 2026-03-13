// === TextClockPage.ets ===
import { i18n } from '@kit.LocalizationKit';

@Entry
@Component
struct TextClockPage {
  @State tzInfo: string = '';

  build() {
    Column() {
      Text('Click the button to display the current time zone information.')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 50, bottom: 20 })

      Button('Show TimeZone')
        .onClick(() => {
          let timezone = i18n.getTimeZone();
          let displayName = timezone.getDisplayName();
          let id = timezone.getID();
          this.tzInfo = `Time Zone : ${displayName}, Time Zone Id: ${id}`;
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