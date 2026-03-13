/**
 * ViewRegistry.ets — R.id.* component reference registry
 *
 * In Android, findViewById(R.id.myButton) returns the view with that id.
 * In ArkUI, components are declarative and do not have object references
 * by default. This registry provides a global id -> component map so that
 * BridgedActivity.findViewById() can resolve references.
 *
 * ArkUI page code registers each component after build, and
 * BridgedActivity.onDestroy() calls clear() to avoid leaks.
 */

export class ViewRegistry {
  /** id -> component reference */
  private static registry: Map<number, Object> = new Map();

  /**
   * Register a component reference under a numeric id.
   * Typically called from ArkUI page code after component creation.
   *
   * @param id the numeric id (mirrors R.id.*)
   * @param component the component object reference
   */
  static register(id: number, component: Object): void {
    ViewRegistry.registry.set(id, component);
  }

  /**
   * Look up a component by its numeric id.
   *
   * @param id the numeric id to resolve
   * @returns the component cast to T, or null if not found
   */
  static find<T>(id: number): T | null {
    const component = ViewRegistry.registry.get(id);
    if (component === undefined) {
      return null;
    }
    return component as T;
  }

  /**
   * Remove all registered component references.
   * Call this during Activity destruction to prevent memory leaks.
   */
  static clear(): void {
    ViewRegistry.registry.clear();
  }
}
