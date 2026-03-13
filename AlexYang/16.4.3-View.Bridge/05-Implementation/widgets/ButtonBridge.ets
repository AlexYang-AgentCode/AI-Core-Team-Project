/**
 * ButtonBridge.ets
 *
 * Bridge for Android's android.widget.Button → ArkUI Button component.
 *
 * Extends TextViewBridge since Android's Button extends TextView.
 * Adds pressed-state management for touch feedback, which in Android
 * is typically handled by StateListDrawable / ColorStateList. Here we
 * maintain normal and pressed colors that the ArkUI component can
 * switch between during touch events.
 */

import { TextViewBridge } from './TextViewBridge';
import { ColorBridge } from './ColorBridge';

export class ButtonBridge extends TextViewBridge {
  /** Whether the button is currently in pressed (touch-down) state. */
  private _isPressed: boolean = false;

  /** Background color in normal (unpressed) state. */
  private _normalColor: string = '';

  /**
   * Background color in pressed state.
   * Default is Color.RED (0xFFFF0000) matching the spec.
   */
  private _pressedColor: string = '#FF0000';

  constructor(id: number) {
    super(id);
  }

  /**
   * Sets the pressed state. Called internally during touch events.
   * When pressed, the ArkUI component should switch to the pressed color.
   *
   * @param pressed - true when finger is down, false on release/cancel
   */
  setPressed(pressed: boolean): void {
    this._isPressed = pressed;
  }

  /**
   * Returns whether the button is currently pressed.
   */
  isPressed(): boolean {
    return this._isPressed;
  }

  /**
   * Sets the normal (unpressed) background color.
   * Overrides ViewBridge.setBackgroundColor to also track the normal color
   * for state-based switching.
   *
   * @param color - 0xAARRGGBB integer
   */
  setBackgroundColor(color: number): void {
    this._normalColor = ColorBridge.toArkUIColor(color);
    super.setBackgroundColor(color);
  }

  /**
   * Sets the pressed-state background color.
   *
   * @param color - 0xAARRGGBB integer
   */
  setPressedColor(color: number): void {
    this._pressedColor = ColorBridge.toArkUIColor(color);
  }

  /**
   * Returns the pressed color as a hex string for ArkUI binding.
   * The component builder uses this when isPressed() returns true.
   */
  getPressedColorState(): string {
    return this._pressedColor;
  }

  /**
   * Returns the appropriate background color based on pressed state.
   * This is a convenience method for ArkUI component builders.
   */
  getBackgroundColorState(): string {
    if (this._isPressed && this._pressedColor !== '') {
      return this._pressedColor;
    }
    // Fall back to normal color, then to parent's logic (drawable filter, etc.)
    if (this._normalColor !== '') {
      return this._normalColor;
    }
    return super.getBackgroundColorState();
  }

  /**
   * Override _dispatchTouch to automatically manage pressed state.
   * On ACTION_DOWN → pressed = true
   * On ACTION_UP / ACTION_CANCEL → pressed = false
   */
  _dispatchTouch(type: number): boolean {
    const ACTION_DOWN = 0;
    const ACTION_UP = 1;
    const ACTION_CANCEL = 3;

    if (type === ACTION_DOWN) {
      this.setPressed(true);
    } else if (type === ACTION_UP || type === ACTION_CANCEL) {
      this.setPressed(false);
    }

    return super._dispatchTouch(type);
  }
}
