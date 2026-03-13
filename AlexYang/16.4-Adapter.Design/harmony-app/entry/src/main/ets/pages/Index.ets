// TextClock HarmonyOS - Android to HarmonyOS Adapted Application
// Original: com.w.homework2.MainActivity (Android)
// Adapted:  HarmonyOS ArkTS @Component
//
// Layout matches Android activity_main.xml ConstraintLayout:
//   Button         vertical_bias=0.067  (top)
//   TextView       vertical_bias=0.231  (below button)
//   TextClock      vertical_bias=0.403  (center-ish)
//
// Android API Mapping:
//   AppCompatActivity    -> UIAbility (EntryAbility.ets)
//   setContentView       -> @Component build()
//   Bundle               -> Want (handled by EntryAbility)
//   findViewById         -> @State variable binding
//   Button               -> ArkUI Button component
//   TextView             -> ArkUI Text component
//   TextClock            -> ArkUI TextClock component
//   OnClickListener      -> .onClick(() => {})
//   TimeZone.getDefault() -> i18n.getTimeZone()
//   ConstraintLayout     -> ArkUI Column layout

import { i18n } from '@kit.LocalizationKit';

@Entry
@Component
struct Index {
  // Maps to: TextView TimeZoneTextview;
  // Android initial text from XML: android:text="TimeZone"
  @State tzInfo: string = 'TimeZone';

  build() {
    Column() {
      // === Button (android:id="@+id/timeZoneButton") ===
      // Android: at top, vertical_bias=0.067
      // Android text: "Get Time Zone"
      Button('Get Time Zone')
        .fontSize(16)
        .width('100%')
        .height(48)
        .onClick(() => {
          // Maps to: TimeZone tz = TimeZone.getDefault();
          let tz = i18n.getTimeZone();
          // Maps to: tz.getDisplayName(false, TimeZone.SHORT)
          let displayName = tz.getDisplayName();
          // Maps to: tz.getID()
          let id = tz.getID();
          // Maps to: TimeZoneTextview.setText("Time Zone : " + ... + "TimeZone Id: " + ...)
          // Note: Android original has NO comma, direct concatenation
          this.tzInfo = `Time Zone : ${displayName}\nTimeZone Id: ${id}`;
        })
        .margin({ top: 40 })

      // === TextView (android:id="@+id/timeZoneShow") ===
      // Android: below button, vertical_bias=0.231
      // Android initial: android:text="TimeZone"
      Text(this.tzInfo)
        .fontSize(16)
        .textAlign(TextAlign.Center)
        .margin({ top: 40 })

      // === TextClock (android:id="@+id/idTextClock") ===
      // Android: center, vertical_bias=0.403
      // Android format: android:format12Hour="hh:mm:ss"
      // Android textSize: 35dp, textColor: colorAccent
      TextClock()
        .format('hh:mm:ss')
        .fontSize(35)
        .margin({ top: 80 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
  }
}
