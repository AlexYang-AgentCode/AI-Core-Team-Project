// HarmonyOS ArkTS equivalent of Android Toast & AlertDialog demo
// Android: Toast.makeText().show() → HarmonyOS: promptAction.showToast()
// Android: AlertDialog.Builder → HarmonyOS: AlertDialog.show()

import { promptAction } from '@kit.ArkUI';

@Entry
@Component
struct ToastDialogPage {
  build() {
    Column() {
      Button('Show Toast')
        .onClick(() => {
          promptAction.showToast({
            message: 'Hello Toast!',
            duration: 2000
          })
        })

      Button('Show Dialog')
        .margin({ top: 16 })
        .onClick(() => {
          AlertDialog.show({
            title: 'Confirm',
            message: 'Are you sure?',
            primaryButton: {
              value: 'Yes',
              action: () => {
                promptAction.showToast({
                  message: 'Confirmed',
                  duration: 2000
                })
              }
            },
            secondaryButton: {
              value: 'No',
              action: () => {
                // No action, equivalent to null in Android
              }
            }
          })
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(16)
  }
}
