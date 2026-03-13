// HarmonyOS ArkTS equivalent of Android Intent/Activity demo (Main page)
// Android: Intent + startActivity + startActivityForResult + putExtra
// HarmonyOS: router.pushUrl + params

import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

interface SecondPageResult {
  resultString?: string
}

@Entry
@Component
struct MainPage {
  @State resultText: string = ''

  onPageShow(): void {
    // Check for result from SecondPage (simulates onActivityResult)
    const params = router.getParams() as SecondPageResult | null
    if (params !== null && params !== undefined) {
      if (params.resultString !== undefined) {
        this.resultText = params.resultString
        promptAction.showToast({ message: 'RESULT_OK', duration: 2000 })
      }
    }
  }

  build() {
    Column() {
      // Title
      Text('Call Activity')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24 })

      Text('ArkTS HarmonyOS')
        .fontSize(14)
        .fontColor('#888888')
        .margin({ top: 8 })

      // Start Activity button
      Button('Start Activity')
        .width('90%')
        .margin({ top: 36 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/SecondPage'
          })
        })

      // Start Activity with Put Extra button
      Button('Start Activity with PutExtra')
        .width('90%')
        .margin({ top: 16 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/SecondPage',
            params: {
              EXTRA_STRING: 'StringValueExtra',
              EXTRA_INT: 1,
              EXTRA_LONG: 1,
              EXTRA_BOOLEAN: true,
              EXTRA_DRAWABLE: 'ic_android',
              EXTRA_MODEL: JSON.stringify({
                name: 'NamePerson',
                any: 'AnyPersonValue'
              })
            }
          })
        })

      // Start Activity For Result button
      Button('Start Activity for Result')
        .width('90%')
        .margin({ top: 16 })
        .onClick(() => {
          router.pushUrl({
            url: 'pages/SecondPage',
            params: {
              FOR_RESULT: true
            }
          })
        })

      // Activity Result section
      Text('Activity Result:')
        .fontSize(16)
        .margin({ top: 24 })

      Text(this.resultText)
        .fontSize(14)
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
