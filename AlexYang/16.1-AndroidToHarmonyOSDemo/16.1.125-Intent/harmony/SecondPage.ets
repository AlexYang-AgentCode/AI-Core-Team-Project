// HarmonyOS ArkTS equivalent of Android SecondActivity
// Android: getIntent().getExtras() → HarmonyOS: router.getParams()
// Android: setResult + finish → HarmonyOS: router.back with params

import { router } from '@kit.ArkUI';

interface Person {
  name: string
  any: string
}

interface PageParams {
  EXTRA_STRING?: string
  EXTRA_INT?: number
  EXTRA_LONG?: number
  EXTRA_BOOLEAN?: boolean
  EXTRA_DRAWABLE?: string
  EXTRA_MODEL?: string
  FOR_RESULT?: boolean
}

@Entry
@Component
struct SecondPage {
  @State extrasText: string = 'No extras'
  private forResult: boolean = false

  aboutToAppear(): void {
    const params = router.getParams() as PageParams | null
    if (params === null || params === undefined) {
      this.extrasText = 'No extras'
      return
    }

    // Check if this was started for result
    if (params.FOR_RESULT === true) {
      this.forResult = true
      this.extrasText = 'No extras (started for result)'
      return
    }

    // Build extras display string
    let sb: string = ''

    if (params.EXTRA_STRING !== undefined &&
        params.EXTRA_INT !== undefined &&
        params.EXTRA_LONG !== undefined &&
        params.EXTRA_BOOLEAN !== undefined &&
        params.EXTRA_MODEL !== undefined) {
      sb += 'String: ' + params.EXTRA_STRING + '\n'
      sb += 'Int: ' + params.EXTRA_INT.toString() + '\n'
      sb += 'Long: ' + params.EXTRA_LONG.toString() + '\n'
      sb += 'Boolean: ' + params.EXTRA_BOOLEAN.toString() + '\n'

      // Parse the Person model
      try {
        const person: Person = JSON.parse(params.EXTRA_MODEL) as Person
        sb += 'ClassModel: \n[Person]\n'
        sb += "\t\t-name='" + person.name + "'\n"
        sb += "\t\t-any='" + person.any + "'\n"
      } catch (e) {
        sb += 'ClassModel: ' + params.EXTRA_MODEL + '\n'
      }
    }

    this.extrasText = sb !== '' ? sb : 'No extras'
  }

  // Equivalent of Android onBackPressed with setResult
  onBackPress(): boolean {
    if (this.forResult) {
      router.back({
        url: 'pages/Index',
        params: {
          resultString: 'THIS VALUE RETURN ACTIVITY FOR RESULT'
        }
      } as router.RouterOptions)
      return true
    }
    return false // default back behavior
  }

  build() {
    Column() {
      // Title
      Text('Second Activity')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 36 })

      // Extras display
      Text(this.extrasText)
        .fontSize(14)
        .width('90%')
        .margin({ top: 36 })
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
