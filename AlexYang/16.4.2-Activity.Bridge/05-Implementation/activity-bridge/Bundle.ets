/**
 * Bundle.ets — Bundle wrapper over HarmonyOS Want
 *
 * Mirrors Android's Bundle class so that migrated code can pass
 * key-value data through Activity launches using the familiar
 * putString / getString / putInt / getInt / putBoolean / getBoolean API.
 *
 * Internally backed by a Map<string, Object>. A Bundle can be created
 * from a HarmonyOS Want (extracting its parameters) via Bundle.fromWant().
 */

import { Want } from '@kit.AbilityKit';

export class Bundle {
  /** Internal key-value store */
  private data: Map<string, Object> = new Map();

  /**
   * Create a Bundle pre-populated from a Want's parameters.
   * Each entry in want.parameters is copied into the Bundle.
   *
   * @param want the HarmonyOS Want whose parameters to extract
   * @returns a new Bundle containing the Want parameters
   */
  static fromWant(want: Want): Bundle {
    const bundle = new Bundle();
    if (want.parameters) {
      const params = want.parameters;
      const keys = Object.keys(params);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = params[key];
        if (value !== undefined && value !== null) {
          bundle.data.set(key, value as Object);
        }
      }
    }
    return bundle;
  }

  // ---- String accessors ----

  /**
   * Store a string value under the given key.
   * @param key the key name
   * @param value the string to store
   */
  putString(key: string, value: string): void {
    this.data.set(key, value);
  }

  /**
   * Retrieve a string value.
   * @param key the key name
   * @param defaultValue value to return if the key is absent
   * @returns the stored string, the default, or null
   */
  getString(key: string, defaultValue?: string): string | null {
    if (this.data.has(key)) {
      const value = this.data.get(key);
      if (typeof value === 'string') {
        return value as string;
      }
    }
    if (defaultValue !== undefined) {
      return defaultValue;
    }
    return null;
  }

  // ---- Integer accessors ----

  /**
   * Store an integer value under the given key.
   * @param key the key name
   * @param value the number to store
   */
  putInt(key: string, value: number): void {
    this.data.set(key, value);
  }

  /**
   * Retrieve an integer value.
   * @param key the key name
   * @param defaultValue value to return if the key is absent (defaults to 0)
   * @returns the stored number or the default
   */
  getInt(key: string, defaultValue?: number): number {
    if (this.data.has(key)) {
      const value = this.data.get(key);
      if (typeof value === 'number') {
        return value as number;
      }
    }
    return defaultValue !== undefined ? defaultValue : 0;
  }

  // ---- Boolean accessors ----

  /**
   * Store a boolean value under the given key.
   * @param key the key name
   * @param value the boolean to store
   */
  putBoolean(key: string, value: boolean): void {
    this.data.set(key, value);
  }

  /**
   * Retrieve a boolean value.
   * @param key the key name
   * @param defaultValue value to return if the key is absent (defaults to false)
   * @returns the stored boolean or the default
   */
  getBoolean(key: string, defaultValue?: boolean): boolean {
    if (this.data.has(key)) {
      const value = this.data.get(key);
      if (typeof value === 'boolean') {
        return value as boolean;
      }
    }
    return defaultValue !== undefined ? defaultValue : false;
  }

  // ---- Utility ----

  /**
   * Check whether a key exists in this Bundle.
   * @param key the key to look up
   * @returns true if the key is present
   */
  containsKey(key: string): boolean {
    return this.data.has(key);
  }
}
