/**
 * AndroidEditText - 模拟Android EditText的ArkUI组件
 * 基于TextInput组件，支持文本输入和编辑
 */

import { ViewRegistry } from '../registry/ViewRegistry';
import { AppStorage } from '@ohos.app.ability.common';
import { ViewProxy, ViewConstants } from './AndroidView';
import { TextViewProxy } from './AndroidTextView';

@Component
export struct AndroidEditText {
  @Prop id: number;
  @Prop text: string = '';
  @Prop hint: string = '';
  
  // 通过StorageLink绑定到AppStorage
  @StorageLink(`EditText_${this.id}_text`) editText: string = '';
  @StorageLink(`EditText_${this.id}_hint`) editHint: string = '';
  @StorageLink(`EditText_${this.id}_textColor`) textColor: number = 0xFF000000; // 默认黑色
  @StorageLink(`EditText_${this.id}_textSize`) textSize: number = 14;
  // View基类属性
  @StorageLink(`View_${this.id}_visibility`) visibility: number = ViewConstants.VISIBLE;
  @StorageLink(`View_${this.id}_backgroundColor`) backgroundColor: number = 0xFFFFFFFF; // 默认白色
  @StorageLink(`View_${this.id}_enabled`) enabled: boolean = true;
  // EditText特有属性
  @StorageLink(`EditText_${this.id}_inputType`) inputType: number = 1; // 1 = TEXT, 2 = NUMBER, 3 = PHONE, etc.
  @StorageLink(`EditText_${this.id}_onTextChanged`) onTextChangedCallback: ((text: string) => void) | null = null;

  aboutToAppear() {
    // 确保代理存在
    const registry = ViewRegistry.getInstance();
    registry.getEditTextProxy(this.id);
    // 设置AppStorage初始值（如果未设置）
    if (!AppStorage.Has(`EditText_${this.id}_text`)) {
      AppStorage.SetOrCreate(`EditText_${this.id}_text`, this.text);
    }
    if (!AppStorage.Has(`EditText_${this.id}_hint`)) {
      AppStorage.SetOrCreate(`EditText_${this.id}_hint`, this.hint);
    }
    if (!AppStorage.Has(`EditText_${this.id}_textColor`)) {
      AppStorage.SetOrCreate(`EditText_${this.id}_textColor`, this.textColor);
    }
    if (!AppStorage.Has(`EditText_${this.id}_textSize`)) {
      AppStorage.SetOrCreate(`EditText_${this.id}_textSize`, this.textSize);
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
    // EditText特有属性
    if (!AppStorage.Has(`EditText_${this.id}_inputType`)) {
      AppStorage.SetOrCreate(`EditText_${this.id}_inputType`, this.inputType);
    }
    // 兼容性：同步旧版EditText-specific属性到View属性
    if (AppStorage.Has(`EditText_${this.id}_backgroundColor`)) {
      const editTextColor = AppStorage.Get<number>(`EditText_${this.id}_backgroundColor`);
      AppStorage.SetOrCreate(`View_${this.id}_backgroundColor`, editTextColor);
    }
    if (AppStorage.Has(`EditText_${this.id}_enabled`)) {
      const editTextEnabled = AppStorage.Get<boolean>(`EditText_${this.id}_enabled`);
      AppStorage.SetOrCreate(`View_${this.id}_enabled`, editTextEnabled);
    }
  }

  build() {
    TextInput({ placeholder: this.editHint || this.hint, text: this.editText || this.text })
      .fontColor(this.textColor)
      .fontSize(this.textSize)
      .visibility(this.getArkUIVisibility())
      .backgroundColor(this.backgroundColor)
      .enabled(this.enabled)
      .type(this.getInputType())
      .onChange((value: string) => {
        this.editText = value;
        if (this.onTextChangedCallback) {
          this.onTextChangedCallback(value);
        }
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

  private getInputType(): InputType {
    switch (this.inputType) {
      case 2: // InputType.TYPE_CLASS_NUMBER
        return InputType.Number;
      case 3: // InputType.TYPE_CLASS_PHONE
        return InputType.PhoneNumber;
      case 129: // InputType.TYPE_TEXT_VARIATION_PASSWORD
        return InputType.Password;
      case 145: // InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS
        return InputType.Email;
      default:
        return InputType.Normal;
    }
  }
}

// 代理类，供Android代码调用
export class EditTextProxy extends TextViewProxy {
  constructor(id: number) {
    super(id);
  }

  setHint(hint: string): void {
    AppStorage.SetOrCreate<string>(`EditText_${this.id}_hint`, hint);
  }

  getHint(): string {
    return AppStorage.Get<string>(`EditText_${this.id}_hint`) || '';
  }

  setBackgroundColor(color: number): void {
    super.setBackgroundColor(color); // 设置View_${id}_backgroundColor
    AppStorage.SetOrCreate<number>(`EditText_${this.id}_backgroundColor`, color);
  }

  setInputType(inputType: number): void {
    AppStorage.SetOrCreate<number>(`EditText_${this.id}_inputType`, inputType);
  }

  setEnabled(enabled: boolean): void {
    super.setEnabled(enabled); // 设置View_${id}_enabled
    AppStorage.SetOrCreate<boolean>(`EditText_${this.id}_enabled`, enabled);
  }

  setOnTextChangedListener(listener: (text: string) => void): void {
    AppStorage.SetOrCreate(`EditText_${this.id}_onTextChanged`, listener);
  }
}

// 输入类型常量（模拟Android InputType）
export class InputTypeConstants {
  static readonly TYPE_CLASS_TEXT = 1;
  static readonly TYPE_CLASS_NUMBER = 2;
  static readonly TYPE_CLASS_PHONE = 3;
  static readonly TYPE_TEXT_VARIATION_PASSWORD = 129;
  static readonly TYPE_TEXT_VARIATION_EMAIL_ADDRESS = 145;
}