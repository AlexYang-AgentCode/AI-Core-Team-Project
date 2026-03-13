/**
 * ViewBridge.ets
 *
 * Base bridge class that maps Android's android.view.View to ArkUI state.
 *
 * Design rationale:
 * - Android Views are imperative: you call setVisibility(), setBackgroundColor(), etc.
 * - ArkUI components are declarative: state drives the UI automatically.
 * - This bridge stores mutable state in plain properties. An @Observed wrapper
 *   or @State in the host component observes changes and triggers re-renders.
 * - invalidate() is intentionally a no-op because ArkUI re-renders automatically
 *   when observed state changes.
 */

import { DrawableBridge } from './DrawableBridge';
import { ColorBridge } from './ColorBridge';

/**
 * Listener interface matching Android's View.OnClickListener.
 */
export interface OnClickListener {
  onClick(view: ViewBridge): void;
}

/**
 * Listener interface matching Android's View.OnTouchListener.
 * Returns true if the event was consumed, false otherwise.
 */
export interface OnTouchListener {
  onTouch(view: ViewBridge, eventType: number): boolean;
}

/**
 * Touch event type constants matching Android's MotionEvent.
 */
export class MotionEventType {
  static readonly ACTION_DOWN: number = 0;
  static readonly ACTION_UP: number = 1;
  static readonly ACTION_MOVE: number = 2;
  static readonly ACTION_CANCEL: number = 3;
}

export class ViewBridge {
  /** Unique identifier for this view, matching Android's View ID. */
  private _id: number;

  /** Background color as an ArkUI hex string. Empty string means no color set. */
  private _backgroundColor: string = '';

  /** Whether this view is visible. Maps to ArkUI Visibility enum. */
  private _visible: boolean = true;

  /**
   * Android visibility constant: VISIBLE(0), INVISIBLE(4), GONE(8).
   * Stored separately so we can distinguish INVISIBLE from GONE.
   */
  private _visibility: number = 0; // VISIBLE

  /** Whether this view is interactable. */
  private _enabled: boolean = true;

  /** Click listener, set via setOnClickListener(). */
  private _clickListener: OnClickListener | null = null;

  /** Touch listener, set via setOnTouchListener(). */
  private _touchListener: OnTouchListener | null = null;

  /** The background drawable for color filter operations. */
  private _backgroundDrawable: DrawableBridge;

  constructor(id: number) {
    this._id = id;
    this._backgroundDrawable = new DrawableBridge(this);
  }

  // ---- Identity ----

  /**
   * Returns this view's unique identifier.
   */
  getId(): number {
    return this._id;
  }

  // ---- Background ----

  /**
   * Sets the background color from an Android 32-bit ARGB color integer.
   * Converts to hex string for ArkUI consumption.
   *
   * @param color - 0xAARRGGBB integer (e.g. 0xFFFF0000 for red)
   */
  setBackgroundColor(color: number): void {
    this._backgroundColor = ColorBridge.toArkUIColor(color);
  }

  /**
   * Returns the background drawable. In Android, View.getBackground() returns
   * a Drawable; here we return our DrawableBridge which supports setColorFilter().
   */
  getBackground(): DrawableBridge {
    return this._backgroundDrawable;
  }

  // ---- Visibility ----

  /**
   * Sets visibility using Android's integer constants.
   *   VISIBLE   = 0  → show the view, it occupies layout space
   *   INVISIBLE = 4  → hide the view, it still occupies layout space
   *   GONE      = 8  → hide the view and remove it from layout flow
   *
   * @param visibility - one of 0, 4, or 8
   */
  setVisibility(visibility: number): void {
    this._visibility = visibility;
    this._visible = (visibility === 0);
  }

  /**
   * Returns the current Android visibility constant.
   */
  getVisibility(): number {
    return this._visibility;
  }

  // ---- Enabled ----

  /**
   * Sets whether this view is enabled (interactable).
   */
  setEnabled(enabled: boolean): void {
    this._enabled = enabled;
  }

  /**
   * Returns whether this view is enabled.
   */
  isEnabled(): boolean {
    return this._enabled;
  }

  // ---- Invalidation ----

  /**
   * No-op in ArkUI. Android's invalidate() requests a redraw; ArkUI
   * automatically re-renders when @State/@Observed properties change.
   * Kept for API compatibility with Android code that calls view.invalidate().
   */
  invalidate(): void {
    // Intentional no-op — ArkUI is declarative and re-renders automatically.
  }

  // ---- Listeners ----

  /**
   * Registers a click listener, matching Android's View.setOnClickListener().
   */
  setOnClickListener(listener: OnClickListener): void {
    this._clickListener = listener;
  }

  /**
   * Registers a touch listener, matching Android's View.setOnTouchListener().
   */
  setOnTouchListener(listener: OnTouchListener): void {
    this._touchListener = listener;
  }

  // ---- Internal dispatch (called by ArkUI event handlers) ----

  /**
   * Called by the ArkUI onClick handler. Dispatches to the registered
   * OnClickListener if one exists and the view is enabled.
   */
  _dispatchClick(): void {
    if (this._enabled && this._clickListener !== null) {
      this._clickListener.onClick(this);
    }
  }

  /**
   * Called by the ArkUI onTouch handler. Dispatches to the registered
   * OnTouchListener if one exists and the view is enabled.
   *
   * @param type - MotionEvent action type (ACTION_DOWN=0, ACTION_UP=1, etc.)
   * @returns true if the touch event was consumed by the listener
   */
  _dispatchTouch(type: number): boolean {
    if (this._enabled && this._touchListener !== null) {
      return this._touchListener.onTouch(this, type);
    }
    return false;
  }

  // ---- State getters for ArkUI binding ----

  /**
   * Returns the background color hex string for ArkUI .backgroundColor().
   * Empty string means no explicit background color is set.
   */
  getBackgroundColorState(): string {
    // If a color filter is applied on the drawable, prefer that
    const filter = this._backgroundDrawable.getColorFilter();
    if (filter !== null) {
      return filter;
    }
    return this._backgroundColor;
  }

  /**
   * Returns the ArkUI Visibility enum value.
   *   VISIBLE(0)   → Visibility.Visible
   *   INVISIBLE(4) → Visibility.Hidden
   *   GONE(8)      → Visibility.None
   */
  getVisibilityState(): number {
    switch (this._visibility) {
      case 4:  // INVISIBLE
        return 1; // Visibility.Hidden
      case 8:  // GONE
        return 2; // Visibility.None
      default: // VISIBLE
        return 0; // Visibility.Visible
    }
  }

  /**
   * Returns the enabled state for ArkUI .enabled() modifier.
   */
  getEnabledState(): boolean {
    return this._enabled;
  }
}
