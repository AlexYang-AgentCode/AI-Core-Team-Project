/**
 * TouchEventBridge.ts
 * Android MotionEvent 到 HarmonyOS TouchEvent 的桥接实现
 * 
 * 提供触摸事件映射、坐标转换等功能
 */

import { TouchEvent, TouchType } from '@kit.ArkUI';

/**
 * Android MotionEvent 动作常量
 */
export class MotionEvent {
  // 动作类型
  static readonly ACTION_DOWN = 0;
  static readonly ACTION_UP = 1;
  static readonly ACTION_MOVE = 2;
  static readonly ACTION_CANCEL = 3;
  static readonly ACTION_OUTSIDE = 4;
  static readonly ACTION_POINTER_DOWN = 5;
  static readonly ACTION_POINTER_UP = 6;
  static readonly ACTION_HOVER_MOVE = 7;
  static readonly ACTION_SCROLL = 8;
  static readonly ACTION_HOVER_ENTER = 9;
  static readonly ACTION_HOVER_EXIT = 10;
  static readonly ACTION_BUTTON_PRESS = 11;
  static readonly ACTION_BUTTON_RELEASE = 12;

  // 边缘标志
  static readonly EDGE_TOP = 0x00000001;
  static readonly EDGE_BOTTOM = 0x00000002;
  static readonly EDGE_LEFT = 0x00000004;
  static readonly EDGE_RIGHT = 0x00000008;

  // 按钮状态
  static readonly BUTTON_PRIMARY = 1;
  static readonly BUTTON_SECONDARY = 2;
  static readonly BUTTON_TERTIARY = 4;
  static readonly BUTTON_BACK = 8;
  static readonly BUTTON_FORWARD = 16;

  // 工具类型
  static readonly TOOL_TYPE_UNKNOWN = 0;
  static readonly TOOL_TYPE_FINGER = 1;
  static readonly TOOL_TYPE_STYLUS = 2;
  static readonly TOOL_TYPE_MOUSE = 3;
  static readonly TOOL_TYPE_ERASER = 4;
}

/**
 * 触摸事件桥接类
 * 将HarmonyOS TouchEvent转换为Android MotionEvent格式
 */
export class TouchEventBridge {
  private touchEvent: TouchEvent;

  /**
   * 构造函数
   * @param touchEvent HarmonyOS TouchEvent
   */
  constructor(touchEvent: TouchEvent) {
    this.touchEvent = touchEvent;
  }

  /**
   * 获取动作类型
   * 对应Android: event.getAction()
   */
  getAction(): number {
    switch (this.touchEvent.type) {
      case TouchType.Down:
        return MotionEvent.ACTION_DOWN;
      case TouchType.Up:
        return MotionEvent.ACTION_UP;
      case TouchType.Move:
        return MotionEvent.ACTION_MOVE;
      case TouchType.Cancel:
        return MotionEvent.ACTION_CANCEL;
      default:
        return MotionEvent.ACTION_OUTSIDE;
    }
  }

  /**
   * 获取动作掩码（用于多指触控）
   * 对应Android: event.getActionMasked()
   */
  getActionMasked(): number {
    return this.getAction();
  }

  /**
   * 获取动作索引（用于多指触控）
   * 对应Android: event.getActionIndex()
   */
  getActionIndex(): number {
    // HarmonyOS可能不直接支持，返回0
    return 0;
  }

  /**
   * 获取X坐标
   * 对应Android: event.getX()
   */
  getX(pointerIndex?: number): number {
    return this.touchEvent.touches[0]?.screenX || 0;
  }

  /**
   * 获取Y坐标
   * 对应Android: event.getY()
   */
  getY(pointerIndex?: number): number {
    return this.touchEvent.touches[0]?.screenY || 0;
  }

  /**
   * 获取原始X坐标
   * 对应Android: event.getRawX()
   */
  getRawX(): number {
    return this.getX();
  }

  /**
   * 获取原始Y坐标
   * 对应Android: event.getRawY()
   */
  getRawY(): number {
    return this.getY();
  }

  /**
   * 获取压力值
   * 对应Android: event.getPressure()
   */
  getPressure(pointerIndex?: number): number {
    return this.touchEvent.touches[0]?.force || 1.0;
  }

  /**
   * 获取触摸点大小
   * 对应Android: event.getSize()
   */
  getSize(pointerIndex?: number): number {
    // HarmonyOS可能不直接支持
    return 1.0;
  }

  /**
   * 获取事件时间
   * 对应Android: event.getEventTime()
   */
  getEventTime(): number {
    return this.touchEvent.timeStamp;
  }

  /**
   * 获取按下时间
   * 对应Android: event.getDownTime()
   */
  getDownTime(): number {
    // HarmonyOS可能不直接支持，使用当前时间
    return this.touchEvent.timeStamp;
  }

  /**
   * 获取指针数量
   * 对应Android: event.getPointerCount()
   */
  getPointerCount(): number {
    return this.touchEvent.touches.length;
  }

  /**
   * 获取指针ID
   * 对应Android: event.getPointerId()
   * @param pointerIndex 指针索引
   */
  getPointerId(pointerIndex: number): number {
    return this.touchEvent.touches[pointerIndex]?.id || pointerIndex;
  }

  /**
   * 查找指针索引
   * 对应Android: event.findPointerIndex()
   * @param pointerId 指针ID
   */
  findPointerIndex(pointerId: number): number {
    return this.touchEvent.touches.findIndex(t => t.id === pointerId);
  }

  /**
   * 获取工具类型
   * 对应Android: event.getToolType()
   */
  getToolType(pointerIndex?: number): number {
    // HarmonyOS简化实现，假设都是手指
    return MotionEvent.TOOL_TYPE_FINGER;
  }

  /**
   * 获取边缘标志
   * 对应Android: event.getEdgeFlags()
   */
  getEdgeFlags(): number {
    // HarmonyOS可能不直接支持
    return 0;
  }

  /**
   * 检查按钮状态
   * 对应Android: event.getButtonState()
   */
  getButtonState(): number {
    // HarmonyOS简化实现
    return MotionEvent.BUTTON_PRIMARY;
  }

  /**
   * 是否为点击事件
   */
  isClick(): boolean {
    return this.touchEvent.type === TouchType.Up;
  }

  /**
   * 是否为长按事件（需要额外判断）
   */
  isLongPress(): boolean {
    // 需要结合时间判断，这里简化处理
    return false;
  }

  /**
   * 获取原生TouchEvent
   */
  getNativeEvent(): TouchEvent {
    return this.touchEvent;
  }

  /**
   * 静态工具方法：转换TouchType到MotionEvent动作
   */
  static touchTypeToAction(type: TouchType): number {
    switch (type) {
      case TouchType.Down:
        return MotionEvent.ACTION_DOWN;
      case TouchType.Up:
        return MotionEvent.ACTION_UP;
      case TouchType.Move:
        return MotionEvent.ACTION_MOVE;
      case TouchType.Cancel:
        return MotionEvent.ACTION_CANCEL;
      default:
        return MotionEvent.ACTION_OUTSIDE;
    }
  }

  /**
   * 静态工具方法：获取X坐标
   */
  static getX(event: TouchEvent): number {
    return event.touches[0]?.screenX || 0;
  }

  /**
   * 静态工具方法：获取Y坐标
   */
  static getY(event: TouchEvent): number {
    return event.touches[0]?.screenY || 0;
  }
}

/**
 * 兼容Android MotionEvent类名
 */
export { MotionEvent as MotionEventCompat };

export default TouchEventBridge;
