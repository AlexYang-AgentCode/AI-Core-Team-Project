/**
 * ToastBridge.ets
 *
 * Bridge for Android's android.widget.Toast → ArkUI promptAction.showToast.
 *
 * Android Toast is a static utility class that shows short popup messages.
 * In ArkUI, we use promptAction.showToast for the same purpose.
 *
 * Usage:
 *   ToastBridge.makeText(context, "Hello", ToastBridge.LENGTH_SHORT).show();
 *   ToastBridge.makeText(context, R.string.message, ToastBridge.LENGTH_LONG).show();
 */

import promptAction from '@ohos.promptAction';

/**
 * Toast duration constants matching Android's Toast class.
 */
export class ToastDuration {
  /** Short display duration (2 seconds). */
  static readonly LENGTH_SHORT: number = 2000;

  /** Long display duration (3.5 seconds). */
  static readonly LENGTH_LONG: number = 3500;
}

/**
 * Toast message representation, similar to Android's Toast internal structure.
 */
export class ToastMessage {
  private text: string = '';
  private duration: number = ToastDuration.LENGTH_SHORT;

  constructor(text: string, duration: number) {
    this.text = text;
    this.duration = duration;
  }

  /**
   * Displays the toast message using ArkUI's promptAction.
   * This is the equivalent of Toast.show() in Android.
   */
  show(): void {
    promptAction.showToast({
      message: this.text,
      duration: this.duration
    });
  }

  /**
   * Sets the text to be displayed.
   */
  setText(text: string): void {
    this.text = text;
  }

  /**
   * Gets the current text.
   */
  getText(): string {
    return this.text;
  }

  /**
   * Sets the duration.
   */
  setDuration(duration: number): void {
    this.duration = duration;
  }

  /**
   * Gets the current duration.
   */
  getDuration(): number {
    return this.duration;
  }
}

/**
 * Toast bridge class matching Android's android.widget.Toast API.
 *
 * In Android, Toast is typically used as:
 *   Toast.makeText(context, "Message", Toast.LENGTH_SHORT).show();
 *
 * In the bridge, context is not needed (ArkUI doesn't require it), so we use:
 *   ToastBridge.makeText(null, "Message", ToastBridge.LENGTH_SHORT).show();
 */
export class ToastBridge {
  /** Short display duration (2 seconds). */
  static readonly LENGTH_SHORT: number = ToastDuration.LENGTH_SHORT;

  /** Long display duration (3.5 seconds). */
  static readonly LENGTH_LONG: number = ToastDuration.LENGTH_LONG;

  /**
   * Creates a Toast message from a string.
   *
   * @param context - Android Context (ignored in ArkUI, pass null)
   * @param text - The text to display
   * @param duration - Either LENGTH_SHORT or LENGTH_LONG
   * @returns A ToastMessage object that can be shown
   */
  static makeText(context: object | null, text: string, duration: number): ToastMessage {
    return new ToastMessage(text, duration);
  }

  /**
   * Creates a Toast message from a resource ID.
   * In the bridge, resource IDs are resolved to strings externally.
   *
   * @param context - Android Context (ignored in ArkUI, pass null)
   * @param resId - Resource ID (should be resolved to string before calling)
   * @param duration - Either LENGTH_SHORT or LENGTH_LONG
   * @returns A ToastMessage object that can be shown
   */
  static makeTextWithResId(context: object | null, resId: number, duration: number): ToastMessage {
    // Resource lookup would be handled by the adapter layer
    // For now, return a placeholder message
    return new ToastMessage(`[Resource ID: ${resId}]`, duration);
  }

  /**
   * Convenience method to show a toast immediately.
   * This combines makeText and show into one call.
   *
   * @param text - The text to display
   * @param duration - Either LENGTH_SHORT or LENGTH_LONG (defaults to SHORT)
   */
  static showText(text: string, duration: number = ToastDuration.LENGTH_SHORT): void {
    promptAction.showToast({
      message: text,
      duration: duration
    });
  }

  /**
   * Shows a toast with centered alignment (Android Toast supports setGravity).
   * Note: ArkUI's showToast doesn't support gravity, this is for API compatibility.
   *
   * @param text - The text to display
   * @param duration - Either LENGTH_SHORT or LENGTH_LONG
   * @param gravity - Android Gravity constant (ignored in ArkUI)
   * @param xOffset - X offset in pixels (ignored in ArkUI)
   * @param yOffset - Y offset in pixels (ignored in ArkUI)
   */
  static showTextWithGravity(
    text: string,
    duration: number,
    gravity: number,
    xOffset: number = 0,
    yOffset: number = 0
  ): void {
    // ArkUI's showToast doesn't support gravity positioning
    // We just show the standard toast for compatibility
    promptAction.showToast({
      message: text,
      duration: duration
    });
  }
}

/**
 * Re-export for convenience - allows import { Toast } from './ToastBridge'.
 */
export const Toast = ToastBridge;
