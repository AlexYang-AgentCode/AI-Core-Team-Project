/**
 * Lifecycle State Management
 * 
 * Implements Android Activity lifecycle state machine.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'LifecycleState';

export enum ActivityState {
  INITIALIZED = 'INITIALIZED',
  CREATED = 'CREATED',
  STARTED = 'STARTED',
  RESUMED = 'RESUMED',
  PAUSED = 'PAUSED',
  STOPPED = 'STOPPED',
  DESTROYED = 'DESTROYED'
}

export interface StateChangeListener {
  onStateChanged(oldState: ActivityState, newState: ActivityState): void;
}

export class LifecycleStateMachine {
  private _state: ActivityState = ActivityState.INITIALIZED;
  private _listeners: Set<StateChangeListener> = new Set();

  // Valid state transitions according to Android Activity lifecycle
  private static readonly VALID_TRANSITIONS: Map<ActivityState, ActivityState[]> = new Map([
    [ActivityState.INITIALIZED, [ActivityState.CREATED]],
    [ActivityState.CREATED, [ActivityState.STARTED, ActivityState.DESTROYED]],
    [ActivityState.STARTED, [ActivityState.RESUMED, ActivityState.STOPPED]],
    [ActivityState.RESUMED, [ActivityState.PAUSED]],
    [ActivityState.PAUSED, [ActivityState.RESUMED, ActivityState.STOPPED]],
    [ActivityState.STOPPED, [ActivityState.STARTED, ActivityState.DESTROYED]],
    [ActivityState.DESTROYED, []]
  ]);

  /**
   * Attempt to transition to a new state
   * @returns true if transition was successful, false otherwise
   */
  transitionTo(newState: ActivityState): boolean {
    const validNextStates = LifecycleStateMachine.VALID_TRANSITIONS.get(this._state) || [];
    
    if (!validNextStates.includes(newState)) {
      hilog.warn(0x0000, TAG, `Invalid state transition: ${this._state} -> ${newState}`);
      return false;
    }
    
    const oldState = this._state;
    this._state = newState;
    
    hilog.debug(0x0000, TAG, `State transition: ${oldState} -> ${newState}`);
    
    this._notifyListeners(oldState, newState);
    return true;
  }

  /**
   * Get current state
   */
  getState(): ActivityState {
    return this._state;
  }

  /**
   * Check if in specific state
   */
  isInState(state: ActivityState): boolean {
    return this._state === state;
  }

  /**
   * Check if at least in the specified state (e.g., at least STARTED)
   */
  isAtLeast(state: ActivityState): boolean {
    const states = [
      ActivityState.INITIALIZED,
      ActivityState.CREATED,
      ActivityState.STARTED,
      ActivityState.RESUMED,
      ActivityState.PAUSED,
      ActivityState.STOPPED,
      ActivityState.DESTROYED
    ];
    
    const currentIndex = states.indexOf(this._state);
    const targetIndex = states.indexOf(state);
    
    return currentIndex >= targetIndex && currentIndex < states.indexOf(ActivityState.DESTROYED);
  }

  /**
   * Add state change listener
   */
  addListener(listener: StateChangeListener): void {
    this._listeners.add(listener);
  }

  /**
   * Remove state change listener
   */
  removeListener(listener: StateChangeListener): void {
    this._listeners.delete(listener);
  }

  private _notifyListeners(oldState: ActivityState, newState: ActivityState): void {
    this._listeners.forEach(listener => {
      try {
        listener.onStateChanged(oldState, newState);
      } catch (err) {
        hilog.error(0x0000, TAG, `Listener callback error: ${JSON.stringify(err)}`);
      }
    });
  }
}

/**
 * Lifecycle event types matching Android Lifecycle.Event
 */
export enum LifecycleEvent {
  ON_CREATE = 'ON_CREATE',
  ON_START = 'ON_START',
  ON_RESUME = 'ON_RESUME',
  ON_PAUSE = 'ON_PAUSE',
  ON_STOP = 'ON_STOP',
  ON_DESTROY = 'ON_DESTROY',
  ON_ANY = 'ON_ANY'
}

/**
 * Maps ActivityState to LifecycleEvent
 */
export function stateToEvent(state: ActivityState): LifecycleEvent {
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
