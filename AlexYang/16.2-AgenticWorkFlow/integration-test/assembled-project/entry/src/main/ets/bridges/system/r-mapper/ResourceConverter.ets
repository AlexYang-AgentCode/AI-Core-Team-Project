/**
 * ResourceConverter — Build-time tool that converts Android resource XML
 * to HarmonyOS resource JSON format.
 *
 * Android keeps strings in res/values/strings.xml and colours in
 * res/values/colors.xml. HarmonyOS uses JSON files under
 * resources/base/element/ (string.json, color.json).
 *
 * This converter does simple regex-based XML parsing — it does NOT need
 * a full XML DOM. The Android resource files follow a very regular format.
 */

export class ResourceConverter {

  // ===========================================================================
  // strings.xml → string.json
  // ===========================================================================

  /**
   * Convert the text content of an Android strings.xml file to a HarmonyOS
   * string.json structure.
   *
   * Input example:
   *   <resources>
   *     <string name="app_name">Calculator</string>
   *     <string name="hello">Hello %s</string>
   *   </resources>
   *
   * Output:
   *   { "string": [ { "name": "app_name", "value": "Calculator" }, ... ] }
   */
  static convertStringsXml(xmlContent: string): string {
    const entries: Array<Record<string, string>> = [];

    // Regex: <string name="xxx">yyy</string>
    // Using a simple pattern — handles single-line entries which is the norm.
    const regex = /<string\s+name="([^"]+)">([\s\S]*?)<\/string>/g;
    let match: RegExpExecArray | null = regex.exec(xmlContent);

    while (match !== null) {
      const name = match[1];
      // Unescape common XML entities
      const value = ResourceConverter._unescapeXml(match[2]);
      entries.push({ name, value });
      match = regex.exec(xmlContent);
    }

    const result: Record<string, Array<Record<string, string>>> = {
      string: entries
    };
    return JSON.stringify(result, null, 2);
  }

  // ===========================================================================
  // colors.xml → color.json
  // ===========================================================================

  /**
   * Convert the text content of an Android colors.xml file to a HarmonyOS
   * color.json structure.
   *
   * Input example:
   *   <resources>
   *     <color name="primary">#FF6200EE</color>
   *     <color name="bg">@android:color/white</color>
   *   </resources>
   *
   * Output:
   *   { "color": [ { "name": "primary", "value": "#FF6200EE" }, ... ] }
   *
   * System colour references (@android:color/xxx) are resolved via
   * resolveSystemColor().
   */
  static convertColorsXml(xmlContent: string): string {
    const entries: Array<Record<string, string>> = [];

    const regex = /<color\s+name="([^"]+)">([\s\S]*?)<\/color>/g;
    let match: RegExpExecArray | null = regex.exec(xmlContent);

    while (match !== null) {
      const name = match[1];
      let value = match[2].trim();

      // Resolve Android system colour references
      if (value.startsWith('@android:color/')) {
        value = ResourceConverter.resolveSystemColor(value);
      }

      entries.push({ name, value });
      match = regex.exec(xmlContent);
    }

    const result: Record<string, Array<Record<string, string>>> = {
      color: entries
    };
    return JSON.stringify(result, null, 2);
  }

  // ===========================================================================
  // Android system colour resolver
  // ===========================================================================

  /**
   * Resolve an Android system colour reference to a hex string.
   * Covers the most commonly used android.R.color values.
   *
   * @param ref - e.g. "@android:color/black"
   * @returns hex colour string, e.g. "#000000"
   */
  static resolveSystemColor(ref: string): string {
    // Strip the prefix to get the colour name
    const name = ref.replace('@android:color/', '');

    const systemColors: Record<string, string> = {
      'black': '#000000',
      'white': '#FFFFFF',
      'transparent': '#00000000',
      'background_dark': '#FF000000',
      'background_light': '#FFFFFFFF',
      'darker_gray': '#FFAAAAAA',
      'holo_blue_bright': '#FF00DDFF',
      'holo_blue_dark': '#FF0099CC',
      'holo_blue_light': '#FF33B5E5',
      'holo_green_dark': '#FF669900',
      'holo_green_light': '#FF99CC00',
      'holo_orange_dark': '#FFFF8800',
      'holo_orange_light': '#FFFFBB33',
      'holo_purple': '#FFAA66CC',
      'holo_red_dark': '#FFCC0000',
      'holo_red_light': '#FFFF4444',
      'primary_text_dark': '#FFFFFFFF',
      'primary_text_light': '#DE000000',
      'secondary_text_dark': '#B3FFFFFF',
      'secondary_text_light': '#8A000000',
      'tab_indicator_text': '#FF808080',
      'widget_edittext_dark': '#FF000000',
    };

    if (systemColors[name] !== undefined) {
      return systemColors[name];
    }

    // Unknown — return the original reference so it can be manually fixed
    console.warn(`ResourceConverter: unknown system colour "${ref}", returning as-is`);
    return ref;
  }

  // ===========================================================================
  // Internal helpers
  // ===========================================================================

  /**
   * Unescape common XML entities back to plain text.
   */
  private static _unescapeXml(text: string): string {
    return text
      .replace(/&amp;/g, '&')
      .replace(/&lt;/g, '<')
      .replace(/&gt;/g, '>')
      .replace(/&quot;/g, '"')
      .replace(/&apos;/g, "'")
      .replace(/\\'/g, "'")   // Android-specific: escaped apostrophe
      .replace(/\\"/g, '"');  // Android-specific: escaped double-quote
  }
}
