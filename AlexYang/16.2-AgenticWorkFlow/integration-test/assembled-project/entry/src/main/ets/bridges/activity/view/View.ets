/**
 * View Base Class and Callback Interfaces
 * 
 * Defines Android View API interface.
 * Actual implementation is provided by 16.4.3 View.Bridge.
 */

import { Context } from '../content/Context';

// ===== Callback Interfaces =====

export interface OnClickListener {
  onClick(view: View): void;
}

export interface OnTouchListener {
  onTouch(view: View, event: MotionEvent): boolean;
}

export interface OnLongClickListener {
  onLongClick(view: View): boolean;
}

export interface OnKeyListener {
  onKey(view: View, keyCode: number, event: KeyEvent): boolean;
}

// ===== Event Classes =====

export class MotionEvent {
  // Action constants
  static readonly ACTION_DOWN: number = 0;
  static readonly ACTION_UP: number = 1;
  static readonly ACTION_MOVE: number = 2;
  static readonly ACTION_CANCEL: number = 3;
  static readonly ACTION_OUTSIDE: number = 4;
  static readonly ACTION_POINTER_DOWN: number = 5;
  static readonly ACTION_POINTER_UP: number = 6;

  private _action: number;
  private _x: number;
  private _y: number;
  private _eventTime: number;
  private _downTime: number;
  private _pointerId: number;

  constructor(action: number, x: number, y: number) {
    this._action = action;
    this._x = x;
    this._y = y;
    this._eventTime = Date.now();
    this._downTime = Date.now();
    this._pointerId = 0;
  }

  getAction(): number {
    return this._action;
  }

  getX(): number {
    return this._x;
  }

  getY(): number {
    return this._y;
  }

  getEventTime(): number {
    return this._eventTime;
  }

  getDownTime(): number {
    return this._downTime;
  }

  getPointerId(): number {
    return this._pointerId;
  }

  /**
   * Create from HarmonyOS TouchEvent
   */
  static fromTouchEvent(event: TouchEvent): MotionEvent {
    let action: number;
    
    switch (event.type) {
      case TouchType.Down:
        action = MotionEvent.ACTION_DOWN;
        break;
      case TouchType.Up:
        action = MotionEvent.ACTION_UP;
        break;
      case TouchType.Move:
        action = MotionEvent.ACTION_MOVE;
        break;
      case TouchType.Cancel:
        action = MotionEvent.ACTION_CANCEL;
        break;
      default:
        action = MotionEvent.ACTION_DOWN;
    }
    
    const touch = event.touches[0];
    return new MotionEvent(action, touch?.x ?? 0, touch?.y ?? 0);
  }
}

export class KeyEvent {
  static readonly KEYCODE_BACK: number = 4;
  static readonly KEYCODE_HOME: number = 3;
  static readonly KEYCODE_MENU: number = 82;
  static readonly ACTION_DOWN: number = 0;
  static readonly ACTION_UP: number = 1;

  private _keyCode: number;
  private _action: number;

  constructor(keyCode: number, action: number) {
    this._keyCode = keyCode;
    this._action = action;
  }

  getKeyCode(): number {
    return this._keyCode;
  }

  getAction(): number {
    return this._action;
  }
}

// ===== View Interface =====

export abstract class View {
  protected _id: number = -1;
  protected _context: Context;
  protected _visibility: number = View.VISIBLE;
  
  // Event listeners
  protected _clickListener: OnClickListener | null = null;
  protected _touchListener: OnTouchListener | null = null;
  protected _longClickListener: OnLongClickListener | null = null;
  protected _keyListener: OnKeyListener | null = null;

  // Visibility constants
  static readonly VISIBLE: number = 0;
  static readonly INVISIBLE: number = 4;
  static readonly GONE: number = 8;

  constructor(context: Context) {
    this._context = context;
  }

  // ===== ID =====
  
  getId(): number {
    return this._id;
  }

  setId(id: number): void {
    this._id = id;
  }

  // ===== Context =====
  
  getContext(): Context {
    return this._context;
  }

  // ===== Visibility =====
  
  setVisibility(visibility: number): void {
    this._visibility = visibility;
    this.requestLayout();
  }

  getVisibility(): number {
    return this._visibility;
  }

  isShown(): boolean {
    return this._visibility === View.VISIBLE;
  }

  // ===== Event Listeners =====
  
  setOnClickListener(listener: OnClickListener | null): void {
    this._clickListener = listener;
  }

  setOnTouchListener(listener: OnTouchListener | null): void {
    this._touchListener = listener;
  }

  setOnLongClickListener(listener: OnLongClickListener | null): void {
    this._longClickListener = listener;
  }

  setOnKeyListener(listener: OnKeyListener | null): void {
    this._keyListener = listener;
  }

  // ===== Event Dispatch =====
  
  dispatchClick(): void {
    if (this._clickListener) {
      this._clickListener.onClick(this);
    }
  }

  dispatchTouchEvent(event: MotionEvent): boolean {
    if (this._touchListener) {
      return this._touchListener.onTouch(this, event);
    }
    return false;
  }

  dispatchLongClick(): boolean {
    if (this._longClickListener) {
      return this._longClickListener.onLongClick(this);
    }
    return false;
  }

  // ===== Layout =====
  
  requestLayout(): void {
    // Trigger re-render in ArkUI
    // Implementation depends on 16.4.3 View.Bridge
  }

  invalidate(): void {
    // Mark view as needing redraw
    // In ArkUI this is automatic, but we keep for compatibility
  }

  // ===== Focus =====
  
  requestFocus(): boolean {
    // Request focus for this view
    return true;
  }

  clearFocus(): void {
    // Clear focus from this view
  }

  hasFocus(): boolean {
    // Return focus state
    return false;
  }

  // ===== Dimensions (abstract) =====
  
  abstract getWidth(): number;
  abstract getHeight(): number;
  abstract getMeasuredWidth(): number;
  abstract getMeasuredHeight(): number;

  // ===== Position (abstract) =====
  
  abstract getLeft(): number;
  abstract getTop(): number;
  abstract getRight(): number;
  abstract getBottom(): number;

  // ===== Tag =====
  
  private _tag: Object | null = null;

  setTag(tag: Object): void {
    this._tag = tag;
  }

  getTag(): Object | null {
    return this._tag;
  }
}

// TouchType from HarmonyOS (for reference)
enum TouchType {
  Down = 0,
  Up = 1,
  Move = 2,
  Cancel = 3
}
