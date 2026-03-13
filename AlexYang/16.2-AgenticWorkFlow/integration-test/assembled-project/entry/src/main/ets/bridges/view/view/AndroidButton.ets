/**
 * AndroidButton - 模拟Android Button的ArkUI组件
 * 通过AppStorage与Android命令式代码交互
 */

import { ViewRegistry } from '../registry/ViewRegistry';
import { AppStorage } from '@ohos.app.ability.common';
import { ViewProxy, ViewConstants } from './AndroidView';
import { TextViewProxy } from './AndroidTextView';
import { TouchType, TouchEvent } from '@ohos.arkui.node';
import { Padding, Margin, Gravity } from './LayoutParams';

@Component
export struct AndroidButton {
  @Prop id: number;
  @Prop text: string = '';
  
  // 通过StorageLink绑定到AppStorage
  @StorageLink(`Button_${this.id}_text`) buttonText: string = '';
  @StorageLink(`Button_${this.id}_textColor`) textColor: number = 0xFFFFFFFF; // 默认白色
  @StorageLink(`Button_${this.id}_textSize`) textSize: number = 14;
  // View基类属性
  @StorageLink(`View_${this.id}_visibility`) visibility: number = ViewConstants.VISIBLE;
  @StorageLink(`View_${this.id}_backgroundColor`) backgroundColor: number = 0xFF3F51B5; // 默认颜色
  @StorageLink(`View_${this.id}_enabled`) enabled: boolean = true;
  @StorageLink(`View_${this.id}_alpha`) alpha: number = 1.0;
  @StorageLink(`View_${this.id}_clickable`) clickable: boolean = true;
  // 布局属性
  @StorageLink(`View_${this.id}_padding`) padding: Padding = new Padding();
  @StorageLink(`View_${this.id}_margin`) margin: Margin = new Margin();
  // 兼容旧版Button-specific属性（从View属性同步）
  @StorageLink(`Button_${this.id}_backgroundColor`) buttonBackgroundColor: number = 0xFF3F51B5;
  @StorageLink(`Button_${this.id}_enabled`) buttonEnabled: boolean = true;
  // 点击监听器（存储在ViewProxy实例中，这里仅用于触发）
  @StorageLink(`Button_${this.id}_onClick`) onClickCallback: (() => void) | null = null;
  // 按压状态背景色（默认比正常背景色暗20%）
  @StorageLink(`Button_${this.id}_pressedBackgroundColor`) pressedBackgroundColor: number = 0;
  // 按压状态（本地状态，不持久化）
  @State isPressed: boolean = false;

