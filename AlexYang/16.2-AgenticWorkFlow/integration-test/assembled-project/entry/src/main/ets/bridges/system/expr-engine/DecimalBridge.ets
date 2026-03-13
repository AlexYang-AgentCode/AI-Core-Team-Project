/**
 * DecimalBridge — java.math.BigDecimal bridge for HarmonyOS
 *
 * Provides the same API surface as Android's BigDecimal so migrated code
 * can keep its existing arithmetic and rounding calls. Internally uses
 * JavaScript number (IEEE 754 double) which gives ~15-17 significant digits.
 *
 * For most mobile calculator/business apps this precision is sufficient.
 * If true arbitrary-precision is needed, swap the internal representation
 * to a big-decimal library later without changing the public API.
 *
 * Usage (mirrors Java):
 *   const a = new DecimalBridge("123.456");
 *   const b = new DecimalBridge(2);
 *   const c = a.multiply(b).setScale(2, DecimalBridge.ROUND_HALF_UP);
 *   console.log(c.toPlainString()); // "246.91"
 */

export class DecimalBridge {
  private _value: number;

  // ===========================================================================
  // Rounding mode constants (match java.math.BigDecimal values)
  // ===========================================================================

  static readonly ROUND_UP: number = 0;
  static readonly ROUND_DOWN: number = 1;
  static readonly ROUND_CEILING: number = 2;
  static readonly ROUND_FLOOR: number = 3;
  static readonly ROUND_HALF_UP: number = 4;
  static readonly ROUND_HALF_DOWN: number = 5;
  static readonly ROUND_HALF_EVEN: number = 6;

  // ===========================================================================
  // Constructor
  // ===========================================================================

  constructor(value: string | number) {
    if (typeof value === 'string') {
      const parsed = parseFloat(value);
      if (isNaN(parsed)) {
        throw new Error(`DecimalBridge: invalid number string "${value}"`);
      }
      this._value = parsed;
    } else {
      this._value = value;
    }
  }

  // ===========================================================================
  // Arithmetic
  // ===========================================================================

  add(other: DecimalBridge): DecimalBridge {
    return new DecimalBridge(this._value + other._value);
  }

  subtract(other: DecimalBridge): DecimalBridge {
    return new DecimalBridge(this._value - other._value);
  }

  multiply(other: DecimalBridge): DecimalBridge {
    return new DecimalBridge(this._value * other._value);
  }

  /**
   * Divide this by other.
   * If scale and roundingMode are provided, the result is rounded to
   * the given number of decimal places.
   */
  divide(other: DecimalBridge, scale?: number, roundingMode?: number): DecimalBridge {
    if (other._value === 0) {
      throw new Error('DecimalBridge: division by zero');
    }
    const raw = this._value / other._value;
    if (scale !== undefined && roundingMode !== undefined) {
      return new DecimalBridge(DecimalBridge._round(raw, scale, roundingMode));
    }
    return new DecimalBridge(raw);
  }

  // ===========================================================================
  // Comparison
  // ===========================================================================

  /**
   * Compare to another DecimalBridge.
   * Returns -1, 0, or 1 — same semantics as Java's compareTo.
   */
  compareTo(other: DecimalBridge): number {
    if (this._value < other._value) return -1;
    if (this._value > other._value) return 1;
    return 0;
  }

  // ===========================================================================
  // Scale / rounding
  // ===========================================================================

  /**
   * Return a new DecimalBridge rounded to the given scale (decimal places)
   * using the specified rounding mode.
   */
  setScale(scale: number, roundingMode: number): DecimalBridge {
    return new DecimalBridge(DecimalBridge._round(this._value, scale, roundingMode));
  }

  // ===========================================================================
  // String output
  // ===========================================================================

  /**
   * Return the number as a plain decimal string (no scientific notation).
   */
  toPlainString(): string {
    return DecimalBridge._toPlain(this._value);
  }

  toString(): string {
    return this.toPlainString();
  }

  valueOf(): number {
    return this._value;
  }

  // ===========================================================================
  // Internal rounding logic
  // ===========================================================================

