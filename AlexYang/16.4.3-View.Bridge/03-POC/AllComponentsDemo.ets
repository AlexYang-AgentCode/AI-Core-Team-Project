/**
 * AllComponentsDemo - 展示所有Android View桥接组件的综合演示
 */

import { AndroidTextView } from '../05-Implementation/view/AndroidTextView';
import { AndroidButton } from '../05-Implementation/view/AndroidButton';
import { AndroidEditText } from '../05-Implementation/view/AndroidEditText';
import { AndroidTextClock } from '../05-Implementation/view/AndroidTextClock';
import { AndroidLinearLayout } from '../05-Implementation/layout/AndroidLinearLayout';
import { ViewRegistry } from '../05-Implementation/registry/ViewRegistry';

// 模拟Android R.id常量
const R = {
  id: {
    // TextView
    demoTextView: 4001,
    
    // Buttons
    demoButton1: 4002,
    demoButton2: 4003,
    demoButton3: 4004,
    
    // EditText
    demoEditText: 4005,
    
    // TextClock
    demoTextClock: 4006,
    
    // Layouts
    mainLayout: 4007,
    buttonRow: 4008,
    inputRow: 4009,
  }
};

// 演示逻辑
class DemoLogic {
  private registry: ViewRegistry;
  private clickCount: number = 0;

  constructor() {
    this.registry = ViewRegistry.getInstance();
    this.setupButtonListeners();
    this.setupEditTextListener();
  }

  private setupButtonListeners(): void {
    // 按钮1: 更新TextView
    const button1 = this.registry.findViewById(R.id.demoButton1, 'Button');
    if (button1) {
      button1.setOnClickListener(() => {
        this.clickCount++;
        const textView = this.registry.findViewById(R.id.demoTextView, 'TextView');
        if (textView) {
          textView.setText(`按钮点击次数: ${this.clickCount}`);
        }
      });
    }

    // 按钮2: 切换TextClock格式
    const button2 = this.registry.findViewById(R.id.demoButton2, 'Button');
    if (button2) {
      button2.setOnClickListener(() => {
        const textClock = this.registry.findViewById(R.id.demoTextClock, 'TextClock');
        if (textClock) {
          const is24Hour = textClock.getIs24HourMode();
          textClock.setIs24HourMode(!is24Hour);
          
          // 更新按钮文本
          button2.setText(is24Hour ? '切换到24小时制' : '切换到12小时制');
        }
      });
    }

    // 按钮3: 清除EditText
    const button3 = this.registry.findViewById(R.id.demoButton3, 'Button');
    if (button3) {
      button3.setOnClickListener(() => {
        const editText = this.registry.findViewById(R.id.demoEditText, 'EditText');
        if (editText) {
          editText.setText('');
          editText.setHint('已清除，请输入新文本...');
        }
      });
    }
  }

  private setupEditTextListener(): void {
    const editText = this.registry.findViewById(R.id.demoEditText, 'EditText');
    if (editText) {
      editText.setOnTextChangedListener((text: string) => {
        const textView = this.registry.findViewById(R.id.demoTextView, 'TextView');
        if (textView) {
          textView.setText(`输入内容: "${text}"`);
        }
      });
    }
  }
}

@Component
struct AllComponentsPage {
  private demoLogic: DemoLogic = new DemoLogic();

  build() {
    Column() {
      Text('Android View Bridge - 所有组件演示')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 20 })
        .width('100%')
        .textAlign(TextAlign.Center)

      // 主布局 - 使用AndroidLinearLayout
      AndroidLinearLayout({ id: R.id.mainLayout, orientation: 'vertical' }) {
        // TextClock演示
        Text('TextClock (时钟)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 10, bottom: 5 })
        
        AndroidTextClock({ 
          id: R.id.demoTextClock, 
          format12Hour: 'hh:mm:ss a',
          format24Hour: 'HH:mm:ss'
        })
          .width('100%')
          .height(50)
          .backgroundColor(0xFFF5F5F5)
          .fontColor(0xFF3F51B5)
          .fontSize(20)
          .textAlign(TextAlign.Center)

        // TextView演示
        Text('TextView (文本显示)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 20, bottom: 5 })
        
        AndroidTextView({ id: R.id.demoTextView, text: '等待按钮点击或文本输入...' })
          .width('100%')
          .height(60)
          .backgroundColor(0xFFE8EAF6)
          .fontColor(0xFF303F9F)
          .fontSize(18)
          .textAlign(TextAlign.Center)
          .padding(10)

        // EditText演示
        Text('EditText (文本输入)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 20, bottom: 5 })
        
        AndroidEditText({ 
          id: R.id.demoEditText, 
          hint: '在此输入文本...',
          text: ''
        })
          .width('100%')
          .height(50)
          .backgroundColor(0xFFFFFFFF)
          .fontColor(0xFF000000)
          .fontSize(16)
          .padding({ left: 10, right: 10 })

        // 按钮行 - 使用AndroidLinearLayout
        Text('Button (按钮)')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 20, bottom: 5 })
        
        AndroidLinearLayout({ id: R.id.buttonRow, orientation: 'horizontal' }) {
          AndroidButton({ id: R.id.demoButton1, text: '点击计数' })
            .layoutWeight(1)
            .margin({ right: 5 })
          
          AndroidButton({ id: R.id.demoButton2, text: '切换到24小时制' })
            .layoutWeight(1)
            .margin({ left: 5, right: 5 })
          
          AndroidButton({ id: R.id.demoButton3, text: '清除输入' })
            .layoutWeight(1)
            .margin({ left: 5 })
        }
        .width('100%')
        .height(60)
        .margin({ top: 10, bottom: 20 })

        // 说明区域
        Text('组件说明')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .margin({ top: 10, bottom: 5 })
        
        Text('本演示展示了Android View桥接组件的功能：\n' +
             '1. TextView: 显示文本，可通过代码更新\n' +
             '2. Button: 点击触发事件，更新其他组件\n' +
             '3. EditText: 文本输入，实时监听变化\n' +
             '4. TextClock: 自动更新的时钟\n' +
             '5. LinearLayout: 水平和垂直布局容器')
          .fontSize(14)
          .fontColor(0xFF666666)
          .width('100%')
          .textAlign(TextAlign.Start)
          .padding(10)
          .backgroundColor(0xFFFAFAFA)
      }
      .width('100%')
      .height('80%')
      .padding(20)
      .backgroundColor(0xFFFFFFFF)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xFFEEEEEE)
  }
}

// 入口页面
@Entry
@Component
struct Index {
  build() {
    Column() {
      AllComponentsPage()
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}