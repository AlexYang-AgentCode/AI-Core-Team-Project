/**
 * Lifecycle Owner Interface
 *
 * Marks a class as a lifecycle owner, providing access to its Lifecycle.
 * Similar to Android androidx.lifecycle.LifecycleOwner
 */

import { Lifecycle } from './Lifecycle';

/**
 * Interface for objects that have a lifecycle
 * Activities and Fragments implement this interface.
 */
export interface LifecycleOwner {
  /**
   * Returns the Lifecycle of the provider.
   */
  getLifecycle(): Lifecycle;
}

/**
 * Default implementation of LifecycleOwner
 * Can be extended by Activity and Fragment classes
 */
export abstract class LifecycleOwnerBase implements LifecycleOwner {
  protected _lifecycle: Lifecycle = new Lifecycle();

  /**
   * Get the lifecycle for this owner
   */
  getLifecycle(): Lifecycle {
    return this._lifecycle;
  }

  /**
   * Called when lifecycle events occur
   * Subclasses should call super when overriding lifecycle methods
   */
  protected onCreate(): void {
    // Lifecycle event handled by Activity base class
  }

  protected onStart(): void {
    // Lifecycle event handled by Activity base class
  }

  protected onResume(): void {
    // Lifecycle event handled by Activity base class
  }

  protected onPause(): void {
    // Lifecycle event handled by Activity base class
  }

  protected onStop(): void {
    // Lifecycle event handled by Activity base class
  }

  protected onDestroy(): void {
    // Lifecycle event handled by Activity base class
  }
}
