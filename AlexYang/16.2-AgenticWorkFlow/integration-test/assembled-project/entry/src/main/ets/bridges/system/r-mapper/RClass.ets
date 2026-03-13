/**
 * RClass — R class registry for resource IDs
 *
 * Android code references resources via R.layout.xxx, R.id.xxx, R.string.xxx,
 * R.color.xxx — all of which are compile-time integer constants. In HarmonyOS
 * the resource system is different, so this class provides a runtime registry
 * that maps Android resource names to HarmonyOS resource IDs.
 *
 * During app initialisation, a generated mapping file calls the register*
 * methods to populate the maps. Thereafter, existing Android code that uses
 * R.id.xxx style lookups can be migrated to R.getViewId("xxx") etc.
 *
 * Usage:
 *   // At init time (generated code)
 *   R.registerString("app_name", 0x7F040001);
 *   R.registerColor("primary", 0x7F050001);
 *
 *   // At usage site (migrated code)
 *   const id = R.getViewId("btn_ok");
 */

export class R {
  // Resource maps keyed by Android resource name → HarmonyOS resource ID
  static layout: Map<string, number> = new Map();
  static id: Map<string, number> = new Map();
  static string: Map<string, number> = new Map();
  static color: Map<string, number> = new Map();

  // ===========================================================================
  // Registration
  // ===========================================================================

  static registerLayout(name: string, id: number): void {
    R.layout.set(name, id);
  }

  static registerId(name: string, id: number): void {
    R.id.set(name, id);
  }

  static registerString(name: string, id: number): void {
    R.string.set(name, id);
  }

  static registerColor(name: string, id: number): void {
    R.color.set(name, id);
  }

  // ===========================================================================
  // Lookup
  // ===========================================================================

  /**
   * Look up a layout resource ID by name.
   * Throws if the name was never registered.
   */
  static getLayoutId(name: string): number {
    const val = R.layout.get(name);
    if (val === undefined) {
      throw new Error(`R.layout.${name} is not registered`);
    }
    return val;
  }

  /**
   * Look up a view / id resource ID by name.
   * Throws if the name was never registered.
   */
  static getViewId(name: string): number {
    const val = R.id.get(name);
    if (val === undefined) {
      throw new Error(`R.id.${name} is not registered`);
    }
    return val;
  }

  /**
   * Look up a string resource ID by name.
   * Throws if the name was never registered.
   */
  static getStringId(name: string): number {
    const val = R.string.get(name);
    if (val === undefined) {
      throw new Error(`R.string.${name} is not registered`);
    }
    return val;
  }

  /**
   * Look up a colour resource ID by name.
   * Throws if the name was never registered.
   */
  static getColorId(name: string): number {
    const val = R.color.get(name);
    if (val === undefined) {
      throw new Error(`R.color.${name} is not registered`);
    }
    return val;
  }

  // ===========================================================================
  // Bulk registration helper
  // ===========================================================================

  /**
   * Register many resources at once from a plain object.
   * Useful for generated init code.
   *
   * @param category - "layout" | "id" | "string" | "color"
   * @param entries  - { name: id } mapping
   */
  static registerBatch(category: string, entries: Record<string, number>): void {
    const keys = Object.keys(entries);
    for (let i = 0; i < keys.length; i++) {
      const name = keys[i];
      const id = entries[name];
      switch (category) {
        case 'layout':
          R.registerLayout(name, id);
          break;
        case 'id':
          R.registerId(name, id);
          break;
        case 'string':
          R.registerString(name, id);
          break;
        case 'color':
          R.registerColor(name, id);
          break;
        default:
          console.warn(`R.registerBatch: unknown category "${category}"`);
      }
    }
  }

  /**
   * Clear all registrations. Useful for testing.
   */
  static clear(): void {
    R.layout.clear();
    R.id.clear();
    R.string.clear();
    R.color.clear();
  }
}
