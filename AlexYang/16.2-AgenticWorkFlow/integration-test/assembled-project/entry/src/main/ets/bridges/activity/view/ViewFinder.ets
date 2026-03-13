/**
 * View Finder Implementation
 * 
 * Maps Android R.id.* to ArkUI components.
 * Collaborates with 16.4.3 View.Bridge for actual View instances.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { View } from './View';

const TAG = 'ViewFinder';

/**
 * Interface for finding Views by their Android resource ID
 */
export interface ViewFinder {
  /**
   * Find a view by its Android R.id.* resource ID
   * @param id The Android resource ID (e.g., R.id.button_submit)
   * @returns The View instance if found, null otherwise
   */
  findViewById<T>(id: number): T | null;

  /**
   * Register a view with its Android resource ID
   * Called by 16.4.3 View.Bridge when building the UI
   * @param id The Android resource ID
   * @param view The View instance
   */
  registerView(id: number, view: View): void;

  /**
   * Unregister a view
   * @param id The Android resource ID
   */
  unregisterView(id: number): void;

  /**
   * Clear all registered views
   * Called when Activity is destroyed
   */
  clear(): void;

  /**
   * Get the number of registered views
   */
  getViewCount(): number;
}

/**
 * Implementation of ViewFinder
 */
class ViewFinderImpl implements ViewFinder {
  private _views: Map<number, View> = new Map();

  findViewById<T>(id: number): T | null {
    const view = this._views.get(id);
    if (!view) {
      hilog.warn(0x0000, TAG, `View not found for ID: 0x${id.toString(16)}`);
      return null;
    }
    return view as T;
  }

  registerView(id: number, view: View): void {
    hilog.debug(0x0000, TAG, `Registering view 0x${id.toString(16)}`);
    this._views.set(id, view);
  }

  unregisterView(id: number): void {
    hilog.debug(0x0000, TAG, `Unregistering view 0x${id.toString(16)}`);
    this._views.delete(id);
  }

  clear(): void {
    hilog.info(0x0000, TAG, `Clearing all ${this._views.size} views`);
    this._views.clear();
  }

  getViewCount(): number {
    return this._views.size;
  }
}

// Singleton instance
export const viewFinder: ViewFinder = new ViewFinderImpl();

/**
 * View ID Registry
 * 
 * Maps Android R.id.* integers to component identifiers
 */
export class ViewIdRegistry {
  private static _idToComponent: Map<number, string> = new Map();

  /**
   * Register a mapping from Android resource ID to component ID
   * Called during app initialization (by 16.4.1 JIT generated code)
   */
  static register(id: number, componentId: string): void {
    ViewIdRegistry._idToComponent.set(id, componentId);
  }

  /**
   * Get the component ID for an Android resource ID
   */
  static getComponentId(id: number): string | undefined {
    return ViewIdRegistry._idToComponent.get(id);
  }

  /**
   * Check if a resource ID is registered
   */
  static hasId(id: number): boolean {
    return ViewIdRegistry._idToComponent.has(id);
  }

  /**
   * Get all registered IDs
   */
  static getAllIds(): number[] {
    return Array.from(ViewIdRegistry._idToComponent.keys());
  }
}
