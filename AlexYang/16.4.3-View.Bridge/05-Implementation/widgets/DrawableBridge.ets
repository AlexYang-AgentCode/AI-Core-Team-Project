/**
 * DrawableBridge.ets
 *
 * Bridge for Android's Drawable class, specifically the background drawable
 * returned by View.getBackground(). In the Android→HarmonyOS bridge, the
 * primary use case is applying color filters to view backgrounds
 * (e.g. drawable.setColorFilter(color, PorterDuff.Mode.SRC_ATOP)).
 *
 * ArkUI does not have a direct Drawable equivalent; instead, we store
 * the filter color and apply it to the view's background via state binding.
 */

import { ColorBridge } from './ColorBridge';

// Forward reference — the actual ViewBridge type is used at runtime.
// We use a minimal interface here to avoid circular imports.
interface ViewBridgeLike {
  getId(): number;
}

export class DrawableBridge {
  /** The current color filter as a hex string, or null if none applied. */
  private _colorFilter: string | null = null;

  /** The PorterDuff mode of the current filter (for reference/debugging). */
  private _filterMode: number = -1;

  /** Back-reference to the owning view (needed for invalidation signals). */
  private _view: ViewBridgeLike;

  /**
   * @param view - the ViewBridge that owns this drawable
   */
  constructor(view: ViewBridgeLike) {
    this._view = view;
  }

  /**
   * Sets a color filter on this drawable.
   * Maps Android's Drawable.setColorFilter(int color, PorterDuff.Mode mode).
   *
   * In ArkUI, we store the resulting color and expose it via getColorFilter()
   * so the component builder can apply it to the background.
   *
   * @param color - Android 32-bit ARGB color integer
   * @param mode  - PorterDuff.Mode ordinal (e.g. SRC_ATOP=9)
   */
  setColorFilter(color: number, mode: number): void {
    this._colorFilter = ColorBridge.toArkUIColor(color);
    this._filterMode = mode;
  }

  /**
   * Removes the color filter from this drawable.
   */
  clearColorFilter(): void {
    this._colorFilter = null;
    this._filterMode = -1;
  }

  /**
   * Returns the current color filter as an ArkUI hex string, or null.
   * ArkUI components should use this to conditionally tint their background.
   */
  getColorFilter(): string | null {
    return this._colorFilter;
  }

  /**
   * Returns the PorterDuff mode ordinal of the active filter, or -1 if none.
   */
  getFilterMode(): number {
    return this._filterMode;
  }
}
