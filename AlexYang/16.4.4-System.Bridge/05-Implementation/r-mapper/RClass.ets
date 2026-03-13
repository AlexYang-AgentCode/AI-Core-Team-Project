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
 *   R.registerId("btn_ok", 0x7F050001);
 *
 *   // At usage site (migrated code)
 *   const id = R.getViewId("btn_ok");
 *
 * Calculator Demo Specific Mappings:
 *   This R class includes all 21 R.id entries used by 16.1 Calculator's MainActivity.java
 *   - textViewInputNumbers, textViewOutput
 *   - button0-button9, buttonAdd, buttonSubtract, buttonMultiply, buttonDivide
 *   - buttonEquals, buttonClear, buttonDecimal, buttonPercent, buttonParentheses
 */

export class R {
  // Resource maps keyed by Android resource name → HarmonyOS resource ID
  static layoutMap: Map<string, number> = new Map();
  static idMap: Map<string, number> = new Map();
  static stringMap: Map<string, number> = new Map();
  static colorMap: Map<string, number> = new Map();

  // ===========================================================================
  // Calculator Demo R.id Constants (Auto-generated mappings)
  // These IDs match the R.id.* references in 16.1 Calculator MainActivity.java
  // ===========================================================================

  static readonly id = {
    // Display fields
    textViewInputNumbers: 0x7F050001,
    textViewOutput: 0x7F050002,

    // Number buttons 0-9
    button0: 0x7F050010,
    button1: 0x7F050011,
    button2: 0x7F050012,
    button3: 0x7F050013,
    button4: 0x7F050014,
    button5: 0x7F050015,
    button6: 0x7F050016,
    button7: 0x7F050017,
    button8: 0x7F050018,
    button9: 0x7F050019,

    // Operator buttons
    buttonAdd: 0x7F050020,
    buttonSubtract: 0x7F050021,
    buttonMultiply: 0x7F050022,
    buttonDivide: 0x7F050023,
    buttonEquals: 0x7F050024,

    // Function buttons
    buttonClear: 0x7F050030,
    buttonDecimal: 0x7F050031,
    buttonPercent: 0x7F050032,
    buttonParentheses: 0x7F050033,

    // Legacy Calculator naming variants (for compatibility)
    button_zero: 0x7F050010,
    button_one: 0x7F050011,
    button_two: 0x7F050012,
    button_three: 0x7F050013,
    button_four: 0x7F050014,
    button_five: 0x7F050015,
    button_six: 0x7F050016,
    button_seven: 0x7F050017,
    button_eight: 0x7F050018,
    button_nine: 0x7F050019,
    button_dot: 0x7F050031,
    button_equal: 0x7F050024,
  };

  static readonly layout = {
    activity_main: 0x7F030001,
  };

  static readonly string = {
    app_name: 0x7F040001,
  };

  static readonly color = {
    colorPrimary: 0x7F060001,
    colorPrimaryDark: 0x7F060002,
    colorAccent: 0x7F060003,
    black: 0x7F060010,
    white: 0x7F060011,
  };

  // ===========================================================================
  // Registration
  // ===========================================================================

  static registerLayout(name: string, id: number): void {
    R.layoutMap.set(name, id);
  }

  static registerId(name: string, id: number): void {
    R.idMap.set(name, id);
  }

  static registerString(name: string, id: number): void {
    R.stringMap.set(name, id);
  }

  static registerColor(name: string, id: number): void {
    R.colorMap.set(name, id);
  }

  // ===========================================================================
  // Lookup
  // ===========================================================================

  /**
   * Look up a layout resource ID by name.
   * Throws if the name was never registered.
   */
  static getLayoutId(name: string): number {
    const val = R.layoutMap.get(name);
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
    const val = R.idMap.get(name);
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
    const val = R.stringMap.get(name);
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
    const val = R.colorMap.get(name);
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
    R.layoutMap.clear();
    R.idMap.clear();
    R.stringMap.clear();
    R.colorMap.clear();
  }

  /**
   * Initialize Calculator Demo resource mappings.
   * Call this in EntryAbility.onCreate() to populate the maps.
   */
  static initCalculatorMappings(): void {
    // Register all Calculator R.id entries
    R.registerId('textViewInputNumbers', R.id.textViewInputNumbers);
    R.registerId('textViewOutput', R.id.textViewOutput);

    // Number buttons
    R.registerId('button0', R.id.button0);
    R.registerId('button1', R.id.button1);
    R.registerId('button2', R.id.button2);
    R.registerId('button3', R.id.button3);
    R.registerId('button4', R.id.button4);
    R.registerId('button5', R.id.button5);
    R.registerId('button6', R.id.button6);
    R.registerId('button7', R.id.button7);
    R.registerId('button8', R.id.button8);
    R.registerId('button9', R.id.button9);

    // Operator buttons
    R.registerId('buttonAdd', R.id.buttonAdd);
    R.registerId('buttonSubtract', R.id.buttonSubtract);
    R.registerId('buttonMultiply', R.id.buttonMultiply);
    R.registerId('buttonDivide', R.id.buttonDivide);
    R.registerId('buttonEquals', R.id.buttonEquals);

    // Function buttons
    R.registerId('buttonClear', R.id.buttonClear);
    R.registerId('buttonDecimal', R.id.buttonDecimal);
    R.registerId('buttonPercent', R.id.buttonPercent);
    R.registerId('buttonParentheses', R.id.buttonParentheses);

    // Legacy naming variants
    R.registerId('button_zero', R.id.button_zero);
    R.registerId('button_one', R.id.button_one);
    R.registerId('button_two', R.id.button_two);
    R.registerId('button_three', R.id.button_three);
    R.registerId('button_four', R.id.button_four);
    R.registerId('button_five', R.id.button_five);
    R.registerId('button_six', R.id.button_six);
    R.registerId('button_seven', R.id.button_seven);
    R.registerId('button_eight', R.id.button_eight);
    R.registerId('button_nine', R.id.button_nine);
    R.registerId('button_dot', R.id.button_dot);
    R.registerId('button_equal', R.id.button_equal);

    // Layout
    R.registerLayout('activity_main', R.layout.activity_main);

    // Strings
    R.registerString('app_name', R.string.app_name);

    // Colors
    R.registerColor('colorPrimary', R.color.colorPrimary);
    R.registerColor('colorPrimaryDark', R.color.colorPrimaryDark);
    R.registerColor('colorAccent', R.color.colorAccent);
    R.registerColor('black', R.color.black);
    R.registerColor('white', R.color.white);
  }
}
