/**
 * AndroidRelativeLayout - 模拟Android RelativeLayout的ArkUI组件
 * 使用ArkUI的RelativeContainer实现相对布局
 */

import { AppStorage } from '@ohos.app.ability.common';
import { ViewRegistry } from '../registry/ViewRegistry';
import { ViewProxy, ViewConstants } from '../view/AndroidView';

@Component
export struct AndroidRelativeLayout {
  @Prop id: number;
  @Slot() children?: any; // 子组件
  
  // View基类属性
  @StorageLink(`View_${this.id}_visibility`) visibility: number = ViewConstants.VISIBLE;
  @StorageLink(`View_${this.id}_backgroundColor`) backgroundColor: number = 0;
  @StorageLink(`View_${this.id}_enabled`) enabled: boolean = true;

  aboutToAppear() {
    // 确保代理存在
    const registry = ViewRegistry.getInstance();
    registry.getRelativeLayoutProxy(this.id);
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
    RelativeContainer() {
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
export class RelativeLayoutProxy extends ViewProxy {
  constructor(id: number) {
    super(id);
  }

  // RelativeLayout特有的方法
  addRule(verb: number, anchor: number): void {
    // 添加相对布局规则
    // verb: RelativeLayout的规则常量，如RelativeLayout.ABOVE, RelativeLayout.BELOW
    // anchor: 锚点View的ID
    // 存储规则到AppStorage，供组件使用
    const rulesKey = `RelativeLayout_${this.id}_rules`;
    let rules = AppStorage.Get<Array<{verb: number, anchor: number}>>(rulesKey) || [];
    rules.push({verb, anchor});
    AppStorage.SetOrCreate(rulesKey, rules);
  }

  removeRule(verb: number, anchor: number): void {
    const rulesKey = `RelativeLayout_${this.id}_rules`;
    let rules = AppStorage.Get<Array<{verb: number, anchor: number}>>(rulesKey) || [];
    rules = rules.filter(rule => !(rule.verb === verb && rule.anchor === anchor));
    AppStorage.SetOrCreate(rulesKey, rules);
  }

  clearRules(): void {
    AppStorage.SetOrCreate(`RelativeLayout_${this.id}_rules`, []);
  }
}

// RelativeLayout规则常量（模拟Android RelativeLayout）
export class RelativeLayoutRules {
  static readonly ABOVE = 2;          // 在指定View上方
  static readonly BELOW = 3;          // 在指定View下方
  static readonly LEFT_OF = 0;        // 在指定View左侧
  static readonly RIGHT_OF = 1;       // 在指定View右侧
  static readonly ALIGN_BASELINE = 4; // 基线对齐
  static readonly ALIGN_LEFT = 5;     // 左对齐
  static readonly ALIGN_TOP = 6;      // 上对齐
  static readonly ALIGN_RIGHT = 7;    // 右对齐
  static readonly ALIGN_BOTTOM = 8;   // 下对齐
  static readonly ALIGN_PARENT_LEFT = 9;    // 与父容器左对齐
  static readonly ALIGN_PARENT_TOP = 10;    // 与父容器上对齐
  static readonly ALIGN_PARENT_RIGHT = 11;  // 与父容器右对齐
  static readonly ALIGN_PARENT_BOTTOM = 12; // 与父容器下对齐
  static readonly CENTER_IN_PARENT = 13;    // 在父容器居中
  static readonly CENTER_HORIZONTAL = 14;   // 水平居中
  static readonly CENTER_VERTICAL = 15;     // 垂直居中
}