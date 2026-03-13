/**
 * AndroidFrameLayout - 模拟Android FrameLayout的ArkUI组件
 * 使用ArkUI的Stack实现层叠布局
 */

import { AppStorage } from '@ohos.app.ability.common';
import { ViewRegistry } from '../registry/ViewRegistry';
import { ViewProxy, ViewConstants } from '../view/AndroidView';

@Component
export struct AndroidFrameLayout {
  @Prop id: number;
  @Slot() children?: any; // 子组件
  
  // View基类属性
  @StorageLink(`View_${this.id}_visibility`) visibility: number = ViewConstants.VISIBLE;
  @StorageLink(`View_${this.id}_backgroundColor`) backgroundColor: number = 0;
  @StorageLink(`View_${this.id}_enabled`) enabled: boolean = true;

  aboutToAppear() {
    // 确保代理存在
    const registry = ViewRegistry.getInstance();
    registry.getFrameLayoutProxy(this.id);
    // 设置AppStorage初始值（如果未设置）
    if (!AppStorage.Has(`View_${this.id}_visibility`)) {
      AppStorage.SetOrCreate(`View_${this.id}_visibility`, this.visibility);
    }
    if (!AppStorage.Has(`View_${this.id}_backgroundColor`)) {
      AppStorage.SetOrCreate(`View_${this.id}_backgroundColor`, this.backgroundColor);
    }
    if (!AppStorage.Has(`View_${this.id}_enabled`)) {
      AppStorage.SetOrCreate(`View_${this.id}_enabled`, this.enabled);
    }
  }

  build() {
    Stack() {
      if (this.children) {
        this.children();
      }
    }
    .visibility(this.getArkUIVisibility())
    .backgroundColor(this.backgroundColor)
    .enabled(this.enabled)
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
}

// 代理类，供Android代码调用
export class FrameLayoutProxy extends ViewProxy {
  constructor(id: number) {
    super(id);
  }

  // FrameLayout特有的方法
  setForegroundGravity(gravity: number): void {
    // 设置前景重力（布局对齐方式）
    AppStorage.SetOrCreate<number>(`FrameLayout_${this.id}_foregroundGravity`, gravity);
  }

  getForegroundGravity(): number {
    return AppStorage.Get<number>(`FrameLayout_${this.id}_foregroundGravity`) || 0;
  }

  setMeasureAllChildren(measureAll: boolean): void {
    // 设置是否测量所有子View
    AppStorage.SetOrCreate<boolean>(`FrameLayout_${this.id}_measureAllChildren`, measureAll);
  }

  getMeasureAllChildren(): boolean {
    return AppStorage.Get<boolean>(`FrameLayout_${this.id}_measureAllChildren`) || false;
  }
}