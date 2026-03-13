/**
 * Android Bundle Implementation
 * 
 * Maps Android Bundle to HarmonyOS Want parameters and AppStorage.
 */

import { Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'Bundle';

export class Bundle {
  private _data: Map<string, Object> = new Map();
  private _parcelledData: Uint8Array | null = null;

  constructor() {}

  /**
   * Create Bundle from HarmonyOS Want
   */
  static fromWant(want: Want): Bundle {
    const bundle = new Bundle();
    
    if (want.parameters) {
      Object.keys(want.parameters).forEach(key => {
        const value = want.parameters![key];
        bundle._data.set(key, value);
      });
    }
    
    hilog.debug(0x0000, TAG, `Bundle created from Want with ${bundle._data.size} entries`);
    return bundle;
  }

  /**
   * Convert Bundle to HarmonyOS Want parameters
   */
  toWantParameters(): Record<string, Object> {
    const params: Record<string, Object> = {};
    this._data.forEach((value, key) => {
      params[key] = value;
    });
    return params;
  }

  // ===== String operations =====
  
  putString(key: string, value: string): void {
    this._data.set(key, value);
  }

  getString(key: string): string | null {
    return this._data.get(key) as string || null;
  }

  getString(key: string, defaultValue: string): string {
    return (this._data.get(key) as string) ?? defaultValue;
  }

  // ===== Int operations =====
  
  putInt(key: string, value: number): void {
    this._data.set(key, value);
  }

  getInt(key: string): number {
    return (this._data.get(key) as number) || 0;
  }

  getInt(key: string, defaultValue: number): number {
    return (this._data.get(key) as number) ?? defaultValue;
  }

  // ===== Long operations =====
  
  putLong(key: string, value: number): void {
    this._data.set(key, value);
  }

  getLong(key: string): number {
    return (this._data.get(key) as number) || 0;
  }

  getLong(key: string, defaultValue: number): number {
    return (this._data.get(key) as number) ?? defaultValue;
  }

  // ===== Boolean operations =====
  
  putBoolean(key: string, value: boolean): void {
    this._data.set(key, value);
  }

  getBoolean(key: string): boolean {
    return (this._data.get(key) as boolean) || false;
  }

  getBoolean(key: string, defaultValue: boolean): boolean {
    return (this._data.get(key) as boolean) ?? defaultValue;
  }

  // ===== Float operations =====
  
  putFloat(key: string, value: number): void {
    this._data.set(key, value);
  }

  getFloat(key: string): number {
    return (this._data.get(key) as number) || 0.0;
  }

  getFloat(key: string, defaultValue: number): number {
    return (this._data.get(key) as number) ?? defaultValue;
  }

  // ===== Double operations =====
  
  putDouble(key: string, value: number): void {
    this._data.set(key, value);
  }

  getDouble(key: string): number {
    return (this._data.get(key) as number) || 0.0;
  }

  getDouble(key: string, defaultValue: number): number {
    return (this._data.get(key) as number) ?? defaultValue;
  }

  // ===== String Array operations =====
  
  putStringArray(key: string, value: string[]): void {
    this._data.set(key, value);
  }

  getStringArray(key: string): string[] | null {
    return this._data.get(key) as string[] || null;
  }

  // ===== Int Array operations =====
  
  putIntArray(key: string, value: number[]): void {
    this._data.set(key, value);
  }

  getIntArray(key: string): number[] | null {
    return this._data.get(key) as number[] || null;
  }

  // ===== Bundle operations =====
  
  putBundle(key: string, value: Bundle): void {
    this._data.set(key, value);
  }

  getBundle(key: string): Bundle | null {
    return this._data.get(key) as Bundle || null;
  }

  // ===== General operations =====
  
  containsKey(key: string): boolean {
    return this._data.has(key);
  }

  remove(key: string): void {
    this._data.delete(key);
  }

  clear(): void {
    this._data.clear();
  }

  isEmpty(): boolean {
    return this._data.size === 0;
  }

  size(): number {
    return this._data.size;
  }

  keySet(): Set<string> {
    return new Set(this._data.keys());
  }

  /**
   * Returns a shallow copy of this Bundle
   */
  clone(): Bundle {
    const copy = new Bundle();
    this._data.forEach((value, key) => {
      copy._data.set(key, value);
    });
    return copy;
  }

  /**
   * Put any value (for compatibility)
   */
  put(key: string, value: Object): void {
    this._data.set(key, value);
  }

  /**
   * Get any value (for compatibility)
   */
  get(key: string): Object | null {
    return this._data.get(key) || null;
  }
}
