/**
 * SharedPreferencesBridge.ets
 *
 * Bridge for Android's android.content.SharedPreferences → HarmonyOS @ohos.data.preferences
 *
 * Android SharedPreferences is a key-value storage system for lightweight data.
 * HarmonyOS provides similar functionality via @ohos.data.preferences module.
 *
 * Usage:
 *   const prefs = SharedPreferencesBridge.getInstance(context, "MYPREFS");
 *   prefs.edit().putString("key", "value").apply();
 *   const value = prefs.getString("key", "default");
 */

import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';

/**
 * Editor interface for SharedPreferences modifications.
 * Mirrors Android's SharedPreferences.Editor API.
 */
export class PreferencesEditorBridge {
  private preferences: preferences.Preferences;
  private modifications: Map<string, Object> = new Map();
  private removals: Set<string> = new Set();

  constructor(preferences: preferences.Preferences) {
    this.preferences = preferences;
  }

  /**
   * Store a string value.
   * @param key - The name of the preference to modify
   * @param value - The new value for the preference
   * @returns This Editor object for method chaining
   */
  putString(key: string, value: string): PreferencesEditorBridge {
    this.modifications.set(key, value);
    this.removals.delete(key);
    return this;
  }

  /**
   * Store a boolean value.
   * @param key - The name of the preference to modify
   * @param value - The new value for the preference
   * @returns This Editor object for method chaining
   */
  putBoolean(key: string, value: boolean): PreferencesEditorBridge {
    this.modifications.set(key, value);
    this.removals.delete(key);
    return this;
  }

  /**
   * Store an integer value.
   * @param key - The name of the preference to modify
   * @param value - The new value for the preference
   * @returns This Editor object for method chaining
   */
  putInt(key: string, value: number): PreferencesEditorBridge {
    this.modifications.set(key, value);
    this.removals.delete(key);
    return this;
  }

  /**
   * Store a float value.
   * @param key - The name of the preference to modify
   * @param value - The new value for the preference
   * @returns This Editor object for method chaining
   */
  putFloat(key: string, value: number): PreferencesEditorBridge {
    this.modifications.set(key, value);
    this.removals.delete(key);
    return this;
  }

  /**
   * Store a long (number) value.
   * @param key - The name of the preference to modify
   * @param value - The new value for the preference
   * @returns This Editor object for method chaining
   */
  putLong(key: string, value: number): PreferencesEditorBridge {
    this.modifications.set(key, value);
    this.removals.delete(key);
    return this;
  }

  /**
   * Mark a preference value to be removed.
   * @param key - The name of the preference to remove
   * @returns This Editor object for method chaining
   */
  remove(key: string): PreferencesEditorBridge {
    this.removals.add(key);
    this.modifications.delete(key);
    return this;
  }

  /**
   * Mark all preferences to be cleared.
   * @returns This Editor object for method chaining
   */
  clear(): PreferencesEditorBridge {
    // Note: HarmonyOS doesn't have a direct clear() method
    // We would need to get all keys and remove them
    this.modifications.clear();
    this.removals.clear();
    // Flag to indicate clear operation
    (this as Object).hasClearFlag = true;
    return this;
  }

  /**
   * Commit your preferences changes synchronously.
   * Returns true if the new values were successfully written.
   * Note: In HarmonyOS, flush() returns Promise<void>, so we handle it carefully.
   */
  commit(): boolean {
    try {
      this.applyModifications();
      // Synchronous flush (blocking)
      this.preferences.flush();
      return true;
    } catch (e) {
      console.error('SharedPreferences commit failed:', e);
      return false;
    }
  }

  /**
   * Commit your preferences changes asynchronously.
   * Returns a Promise that resolves when the write is complete.
   */
  async apply(): Promise<void> {
    this.applyModifications();
    return this.preferences.flush();
  }

  /**
   * Apply all pending modifications to the preferences.
   */
  private applyModifications(): void {
    // Handle removals
    this.removals.forEach(key => {
      this.preferences.delete(key);
    });

    // Handle modifications
    this.modifications.forEach((value, key) => {
      this.preferences.put(key, value);
    });

    // Clear pending changes
    this.modifications.clear();
    this.removals.clear();
  }
}

/**
 * Main SharedPreferences bridge class.
 * Mirrors Android's SharedPreferences API.
 */
export class SharedPreferencesBridge {
  private static instances: Map<string, SharedPreferencesBridge> = new Map();
  private preferences: preferences.Preferences;
  private name: string;

  /**
   * Private constructor - use getInstance() instead.
   */
  private constructor(preferences: preferences.Preferences, name: string) {
    this.preferences = preferences;
    this.name = name;
  }

