/**
 * Toast Implementation
 * 
 * Bridges Android Toast API to HarmonyOS promptAction.
 * Depends on 16.4.4 System.Bridge for actual Toast display.
 */

import { promptAction } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Context } from '../content/Context';

const TAG = 'Toast';

/**
 * Android Toast API wrapper
 * 
 * Usage (from Android code):
 * ```
 * Toast.makeText(context, "Hello", Toast.LENGTH_SHORT).show();
 * ```
 */
export class Toast {
  /**
   * Show the toast for a short period
   */
  static readonly LENGTH_SHORT: number = 2000;

  /**
   * Show the toast for a long period
   */
  static readonly LENGTH_LONG: number = 3500;

  private _text: string;
  private _duration: number;
  private _context: Context;

  /**
   * Private constructor - use makeText factory method
   */
  private constructor(context: Context, text: string, duration: number) {
    this._context = context;
    this._text = text;
    this._duration = duration;
  }

  /**
   * Make a standard toast that just contains text
   * 
   * @param context The context to use
   * @param text The text to show
   * @param duration How long to display the message (LENGTH_SHORT or LENGTH_LONG)
   * @returns Toast instance
   */
  static makeText(context: Context, text: string, duration: number): Toast {
    return new Toast(context, text, duration);
  }

  /**
   * Update the text in a Toast that was previously created
   * 
   * @param resId The new text for the Toast
   */
  setText(resId: number): void;
  setText(s: string): void;
  setText(textOrResId: string | number): void {
    if (typeof textOrResId === 'string') {
      this._text = textOrResId;
    } else {
      // Would resolve from Resources in full implementation
      this._text = '';
    }
  }

  /**
   * Show the view for the specified duration
   */
  show(): void {
    hilog.debug(0x0000, TAG, `Showing toast: "${this._text}" (${this._duration}ms)`);

    // Map to HarmonyOS promptAction
    promptAction.showToast({
      message: this._text,
      duration: this._duration
    }).catch((err: Error) => {
      hilog.error(0x0000, TAG, `Failed to show toast: ${err.message}`);
    });
  }

  /**
   * Close the view if it's showing
   */
  cancel(): void {
    // HarmonyOS promptAction doesn't support canceling
    // This is a no-op for compatibility
    hilog.debug(0x0000, TAG, 'cancel() called (no-op in HarmonyOS)');
  }

  /**
   * Get the text of the toast
   */
  getView(): View | null {
    // Android Toast has a View - HarmonyOS doesn't expose this
    // Return null for compatibility
    return null;
  }

  /**
   * Set the position of the toast
   * 
   * @param gravity Position constant (not fully supported in HarmonyOS)
   * @param xOffset X offset in pixels
   * @param yOffset Y offset in pixels
   */
  setGravity(gravity: number, xOffset: number, yOffset: number): void {
    // HarmonyOS promptAction doesn't support custom positioning
    // This is a no-op for compatibility
    hilog.debug(0x0000, TAG, 'setGravity() called (no-op in HarmonyOS)');
  }
}

// Gravity constants for setGravity
export const GRAVITY_TOP: number = 48;
export const GRAVITY_BOTTOM: number = 80;
export const GRAVITY_LEFT: number = 3;
export const GRAVITY_RIGHT: number = 5;
export const GRAVITY_CENTER_VERTICAL: number = 16;
export const GRAVITY_CENTER_HORIZONTAL: number = 1;
export const GRAVITY_CENTER: number = 17;

// Stub View class for return type
class View {
  // Placeholder
}
