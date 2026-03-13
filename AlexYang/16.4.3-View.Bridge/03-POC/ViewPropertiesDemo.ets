/**
 * ViewPropertiesDemo - 展示 View 核心属性的演示页面
 * 
 * 演示以下属性：
 * - Padding（内边距）
 * - Margin（外边距）
 * - Gravity（对齐方式）
 * - Alpha（透明度）
 * - LayoutParams（宽高设置）
 */

import { ViewRegistry } from '../registry/ViewRegistry';
import { Gravity, Padding, Margin, LayoutParams } from '../view/LayoutParams';
import { AndroidTextView } from '../view/AndroidTextView';
import { AndroidButton } from '../view/AndroidButton';
import { AndroidLinearLayout, LinearLayoutOrientation } from '../layout/AndroidLinearLayout';
import { promptAction } from '@ohos.promptAction';

// View ID 常量
const R = {
  id: {
    container: 1000,
    title: 1001,
    demoText: 1002,
    paddingBtn: 1003,
    marginBtn: 1004,
    gravityBtn: 1005,
    alphaBtn: 1006,
    resetBtn: 1007,
    statusText: 1008,
    buttonRow1: 1009,
    buttonRow2: 1010,
  }
};

@Component
export struct ViewPropertiesDemo {
  private registry: ViewRegistry = ViewRegistry.getInstance();

  aboutToAppear() {
    // 初始化视图代理
    this.initializeViews();
    // 设置初始状态
    this.updateStatus('点击按钮查看不同属性效果');
  }

  private initializeViews() {
    // 获取代理对象并设置初始属性
    const title = this.registry.getTextViewProxy(R.id.title);
    title.setText('View 属性演示');
    title.setTextSize(0, 24);
    title.setTextColor(0xFF3F51B5);

    const demoText = this.registry.getTextViewProxy(R.id.demoText);
    demoText.setText('示例文本');
    demoText.setTextSize(0, 20);
    demoText.setTextColor(0xFF333333);
    demoText.setBackgroundColor(0xFFE3F2FD);
    // 设置初始内边距
    demoText.setPadding(20, 20, 20, 20);
    // 设置初始 margin
    demoText.setMargin(10, 10, 10, 10);

    const statusText = this.registry.getTextViewProxy(R.id.statusText);
    statusText.setText('准备就绪');
    statusText.setTextSize(0, 14);
    statusText.setTextColor(0xFF666666);

    // 设置按钮
    this.setupButton(R.id.paddingBtn, 'Padding 演示', () => this.demoPadding());
    this.setupButton(R.id.marginBtn, 'Margin 演示', () => this.demoMargin());
    this.setupButton(R.id.gravityBtn, 'Gravity 演示', () => this.demoGravity());
    this.setupButton(R.id.alphaBtn, 'Alpha 演示', () => this.demoAlpha());
    this.setupButton(R.id.resetBtn, '重置', () => this.resetProperties());
  }

  private setupButton(id: number, text: string, onClick: () => void) {
    const btn = this.registry.getButtonProxy(id);
    btn.setText(text);
    btn.setTextSize(0, 16);
    btn.setOnClickListener(onClick);
    // 设置统一的外边距
    btn.setMargin(8, 8, 8, 8);
  }

  private demoPadding() {
    const demoText = this.registry.getTextViewProxy(R.id.demoText);
    const currentPadding = demoText.getPadding();
    
    // 循环切换不同的 padding 值
    if (currentPadding.left < 30) {
      demoText.setPadding(40, 40, 40, 40);
      this.updateStatus('Padding 增大: 40dp');
    } else if (currentPadding.left < 50) {
      demoText.setPadding(60, 20, 60, 20);
      this.updateStatus('Padding 不均匀: 左右60, 上下20');
    } else {
      demoText.setPadding(20, 20, 20, 20);
      this.updateStatus('Padding 恢复默认: 20dp');
    }
  }

  private demoMargin() {
    const demoText = this.registry.getTextViewProxy(R.id.demoText);
    const currentMargin = demoText.getMargin();
    
    // 循环切换不同的 margin 值
    if (currentMargin.left < 30) {
      demoText.setMargin(40, 20, 40, 20);
      this.updateStatus('Margin 增大: 40,20,40,20');
    } else if (currentMargin.left < 50) {
      demoText.setMargin(60, 40, 20, 40);
      this.updateStatus('Margin 不均匀: 60,40,20,40');
    } else {
      demoText.setMargin(10, 10, 10, 10);
      this.updateStatus('Margin 恢复默认: 10dp');
    }
  }