  /**
   * Round a number to the given number of decimal places using the
   * specified Java BigDecimal rounding mode.
   */
  private static _round(value: number, scale: number, mode: number): number {
    const factor = Math.pow(10, scale);
    const shifted = value * factor;

    switch (mode) {
      case DecimalBridge.ROUND_UP:
        // Away from zero
        return (shifted > 0 ? Math.ceil(shifted) : Math.floor(shifted)) / factor;

      case DecimalBridge.ROUND_DOWN:
        // Towards zero (truncate)
        return Math.trunc(shifted) / factor;

      case DecimalBridge.ROUND_CEILING:
        // Towards positive infinity
        return Math.ceil(shifted) / factor;

      case DecimalBridge.ROUND_FLOOR:
        // Towards negative infinity
        return Math.floor(shifted) / factor;

      case DecimalBridge.ROUND_HALF_UP:
        // Round half away from zero (standard rounding)
        return DecimalBridge._roundHalfUp(shifted) / factor;

      case DecimalBridge.ROUND_HALF_DOWN:
        // Round half towards zero
        return DecimalBridge._roundHalfDown(shifted) / factor;

      case DecimalBridge.ROUND_HALF_EVEN:
        // Banker's rounding
        return DecimalBridge._roundHalfEven(shifted) / factor;

      default:
        throw new Error(`DecimalBridge: unknown rounding mode ${mode}`);
    }
  }

  /** Round half away from zero: 2.5 → 3, -2.5 → -3 */
  private static _roundHalfUp(x: number): number {
    if (x >= 0) {
      return Math.floor(x + 0.5);
    }
    return Math.ceil(x - 0.5);
  }

  /** Round half towards zero: 2.5 → 2, -2.5 → -2 */
  private static _roundHalfDown(x: number): number {
    const floor = Math.floor(x);
    const frac = x - floor;
    // If exactly 0.5, go towards zero
    if (Math.abs(frac - 0.5) < 1e-12) {
      return x >= 0 ? floor : Math.ceil(x);
    }
    return Math.round(x);
  }

  /** Banker's rounding: round half to even. 2.5 → 2, 3.5 → 4 */
  private static _roundHalfEven(x: number): number {
    const rounded = Math.round(x);
    const frac = Math.abs(x) - Math.floor(Math.abs(x));

    // Check if we are exactly at .5
    if (Math.abs(frac - 0.5) < 1e-12) {
      // Round to the nearest even integer
      const floor = Math.floor(x);
      const ceil = Math.ceil(x);
      if (floor % 2 === 0) return floor;
      return ceil;
    }

    return rounded;
  }

  /**
   * Convert a number to a plain decimal string, avoiding scientific notation.
   * JavaScript's toString() may output "1e-7" for very small numbers.
   */
  private static _toPlain(value: number): string {
    if (Number.isNaN(value)) return 'NaN';
    if (!Number.isFinite(value)) return value > 0 ? 'Infinity' : '-Infinity';

    const str = String(value);
    // If there's no 'e' or 'E', it's already plain
    if (str.indexOf('e') === -1 && str.indexOf('E') === -1) {
      return str;
    }

    // Use toFixed with enough decimal places to avoid scientific notation
    // IEEE 754 double has at most 17 significant digits
    const abs = Math.abs(value);
    if (abs < 1) {
      // Small number: need enough decimals
      const fixed = value.toFixed(20);
      // Trim trailing zeros after the decimal point
      return DecimalBridge._trimTrailingZeros(fixed);
    } else {
      // Large number
      const fixed = value.toFixed(0);
      return fixed;
    }
  }

  /** Remove trailing zeros from a decimal string: "1.2300" → "1.23" */
  private static _trimTrailingZeros(s: string): string {
    if (s.indexOf('.') === -1) return s;
    let end = s.length - 1;
    while (end > 0 && s[end] === '0') {
      end--;
    }
    if (s[end] === '.') {
      end--; // remove trailing dot too
    }
    return s.substring(0, end + 1);
  }
}
