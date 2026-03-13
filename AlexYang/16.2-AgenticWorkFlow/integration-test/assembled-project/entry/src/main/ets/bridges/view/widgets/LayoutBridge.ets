/**
 * LayoutBridge.ets
 *
 * Bridge classes for Android layout containers and constants.
 *
 * LinearLayoutBridge maps Android's LinearLayout to ArkUI's Column (vertical)
 * or Row (horizontal) containers.
 *
 * Gravity and ViewVisibility provide the standard Android constant values
 * used throughout the bridge layer.
 */

import { ViewBridge } from './ViewBridge';

/**
 * Bridge for Android's LinearLayout.
 *
 * Android LinearLayout arranges children in a single direction:
 *   VERTICAL (1)   → children stacked top-to-bottom → ArkUI Column
 *   HORIZONTAL (0) → children placed left-to-right  → ArkUI Row
 */
export class LinearLayoutBridge {
  /** Horizontal orientation — maps to ArkUI Row. */
  static readonly HORIZONTAL: number = 0;

  /** Vertical orientation — maps to ArkUI Column. */
  static readonly VERTICAL: number = 1;

  /** Current orientation. Default is HORIZONTAL to match Android. */
  orientation: number = LinearLayoutBridge.HORIZONTAL;

  /** Ordered list of child views. */
  children: ViewBridge[] = [];

  /**
   * Adds a child view to the end of this layout.
   * Equivalent to Android's ViewGroup.addView(View).
   *
   * @param child - the ViewBridge to add
   */
  addView(child: ViewBridge): void {
    this.children.push(child);
  }

  /**
   * Removes a child view from this layout.
   * Equivalent to Android's ViewGroup.removeView(View).
   * Matches by reference. Does nothing if the child is not found.
   *
   * @param child - the ViewBridge to remove
   */
  removeView(child: ViewBridge): void {
    const index = this.children.indexOf(child);
    if (index !== -1) {
      this.children.splice(index, 1);
    }
  }

  /**
   * Returns the number of children in this layout.
   */
  getChildCount(): number {
    return this.children.length;
  }

  /**
   * Returns the child view at the specified index.
   *
   * @param index - zero-based position
   * @throws RangeError if index is out of bounds
   */
  getChildAt(index: number): ViewBridge {
    if (index < 0 || index >= this.children.length) {
      throw new RangeError(
        `Child index ${index} out of range [0, ${this.children.length})`
      );
    }
    return this.children[index];
  }

  /**
   * Returns the ArkUI container type name for this layout's orientation.
   * Used by the component builder to decide which container to render.
   *
   * @returns 'Column' for VERTICAL, 'Row' for HORIZONTAL
   */
  getArkUIContainerType(): string {
    return this.orientation === LinearLayoutBridge.VERTICAL ? 'Column' : 'Row';
  }
}

/**
 * Android Gravity constants.
 *
 * These match the integer values from android.view.Gravity and are used
 * by setGravity(), layout params, and text alignment throughout the bridge.
 */
export class Gravity {
  /** Push content to the left of its container. */
  static readonly LEFT: number = 3;

  /** Push content to the right of its container. */
  static readonly RIGHT: number = 5;

  /** Center content in both axes. */
  static readonly CENTER: number = 17;

  /** Push content to the top of its container. */
  static readonly TOP: number = 48;

  /** Push content to the bottom of its container. */
  static readonly BOTTOM: number = 80;

  /** Center content horizontally within its container. */
  static readonly CENTER_HORIZONTAL: number = 1;

  /** Center content vertically within its container. */
  static readonly CENTER_VERTICAL: number = 16;

  /** Push content to the start (LTR=left, RTL=right) of its container. */
  static readonly START: number = 8388611;

  /** Push content to the end (LTR=right, RTL=left) of its container. */
  static readonly END: number = 8388613;

  /** Fill the container horizontally. */
  static readonly FILL_HORIZONTAL: number = 7;

  /** Fill the container vertically. */
  static readonly FILL_VERTICAL: number = 112;

  /** Fill the container in both axes. */
  static readonly FILL: number = 119;

  /** Clip the content at the horizontal edge of its container. */
  static readonly CLIP_HORIZONTAL: number = 8;

  /** Clip the content at the vertical edge of its container. */
  static readonly CLIP_VERTICAL: number = 128;

  /** No gravity. Equivalent to TOP|LEFT in Android. */
  static readonly NO_GRAVITY: number = 0;
}

/**
 * Android View visibility constants.
 *
 * These match the integer values from android.view.View and are passed
 * to ViewBridge.setVisibility().
 */
export class ViewVisibility {
  /** The view is visible and occupies layout space. */
  static readonly VISIBLE: number = 0;

  /** The view is invisible but still occupies layout space. */
  static readonly INVISIBLE: number = 4;

  /** The view is invisible and does not occupy layout space. */
  static readonly GONE: number = 8;
}
