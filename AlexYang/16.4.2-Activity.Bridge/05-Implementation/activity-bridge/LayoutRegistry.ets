/**
 * LayoutRegistry.ets — R.layout.* to ArkUI page path mapping
 *
 * In Android, setContentView(R.layout.activity_main) loads an XML layout.
 * In HarmonyOS, we need to map that numeric layout id to an ArkUI page
 * path string (e.g. "pages/MainPage") for windowStage.loadContent().
 *
 * Migrated apps register their mappings at startup, typically in
 * AbilityStage.onCreate() or a static initializer block.
 */

export class LayoutRegistry {
  /** layout id -> ArkUI page path */
  private static registry: Map<number, string> = new Map();

  /**
   * Register a single layout id to page path mapping.
   *
   * @param layoutId the numeric id (mirrors R.layout.*)
   * @param pagePath the ArkUI page route, e.g. "pages/MainPage"
   */
  static register(layoutId: number, pagePath: string): void {
    LayoutRegistry.registry.set(layoutId, pagePath);
  }

  /**
   * Look up the ArkUI page path for a given layout id.
   *
   * @param layoutId the numeric id to resolve
   * @returns the page path string
   * @throws Error if the layout id has not been registered
   */
  static getPagePath(layoutId: number): string {
    const path = LayoutRegistry.registry.get(layoutId);
    if (path === undefined) {
      throw new Error(
        `LayoutRegistry: no page path registered for layoutId=${layoutId}. ` +
        `Call LayoutRegistry.register() before setContentView().`
      );
    }
    return path;
  }

  /**
   * Bulk-register multiple layout id -> page path mappings at once.
   *
   * @param mappings a Map of layoutId to pagePath entries
   */
  static registerAll(mappings: Map<number, string>): void {
    mappings.forEach((pagePath: string, layoutId: number) => {
      LayoutRegistry.registry.set(layoutId, pagePath);
    });
  }
}
