// === TextClockPage.ets ===
import { i18n } from '@kit.LocalizationKit';
import { FontWeight, FlexAlign, HorizontalAlign } from '@kit.ArkUI';

@Entry
@Component
struct TextClockPage {
  @State tzInfo: string = '';

  build() {
    Column() {
      Text('Click the button to display the time zone information.')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 100 })

      Button('Show TimeZone')
        .onClick(() => {
          let timezone = i18n.getTimeZone();
          let displayName = timezone.getDisplayName(); // Fixed API call
          let id = timezone.getID();
          this.tzInfo = `Time Zone : ${displayName}, TimeZone Id: ${id}`;
        })
        .margin({ top: 20 })

      Text(this.tzInfo)
        .fontSize(18)
        .fontColor('#666666')
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}