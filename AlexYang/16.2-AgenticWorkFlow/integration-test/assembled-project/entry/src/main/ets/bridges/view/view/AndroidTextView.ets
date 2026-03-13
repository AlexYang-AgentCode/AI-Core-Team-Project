/**
 * AndroidTextView - 模拟Android TextView的ArkUI组件
 * 通过AppStorage与Android命令式代码交互
 */

import { ViewRegistry } from '../registry/ViewRegistry';
import { AppStorage } from '@ohos.app.ability.common';
import { ViewProxy, ViewConstants } from './AndroidView';
import { CharSequence } from '../widgets/CharSequence';
import { Padding, Margin, Gravity, DimensionUtils } from './LayoutParams';

@Component
export struct AndroidTextView {
  // Android View ID
  @Prop id: number;
  
  // 通过StorageLink绑定到AppStorage
  @StorageLink(`TextView_${this.id}_text`) text: string = '';
  @StorageLink(`TextView_${this.id}_textColor`) textColor: number = 0xFF000000; // 默认黑色
  @StorageLink(`TextView_${this.id}_textSize`) textSize: number = 14;
  // View基类属性
  @StorageLink(`View_${this.id}_visibility`) visibility: number = ViewConstants.VISIBLE;
  @StorageLink(`View_${this.id}_backgroundColor`) backgroundColor: number = 0;
  @StorageLink(`View_${this.id}_enabled`) enabled: boolean = true;
  @StorageLink(`View_${this.id}_alpha`) alpha: number = 1.0;
  // 布局属性
  @StorageLink(`View_${this.id}_padding`) padding: Padding = new Padding();
  @StorageLink(`View_${this.id}_margin`) margin: Margin = new Margin();
  @StorageLink(`View_${this.id}_gravity`) gravity: number = Gravity.TOP | Gravity.START;

  aboutToAppear() {
    // 确保代理存在
    const registry = ViewRegistry.getInstance();
    registry.getTextViewProxy(this.id);
    // 设置AppStorage初始值（如果未设置）
    if (!AppStorage.Has(`TextView_${this.id}_text`)) {
      AppStorage.SetOrCreate(`TextView_${this.id}_text`, this.text);
    }
    if (!AppStorage.Has(`TextView_${this.id}_textColor`)) {
      AppStorage.SetOrCreate(`TextView_${this.id}_textColor`, this.textColor);
    }
    if (!AppStorage.Has(`TextView_${this.id}_textSize`)) {
      AppStorage.SetOrCreate(`TextView_${this.id}_textSize`, this.textSize);
    }
    // View基类属性
    if (!AppStorage.Has(`View_${this.id}_visibility`)) {
      AppStorage.SetOrCreate(`View_${this.id}_visibility`, this.visibility);
    }
    if (!AppStorage.Has(`View_${this.id}_backgroundColor`)) {
      AppStorage.SetOrCreate(`View_${this.id}_backgroundColor`, this.backgroundColor);
    }
    if (!AppStorage.Has(`View_${this.id}_enabled`)) {
      AppStorage.SetOrCreate(`View_${this.id}_enabled`, this.enabled);
    }
    if (!AppStorage.Has(`View_${this.id}_alpha`)) {
      AppStorage.SetOrCreate(`View_${this.id}_alpha`, this.alpha);
    }
    // 布局属性
    if (!AppStorage.Has(`View_${this.id}_padding`)) {
      AppStorage.SetOrCreate(`View_${this.id}_padding`, this.padding);
    }
    if (!AppStorage.Has(`View_${this.id}_margin`)) {
      AppStorage.SetOrCreate(`View_${this.id}_margin`, this.margin);
    }
    if (!AppStorage.Has(`View_${this.id}_gravity`)) {
      AppStorage.SetOrCreate(`View_${this.id}_gravity`, this.gravity);
    }
  }

  build() {
    Text(this.text)
      .fontColor(this.textColor)
      .fontSize(this.textSize)
      .visibility(this.getArkUIVisibility())
      .backgroundColor(this.backgroundColor)
      .enabled(this.enabled)
      .opacity(this.alpha)
      .padding({
        left: this.padding.left,
        right: this.padding.right,
        top: this.padding.top,
        bottom: this.padding.bottom
      })
      .margin({
        left: this.margin.left,
        right: this.margin.right,
        top: this.margin.top,
        bottom: this.margin.bottom
      })
      .textAlign(this.getTextAlign())
      .align(Alignment.Start)
      .width('100%')
      .height('100%')
  }

  private getArkUIVisibility(): number {
    switch (this.visibility) {
      case ViewConstants.INVISIBLE:
        return 1; // Visibility.Hidden
      case ViewConstants.GONE:
        return 2; // Visibility.None
      default: // ViewConstants.VISIBLE
        return 0; // Visibility.Visible
    }
  }

  private getTextAlign(): TextAlign {
    const hGravity = Gravity.getHorizontal(this.gravity);
    
    if (Gravity.has(hGravity, Gravity.CENTER_HORIZONTAL) || Gravity.has(this.gravity, Gravity.CENTER)) {
      return TextAlign.Center;
    } else if (Gravity.has(hGravity, Gravity.RIGHT) || Gravity.has(hGravity, Gravity.END)) {
      return TextAlign.End;
    } else {
      // Gravity.LEFT, Gravity.START, or default
      return TextAlign.Start;
    }
  }
}

// 代理类，供Android代码调用
export class TextViewProxy extends ViewProxy {
  constructor(id: number) {
    super(id);
  }

  setText(text: CharSequence | string): void {
    const textStr = typeof text === 'string' ? text : text.toString();
    AppStorage.SetOrCreate<string>(`TextView_${this.id}_text`, textStr);
  }

  getText(): CharSequence {
    const text = AppStorage.Get<string>(`TextView_${this.id}_text`) || '';
    return new CharSequence(text);
  }

  setTextColor(color: number): void {
    AppStorage.SetOrCreate<number>(`TextView_${this.id}_textColor`, color);
  }

  setTextSize(unit: number, size: number): void {
    // unit: TypedValue.COMPLEX_UNIT_SP, COMPLEX_UNIT_DIP, etc.
    // 简化：直接存储size，忽略unit（假设为SP）
    AppStorage.SetOrCreate<number>(`TextView_${this.id}_textSize`, size);
  }
}
