/**
 * CalculatorDemo - 展示Android View桥接组件的POC演示
 * 模拟16.1 Calculator App的UI和逻辑
 */

import { AndroidTextView } from '../05-Implementation/view/AndroidTextView';
import { AndroidButton } from '../05-Implementation/view/AndroidButton';
import { AndroidLinearLayout } from '../05-Implementation/layout/AndroidLinearLayout';
import { ViewRegistry } from '../05-Implementation/registry/ViewRegistry';

// 模拟Android R.id常量
const R = {
  id: {
    textViewInputNumbers: 1001,
    button0: 2000,
    button1: 2001,
    button2: 2002,
    button3: 2003,
    button4: 2004,
    button5: 2005,
    button6: 2006,
    button7: 2007,
    button8: 2008,
    button9: 2009,
    buttonAdd: 2010,
    buttonSubtract: 2011,
    buttonMultiply: 2012,
    buttonDivide: 2013,
    buttonEquals: 2014,
    buttonClear: 2015,
    buttonDecimal: 2016,
    buttonPercent: 2017,
    buttonParentheses: 2018,
  }
};

// 模拟Calculator逻辑，使用Android View代理
class CalculatorLogic {
  private registry: ViewRegistry;
  private currentInput: string = '';
  private previousResult: string = '';

  constructor() {
    this.registry = ViewRegistry.getInstance();
    this.setupButtonListeners();
  }

  private setupButtonListeners(): void {
    // 数字按钮
    for (let i = 0; i <= 9; i++) {
      const buttonId = R.id[`button${i}`];
      const button = this.registry.findViewById(buttonId, 'Button');
      if (button) {
        button.setOnClickListener(() => this.appendNumber(i.toString()));
      }
    }

    // 操作符按钮
    const operators = [
      { id: R.id.buttonAdd, op: '+' },
      { id: R.id.buttonSubtract, op: '-' },
      { id: R.id.buttonMultiply, op: '×' },
      { id: R.id.buttonDivide, op: '÷' },
      { id: R.id.buttonPercent, op: '%' },
      { id: R.id.buttonDecimal, op: '.' },
      { id: R.id.buttonParentheses, op: '()' },
    ];

    operators.forEach(({ id, op }) => {
      const button = this.registry.findViewById(id, 'Button');
      if (button) {
        button.setOnClickListener(() => this.appendOperator(op));
      }
    });

    // 等号按钮
    const equalsButton = this.registry.findViewById(R.id.buttonEquals, 'Button');
    if (equalsButton) {
      equalsButton.setOnClickListener(() => this.calculate());
    }

    // 清除按钮
    const clearButton = this.registry.findViewById(R.id.buttonClear, 'Button');
    if (clearButton) {
      clearButton.setOnClickListener(() => this.clear());
    }
  }

  private appendNumber(num: string): void {
    this.currentInput += num;
    this.updateDisplay();
  }

  private appendOperator(op: string): void {
    this.currentInput += ` ${op} `;
    this.updateDisplay();
  }

  private calculate(): void {
    try {
      // 简单计算逻辑（实际需要更复杂的表达式解析）
      const expression = this.currentInput.replace(/×/g, '*').replace(/÷/g, '/');
      const result = eval(expression); // 注意：eval有安全风险，仅用于演示
      this.previousResult = result.toString();
      this.currentInput = this.previousResult;
      this.updateDisplay();
    } catch (e) {
      this.currentInput = 'Error';
      this.updateDisplay();
    }
  }

  private clear(): void {
    this.currentInput = '';
    this.previousResult = '';
    this.updateDisplay();
  }

  private updateDisplay(): void {
    const textView = this.registry.findViewById(R.id.textViewInputNumbers, 'TextView');
    if (textView) {
      textView.setText(this.currentInput || '0');
    }
  }
}

@Component
struct CalculatorPage {
  private calculatorLogic: CalculatorLogic = new CalculatorLogic();

  build() {
    Column() {
      // 显示区域 - 使用AndroidTextView
      AndroidTextView({ id: R.id.textViewInputNumbers, text: '0' })
        .width('100%')
        .height(100)
        .backgroundColor(0xFF000000)
        .fontColor(0xFFFFFFFF)
        .fontSize(30)
        .textAlign(TextAlign.End)

      // 按钮区域 - 使用AndroidLinearLayout嵌套
      AndroidLinearLayout({ id: 3000, orientation: 'vertical' }) {
        // 第一行按钮
        AndroidLinearLayout({ id: 3001, orientation: 'horizontal' }) {
          AndroidButton({ id: R.id.buttonClear, text: 'C' })
          AndroidButton({ id: R.id.buttonParentheses, text: '()' })
          AndroidButton({ id: R.id.buttonPercent, text: '%' })
          AndroidButton({ id: R.id.buttonDivide, text: '÷' })
        }
        .layoutWeight(1)

        // 第二行按钮
        AndroidLinearLayout({ id: 3002, orientation: 'horizontal' }) {
          AndroidButton({ id: R.id.button7, text: '7' })
          AndroidButton({ id: R.id.button8, text: '8' })
          AndroidButton({ id: R.id.button9, text: '9' })
          AndroidButton({ id: R.id.buttonMultiply, text: '×' })
        }
        .layoutWeight(1)

        // 第三行按钮
        AndroidLinearLayout({ id: 3003, orientation: 'horizontal' }) {
          AndroidButton({ id: R.id.button4, text: '4' })
          AndroidButton({ id: R.id.button5, text: '5' })
          AndroidButton({ id: R.id.button6, text: '6' })
          AndroidButton({ id: R.id.buttonSubtract, text: '-' })
        }
        .layoutWeight(1)

        // 第四行按钮
        AndroidLinearLayout({ id: 3004, orientation: 'horizontal' }) {
          AndroidButton({ id: R.id.button1, text: '1' })
          AndroidButton({ id: R.id.button2, text: '2' })
          AndroidButton({ id: R.id.button3, text: '3' })
          AndroidButton({ id: R.id.buttonAdd, text: '+' })
        }
        .layoutWeight(1)

        // 第五行按钮
        AndroidLinearLayout({ id: 3005, orientation: 'horizontal' }) {
          AndroidButton({ id: R.id.button0, text: '0' })

          AndroidButton({ id: R.id.buttonDecimal, text: '.' })
          AndroidButton({ id: R.id.buttonEquals, text: '=' })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .height('80%')
      .backgroundColor(0xFF222222)
    }
    .width('100%')
    .height('100%')
    .padding(10)
  }
}

// 入口页面
@Entry
@Component
struct Index {
  build() {
    Column() {
      Text('Android View Bridge Demo - Calculator')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 })

      CalculatorPage()
        .width('100%')
        .height('90%')
    }
    .width('100%')
    .height('100%')
  }
}