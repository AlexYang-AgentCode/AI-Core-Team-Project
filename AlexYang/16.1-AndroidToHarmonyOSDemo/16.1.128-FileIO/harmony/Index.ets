// HarmonyOS ArkTS equivalent of Android FileIO demo
// Android: FileInputStream/FileOutputStream → HarmonyOS: @ohos.file.fs

import fs from '@ohos.file.fs';
import promptAction from '@ohos.promptAction';

@Entry
@Component
struct FileIOPage {
  private readonly FILENAME: string = 'demo.txt';
  @State inputText: string = '';
  @State outputText: string = '(loaded content appears here)';

  private getFilePath(): string {
    return getContext(this).filesDir + '/' + this.FILENAME;
  }

  private saveToFile(): void {
    try {
      const filePath = this.getFilePath();
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE | fs.OpenMode.TRUNC);
      // fs.writeSync accepts string directly in HarmonyOS
      fs.writeSync(file.fd, this.inputText);
      fs.closeSync(file);
      promptAction.showToast({ message: 'Saved!' });
    } catch (err) {
      promptAction.showToast({ message: 'Save failed: ' + (err as Error).message });
    }
  }

  private loadFromFile(): void {
    try {
      const filePath = this.getFilePath();
      const content = fs.readTextSync(filePath);
      this.outputText = content;
    } catch (err) {
      this.outputText = 'Load failed: ' + (err as Error).message;
    }
  }

  build() {
    Column() {
      TextInput({ placeholder: 'Enter text to save', text: this.inputText })
        .width('100%')
        .onChange((value: string) => {
          this.inputText = value;
        })

      Button('Save to File')
        .margin({ top: 12 })
        .onClick(() => {
          this.saveToFile();
        })

      Button('Load from File')
        .margin({ top: 12 })
        .onClick(() => {
          this.loadFromFile();
        })

      Text(this.outputText)
        .fontSize(16)
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Center)
  }
}