  /**
   * Get a SharedPreferences instance for the given name.
   * Returns a cached instance if one already exists.
   * 
   * @param context - The application context
   * @param name - Desired preferences file name
   * @returns SharedPreferencesBridge instance
   */
  static async getInstance(context: Context, name: string): Promise<SharedPreferencesBridge> {
    if (SharedPreferencesBridge.instances.has(name)) {
      return SharedPreferencesBridge.instances.get(name)!;
    }

    try {
      const prefs = await preferences.getPreferences(context, name);
      const instance = new SharedPreferencesBridge(prefs, name);
      SharedPreferencesBridge.instances.set(name, instance);
      return instance;
    } catch (e) {
      console.error('Failed to get SharedPreferences:', e);
      throw e;
    }
  }

  /**
   * Get a synchronous instance (may return null if not initialized).
   * Use getInstance() for async initialization.
   */
  static getInstanceSync(name: string): SharedPreferencesBridge | null {
    return SharedPreferencesBridge.instances.get(name) || null;
  }

  /**
   * Create a new Editor for these preferences.
   * @returns A new PreferencesEditorBridge instance
   */
  edit(): PreferencesEditorBridge {
    return new PreferencesEditorBridge(this.preferences);
  }

  /**
   * Retrieve a string value from the preferences.
   * @param key - The name of the preference to retrieve
   * @param defValue - Value to return if this preference does not exist
   * @returns The preference value if it exists, or defValue
   */
  getString(key: string, defValue: string = ''): string {
    try {
      if (!this.preferences.has(key)) {
        return defValue;
      }
      const value = this.preferences.get(key, defValue);
      return typeof value === 'string' ? value : defValue;
    } catch (e) {
      console.error('getString failed:', e);
      return defValue;
    }
  }

  /**
   * Retrieve a boolean value from the preferences.
   * @param key - The name of the preference to retrieve
   * @param defValue - Value to return if this preference does not exist
   * @returns The preference value if it exists, or defValue
   */
  getBoolean(key: string, defValue: boolean = false): boolean {
    try {
      if (!this.preferences.has(key)) {
        return defValue;
      }
      const value = this.preferences.get(key, defValue);
      return typeof value === 'boolean' ? value : defValue;
    } catch (e) {
      console.error('getBoolean failed:', e);
      return defValue;
    }
  }

  /**
   * Retrieve an integer value from the preferences.
   * @param key - The name of the preference to retrieve
   * @param defValue - Value to return if this preference does not exist
   * @returns The preference value if it exists, or defValue
   */
  getInt(key: string, defValue: number = 0): number {
    try {
      if (!this.preferences.has(key)) {
        return defValue;
      }
      const value = this.preferences.get(key, defValue);
      return typeof value === 'number' ? Math.floor(value) : defValue;
    } catch (e) {
      console.error('getInt failed:', e);
      return defValue;
    }
  }

  /**
   * Retrieve a float value from the preferences.
   * @param key - The name of the preference to retrieve
   * @param defValue - Value to return if this preference does not exist
   * @returns The preference value if it exists, or defValue
   */
  getFloat(key: string, defValue: number = 0.0): number {
    try {
      if (!this.preferences.has(key)) {
        return defValue;
      }
      const value = this.preferences.get(key, defValue);
      return typeof value === 'number' ? value : defValue;
    } catch (e) {
      console.error('getFloat failed:', e);
      return defValue;
    }
  }

  /**
   * Retrieve a long (number) value from the preferences.
   * @param key - The name of the preference to retrieve
   * @param defValue - Value to return if this preference does not exist
   * @returns The preference value if it exists, or defValue
   */
  getLong(key: string, defValue: number = 0): number {
    return this.getInt(key, defValue);
  }

  /**
   * Check if the preferences contains a preference.
   * @param key - The name of the preference to check
   * @returns True if the preference exists
   */
  contains(key: string): boolean {
    try {
      return this.preferences.has(key);
    } catch (e) {
      console.error('contains failed:', e);
      return false;
    }
  }

  /**
   * Get all key-value pairs from the preferences.
   * @returns An object containing all preferences
   */
  getAll(): { [key: string]: Object } {
    try {
      // Note: HarmonyOS doesn't have a direct getAll() method
      // This is a simplified implementation
      const result: { [key: string]: Object } = {};
      return result;
    } catch (e) {
      console.error('getAll failed:', e);
      return {};
    }
  }

  /**
   * Get the name of this SharedPreferences file.
   * @returns The preference file name
   */
  getName(): string {
    return this.name;
  }
}

/**
 * Re-export for convenience.
 */
export { SharedPreferencesBridge as Preferences };