  private demoGravity() {
    const demoText = this.registry.getTextViewProxy(R.id.demoText);
    const currentGravity = demoText.getGravity();
    
    // 循环切换不同的 gravity 值
    let newGravity: number;
    let description: string;
    
    if (Gravity.has(currentGravity, Gravity.CENTER)) {
      newGravity = Gravity.START | Gravity.TOP;
      description = 'Gravity.START | Gravity.TOP (左上)';
    } else if (Gravity.has(currentGravity, Gravity.START)) {
      newGravity = Gravity.END | Gravity.TOP;
      description = 'Gravity.END | Gravity.TOP (右上)';
    } else if (Gravity.has(currentGravity, Gravity.END)) {
      newGravity = Gravity.CENTER;
      description = 'Gravity.CENTER (居中)';
    } else {
      newGravity = Gravity.START | Gravity.TOP;
      description = 'Gravity.START | Gravity.TOP (左上)';
    }
    
    demoText.setGravity(newGravity);
    this.updateStatus(`Gravity 切换: ${description}`);
  }

  private demoAlpha() {
    const demoText = this.registry.getTextViewProxy(R.id.demoText);
    const currentAlpha = demoText.getAlpha();
    
    // 循环切换不同的透明度
    let newAlpha: number;
    let description: string;
    
    if (currentAlpha > 0.8) {
      newAlpha = 0.6;
      description = '60% 不透明';
    } else if (currentAlpha > 0.5) {
      newAlpha = 0.3;
      description = '30% 不透明';
    } else if (currentAlpha > 0.2) {
      newAlpha = 0.1;
      description = '10% 不透明 (几乎透明)';
    } else {
      newAlpha = 1.0;
      description = '100% 不透明';
    }
    
    demoText.setAlpha(newAlpha);
    this.updateStatus(`Alpha 切换: ${description}`);
  }

  private resetProperties() {
    const demoText = this.registry.getTextViewProxy(R.id.demoText);
    
    // 重置所有属性
    demoText.setPadding(20, 20, 20, 20);
    demoText.setMargin(10, 10, 10, 10);
    demoText.setGravity(Gravity.START | Gravity.TOP);
    demoText.setAlpha(1.0);
    demoText.setBackgroundColor(0xFFE3F2FD);
    
    this.updateStatus('所有属性已重置');
    promptAction.showToast({ message: '属性已重置', duration: 2000 });
  }

  private updateStatus(message: string) {
    const statusText = this.registry.getTextViewProxy(R.id.statusText);
    statusText.setText(message);
  }

  build() {
    Column({ space: 16 }) {
      // 标题
      AndroidTextView({ id: R.id.title })
        .width('100%')
        .height(60)

      // 演示文本区域
      Column() {
        AndroidTextView({ id: R.id.demoText })
          .width('90%')
          .height(120)
      }
      .width('100%')
      .backgroundColor(0xFFF5F5F5)
      .padding(20)

      // 状态文本
      AndroidTextView({ id: R.id.statusText })
        .width('100%')
        .height(40)
        .margin({ top: 10, bottom: 10 })

      // 按钮行1
      Row({ space: 8 }) {
        AndroidButton({ id: R.id.paddingBtn })
          .layoutWeight(1)
          .height(50)
        
        AndroidButton({ id: R.id.marginBtn })
          .layoutWeight(1)
          .height(50)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 按钮行2
      Row({ space: 8 }) {
        AndroidButton({ id: R.id.gravityBtn })
          .layoutWeight(1)
          .height(50)
        
        AndroidButton({ id: R.id.alphaBtn })
          .layoutWeight(1)
          .height(50)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 重置按钮
      AndroidButton({ id: R.id.resetBtn })
        .width('50%')
        .height(50)
        .margin({ top: 20 })

      // 说明文本
      Text('说明：\n• Padding: 内边距，影响内容与边框的距离\n• Margin: 外边距，影响组件与其他组件的距离\n• Gravity: 内容对齐方式\n• Alpha: 透明度，0.0-1.0')
        .fontSize(12)
        .fontColor(0xFF888888)
        .width('90%')
        .margin({ top: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(0xFFFFFFFF)
    .padding({ top: 20, bottom: 20 })
  }
}
