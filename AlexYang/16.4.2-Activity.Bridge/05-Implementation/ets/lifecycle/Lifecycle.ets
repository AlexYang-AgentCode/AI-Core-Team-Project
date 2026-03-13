/**
 * Android Lifecycle Component
 *
 * Provides lifecycle observation capabilities similar to Android Architecture Components.
 * Allows observers to react to lifecycle events without modifying Activity code.
 */

import { ActivityState, LifecycleEvent } from './LifecycleState';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'Lifecycle';

/**
 * Lifecycle observer interface
 * Observers can react to lifecycle state changes.
 */
export interface LifecycleObserver {
  /**
   * Called when the lifecycle owner enters a new state
   */
  onStateChanged(event: LifecycleEvent): void;
}

/**
 * Lifecycle class for managing lifecycle observers
 * Similar to Android androidx.lifecycle.Lifecycle
 */
export class Lifecycle {
  private _observers: Set<LifecycleObserver> = new Set();
  private _currentState: ActivityState = ActivityState.INITIALIZED;
  private _currentEvent: LifecycleEvent = LifecycleEvent.ON_ANY;

  /**
   * Add an observer to be notified of lifecycle events
   */
  addObserver(observer: LifecycleObserver): void {
    hilog.debug(0x0000, TAG, 'Adding lifecycle observer');
    this._observers.add(observer);

    // Immediately notify of current state
    observer.onStateChanged(this._currentEvent);
  }

  /**
   * Remove an observer
   */
  removeObserver(observer: LifecycleObserver): void {
    hilog.debug(0x0000, TAG, 'Removing lifecycle observer');
    this._observers.delete(observer);
  }

  /**
   * Get the current lifecycle state
   */
  getCurrentState(): ActivityState {
    return this._currentState;
  }

  /**
   * Handle lifecycle event and notify observers
   * Called by Activity when lifecycle events occur
   */
  handleLifecycleEvent(event: LifecycleEvent): void {
    hilog.debug(0x0000, TAG, `Handling lifecycle event: ${event}`);

    this._currentEvent = event;
    this._currentState = this._eventToState(event);

    // Notify all observers
    this._observers.forEach(observer => {
      try {
        observer.onStateChanged(event);
      } catch (err) {
        hilog.error(0x0000, TAG, `Observer error: ${JSON.stringify(err)}`);
      }
    });
  }

  /**
   * Set current state (used for state restoration)
   */
  setCurrentState(state: ActivityState): void {
    this._currentState = state;
    this._currentEvent = this._stateToEvent(state);
  }

  /**
   * Check if lifecycle is at least in the given state
   */
  isAtLeast(state: ActivityState): boolean {
    const stateOrder = [
      ActivityState.INITIALIZED,
      ActivityState.CREATED,
      ActivityState.STARTED,
      ActivityState.RESUMED,
      ActivityState.PAUSED,
      ActivityState.STOPPED,
      ActivityState.DESTROYED
    ];

    const currentIndex = stateOrder.indexOf(this._currentState);
    const targetIndex = stateOrder.indexOf(state);

    return currentIndex >= targetIndex && currentIndex < stateOrder.indexOf(ActivityState.DESTROYED);
  }

  /**
   * Get the number of registered observers
   */
  getObserverCount(): number {
    return this._observers.size;
  }

  /**
   * Remove all observers
   */
  removeAllObservers(): void {
    hilog.debug(0x0000, TAG, `Removing all ${this._observers.size} observers`);
    this._observers.clear();
  }

  /**
   * Convert LifecycleEvent to ActivityState
   */
  private _eventToState(event: LifecycleEvent): ActivityState {
    switch (event) {
      case LifecycleEvent.ON_CREATE:
        return ActivityState.CREATED;
      case LifecycleEvent.ON_START:
        return ActivityState.STARTED;
      case LifecycleEvent.ON_RESUME:
        return ActivityState.RESUMED;
      case LifecycleEvent.ON_PAUSE:
        return ActivityState.PAUSED;
      case LifecycleEvent.ON_STOP:
        return ActivityState.STOPPED;
      case LifecycleEvent.ON_DESTROY:
        return ActivityState.DESTROYED;
      default:
        return this._currentState;
    }
  }

  /**
   * Convert ActivityState to LifecycleEvent
   */
  private _stateToEvent(state: ActivityState): LifecycleEvent {
    switch (state) {
      case ActivityState.CREATED:
        return LifecycleEvent.ON_CREATE;
      case ActivityState.STARTED:
        return LifecycleEvent.ON_START;
      case ActivityState.RESUMED:
        return LifecycleEvent.ON_RESUME;
      case ActivityState.PAUSED:
        return LifecycleEvent.ON_PAUSE;
      case ActivityState.STOPPED:
        return LifecycleEvent.ON_STOP;
      case ActivityState.DESTROYED:
        return LifecycleEvent.ON_DESTROY;
      default:
        return LifecycleEvent.ON_ANY;
    }
  }
}

/**
 * Default lifecycle observer implementation
 * Provides empty implementations for easy extension
 */
export abstract class DefaultLifecycleObserver implements LifecycleObserver {
  onCreate(): void {}
  onStart(): void {}
  onResume(): void {}
  onPause(): void {}
  onStop(): void {}
  onDestroy(): void {}

  onStateChanged(event: LifecycleEvent): void {
    switch (event) {
      case LifecycleEvent.ON_CREATE:
        this.onCreate();
        break;
      case LifecycleEvent.ON_START:
        this.onStart();
        break;
      case LifecycleEvent.ON_RESUME:
        this.onResume();
        break;
      case LifecycleEvent.ON_PAUSE:
        this.onPause();
        break;
      case LifecycleEvent.ON_STOP:
        this.onStop();
        break;
      case LifecycleEvent.ON_DESTROY:
        this.onDestroy();
        break;
    }
  }
}
