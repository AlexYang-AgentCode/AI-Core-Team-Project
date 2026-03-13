/**
 * ToastBridge.ts
 * Android Toast API 到 HarmonyOS promptAction 的桥接实现
 * 
 * Android API: Toast.makeText(context, message, duration).show()
 * HarmonyOS:  promptAction.showToast({ message, duration })
 */

import { promptAction } from '@kit.ArkUI';

/**
 * Toast显示时长常量
 */
export class Toast {
  static readonly LENGTH_SHORT = 2000;  // Android: 2000ms
  static readonly LENGTH_LONG = 3500;   // Android: 3500ms

  private message: string;
  private duration: number;

  /**
   * 工厂方法 - 对应Android Toast.makeText()
   * @param context Android Context (HarmonyOS中不使用，保留API兼容)
   * @param message 显示的消息文本
   * @param duration 显示时长 (LENGTH_SHORT 或 LENGTH_LONG)
   * @returns Toast实例
   */
  static makeText(context: object | null, message: string | Resource, duration: number): Toast {
    const msg = typeof message === 'string' ? message : message.toString();
    return new Toast(msg, duration);
  }

  /**
   * 简化版本 - 直接显示Toast
   * @param message 消息文本
   */
  static show(message: string, isLong: boolean = false): void {
    promptAction.showToast({
      message: message,
      duration: isLong ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT
    });
  }

  /**
   * 私有构造函数
   */
  private constructor(message: string, duration: number) {
    this.message = message;
    this.duration = duration;
  }

  /**
   * 显示Toast
   */
  show(): void {
    promptAction.showToast({
      message: this.message,
      duration: this.duration
    });
  }

  /**
   * 设置消息文本 (Android API兼容)
   */
  setText(text: string): void {
    this.message = text;
  }

  /**
   * 设置显示时长 (Android API兼容)
   */
  setDuration(duration: number): void {
    this.duration = duration;
  }

  /**
   * 获取显示时长
   */
  getDuration(): number {
    return this.duration;
  }

  /**
   * 获取消息文本
   */
  getMessage(): string {
    return this.message;
  }
}

export default Toast;
