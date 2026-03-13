// HarmonyOS ArkTS equivalent of Android SharedPreferences demo
// Android: SharedPreferences → HarmonyOS: @ohos.data.preferences

import { preferences } from '@kit.ArkData';
import { promptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';

@Entry
@Component
struct SharedPreferencesPage {
  @State inputText: string = 'Hello'
  @State displayText: string = '[SharedPreference]'

  private pref: preferences.Preferences | null = null
  private readonly PREF_NAME: string = 'MyPrefs'
  private readonly KEY_1: string = 'KEY_TEXT'

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext
    try {
      this.pref = preferences.getPreferencesSync(context, { name: this.PREF_NAME })
      this.loadPreference()
    } catch (err) {
      console.error('Failed to get preferences: ' + JSON.stringify(err))
    }
  }

  private loadPreference(): void {
    if (this.pref === null) return
    try {
      const value = this.pref.getSync(this.KEY_1, '') as string
      if (value !== '') {
        this.displayText = value
      } else {
        this.displayText = 'SharedPreferences is null'
      }
    } catch (err) {
      this.displayText = 'SharedPreferences is null'
    }
  }

  private savePreference(): void {
    if (this.inputText.trim() === '') {
      this.showToast('Please set any text')
      return
    }
    if (this.pref === null) return
    try {
      this.pref.putSync(this.KEY_1, this.inputText.trim())
      this.pref.flush()
      this.showToast('SharedPreferences Saved!\nPress Open to view')
    } catch (err) {
      this.showToast('Failed to save')
    }
  }

  private deletePreference(): void {
    if (this.pref === null) return
    try {
      this.pref.deleteSync(this.KEY_1)
      this.pref.flush()
      this.displayText = 'SharedPreferences is null'
      this.showToast('SharedPreferences deleted')
    } catch (err) {
      this.showToast('Failed to delete')
    }
  }

  private showToast(message: string): void {
    promptAction.showToast({ message: message, duration: 2000 })
  }

  build() {
    Column() {
      // Title
      Text('SharedPreferences')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24 })

      Text('ArkTS HarmonyOS')
        .fontSize(14)
        .fontColor('#888888')
        .margin({ top: 8 })

      // Input field
      TextInput({ text: this.inputText, placeholder: 'Enter text...' })
        .onChange((value: string) => {
          this.inputText = value
        })
        .maxLength(32)
        .width('90%')
        .margin({ top: 36 })

      // Save button
      Button('SAVE')
        .width('90%')
        .margin({ top: 28 })
        .onClick(() => {
          this.savePreference()
        })

      // Open button
      Button('OPEN')
        .width('90%')
        .margin({ top: 28 })
        .onClick(() => {
          this.loadPreference()
        })

      // Delete button
      Button('DELETE')
        .width('90%')
        .margin({ top: 28 })
        .onClick(() => {
          this.deletePreference()
        })

      // Display label
      Text('SharedPreferences')
        .fontSize(16)
        .margin({ top: 32 })

      // Display value
      Text(this.displayText)
        .fontSize(16)
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
