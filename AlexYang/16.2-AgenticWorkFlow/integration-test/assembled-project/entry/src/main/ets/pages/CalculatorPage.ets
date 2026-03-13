/**
 * CalculatorPage - Integration test page
 * Demonstrates Calculator APK running through all 4 bridge layers on HarmonyOS
 *
 * Data flow:
 *   16.1 APK (Java) → 16.4.1 JIT → 16.4.2 Activity → 16.4.3 View → 16.4.4 System
 *
 * This page simulates what happens when the bridge stack runs the Calculator:
 * - Activity.onCreate() sets up the UI (16.4.2)
 * - Button/TextView render via ArkUI (16.4.3)
 * - Expression evaluation via ExpressionEvaluator (16.4.4)
 */
import { router } from '@kit.ArkUI';

@Entry
@Component
struct CalculatorPage {
  @State display: string = '0';
  @State subDisplay: string = '';
  @State currentExpression: string = '';
  @State lifecycleLog: string = '';
  @State showBridgeInfo: boolean = false;

  aboutToAppear(): void {
    // Simulate Activity lifecycle through bridge (16.4.2)
    this.lifecycleLog += '[16.4.2] Activity.onCreate()\n';
    this.lifecycleLog += '[16.4.2] Activity.setContentView(R.layout.activity_main)\n';
    this.lifecycleLog += '[16.4.3] Inflating 19 Button + 2 TextView via ViewBridge\n';
    this.lifecycleLog += '[16.4.2] Activity.onStart()\n';
    this.lifecycleLog += '[16.4.2] Activity.onResume()\n';
    this.lifecycleLog += '[16.4.4] RClass.resolve(21 R.id entries)\n';
  }

