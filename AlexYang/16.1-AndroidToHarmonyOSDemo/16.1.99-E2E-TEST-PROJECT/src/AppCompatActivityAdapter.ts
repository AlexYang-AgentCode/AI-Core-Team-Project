/**
 * API #1: AppCompatActivity Adapter (Simplified for E2E Testing)
 *
 * This is a simplified version suitable for actual TypeScript compilation and Jest testing.
 * Full version with HarmonyOS decorators would require ArkUI framework.
 */

/**
 * Platform detection
 */
enum PlatformType {
  ANDROID = 'android',
  HARMONYOS = 'harmonyos',
  UNKNOWN = 'unknown'
}

/**
 * Lifecycle events
 */
enum LifecycleEvent {
  INIT = 'init',
  ON_SHOW = 'onShow',
  ON_HIDE = 'onHide',
  DESTROY = 'destroy'
}

/**
 * Component wrapper for cross-platform compatibility
 */
interface IComponent {
  getId(): string;
  setText(text: string): void;
  getText(): string;
}

/**
 * Generic component wrapper
 */
class ComponentWrapper implements IComponent {
  constructor(
    private id: string,
    private text: string = ''
  ) {}

  getId(): string {
    return this.id;
  }

  setText(text: string): void {
    this.text = text;
  }

  getText(): string {
    return this.text;
  }
}

/**
 * State wrapper for cross-platform state management
 */
class StateWrapper {
  private state: Record<string, any> = {};

  get(key: string, defaultValue?: any): any {
    return this.state[key] !== undefined ? this.state[key] : defaultValue;
  }

  set(key: string, value: any): void {
    this.state[key] = value;
  }

  getAll(): Record<string, any> {
    return { ...this.state };
  }

  clear(): void {
    this.state = {};
  }
}

/**
 * Main AppCompatActivity Adapter
 */
export class AppCompatActivityAdapter {
  private platform: PlatformType = PlatformType.UNKNOWN;
  private components: Map<string, IComponent> = new Map();
  private state: StateWrapper = new StateWrapper();
  private listeners: Map<string, Function[]> = new Map();
  private lifecycleState: LifecycleEvent = LifecycleEvent.DESTROY;
  private nativeActivity: any;

  constructor(nativeActivity?: any) {
    this.nativeActivity = nativeActivity;
    this.detectPlatform();
    this.initializeComponents();
  }

  /**
   * Detect platform
   */
  private detectPlatform(): void {
    // In Jest test environment, default to HARMONYOS for TypeScript
    this.platform = PlatformType.HARMONYOS;
  }

  /**
   * Initialize default components
   */
  private initializeComponents(): void {
    this.registerComponent('text_clock', new ComponentWrapper('text_clock', '00:00:00 AM'));
    this.registerComponent('location_text', new ComponentWrapper('location_text', 'Default Location'));
    this.registerComponent('refresh_button', new ComponentWrapper('refresh_button', 'Refresh'));
  }

  /**
   * Lifecycle: Initialize (maps to Android onCreate + onResume)
   */
  public init(): void {
    if (this.lifecycleState === LifecycleEvent.INIT) {
      return; // Already initialized
    }

    this.lifecycleState = LifecycleEvent.INIT;
    this.emit('lifecycle', LifecycleEvent.INIT);

    if (this.nativeActivity && typeof this.nativeActivity.onCreate === 'function') {
      this.nativeActivity.onCreate();
    }
  }

  /**
   * Lifecycle: Show (maps to Android onResume + HarmonyOS onPageShow)
   */
  public onShow(): void {
    if (this.lifecycleState !== LifecycleEvent.INIT && this.lifecycleState !== LifecycleEvent.ON_HIDE) {
      return;
    }

    this.lifecycleState = LifecycleEvent.ON_SHOW;
    this.emit('lifecycle', LifecycleEvent.ON_SHOW);

    if (this.nativeActivity && typeof this.nativeActivity.onResume === 'function') {
      this.nativeActivity.onResume();
    }
  }

  /**
   * Lifecycle: Hide (maps to Android onPause + HarmonyOS onPageHide)
   */
  public onHide(): void {
    if (this.lifecycleState !== LifecycleEvent.ON_SHOW) {
      return;
    }

    this.lifecycleState = LifecycleEvent.ON_HIDE;
    this.emit('lifecycle', LifecycleEvent.ON_HIDE);

    if (this.nativeActivity && typeof this.nativeActivity.onPause === 'function') {
      this.nativeActivity.onPause();
    }
  }

  /**
   * Lifecycle: Destroy
   */
  public destroy(): void {
    if (this.lifecycleState === LifecycleEvent.DESTROY) {
      return;
    }

    this.lifecycleState = LifecycleEvent.DESTROY;
    this.emit('lifecycle', LifecycleEvent.DESTROY);

    if (this.nativeActivity && typeof this.nativeActivity.onDestroy === 'function') {
      this.nativeActivity.onDestroy();
    }

    this.components.clear();
    this.state.clear();
    this.listeners.clear();
  }

  /**
   * Register a component
   */
  public registerComponent(id: string, component: IComponent): void {
    this.components.set(id, component);
  }

  /**
   * Find a component by ID
   */
  public findViewById(id: string): IComponent | null {
    return this.components.get(id) || null;
  }

  /**
   * Set event listener
   */
  public setOnClickListener(componentId: string, callback: Function): void {
    if (!this.listeners.has(componentId)) {
      this.listeners.set(componentId, []);
    }
    this.listeners.get(componentId)!.push(callback);
  }

  /**
   * Handle component click
   */
  public handleClick(componentId: string): void {
    const callbacks = this.listeners.get(componentId) || [];
    callbacks.forEach(cb => cb());
  }

  /**
   * Set location
   */
  public setLocation(location: string): void {
    this.state.set('location', location);
    const component = this.findViewById('location_text');
    if (component) {
      component.setText(location);
    }
  }

  /**
   * Get location
   */
  public getLocation(): string {
    return this.state.get('location', 'Default Location');
  }

  /**
   * Set time
   */
  public setTime(time: string): void {
    this.state.set('time', time);
    const component = this.findViewById('text_clock');
    if (component) {
      component.setText(time);
    }
  }

  /**
   * Get time
   */
  public getTime(): string {
    return this.state.get('time', '00:00:00 AM');
  }

  /**
   * Update UI (refresh all components)
   */
  public updateUI(): void {
    this.emit('ui_update');
    const now = new Date();
    const hours = String(now.getHours() % 12 || 12).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    const ampm = now.getHours() >= 12 ? 'PM' : 'AM';
    this.setTime(`${hours}:${minutes}:${seconds} ${ampm}`);
  }

  /**
   * Save state
   */
  public saveState(state: Record<string, any>): void {
    Object.keys(state).forEach(key => {
      this.state.set(key, state[key]);
    });
  }

  /**
   * Restore state
   */
  public restoreState(): Record<string, any> {
    return this.state.getAll();
  }

  /**
   * Emit an event
   */
  private emit(eventType: string, eventData?: any): void {
    // Event emission for testing
  }

  /**
   * Get platform type
   */
  public getPlatform(): PlatformType {
    return this.platform;
  }

  /**
   * Check if running on Android
   */
  public isAndroid(): boolean {
    return this.platform === PlatformType.ANDROID;
  }

  /**
   * Check if running on HarmonyOS
   */
  public isHarmonyOS(): boolean {
    return this.platform === PlatformType.HARMONYOS;
  }
}

// Export for testing
export { PlatformType, LifecycleEvent, ComponentWrapper, StateWrapper };
