/**
 * TextViewBridge.ets
 *
 * Bridge for Android's android.widget.TextView → ArkUI Text component.
 *
 * Maps imperative TextView APIs (setText, setTextColor, setTextSize, setGravity)
 * to observable state that ArkUI Text components can bind to via @State.
 *
 * Android gravity constants are mapped to ArkUI's TextAlign enum for
 * horizontal text alignment.
 */

import { ViewBridge } from './ViewBridge';
import { CharSequence } from './CharSequence';
import { ColorBridge } from './ColorBridge';

/**
 * Android TypedValue unit constants used in setTextSize(unit, size).
 */
export class TypedValue {
  static readonly COMPLEX_UNIT_PX: number = 0;
  static readonly COMPLEX_UNIT_DIP: number = 1;
  static readonly COMPLEX_UNIT_SP: number = 2;
  static readonly COMPLEX_UNIT_PT: number = 3;
  static readonly COMPLEX_UNIT_IN: number = 4;
  static readonly COMPLEX_UNIT_MM: number = 5;
}

export class TextViewBridge extends ViewBridge {
  /** The displayed text content. */
  private _text: string = '';

  /** Text color as an ArkUI hex string. Default is black. */
  private _textColor: string = '#000000';

  /** Text size in fp (ArkUI font points). Default 16. */
  private _textSize: number = 16;

  /**
   * Android Gravity flags for text alignment.
   * Gravity.LEFT=3, Gravity.CENTER=17, Gravity.RIGHT=5, Gravity.END=8388613
   */
  private _gravity: number = 0;

  constructor(id: number) {
    super(id);
  }

  // ---- Text ----

  /**
   * Sets the text content. Accepts either a string or a numeric resource ID.
   * When a number is passed, it is converted to its string representation
   * (resource lookup would be handled by the adapter layer).
   *
   * @param text - string content or numeric value
   */
  setText(text: string | number): void {
    if (typeof text === 'number') {
      this._text = text.toString();
    } else {
      this._text = text;
    }
  }

  /**
   * Returns the text as a CharSequence, matching Android's TextView.getText().
   * The returned CharSequence wraps the current text string.
   */
  getText(): CharSequence {
    return new CharSequence(this._text);
  }

  // ---- Text color ----

  /**
   * Sets the text color from an Android 32-bit ARGB color integer.
   *
   * @param color - 0xAARRGGBB integer (e.g. 0xFFFF0000 for red)
   */
  setTextColor(color: number): void {
    this._textColor = ColorBridge.toArkUIColor(color);
  }

  // ---- Text size ----

  /**
   * Sets the text size. In Android, the unit parameter determines the
   * measurement unit (SP, DP, PX, etc.). ArkUI uses fp (font points)
   * which is analogous to Android's SP.
   *
   * For simplicity, all units are treated as fp in this bridge.
   * A more complete implementation could apply conversion factors.
   *
   * @param unit - TypedValue.COMPLEX_UNIT_* constant
   * @param size - the text size value
   */
  setTextSize(unit: number, size: number): void {
    // In ArkUI, fp ≈ sp. For px/dp/pt/in/mm, a conversion factor
    // would be needed based on device density. For now, use size directly.
    this._textSize = size;
  }

  // ---- Gravity / alignment ----

  /**
   * Sets the gravity (alignment) for the text content.
   * Maps Android Gravity flags to ArkUI TextAlign values.
   *
   * @param gravity - Android Gravity constant or combined flags
   */
  setGravity(gravity: number): void {
    this._gravity = gravity;
  }

  // ---- State getters for ArkUI binding ----

  /**
   * Returns the current text for ArkUI Text component content.
   */
  getTextState(): string {
    return this._text;
  }

  /**
   * Returns the current text color as a hex string for ArkUI .fontColor().
   */
  getTextColorState(): string {
    return this._textColor;
  }

  /**
   * Returns the current text size in fp for ArkUI .fontSize().
   */
  getTextSizeState(): number {
    return this._textSize;
  }

  /**
   * Maps the Android gravity value to an ArkUI TextAlign enum value.
   *
   * Mapping:
   *   Gravity.LEFT (3) / Gravity.START / default → TextAlign.Start (0)
   *   Gravity.CENTER (17) / CENTER_HORIZONTAL (1) → TextAlign.Center (1)
   *   Gravity.RIGHT (5) / Gravity.END (8388613)  → TextAlign.End (2)
   *
   * Note: ArkUI TextAlign enum values — Start=0, Center=1, End=2.
   * We return number to avoid importing ArkUI types in the bridge layer.
   */
  getGravityState(): number {
    // Check for CENTER first (Gravity.CENTER = 17 includes both axes)
    if (this._gravity === 17 || this._gravity === 1) {
      return 1; // TextAlign.Center
    }
    // RIGHT or END
    if (this._gravity === 5 || this._gravity === 8388613) {
      return 2; // TextAlign.End
    }
    // Bitmask check: horizontal center bit (bit 0) set
    if ((this._gravity & 1) !== 0) {
      return 1; // TextAlign.Center
    }
    // Bitmask check: RIGHT bit (bit 2) set
    if ((this._gravity & 5) === 5) {
      return 2; // TextAlign.End
    }
    // Default: LEFT / START
    return 0; // TextAlign.Start
  }
}