  build() {
    Column() {
      // Header showing bridge info
      Row() {
        Text('◀')
          .fontSize(20)
          .fontColor('#FFFFFF')
          .onClick(() => router.back())
          .padding({ left: 16 })
        Text('Calculator (APK → HarmonyOS)')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(this.showBridgeInfo ? '▼' : '▶')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .padding({ right: 16 })
          .onClick(() => { this.showBridgeInfo = !this.showBridgeInfo; })
      }
      .width('100%')
      .height(48)
      .backgroundColor('#1565C0')

      // Bridge info panel (collapsible)
      if (this.showBridgeInfo) {
        Scroll() {
          Text(this.lifecycleLog)
            .fontSize(10)
            .fontColor('#00FF00')
            .fontFamily('monospace')
            .width('100%')
            .padding(8)
        }
        .width('100%')
        .height(120)
        .backgroundColor('#1A1A1A')
      }

      // Calculator display area - mapped from Android TextView (16.4.3)
      Column() {
        // Sub display (expression)
        Text(this.subDisplay)
          .fontSize(16)
          .fontColor('#888888')
          .width('100%')
          .textAlign(TextAlign.End)
          .padding({ right: 20, top: 10 })
          .height(30)

        // Main display - Android TextView via View Bridge
        Text(this.display)
          .fontSize(48)
          .fontWeight(FontWeight.Light)
          .fontColor('#FFFFFF')
          .width('100%')
          .textAlign(TextAlign.End)
          .padding({ right: 20, bottom: 10 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(140)
      .backgroundColor('#000000')

      // Bridge layer indicator
      Row() {
        Text('16.4.3 View Bridge')
          .fontSize(9)
          .fontColor('#90CAF9')
        Text('  |  ')
          .fontSize(9)
          .fontColor('#424242')
        Text('16.4.4 ExpressionEvaluator')
          .fontSize(9)
          .fontColor('#A5D6A7')
      }
      .width('100%')
      .height(20)
      .backgroundColor('#1A1A1A')
      .justifyContent(FlexAlign.Center)

      // Button grid - mapped from Android Buttons (16.4.3 View Bridge)
      Column() {
        // Row 1: C () % ÷
        Row() {
          this.funcButton('C', '#A5A5A5', '#000000')
          this.funcButton('()', '#A5A5A5', '#000000')
          this.funcButton('%', '#A5A5A5', '#000000')
          this.opButton('÷')
        }.width('100%').layoutWeight(1)

        // Row 2: 7 8 9 ×
        Row() {
          this.numButton('7')
          this.numButton('8')
          this.numButton('9')
          this.opButton('×')
        }.width('100%').layoutWeight(1)

        // Row 3: 4 5 6 -
        Row() {
          this.numButton('4')
          this.numButton('5')
          this.numButton('6')
          this.opButton('-')
        }.width('100%').layoutWeight(1)

        // Row 4: 1 2 3 +
        Row() {
          this.numButton('1')
          this.numButton('2')
          this.numButton('3')
          this.opButton('+')
        }.width('100%').layoutWeight(1)

        // Row 5: 0 . =
        Row() {
          this.zeroButton()
          this.numButton('.')
          this.equalsButton()
        }.width('100%').layoutWeight(1)
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#222222')
      .padding(4)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  numButton(label: string) {
    Button(label)
      .fontSize(24)
      .fontColor('#FFFFFF')
      .backgroundColor('#333333')
      .layoutWeight(1)
      .height('100%')
      .margin(2)
      .borderRadius(50)
      .onClick(() => this.onNumberPress(label))
  }

  @Builder
  zeroButton() {
    Button('0')
      .fontSize(24)
      .fontColor('#FFFFFF')
      .backgroundColor('#333333')
      .layoutWeight(2)
      .height('100%')
      .margin(2)
      .borderRadius(50)
      .onClick(() => this.onNumberPress('0'))
  }

  @Builder
  opButton(label: string) {
    Button(label)
      .fontSize(24)
      .fontColor('#FFFFFF')
      .backgroundColor('#FF9500')
      .layoutWeight(1)
      .height('100%')
      .margin(2)
      .borderRadius(50)
      .onClick(() => this.onOperatorPress(label))
  }

  @Builder
  funcButton(label: string, bg: string, fg: string) {
    Button(label)
      .fontSize(20)
      .fontColor(fg)
      .backgroundColor(bg)
      .layoutWeight(1)
      .height('100%')
      .margin(2)
      .borderRadius(50)
      .onClick(() => this.onFunctionPress(label))
  }

  @Builder
  equalsButton() {
    Button('=')
      .fontSize(24)
      .fontColor('#FFFFFF')
      .backgroundColor('#FF9500')
      .layoutWeight(1)
      .height('100%')
      .margin(2)
      .borderRadius(50)
      .onClick(() => this.onEquals())
  }

  // --- Calculator logic (simulates 16.4.4 ExpressionEvaluator) ---

  onNumberPress(num: string): void {
    if (this.display === '0' && num !== '.') {
      this.display = num;
    } else {
      this.display += num;
    }
    this.currentExpression += num;
    this.lifecycleLog += `[16.4.3] Button.onClick("${num}") → View.setText\n`;
  }

  onOperatorPress(op: string): void {
    this.display += ` ${op} `;
    this.currentExpression += op === '×' ? '*' : op === '÷' ? '/' : op;
    this.lifecycleLog += `[16.4.3] Button.onClick("${op}") → append operator\n`;
  }

  onFunctionPress(func: string): void {
    if (func === 'C') {
      this.display = '0';
      this.subDisplay = '';
      this.currentExpression = '';
      this.lifecycleLog += '[16.4.3] Clear button → reset display\n';
    } else if (func === '%') {
      this.currentExpression += '%';
      this.display += '%';
    } else if (func === '()') {
      // Simple parentheses toggle
      const openCount = (this.currentExpression.match(/\(/g) || []).length;
      const closeCount = (this.currentExpression.match(/\)/g) || []).length;
      if (openCount > closeCount) {
        this.currentExpression += ')';
        this.display += ')';
      } else {
        this.currentExpression += '(';
        this.display += '(';
      }
    }
  }

  onEquals(): void {
    this.lifecycleLog += `[16.4.4] ExpressionEvaluator.evaluate("${this.currentExpression}")\n`;

    try {
      // Simulate ExpressionEvaluator from 16.4.4
      const expr = this.currentExpression
        .replace(/%/g, '/100');
      const result = this.safeEvaluate(expr);
      this.subDisplay = this.display + ' =';
      this.display = result;
      this.currentExpression = result;
      this.lifecycleLog += `[16.4.4] Result: ${result}\n`;
      this.lifecycleLog += `[16.4.3] TextView.setText("${result}")\n`;
    } catch (e) {
      this.display = 'Error';
      this.currentExpression = '';
      this.lifecycleLog += '[16.4.4] ExpressionEvaluator: Error\n';
    }
  }

  // Safe expression evaluator (mirrors 16.4.4 ExpressionEvaluator logic)
  safeEvaluate(expr: string): string {
    // Tokenize
    const tokens: string[] = [];
    let num = '';
    for (let i = 0; i < expr.length; i++) {
      const ch = expr[i];
      if ((ch >= '0' && ch <= '9') || ch === '.') {
        num += ch;
      } else if ('+-*/()'.includes(ch)) {
        if (num) { tokens.push(num); num = ''; }
        tokens.push(ch);
      }
    }
    if (num) tokens.push(num);

    // Shunting-yard algorithm (simplified)
    const output: number[] = [];
    const ops: string[] = [];
    const precedence: Record<string, number> = { '+': 1, '-': 1, '*': 2, '/': 2 };

    const applyOp = () => {
      const op = ops.pop()!;
      const b = output.pop()!;
      const a = output.pop()!;
      switch (op) {
        case '+': output.push(a + b); break;
        case '-': output.push(a - b); break;
        case '*': output.push(a * b); break;
        case '/': output.push(b !== 0 ? a / b : NaN); break;
      }
    };

    for (const token of tokens) {
      if (!isNaN(Number(token))) {
        output.push(Number(token));
      } else if (token === '(') {
        ops.push(token);
      } else if (token === ')') {
        while (ops.length && ops[ops.length - 1] !== '(') applyOp();
        ops.pop();
      } else if ('+-*/'.includes(token)) {
        while (ops.length && ops[ops.length - 1] !== '(' &&
          (precedence[ops[ops.length - 1]] ?? 0) >= (precedence[token] ?? 0)) {
          applyOp();
        }
        ops.push(token);
      }
    }
    while (ops.length) applyOp();

    const result = output[0];
    if (isNaN(result)) return 'Error';
    // Format: remove trailing zeros
    return Number(result.toFixed(10)).toString();
  }
}
