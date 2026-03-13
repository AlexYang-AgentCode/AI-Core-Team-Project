/**
 * AndroidLinearLayout - 模拟Android LinearLayout的ArkUI组件
 * 根据orientation渲染Column或Row
 */

import { AppStorage } from '@ohos.app.ability.common';
import { ViewRegistry } from '../registry/ViewRegistry';
import { ViewProxy, ViewConstants } from '../view/AndroidView';

@Component
export struct AndroidLinearLayout {
  @Prop id: number;
  @Prop orientation: string = 'vertical'; // 'vertical' or 'horizontal'
  @Prop weight: number = 0; // layout_weight 属性
  @Slot() children?: any; // 子组件
  @StorageLink(`LinearLayout_${this.id}_orientation`) orientationState: string = 'vertical';
  // View基类属性
  @StorageLink(`View_${this.id}_visibility`) visibility: number = ViewConstants.VISIBLE;
  @StorageLink(`View_${this.id}_backgroundColor`) backgroundColor: number = 0;
  @StorageLink(`View_${this.id}_enabled`) enabled: boolean = true;

  aboutToAppear() {
    // 确保代理存在
    const registry = ViewRegistry.getInstance();
    registry.getLinearLayoutProxy(this.id);
    // 设置AppStorage初始值（如果未设置）
    if (!AppStorage.Has(`LinearLayout_${this.id}_orientation`)) {
      AppStorage.SetOrCreate(`LinearLayout_${this.id}_orientation`, this.orientation);
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
  }

  // layoutWeight 修饰器，支持链式调用
  layoutWeight(weight: number): AndroidLinearLayout {
    this.weight = weight;
    return this;
  }

  build() {
    if (this.orientationState === 'horizontal') {
      Row() {
        if (this.children) {
          this.children();
        }
      }
      .visibility(this.getArkUIVisibility())
      .backgroundColor(this.backgroundColor)
      .enabled(this.enabled)
      .width('100%')
      .height('100%')
      .layoutWeight(this.weight > 0 ? this.weight : undefined)
    } else {
      Column() {
        if (this.children) {
          this.children();
        }
      }
      .visibility(this.getArkUIVisibility())
      .backgroundColor(this.backgroundColor)
      .enabled(this.enabled)
      .width('100%')
      .height('100%')
      .layoutWeight(this.weight > 0 ? this.weight : undefined)
    }
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
export class LinearLayoutProxy extends ViewProxy {
  constructor(id: number) {
    super(id);
  }

  setOrientation(orientation: string): void {
    // 存储到AppStorage，组件通过StorageLink读取
    AppStorage.SetOrCreate(`LinearLayout_${this.id}_orientation`, orientation);
  }

  getOrientation(): string {
    return AppStorage.Get<string>(`LinearLayout_${this.id}_orientation`) || 'vertical';
  }
}

// 扩展ViewRegistry以支持LinearLayout
// 需要在ViewRegistry中添加getLinearLayoutProxy等方法