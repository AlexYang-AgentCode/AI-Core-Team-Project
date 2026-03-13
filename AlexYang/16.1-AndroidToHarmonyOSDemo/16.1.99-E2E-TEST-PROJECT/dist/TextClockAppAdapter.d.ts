/**
 * TextClock Application Adapter - Complete Android API Bridge
 *
 * Implements 12 core Android APIs for TextClock application
 * that bridges Android and HarmonyOS ecosystems.
 *
 * APIs:
 * 1. AppCompatActivity (API #1) - Already implemented in AppCompatActivityAdapter.ts
 * 2. Bundle - Key-value data container
 * 3. setContentView - Layout inflation
 * 4. ConstraintLayout - Layout manager
 * 5. TextView - Text display component
 * 6. Button - Clickable button component
 * 7. TextClock - Time display with formatting
 * 8. OnClickListener - Click event handler
 * 9. findViewById - Component reference lookup
 * 10. TimeZone - Timezone handling
 * 11. Calendar/Date - Time calculations
 * 12. Intent - Inter-component communication
 */
/**
 * API #2: Bundle - Key-value data container
 * Purpose: Store and retrieve application state data
 */
export declare class Bundle {
    private data;
    putString(key: string, value: string): void;
    getString(key: string, defaultValue?: string): string;
    putInt(key: string, value: number): void;
    getInt(key: string, defaultValue?: number): number;
    putBoolean(key: string, value: boolean): void;
    getBoolean(key: string, defaultValue?: boolean): boolean;
    containsKey(key: string): boolean;
    remove(key: string): void;
    clear(): void;
    keySet(): string[];
    getAll(): Record<string, any>;
}
/**
 * API #3: Layout Resource Handler
 * Purpose: Manage layout inflation and view hierarchy
 */
export interface LayoutResource {
    id: string;
    components: Map<string, UIComponent>;
}
/**
 * API #4: ConstraintLayout - Layout manager
 * Purpose: Position views with constraints (simplified for TypeScript)
 */
export declare class ConstraintLayout implements LayoutResource {
    id: string;
    components: Map<string, UIComponent>;
    width: number;
    height: number;
    addView(id: string, component: UIComponent): void;
    getView(id: string): UIComponent | null;
    getViewById(id: string): UIComponent | null;
    removeView(id: string): void;
    getMeasuredWidth(): number;
    getMeasuredHeight(): number;
    setMeasuredDimension(width: number, height: number): void;
}
/**
 * Base UI Component interface
 */
export interface UIComponent {
    getId(): string;
    setText(text: string): void;
    getText(): string;
    setVisibility(visibility: number): void;
    getVisibility(): number;
    setOnClickListener(listener: OnClickListener | null): void;
}
export declare const VISIBLE = 0;
export declare const INVISIBLE = 4;
export declare const GONE = 8;
/**
 * API #5: TextView - Text display component
 */
export declare class TextView implements UIComponent {
    private id;
    private text;
    private textSize;
    private textColor;
    private visibility;
    private clickListener;
    constructor(id: string);
    getId(): string;
    setText(text: string): void;
    getText(): string;
    setTextSize(size: number): void;
    getTextSize(): number;
    setTextColor(color: number): void;
    getTextColor(): number;
    setVisibility(visibility: number): void;
    getVisibility(): number;
    setOnClickListener(listener: OnClickListener | null): void;
    performClick(): void;
}
/**
 * API #6: Button - Clickable button component
 */
export declare class Button extends TextView {
    constructor(id: string);
}
/**
 * API #7: TextClock - Time display with automatic updates
 */
export declare class TextClock extends TextView {
    private format12Hour;
    private format24Hour;
    private timeZone;
    private is24HourFormat;
    private updateInterval;
    constructor(id: string);
    setFormat12Hour(format: string): void;
    getFormat12Hour(): string;
    setFormat24Hour(format: string): void;
    getFormat24Hour(): string;
    setTimeZone(timeZone: string): void;
    getTimeZone(): string;
    private updateTime;
    startTicking(): void;
    stopTicking(): void;
}
/**
 * API #8: OnClickListener - Click event interface
 */
export interface OnClickListener {
    onClick(view: UIComponent): void;
}
/**
 * API #10: TimeZone - Timezone handling
 */
export declare class TimeZone {
    private static timeZones;
    private id;
    private displayName;
    private offset;
    private constructor();
    static getTimeZone(id: string): TimeZone;
    static getDefault(): TimeZone;
    getId(): string;
    getDisplayName(): string;
    getOffset(): number;
    getOffsetHours(): number;
}
/**
 * API #11: Calendar/Date - Time calculations
 * Simplified Date API for JavaScript compatibility
 */
export declare class CalendarDate {
    private date;
    constructor();
    static getInstance(): CalendarDate;
    getTime(): Date;
    setTime(date: Date): void;
    get(field: number): number;
    set(field: number, value: number): void;
    toString(): string;
    getTimeInMillis(): number;
}
export declare const YEAR = 1;
export declare const MONTH = 2;
export declare const DAY_OF_MONTH = 5;
export declare const HOUR = 10;
export declare const HOUR_OF_DAY = 11;
export declare const MINUTE = 12;
export declare const SECOND = 13;
export declare const MILLISECOND = 14;
export declare const DAY_OF_WEEK = 7;
/**
 * API #12: Intent - Inter-component communication
 */
export declare class Intent {
    private extras;
    private action;
    private component;
    constructor(action?: string, component?: string);
    putExtra(name: string, value: any): Intent;
    getStringExtra(name: string): string;
    getIntExtra(name: string, defaultValue?: number): number;
    getExtras(): Bundle;
    setAction(action: string): Intent;
    getAction(): string;
    setComponent(component: string): Intent;
    getComponent(): string;
}
/**
 * API #3 Extended: setContentView - Layout inflation handler
 */
export declare class LayoutInflater {
    static inflate(layoutId: string): LayoutResource;
}
/**
 * Complete TextClock Application Adapter
 * Combines all 12 APIs into a unified interface
 */
export declare class TextClockAppAdapter {
    private activity;
    private layout;
    private bundle;
    private intent;
    private textClockComponent;
    constructor(activity?: any);
    setContentView(layoutId: string): void;
    findViewById(id: string): UIComponent | null;
    getBundle(): Bundle;
    saveInstanceState(outState: Bundle): void;
    restoreInstanceState(savedInstanceState: Bundle): void;
    setIntent(intent: Intent): void;
    getIntent(): Intent | null;
    onCreate(savedInstanceState?: Bundle): void;
    onResume(): void;
    onPause(): void;
    onDestroy(): void;
    setLocationText(location: string): void;
    getLocationText(): string;
    setRefreshButtonListener(listener: OnClickListener): void;
    handleRefreshClick(): void;
}
export { LayoutInflater, VISIBLE, INVISIBLE, GONE, YEAR, MONTH, DAY_OF_MONTH, HOUR, HOUR_OF_DAY, MINUTE, SECOND, MILLISECOND, DAY_OF_WEEK, };
//# sourceMappingURL=TextClockAppAdapter.d.ts.map