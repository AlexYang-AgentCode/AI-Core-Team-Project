// === TimeZonePage.ets ===
@Entry
@Component
struct TimeZonePage {
  @State tzDisplayName: string = '';
  @State tzId: string = '';

  build() {
    Column() {
      Text('Click the button to show the time zone information')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20 })

      Button('Get Time Zone')
        .onClick(() => this.getTimeZone())
        .margin({ top: 20 })

      Text(`Time Zone: ${this.tzDisplayName}, ID: ${this.tzId}`)
        .fontSize(18)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  getTimeZone() {
    const timezone = i18n.getTimeZone();
    this.tzDisplayName = timezone.getDisplayName(false, TimeZoneNameStyle.SHORT);
    this.tzId = timezone.getID();
  }
}