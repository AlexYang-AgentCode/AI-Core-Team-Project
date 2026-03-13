/**
 * AndroidCheckBox - 模拟Android CheckBox的ArkUI组件
 * 基于ArkUI Toggle组件，支持选中状态切换
 */

import { ViewRegistry } from '../registry/ViewRegistry';
import { AppStorage } from '@ohos.app.ability.common';
import { ViewProxy, ViewConstants } from './AndroidView';
import { Padding, Margin } from './LayoutParams';
import { CharSequence } from '../widgets/CharSequence';

/**
 * Listener interface for checkbox state changes
 */
export interface OnCheckedChangeListener {
  onCheckedChanged(checkBox: CheckBoxProxy, isChecked: boolean): void;
}

@Component
export struct AndroidCheckBox {
  @Prop id: number;
  @Prop text: string = '';
  @Prop checked: boolean = false;

  // CheckBox specific properties
  @StorageLink(`CheckBox_${this.id}_text`) checkBoxText: string = '';
  @StorageLink(`CheckBox_${this.id}_checked`) isChecked: boolean = false;
  @StorageLink(`CheckBox_${this.id}_textColor`) textColor: number = 0xFF000000;
  @StorageLink(`CheckBox_${this.id}_textSize`) textSize: number = 14;

  // View base properties
  @StorageLink(`View_${this.id}_visibility`) visibility: number = ViewConstants.VISIBLE;
  @StorageLink(`View_${this.id}_backgroundColor`) backgroundColor: number = 0;
  @StorageLink(`View_${this.id}_enabled`) enabled: boolean = true;
  @StorageLink(`View_${this.id}_padding`) padding: Padding = new Padding();
  @StorageLink(`View_${this.id}_margin`) margin: new Margin();

  // Listener callback storage
  @StorageLink(`CheckBox_${this.id}_onCheckedChange`) onCheckedChangeCallback: OnCheckedChangeListener | null = null;

  aboutToAppear() {
    const registry = ViewRegistry.getInstance();
    registry.getCheckBoxProxy(this.id);

    // Initialize storage values
    if (!AppStorage.Has(`CheckBox_${this.id}_text`)) {
      AppStorage.SetOrCreate(`CheckBox_${this.id}_text`, this.text);
    }
    if (!AppStorage.Has(`CheckBox_${this.id}_checked`)) {
      AppStorage.SetOrCreate(`CheckBox_${this.id}_checked`, this.checked);
    }
    if (!AppStorage.Has(`View_${this.id}_visibility`)) {
      AppStorage.SetOrCreate(`View_${this.id}_visibility`, this.visibility);
    }
    if (!AppStorage.Has(`View_${this.id}_enabled`)) {
      AppStorage.SetOrCreate(`View_${this.id}_enabled`, this.enabled);
    }
  }

  build() {
    Row() {
      Toggle({ type: ToggleType.Checkbox, isOn: this.isChecked })
        .enabled(this.enabled)
        .onChange((isOn: boolean) => {
          this.isChecked = isOn;
          AppStorage.SetOrCreate(`CheckBox_${this.id}_checked`, isOn);
          this.dispatchCheckedChange(isOn);
        })
        .margin({ right: 8 })

      if (this.checkBoxText || this.text) {
        Text(this.checkBoxText || this.text)
          .fontColor(this.textColor)
          .fontSize(this.textSize)
          .enabled(this.enabled)
      }
    }
    .visibility(this.getArkUIVisibility())
    .backgroundColor(this.backgroundColor)
    .enabled(this.enabled)
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
    .onClick(() => {
      if (this.enabled) {
        this.isChecked = !this.isChecked;
        AppStorage.SetOrCreate(`CheckBox_${this.id}_checked`, this.isChecked);
        this.dispatchCheckedChange(this.isChecked);
      }
    })
  }

  private getArkUIVisibility(): number {
    switch (this.visibility) {
      case ViewConstants.INVISIBLE:
        return 1;
      case ViewConstants.GONE:
        return 2;
      default:
        return 0;
    }
  }

  private dispatchCheckedChange(isChecked: boolean): void {
    const registry = ViewRegistry.getInstance();
    const proxy = registry.findViewById<CheckBoxProxy>(this.id, 'CheckBox');
    if (proxy) {
      proxy.dispatchCheckedChange(isChecked);
    }
  }
}

/**
 * CheckBox proxy for Android code interaction
 */
export class CheckBoxProxy extends ViewProxy {
  private checkedChangeListener: OnCheckedChangeListener | null = null;

  constructor(id: number) {
    super(id);
  }

  /**
   * Sets the text displayed next to the checkbox.
   */
  setText(text: CharSequence | string): void {
    const textStr = typeof text === 'string' ? text : text.toString();
    AppStorage.SetOrCreate<string>(`CheckBox_${this.id}_text`, textStr);
  }

  /**
   * Gets the text displayed next to the checkbox.
   */
  getText(): CharSequence {
    const text = AppStorage.Get<string>(`CheckBox_${this.id}_text`) || '';
    return new CharSequence(text);
  }

  /**
   * Sets the checked state.
   */
  setChecked(checked: boolean): void {
    AppStorage.SetOrCreate<boolean>(`CheckBox_${this.id}_checked`, checked);
  }

  /**
   * Gets the current checked state.
   */
  isChecked(): boolean {
    return AppStorage.Get<boolean>(`CheckBox_${this.id}_checked`) || false;
  }

  /**
   * Toggles the checked state.
   */
  toggle(): void {
    const current = this.isChecked();
    this.setChecked(!current);
  }

  /**
   * Sets the text color.
   */
  setTextColor(color: number): void {
    AppStorage.SetOrCreate<number>(`CheckBox_${this.id}_textColor`, color);
  }

  /**
   * Gets the text color.
   */
  getTextColor(): number {
    return AppStorage.Get<number>(`CheckBox_${this.id}_textColor`) || 0xFF000000;
  }

  /**
   * Sets the text size.
   */
  setTextSize(size: number): void {
    AppStorage.SetOrCreate<number>(`CheckBox_${this.id}_textSize`, size);
  }

  /**
   * Gets the text size.
   */
  getTextSize(): number {
    return AppStorage.Get<number>(`CheckBox_${this.id}_textSize`) || 14;
  }

  /**
   * Sets the checked change listener.
   */
  setOnCheckedChangeListener(listener: OnCheckedChangeListener): void {
    this.checkedChangeListener = listener;
  }

  /**
   * Internal method to dispatch checked change events.
   */
  dispatchCheckedChange(isChecked: boolean): void {
    if (this.checkedChangeListener && this.isEnabled()) {
      this.checkedChangeListener.onCheckedChanged(this, isChecked);
    }
  }

  /**
   * Sets the button drawable (for custom checkbox appearance).
   * In the bridge, this would be handled by custom styling.
   */
  setButtonDrawable(resId: number): void {
    AppStorage.SetOrCreate<number>(`CheckBox_${this.id}_buttonDrawable`, resId);
  }

  /**
   * Gets the button drawable resource ID.
   */
  getButtonDrawable(): number {
    return AppStorage.Get<number>(`CheckBox_${this.id}_buttonDrawable`) || 0;
  }
}

/**
 * CompoundButton constants for compatibility
 */
export class CompoundButton {
  static readonly CHECKED_STATE_SET: number[] = [0x0101009e]; // Android attribute constant
}
