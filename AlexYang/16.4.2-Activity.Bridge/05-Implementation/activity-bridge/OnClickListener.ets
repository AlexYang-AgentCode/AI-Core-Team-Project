/**
 * OnClickListener.ets — Event interface definitions for Activity Bridge
 *
 * Provides Android-compatible event handling interfaces (OnClickListener,
 * OnTouchListener) and base View/MotionEvent classes so that migrated
 * Android code can set listeners in the familiar imperative style.
 */

/**
 * Android-compatible click listener interface.
 * Implement this to handle click events on bridged views.
 */
export interface OnClickListener {
  onClick(view: View): void;
}

/**
 * Android-compatible touch listener interface.
 * Implement this to handle touch events on bridged views.
 * Return true to consume the event, false to let it propagate.
 */
export interface OnTouchListener {
  onTouch(view: View, event: MotionEvent): boolean;
}

/**
 * Simplified MotionEvent matching Android's touch action constants.
 * Carries the action type so listeners can distinguish down/up/move.
 */
export class MotionEvent {
  /** Finger touched the screen */
  static readonly ACTION_DOWN: number = 0;
  /** Finger lifted from the screen */
  static readonly ACTION_UP: number = 1;
  /** Finger moved on the screen */
  static readonly ACTION_MOVE: number = 2;

  /** The action type for this event (ACTION_DOWN, ACTION_UP, ACTION_MOVE) */
  action: number = MotionEvent.ACTION_DOWN;

  constructor(action?: number) {
    if (action !== undefined) {
      this.action = action;
    }
  }
}

/**
 * Base View class bridging Android's View to ArkUI components.
 *
 * Each View has a numeric id (mirroring R.id.*) and supports
 * imperative listener registration. ArkUI event handlers call
 * the internal dispatch methods which forward to registered listeners.
 */
export class View {
  private _id: number;
  private _clickListener: OnClickListener | null = null;
  private _touchListener: OnTouchListener | null = null;

  constructor(id: number) {
    this._id = id;
  }

  /** Returns the numeric id assigned to this view (mirrors R.id.*) */
  getId(): number {
    return this._id;
  }

  /**
   * Register a click listener — Android-compatible API.
   * @param listener the callback to invoke on click
   */
  setOnClickListener(listener: OnClickListener): void {
    this._clickListener = listener;
  }

  /**
   * Register a touch listener — Android-compatible API.
   * @param listener the callback to invoke on touch events
   */
  setOnTouchListener(listener: OnTouchListener): void {
    this._touchListener = listener;
  }

  // ---- Internal dispatch methods (called by ArkUI event wiring) ----

  /**
   * Dispatches a click event to the registered listener.
   * ArkUI onClick handlers should call this method.
   */
  dispatchClick(): void {
    if (this._clickListener !== null) {
      this._clickListener.onClick(this);
    }
  }

  /**
   * Dispatches a touch event to the registered listener.
   * @param action one of MotionEvent.ACTION_DOWN / ACTION_UP / ACTION_MOVE
   * @returns true if the listener consumed the event, false otherwise
   */
  dispatchTouch(action: number): boolean {
    if (this._touchListener !== null) {
      const event = new MotionEvent(action);
      return this._touchListener.onTouch(this, event);
    }
    return false;
  }
}
