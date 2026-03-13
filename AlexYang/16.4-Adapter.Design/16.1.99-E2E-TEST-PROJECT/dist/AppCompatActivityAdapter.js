"use strict";
/**
 * API #1: AppCompatActivity Adapter (Simplified for E2E Testing)
 *
 * This is a simplified version suitable for actual TypeScript compilation and Jest testing.
 * Full version with HarmonyOS decorators would require ArkUI framework.
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.StateWrapper = exports.ComponentWrapper = exports.LifecycleEvent = exports.PlatformType = exports.AppCompatActivityAdapter = void 0;
/**
 * Platform detection
 */
var PlatformType;
(function (PlatformType) {
    PlatformType["ANDROID"] = "android";
    PlatformType["HARMONYOS"] = "harmonyos";
    PlatformType["UNKNOWN"] = "unknown";
})(PlatformType || (exports.PlatformType = PlatformType = {}));
/**
 * Lifecycle events
 */
var LifecycleEvent;
(function (LifecycleEvent) {
    LifecycleEvent["INIT"] = "init";
    LifecycleEvent["ON_SHOW"] = "onShow";
    LifecycleEvent["ON_HIDE"] = "onHide";
    LifecycleEvent["DESTROY"] = "destroy";
})(LifecycleEvent || (exports.LifecycleEvent = LifecycleEvent = {}));
/**
 * Generic component wrapper
 */
class ComponentWrapper {
    constructor(id, text = '') {
        this.id = id;
        this.text = text;
    }
    getId() {
        return this.id;
    }
    setText(text) {
        this.text = text;
    }
    getText() {
        return this.text;
    }
}
exports.ComponentWrapper = ComponentWrapper;
/**
 * State wrapper for cross-platform state management
 */
class StateWrapper {
    constructor() {
        this.state = {};
    }
    get(key, defaultValue) {
        return this.state[key] !== undefined ? this.state[key] : defaultValue;
    }
    set(key, value) {
        this.state[key] = value;
    }
    getAll() {
        return { ...this.state };
    }
    clear() {
        this.state = {};
    }
}
exports.StateWrapper = StateWrapper;
/**
 * Main AppCompatActivity Adapter
 */
class AppCompatActivityAdapter {
    constructor(nativeActivity) {
        this.platform = PlatformType.UNKNOWN;
        this.components = new Map();
        this.state = new StateWrapper();
        this.listeners = new Map();
        this.lifecycleState = LifecycleEvent.DESTROY;
        this.nativeActivity = nativeActivity;
        this.detectPlatform();
        this.initializeComponents();
    }
    /**
     * Detect platform
     */
    detectPlatform() {
        // In Jest test environment, default to HARMONYOS for TypeScript
        this.platform = PlatformType.HARMONYOS;
    }
    /**
     * Initialize default components
     */
    initializeComponents() {
        this.registerComponent('text_clock', new ComponentWrapper('text_clock', '00:00:00 AM'));
        this.registerComponent('location_text', new ComponentWrapper('location_text', 'Default Location'));
        this.registerComponent('refresh_button', new ComponentWrapper('refresh_button', 'Refresh'));
    }
    /**
     * Lifecycle: Initialize (maps to Android onCreate + onResume)
     */
    init() {
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
    onShow() {
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
    onHide() {
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
    destroy() {
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
    registerComponent(id, component) {
        this.components.set(id, component);
    }
    /**
     * Find a component by ID
     */
    findViewById(id) {
        return this.components.get(id) || null;
    }
    /**
     * Set event listener
     */
    setOnClickListener(componentId, callback) {
        if (!this.listeners.has(componentId)) {
            this.listeners.set(componentId, []);
        }
        this.listeners.get(componentId).push(callback);
    }
    /**
     * Handle component click
     */
    handleClick(componentId) {
        const callbacks = this.listeners.get(componentId) || [];
        callbacks.forEach(cb => cb());
    }
    /**
     * Set location
     */
    setLocation(location) {
        this.state.set('location', location);
        const component = this.findViewById('location_text');
        if (component) {
            component.setText(location);
        }
    }
    /**
     * Get location
     */
    getLocation() {
        return this.state.get('location', 'Default Location');
    }
    /**
     * Set time
     */
    setTime(time) {
        this.state.set('time', time);
        const component = this.findViewById('text_clock');
        if (component) {
            component.setText(time);
        }
    }
    /**
     * Get time
     */
    getTime() {
        return this.state.get('time', '00:00:00 AM');
    }
    /**
     * Update UI (refresh all components)
     */
    updateUI() {
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
    saveState(state) {
        Object.keys(state).forEach(key => {
            this.state.set(key, state[key]);
        });
    }
    /**
     * Restore state
     */
    restoreState() {
        return this.state.getAll();
    }
    /**
     * Emit an event
     */
    emit(eventType, eventData) {
        // Event emission for testing
    }
    /**
     * Get platform type
     */
    getPlatform() {
        return this.platform;
    }
    /**
     * Check if running on Android
     */
    isAndroid() {
        return this.platform === PlatformType.ANDROID;
    }
    /**
     * Check if running on HarmonyOS
     */
    isHarmonyOS() {
        return this.platform === PlatformType.HARMONYOS;
    }
}
exports.AppCompatActivityAdapter = AppCompatActivityAdapter;
//# sourceMappingURL=AppCompatActivityAdapter.js.map