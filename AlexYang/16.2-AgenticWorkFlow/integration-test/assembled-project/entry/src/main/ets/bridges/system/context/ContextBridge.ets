/**
 * ContextBridge — Android Context bridge for HarmonyOS
 *
 * Maps Android's Context/Application pattern to HarmonyOS UIAbilityContext.
 * Provides singleton access so legacy code that passes Context everywhere
 * can be migrated with minimal changes.
 */

import { resourceManager } from '@kit.LocalizationKit';

// Forward declaration — ResourcesBridge lives in the same package
import { ResourcesBridge } from './ResourcesBridge';

export class ContextBridge {
  private _abilityContext: Object; // UIAbilityContext at runtime
  private _resourceManager: Object; // resourceManager.ResourceManager

  // ---- Singleton -----------------------------------------------------------

  static instance: ContextBridge | null = null;

  /**
   * Call once in EntryAbility.onCreate() to seed the global context.
   * @param context - UIAbilityContext from the ability lifecycle
   */
  static init(context: Object): void {
    ContextBridge.instance = new ContextBridge(context);
  }

  /**
   * Retrieve the global ContextBridge. Throws if init() was never called.
   */
  static get(): ContextBridge {
    if (ContextBridge.instance === null) {
      throw new Error('ContextBridge not initialised — call ContextBridge.init(context) first');
    }
    return ContextBridge.instance!;
  }

  // ---- Constructor ---------------------------------------------------------

  constructor(abilityContext: Object) {
    this._abilityContext = abilityContext;
    // UIAbilityContext exposes .resourceManager directly
    this._resourceManager = (abilityContext as Record<string, Object>)['resourceManager'];
  }

  // ---- Public API (mirrors android.content.Context) ------------------------

  /**
   * Android: context.getApplicationContext()
   * In HarmonyOS the ability context already serves the same role,
   * so we return *this* to keep the call-chain working.
   */
  getApplicationContext(): ContextBridge {
    return this;
  }

  /**
   * Android: context.getResources()
   * Returns a lightweight ResourcesBridge wrapper.
   */
  getResources(): ResourcesBridge {
    return new ResourcesBridge(this._resourceManager);
  }

  /**
   * Android: context.getPackageName()
   * Reads bundleName from the context's applicationInfo.
   */
  getPackageName(): string {
    const ctx = this._abilityContext as Record<string, Object>;
    const appInfo = ctx['applicationInfo'] as Record<string, string> | undefined;
    if (appInfo && appInfo['name']) {
      return appInfo['name'];
    }
    // Fallback: abilityInfo.bundleName
    const abilityInfo = ctx['abilityInfo'] as Record<string, string> | undefined;
    if (abilityInfo && abilityInfo['bundleName']) {
      return abilityInfo['bundleName'];
    }
    return '';
  }

  /**
   * Android: context.getString(R.string.xxx)
   * Delegates to resourceManager to fetch a string by its resource id.
   */
  getString(resId: number): string {
    try {
      const mgr = this._resourceManager as resourceManager.ResourceManager;
      return mgr.getStringSync(resId);
    } catch (e) {
      console.error(`ContextBridge.getString failed for resId=${resId}: ${e}`);
      return '';
    }
  }

  // ---- Internal helpers ----------------------------------------------------

  /** Expose the raw UIAbilityContext for code that needs it directly. */
  getRawContext(): Object {
    return this._abilityContext;
  }

  /** Expose the raw ResourceManager. */
  getRawResourceManager(): Object {
    return this._resourceManager;
  }
}


/**
 * ResourcesBridge — thin wrapper so callers of context.getResources() keep working.
 * Kept in the same file to avoid circular-import issues with ContextBridge.
 */
export class ResourcesBridge {
  private _mgr: Object;

  constructor(mgr: Object) {
    this._mgr = mgr;
  }

  /**
   * Android: resources.getString(resId)
   */
  getString(resId: number): string {
    try {
      const mgr = this._mgr as resourceManager.ResourceManager;
      return mgr.getStringSync(resId);
    } catch (e) {
      console.error(`ResourcesBridge.getString failed for resId=${resId}: ${e}`);
      return '';
    }
  }

  /**
   * Android: resources.getColor(resId)
   * Returns the colour as a numeric ARGB value.
   */
  getColor(resId: number): number {
    try {
      const mgr = this._mgr as resourceManager.ResourceManager;
      return mgr.getColorSync(resId);
    } catch (e) {
      console.error(`ResourcesBridge.getColor failed for resId=${resId}: ${e}`);
      return 0;
    }
  }

  /** Expose raw manager when needed. */
  getRawManager(): Object {
    return this._mgr;
  }
}
