/**
 * ToastBridge — Android Toast bridge for HarmonyOS
 *
 * Maps Android's Toast.makeText(context, message, duration).show() pattern
 * to HarmonyOS promptAction.showToast().
 *
 * Usage (mirrors Android):
 *   ToastBridge.makeText(ctx, "Hello", ToastBridge.LENGTH_SHORT).show();
 */

import { promptAction } from '@kit.ArkUI';
import { ContextBridge } from './ContextBridge';

export class ToastBridge {
  // Android duration constants
  static readonly LENGTH_SHORT: number = 0;
  static readonly LENGTH_LONG: number = 1;

  private _message: string;
  private _duration: number; // stored as Android constant (0 or 1)

  private constructor(message: string, duration: number) {
    this._message = message;
    this._duration = duration;
  }

  // ---- Factory (mirrors Toast.makeText) ------------------------------------

  /**
   * Create a ToastBridge instance.
   * @param context - ContextBridge (kept for API compatibility; not used internally)
   * @param message - text to display
   * @param duration - LENGTH_SHORT (0) or LENGTH_LONG (1)
   */
  static makeText(context: ContextBridge, message: string, duration: number): ToastBridge {
    return new ToastBridge(message, duration);
  }

  // ---- Show ----------------------------------------------------------------

  /**
   * Display the toast using HarmonyOS promptAction.
   */
  show(): void {
    const ms = ToastBridge._durationToMs(this._duration);
    try {
      promptAction.showToast({
        message: this._message,
        duration: ms
      });
    } catch (e) {
      console.error(`ToastBridge.show failed: ${e}`);
    }
  }

  // ---- Internals -----------------------------------------------------------

  /**
   * Map Android duration constants to milliseconds.
   * LENGTH_SHORT → 2000 ms, LENGTH_LONG → 3500 ms.
   * Any unknown value falls back to 2000 ms.
   */
  private static _durationToMs(duration: number): number {
    switch (duration) {
      case ToastBridge.LENGTH_LONG:
        return 3500;
      case ToastBridge.LENGTH_SHORT:
      default:
        return 2000;
    }
  }
}
