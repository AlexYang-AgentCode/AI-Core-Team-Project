// HarmonyOS ArkTS equivalent of Android Calculator demo
// Android: Button/TextView + setOnClickListener/setOnLongClickListener
// HarmonyOS: Button/Text + .onClick() + .gesture(LongPressGesture)

@Entry
@Component
struct CalculatorPage {
  @State inputText: string = ''
  @State outputText: string = ''
  @State inputFontSize: number = 68

  private readonly ADDITION: string = '+'
  private readonly SUBTRACTION: string = '-'
  private readonly MULTIPLICATION: string = '*'
  private readonly DIVISION: string = '/'
  private readonly EQU: string = '='
  private readonly EXTRA: string = '@'
  private readonly MODULUS: string = '%'

  private action: string = ''
  private val1: number = NaN
  private val2: number = 0

  private ifReallyDecimal(): boolean {
    return this.val1 === Math.floor(this.val1)
  }

  private formatVal(value: number): string {
    if (this.ifReallyDecimal()) {
      return Math.floor(value).toString()
    }
    return value.toString()
  }

  private ifErrorOnOutput(): void {
    if (this.outputText === 'Error') {
      this.outputText = ''
    }
  }

  private exceedLength(): void {
    if (this.inputText.length > 10) {
      this.inputFontSize = 20
    } else {
      this.inputFontSize = 68
    }
  }

  private operation(): void {
    if (!isNaN(this.val1)) {
      if (this.outputText.length > 0 && this.outputText.charAt(0) === '-') {
        this.val1 = (-1) * this.val1
      }
      this.val2 = parseFloat(this.inputText)

      switch (this.action) {
        case this.ADDITION:
          this.val1 = this.val1 + this.val2
          break
        case this.SUBTRACTION:
          this.val1 = this.val1 - this.val2
          break
        case this.MULTIPLICATION:
          this.val1 = this.val1 * this.val2
          break
        case this.DIVISION:
          this.val1 = this.val1 / this.val2
          break
        case this.EXTRA:
          this.val1 = (-1) * this.val1
          break
        case this.MODULUS:
          this.val1 = this.val1 % this.val2
          break
        case this.EQU:
          break
      }
    } else {
      this.val1 = parseFloat(this.inputText)
    }
  }

  private onDigitClick(digit: string): void {
    this.ifErrorOnOutput()
    this.exceedLength()
    this.inputText = this.inputText + digit
  }

  private onOperatorClick(op: string, symbol: string): void {
    if (this.inputText.length > 0) {
      this.action = op
      this.operation()
      this.outputText = this.formatVal(this.val1) + symbol
      this.inputText = ''
    } else {
      this.outputText = 'Error'
    }
  }

  @Builder
  NumberButton(label: string, digit: string) {
    Button(label)
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor('#333333')
      .fontColor('#FFFFFF')
      .fontSize(28)
      .onClick(() => {
        this.onDigitClick(digit)
      })
  }

  @Builder
  OperatorButton(label: string) {
    Button(label)
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor('#FF9500')
      .fontColor('#FFFFFF')
      .fontSize(28)
  }

  @Builder
  FunctionButton(label: string) {
    Button(label)
      .width(80)
      .height(80)
      .borderRadius(40)
      .backgroundColor('#A5A5A5')
      .fontColor('#060606')
      .fontSize(28)
  }

  build() {
    Column() {
      // Output display (small, top-right aligned)
      Text(this.outputText)
        .fontSize(36)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.End)
        .padding({ right: 16 })
        .margin({ top: 20 })

      // Input display (large, right-aligned)
      Text(this.inputText)
        .fontSize(this.inputFontSize)
        .fontColor('#FFFFFF')
        .width('100%')
        .textAlign(TextAlign.End)
        .padding({ right: 16 })
        .margin({ top: 10 })
        .layoutWeight(1)

      // Row 1: AC, +/-, %, /
      Row() {
        // AC button - click to backspace, long press to clear all
        Button('AC')
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#A5A5A5')
          .fontColor('#060606')
          .fontSize(28)
          .onClick(() => {
            if (this.inputText.length > 0) {
              this.inputText = this.inputText.substring(0, this.inputText.length - 1)
            } else {
              this.val1 = NaN
              this.val2 = NaN
              this.inputText = ''
              this.outputText = ''
            }
          })
          .gesture(
            LongPressGesture()
              .onAction(() => {
                this.val1 = NaN
                this.val2 = NaN
                this.inputText = ''
                this.outputText = ''
              })
          )

        // +/- button
        Button('+/-')
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#A5A5A5')
          .fontColor('#060606')
          .fontSize(28)
          .onClick(() => {
            if (this.outputText !== '' || this.inputText !== '') {
              this.val1 = parseFloat(this.inputText)
              this.action = this.EXTRA
              this.outputText = '-' + this.inputText
              this.inputText = ''
            } else {
              this.outputText = 'Error'
            }
          })

        // % button
        Button('%')
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#A5A5A5')
          .fontColor('#060606')
          .fontSize(28)
          .onClick(() => {
            if (this.inputText.length > 0) {
              this.action = this.MODULUS
              this.operation()
              this.outputText = this.formatVal(this.val1) + '%'
              this.inputText = ''
            } else {
              this.outputText = 'Error'
            }
          })

        // / button
        Button('/')
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#FF9500')
          .fontColor('#FFFFFF')
          .fontSize(28)
          .onClick(() => {
            this.onOperatorClick(this.DIVISION, '/')
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 10 })

      // Row 2: 7, 8, 9, x
      Row() {
        this.NumberButton('7', '7')
        this.NumberButton('8', '8')
        this.NumberButton('9', '9')
        Button('\u00D7')
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#FF9500')
          .fontColor('#FFFFFF')
          .fontSize(28)
          .onClick(() => {
            this.onOperatorClick(this.MULTIPLICATION, '\u00D7')
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 10 })

      // Row 3: 4, 5, 6, -
      Row() {
        this.NumberButton('4', '4')
        this.NumberButton('5', '5')
        this.NumberButton('6', '6')
        Button('-')
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#FF9500')
          .fontColor('#FFFFFF')
          .fontSize(28)
          .onClick(() => {
            this.onOperatorClick(this.SUBTRACTION, '-')
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 10 })

      // Row 4: 1, 2, 3, +
      Row() {
        this.NumberButton('1', '1')
        this.NumberButton('2', '2')
        this.NumberButton('3', '3')
        Button('+')
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#FF9500')
          .fontColor('#FFFFFF')
          .fontSize(28)
          .onClick(() => {
            this.onOperatorClick(this.ADDITION, '+')
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 10 })

      // Row 5: 0 (wide), ., =
      Row() {
        Button('0')
          .width(180)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#333333')
          .fontColor('#FFFFFF')
          .fontSize(28)
          .onClick(() => {
            this.onDigitClick('0')
          })

        Button('.')
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#333333')
          .fontColor('#FFFFFF')
          .fontSize(28)
          .onClick(() => {
            this.exceedLength()
            this.inputText = this.inputText + '.'
          })

        Button('=')
          .width(80)
          .height(80)
          .borderRadius(40)
          .backgroundColor('#FF9500')
          .fontColor('#FFFFFF')
          .fontSize(28)
          .onClick(() => {
            if (this.inputText.length > 0) {
              this.operation()
              this.action = this.EQU
              this.outputText = this.formatVal(this.val1)
              this.inputText = ''
            } else {
              this.outputText = 'Error'
            }
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceEvenly)
      .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .padding({ left: 8, right: 8 })
  }
}
