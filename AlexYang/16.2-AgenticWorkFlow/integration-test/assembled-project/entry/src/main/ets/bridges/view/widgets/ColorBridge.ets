/**
 * ColorBridge.ets
 *
 * Maps Android color integers to ArkUI hex color strings.
 *
 * Android stores colors as 32-bit ARGB integers (0xAARRGGBB).
 * ArkUI expects hex strings like '#RRGGBB' or '#AARRGGBB'.
 * This class handles the conversion and provides Android's standard
 * color constants and system color name lookups.
 */

export class ColorBridge {
  // ---- Android Color constants (0xAARRGGBB) ----
  static readonly BLACK: number = 0xFF000000;
  static readonly DKGRAY: number = 0xFF444444;
  static readonly GRAY: number = 0xFF888888;
  static readonly LTGRAY: number = 0xFFCCCCCC;
  static readonly WHITE: number = 0xFFFFFFFF;
  static readonly RED: number = 0xFFFF0000;
  static readonly GREEN: number = 0xFF00FF00;
  static readonly BLUE: number = 0xFF0000FF;
  static readonly YELLOW: number = 0xFFFFFF00;
  static readonly CYAN: number = 0xFF00FFFF;
  static readonly MAGENTA: number = 0xFFFF00FF;
  static readonly TRANSPARENT: number = 0x00000000;

  /**
   * Android system color resource names mapped to hex strings.
   * Covers the most commonly referenced @android:color/ values.
   */
  static readonly SYSTEM_COLORS: Map<string, string> = new Map<string, string>([
    ['@android:color/black', '#000000'],
    ['@android:color/white', '#FFFFFF'],
    ['@android:color/transparent', '#00000000'],
    ['@android:color/holo_red_light', '#FFFF4444'],
    ['@android:color/holo_red_dark', '#FFCC0000'],
    ['@android:color/holo_green_light', '#FF99CC00'],
    ['@android:color/holo_green_dark', '#FF669900'],
    ['@android:color/holo_blue_light', '#FF33B5E5'],
    ['@android:color/holo_blue_dark', '#FF0099CC'],
    ['@android:color/holo_blue_bright', '#FF00DDFF'],
    ['@android:color/holo_orange_light', '#FFFFBB33'],
    ['@android:color/holo_orange_dark', '#FFFF8800'],
    ['@android:color/holo_purple', '#FFAA66CC'],
    ['@android:color/darker_gray', '#FFAAAAAA'],
    ['@android:color/background_light', '#FFFAFAFA'],
    ['@android:color/background_dark', '#FF303030'],
  ]);

  /**
   * Converts an Android 32-bit ARGB color integer to a hex string.
   * Always returns an 8-character hex (AARRGGBB) prefixed with '#'.
   *
   * @param androidColor - 0xAARRGGBB integer
   * @returns hex string, e.g. '#FF0000FF'
   */
  static toHexString(androidColor: number): string {
    // Force unsigned 32-bit interpretation
    const unsigned = androidColor >>> 0;
    const hex = unsigned.toString(16).padStart(8, '0').toUpperCase();
    return `#${hex}`;
  }

  /**
   * Parses a color string into an Android-style 32-bit ARGB integer.
   * Supports formats: '#RGB', '#RRGGBB', '#AARRGGBB', and named colors.
   *
   * @param colorString - e.g. '#FF0000', '#80FF0000', 'red'
   * @returns 0xAARRGGBB integer
   */
  static parseColor(colorString: string): number {
    const named: Record<string, number> = {
      'black': ColorBridge.BLACK,
      'white': ColorBridge.WHITE,
      'red': ColorBridge.RED,
      'green': ColorBridge.GREEN,
      'blue': ColorBridge.BLUE,
      'yellow': ColorBridge.YELLOW,
      'cyan': ColorBridge.CYAN,
      'magenta': ColorBridge.MAGENTA,
      'transparent': ColorBridge.TRANSPARENT,
      'gray': ColorBridge.GRAY,
      'grey': ColorBridge.GRAY,
      'ltgray': ColorBridge.LTGRAY,
      'ltgrey': ColorBridge.LTGRAY,
      'dkgray': ColorBridge.DKGRAY,
      'dkgrey': ColorBridge.DKGRAY,
    };

    const lower = colorString.trim().toLowerCase();
    if (named[lower] !== undefined) {
      return named[lower];
    }

    if (!colorString.startsWith('#')) {
      throw new Error(`Unknown color: ${colorString}`);
    }

    const hex = colorString.substring(1);
    switch (hex.length) {
      case 3: {
        // #RGB → #FFRRGGBB
        const r = hex[0];
        const g = hex[1];
        const b = hex[2];
        return parseInt(`FF${r}${r}${g}${g}${b}${b}`, 16) >>> 0;
      }
      case 6:
        // #RRGGBB → #FFRRGGBB
        return parseInt(`FF${hex}`, 16) >>> 0;
      case 8:
        // #AARRGGBB
        return parseInt(hex, 16) >>> 0;
      default:
        throw new Error(`Invalid color format: ${colorString}`);
    }
  }

  /**
   * Converts an Android 32-bit ARGB color to an ArkUI-compatible hex string.
   * If the alpha channel is fully opaque (0xFF), returns '#RRGGBB'.
   * Otherwise returns '#AARRGGBB' to preserve transparency.
   *
   * @param androidColor - 0xAARRGGBB integer
   * @returns hex string suitable for ArkUI Color properties
   */
  static toArkUIColor(androidColor: number): string {
    const unsigned = androidColor >>> 0;
    const alpha = (unsigned >>> 24) & 0xFF;
    const rgb = unsigned & 0x00FFFFFF;

    if (alpha === 0xFF) {
      // Fully opaque — use short '#RRGGBB' form
      return `#${rgb.toString(16).padStart(6, '0').toUpperCase()}`;
    }
    // Semi-transparent — include alpha
    return `#${unsigned.toString(16).padStart(8, '0').toUpperCase()}`;
  }
}

/**
 * PorterDuff blending modes used by Drawable.setColorFilter().
 * Maps Android's PorterDuff.Mode enum ordinals.
 */
export class PorterDuff {
  static readonly Mode: Record<string, number> = {
    CLEAR: 0,
    SRC: 1,
    DST: 2,
    SRC_OVER: 3,
    DST_OVER: 4,
    SRC_IN: 5,
    DST_IN: 6,
    SRC_OUT: 7,
    DST_OUT: 8,
    SRC_ATOP: 9,
    DST_ATOP: 10,
    XOR: 11,
    DARKEN: 12,
    LIGHTEN: 13,
    MULTIPLY: 14,
    SCREEN: 15,
    ADD: 16,
    OVERLAY: 17,
  };
}