  aboutToAppear() {
    // 确保代理存在
    const registry = ViewRegistry.getInstance();
    registry.getButtonProxy(this.id);
    // 设置AppStorage初始值（如果未设置）
    if (!AppStorage.Has(`Button_${this.id}_text`)) {
      AppStorage.SetOrCreate(`Button_${this.id}_text`, this.text);
    }
    if (!AppStorage.Has(`Button_${this.id}_textColor`)) {
      AppStorage.SetOrCreate(`Button_${this.id}_textColor`, this.textColor);
    }
    if (!AppStorage.Has(`Button_${this.id}_textSize`)) {
      AppStorage.SetOrCreate(`Button_${this.id}_textSize`, this.textSize);
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
    if (!AppStorage.Has(`View_${this.id}_clickable`)) {
      AppStorage.SetOrCreate(`View_${this.id}_clickable`, this.clickable);
    }
    // 布局属性
    if (!AppStorage.Has(`View_${this.id}_padding`)) {
      AppStorage.SetOrCreate(`View_${this.id}_padding`, this.padding);
    }
    if (!AppStorage.Has(`View_${this.id}_margin`)) {
      AppStorage.SetOrCreate(`View_${this.id}_margin`, this.margin);
    }
    // 兼容性：如果Button-specific属性存在，同步到View属性
    if (AppStorage.Has(`Button_${this.id}_backgroundColor`)) {
      const buttonColor = AppStorage.Get<number>(`Button_${this.id}_backgroundColor`);
      AppStorage.SetOrCreate(`View_${this.id}_backgroundColor`, buttonColor);
    }
    if (AppStorage.Has(`Button_${this.id}_enabled`)) {
      const buttonEnabled = AppStorage.Get<boolean>(`Button_${this.id}_enabled`);
      AppStorage.SetOrCreate(`View_${this.id}_enabled`, buttonEnabled);
    }
    // 点击监听器（存储在ViewProxy实例中，这里不需要AppStorage存储）
    // 保留旧版onClick存储以兼容
    if (!AppStorage.Has(`Button_${this.id}_onClick`)) {
      AppStorage.SetOrCreate(`Button_${this.id}_onClick`, this.onClickCallback);
    }
  }

  build() {
    Button(this.buttonText || this.text)
      .fontColor(this.textColor)
      .fontSize(this.textSize)
      .visibility(this.getArkUIVisibility())
      .backgroundColor(this.getCurrentBackgroundColor())
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
      .onTouch((event: TouchEvent) => {
        if (!this.enabled || !this.clickable) {
          return;
        }
        switch (event.type) {
          case TouchType.Down:
            this.isPressed = true;
            // 触发触摸监听器
            this.dispatchTouchEvent(0); // ACTION_DOWN
            break;
          case TouchType.Up:
            this.isPressed = false;
            // 触发触摸监听器
            this.dispatchTouchEvent(1); // ACTION_UP
            break;
          case TouchType.Cancel:
            this.isPressed = false;
            // 触发触摸监听器
            this.dispatchTouchEvent(3); // ACTION_CANCEL
            break;
        }
      })
      .onClick(() => {
        // 触发ViewProxy中的点击监听器
        this.dispatchClickEvent();
      })
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

  private getCurrentBackgroundColor(): number {
    if (this.isPressed) {
      // 如果设置了按压背景色，使用它
      if (this.pressedBackgroundColor !== 0) {
        return this.pressedBackgroundColor;
      }
      // 否则将正常背景色变暗20%
      return this.darkenColor(this.backgroundColor, 0.8);
    }
    return this.backgroundColor;
  }

  private darkenColor(color: number, factor: number): number {
    // 从ARGB颜色中提取分量
    const a = (color >> 24) & 0xFF;
    const r = Math.floor(((color >> 16) & 0xFF) * factor);
    const g = Math.floor(((color >> 8) & 0xFF) * factor);
    const b = Math.floor((color & 0xFF) * factor);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  private dispatchTouchEvent(actionType: number): void {
    const registry = ViewRegistry.getInstance();
    const proxy = registry.findViewById<ButtonProxy>(this.id, 'Button');
    if (proxy) {
      proxy.dispatchTouch(actionType);
    }
  }

  private dispatchClickEvent(): void {
    const registry = ViewRegistry.getInstance();
    const proxy = registry.findViewById<ButtonProxy>(this.id, 'Button');
    if (proxy) {
      proxy.dispatchClick();
    }
  }
}

// 代理类，供Android代码调用
export class ButtonProxy extends TextViewProxy {
  constructor(id: number) {
    super(id);
  }

  // 重写setBackgroundColor以同时设置View的背景色
  setBackgroundColor(color: number): void {
    super.setBackgroundColor(color); // 设置View_${id}_backgroundColor
    AppStorage.SetOrCreate<number>(`Button_${this.id}_backgroundColor`, color);
  }

  // 重写setEnabled以同时设置View的enabled
  setEnabled(enabled: boolean): void {
    super.setEnabled(enabled);
    AppStorage.SetOrCreate<boolean>(`Button_${this.id}_enabled`, enabled);
  }

  // 重写setOnClickListener以使用ViewProxy的监听器存储
  setOnClickListener(listener: () => void): void {
    super.setOnClickListener(listener);
  }

  // 设置按压状态背景色
  setPressedBackgroundColor(color: number): void {
    AppStorage.SetOrCreate<number>(`Button_${this.id}_pressedBackgroundColor`, color);
  }
}

// 需要在ViewRegistry中添加registerButtonProxy方法
// 修改ViewRegistry.ets
