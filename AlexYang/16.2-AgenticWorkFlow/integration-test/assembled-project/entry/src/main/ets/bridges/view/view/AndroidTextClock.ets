/**
 * AndroidTextClock - 模拟Android TextClock的ArkUI组件
 * 使用ArkUI的TextClock组件显示自动更新的时间
 */

import { ViewRegistry } from '../registry/ViewRegistry';
import { AppStorage } from '@ohos.app.ability.common';
import { ViewProxy, ViewConstants } from './AndroidView';

@Component
export struct AndroidTextClock {
  @Prop id: number;
  @Prop format12Hour: string = 'hh:mm:ss a'; // 12小时格式
  @Prop format24Hour: string = 'HH:mm:ss';   // 24小时格式
  
  // 通过StorageLink绑定到AppStorage
  @StorageLink(`TextClock_${this.id}_format12Hour`) format12HourState: string = '';
  @StorageLink(`TextClock_${this.id}_format24Hour`) format24HourState: string = '';
  @StorageLink(`TextClock_${this.id}_textColor`) textColor: number = 0xFF000000; // 默认黑色
  @StorageLink(`TextClock_${this.id}_textSize`) textSize: number = 14;
  @StorageLink(`TextClock_${this.id}_is24HourMode`) is24HourMode: boolean = false; // 默认12小时制
  // View基类属性
  @StorageLink(`View_${this.id}_visibility`) visibility: number = ViewConstants.VISIBLE;
  @StorageLink(`View_${this.id}_backgroundColor`) backgroundColor: number = 0;
  @StorageLink(`View_${this.id}_enabled`) enabled: boolean = true;

  aboutToAppear() {
    // 确保代理存在
    const registry = ViewRegistry.getInstance();
    registry.getTextClockProxy(this.id);
    // 设置AppStorage初始值（如果未设置）
    if (!AppStorage.Has(`TextClock_${this.id}_format12Hour`)) {
      AppStorage.SetOrCreate(`TextClock_${this.id}_format12Hour`, this.format12Hour);
    }
    if (!AppStorage.Has(`TextClock_${this.id}_format24Hour`)) {
      AppStorage.SetOrCreate(`TextClock_${this.id}_format24Hour`, this.format24Hour);
    }
    if (!AppStorage.Has(`TextClock_${this.id}_textColor`)) {
      AppStorage.SetOrCreate(`TextClock_${this.id}_textColor`, this.textColor);
    }
    if (!AppStorage.Has(`TextClock_${this.id}_textSize`)) {
      AppStorage.SetOrCreate(`TextClock_${this.id}_textSize`, this.textSize);
    }
    if (!AppStorage.Has(`TextClock_${this.id}_is24HourMode`)) {
      AppStorage.SetOrCreate(`TextClock_${this.id}_is24HourMode`, this.is24HourMode);
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

  build() {
    // 使用ArkUI的TextClock组件
    TextClock({
      timeZoneOffset: undefined, // 使用系统时区
      controller: undefined
    })
      .fontColor(this.textColor)
      .fontSize(this.textSize)
      .visibility(this.getArkUIVisibility())
      .backgroundColor(this.backgroundColor)
      .enabled(this.enabled)
      .format(this.getCurrentFormat())
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

  private getCurrentFormat(): string {
    const is24Hour = this.is24HourMode;
    if (is24Hour) {
      return this.format24HourState || this.format24Hour || 'HH:mm:ss';
    } else {
      return this.format12HourState || this.format12Hour || 'hh:mm:ss a';
    }
  }
}

// 代理类，供Android代码调用
export class TextClockProxy extends ViewProxy {
  constructor(id: number) {
    super(id);
  }

  setFormat12Hour(format: string): void {
    AppStorage.SetOrCreate<string>(`TextClock_${this.id}_format12Hour`, format);
  }

  getFormat12Hour(): string {
    return AppStorage.Get<string>(`TextClock_${this.id}_format12Hour`) || 'hh:mm:ss a';
  }

  setFormat24Hour(format: string): void {
    AppStorage.SetOrCreate<string>(`TextClock_${this.id}_format24Hour`, format);
  }

  getFormat24Hour(): string {
    return AppStorage.Get<string>(`TextClock_${this.id}_format24Hour`) || 'HH:mm:ss';
  }

  setTextColor(color: number): void {
    AppStorage.SetOrCreate<number>(`TextClock_${this.id}_textColor`, color);
  }

  setTextSize(size: number): void {
    AppStorage.SetOrCreate<number>(`TextClock_${this.id}_textSize`, size);
  }

  setIs24HourMode(is24Hour: boolean): void {
    AppStorage.SetOrCreate<boolean>(`TextClock_${this.id}_is24HourMode`, is24Hour);
  }

  getIs24HourMode(): boolean {
    return AppStorage.Get<boolean>(`TextClock_${this.id}_is24HourMode`) || false;
  }
}