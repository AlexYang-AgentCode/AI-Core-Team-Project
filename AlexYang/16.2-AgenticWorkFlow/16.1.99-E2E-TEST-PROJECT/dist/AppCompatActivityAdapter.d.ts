/**
 * API #1: AppCompatActivity Adapter (Simplified for E2E Testing)
 *
 * This is a simplified version suitable for actual TypeScript compilation and Jest testing.
 * Full version with HarmonyOS decorators would require ArkUI framework.
 */
/**
 * Platform detection
 */
declare enum PlatformType {
    ANDROID = "android",
    HARMONYOS = "harmonyos",
    UNKNOWN = "unknown"
}
/**
 * Lifecycle events
 */
declare enum LifecycleEvent {
    INIT = "init",
    ON_SHOW = "onShow",
    ON_HIDE = "onHide",
    DESTROY = "destroy"
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
declare class ComponentWrapper implements IComponent {
    private id;
    private text;
    constructor(id: string, text?: string);
    getId(): string;
    setText(text: string): void;
    getText(): string;
}
/**
 * State wrapper for cross-platform state management
 */
declare class StateWrapper {
    private state;
    get(key: string, defaultValue?: any): any;
    set(key: string, value: any): void;
    getAll(): Record<string, any>;
    clear(): void;
}
/**
 * Main AppCompatActivity Adapter
 */
export declare class AppCompatActivityAdapter {
    private platform;
    private components;
    private state;
    private listeners;
    private lifecycleState;
    private nativeActivity;
    constructor(nativeActivity?: any);
    /**
     * Detect platform
     */
    private detectPlatform;
    /**
     * Initialize default components
     */
    private initializeComponents;
    /**
     * Lifecycle: Initialize (maps to Android onCreate + onResume)
     */
    init(): void;
    /**
     * Lifecycle: Show (maps to Android onResume + HarmonyOS onPageShow)
     */
    onShow(): void;
    /**
     * Lifecycle: Hide (maps to Android onPause + HarmonyOS onPageHide)
     */
    onHide(): void;
    /**
     * Lifecycle: Destroy
     */
    destroy(): void;
    /**
     * Register a component
     */
    registerComponent(id: string, component: IComponent): void;
    /**
     * Find a component by ID
     */
    findViewById(id: string): IComponent | null;
    /**
     * Set event listener
     */
    setOnClickListener(componentId: string, callback: Function): void;
    /**
     * Handle component click
     */
    handleClick(componentId: string): void;
    /**
     * Set location
     */
    setLocation(location: string): void;
    /**
     * Get location
     */
    getLocation(): string;
    /**
     * Set time
     */
    setTime(time: string): void;
    /**
     * Get time
     */
    getTime(): string;
    /**
     * Update UI (refresh all components)
     */
    updateUI(): void;
    /**
     * Save state
     */
    saveState(state: Record<string, any>): void;
    /**
     * Restore state
     */
    restoreState(): Record<string, any>;
    /**
     * Emit an event
     */
    private emit;
    /**
     * Get platform type
     */
    getPlatform(): PlatformType;
    /**
     * Check if running on Android
     */
    isAndroid(): boolean;
    /**
     * Check if running on HarmonyOS
     */
    isHarmonyOS(): boolean;
}
export { PlatformType, LifecycleEvent, ComponentWrapper, StateWrapper };
//# sourceMappingURL=AppCompatActivityAdapter.d.ts.map