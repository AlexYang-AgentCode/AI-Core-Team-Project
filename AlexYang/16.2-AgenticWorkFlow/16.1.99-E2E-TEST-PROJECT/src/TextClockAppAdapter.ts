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
export class Bundle {
  private data: Map<string, any> = new Map();

  putString(key: string, value: string): void {
    this.data.set(key, value);
  }

  getString(key: string, defaultValue?: string): string {
    return (this.data.get(key) as string) || defaultValue || '';
  }

  putInt(key: string, value: number): void {
    this.data.set(key, Math.floor(value));
  }

  getInt(key: string, defaultValue?: number): number {
    return (this.data.get(key) as number) || defaultValue || 0;
  }

  putBoolean(key: string, value: boolean): void {
    this.data.set(key, value);
  }

  getBoolean(key: string, defaultValue?: boolean): boolean {
    return (this.data.get(key) as boolean) ?? (defaultValue || false);
  }

  containsKey(key: string): boolean {
    return this.data.has(key);
  }

  remove(key: string): void {
    this.data.delete(key);
  }

  clear(): void {
    this.data.clear();
  }

  keySet(): string[] {
    return Array.from(this.data.keys());
  }

  getAll(): Record<string, any> {
    const result: Record<string, any> = {};
    this.data.forEach((value, key) => {
      result[key] = value;
    });
    return result;
  }
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
export class ConstraintLayout implements LayoutResource {
  id: string = 'constraint_layout_0';
  components: Map<string, UIComponent> = new Map();
  width: number = 1080; // Default Android screen width
  height: number = 1920; // Default Android screen height

  addView(id: string, component: UIComponent): void {
    this.components.set(id, component);
  }

  getView(id: string): UIComponent | null {
    return this.components.get(id) || null;
  }

  getViewById(id: string): UIComponent | null {
    return this.components.get(id) || null;
  }

  removeView(id: string): void {
    this.components.delete(id);
  }

  getMeasuredWidth(): number {
    return this.width;
  }

  getMeasuredHeight(): number {
    return this.height;
  }

  setMeasuredDimension(width: number, height: number): void {
    this.width = width;
    this.height = height;
  }
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

export const VISIBLE = 0;
export const INVISIBLE = 4;
export const GONE = 8;

/**
 * API #5: TextView - Text display component
 */
export class TextView implements UIComponent {
  private id: string;
  private text: string = '';
  private textSize: number = 14;
  private textColor: number = 0xff000000; // Black
  private visibility: number = VISIBLE;
  private clickListener: OnClickListener | null = null;

  constructor(id: string) {
    this.id = id;
  }

  getId(): string {
    return this.id;
  }

  setText(text: string): void {
    this.text = text;
  }

  getText(): string {
    return this.text;
  }

  setTextSize(size: number): void {
    this.textSize = size;
  }

  getTextSize(): number {
    return this.textSize;
  }

  setTextColor(color: number): void {
    this.textColor = color;
  }

  getTextColor(): number {
    return this.textColor;
  }

  setVisibility(visibility: number): void {
    this.visibility = visibility;
  }

  getVisibility(): number {
    return this.visibility;
  }

  setOnClickListener(listener: OnClickListener | null): void {
    this.clickListener = listener;
  }

  performClick(): void {
    if (this.clickListener) {
      this.clickListener.onClick(this);
    }
  }
}

/**
 * API #6: Button - Clickable button component
 */
export class Button extends TextView {
  constructor(id: string) {
    super(id);
    this.setText('Button');
  }

  // Button extends TextView, inherits all properties
}

/**
 * API #7: TextClock - Time display with automatic updates
 */
export class TextClock extends TextView {
  private format12Hour: string = 'hh:mm:ss a';
  private format24Hour: string = 'HH:mm:ss';
  private timeZone: string = 'UTC';
  private is24HourFormat: boolean = false;
  private updateInterval: NodeJS.Timeout | null = null;

  constructor(id: string) {
    super(id);
    this.setText('00:00:00 AM');
  }

  setFormat12Hour(format: string): void {
    this.format12Hour = format;
    this.is24HourFormat = false;
    this.updateTime();
  }

  getFormat12Hour(): string {
    return this.format12Hour;
  }

  setFormat24Hour(format: string): void {
    this.format24Hour = format;
    this.is24HourFormat = true;
    this.updateTime();
  }

  getFormat24Hour(): string {
    return this.format24Hour;
  }

  setTimeZone(timeZone: string): void {
    this.timeZone = timeZone;
    this.updateTime();
  }

  getTimeZone(): string {
    return this.timeZone;
  }

  private updateTime(): void {
    const now = new Date();
    const hours = String(now.getHours() % 12 || 12).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    const ampm = now.getHours() >= 12 ? 'PM' : 'AM';

    if (this.is24HourFormat) {
      const hours24 = String(now.getHours()).padStart(2, '0');
      this.setText(`${hours24}:${minutes}:${seconds}`);
    } else {
      this.setText(`${hours}:${minutes}:${seconds} ${ampm}`);
    }
  }

  startTicking(): void {
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
    }
    this.updateTime();
    this.updateInterval = setInterval(() => {
      this.updateTime();
    }, 1000);
  }

  stopTicking(): void {
    if (this.updateInterval) {
      clearInterval(this.updateInterval);
      this.updateInterval = null;
    }
  }
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
export class TimeZone {
  private static timeZones: Map<string, TimeZone> = new Map();
  private id: string;
  private displayName: string;
  private offset: number; // Minutes from UTC

  private constructor(id: string, displayName: string, offset: number) {
    this.id = id;
    this.displayName = displayName;
    this.offset = offset;
  }

  static getTimeZone(id: string): TimeZone {
    if (!TimeZone.timeZones.has(id)) {
      // Default timezone with UTC offset
      const offsetHours = parseInt(id.split('GMT')[1] || '0', 10);
      const offset = offsetHours * 60;
      const tz = new TimeZone(id, id, offset);
      TimeZone.timeZones.set(id, tz);
    }
    return TimeZone.timeZones.get(id)!;
  }

  static getDefault(): TimeZone {
    // Return UTC as default in testing environment
    return TimeZone.getTimeZone('UTC');
  }

  getId(): string {
    return this.id;
  }

  getDisplayName(): string {
    return this.displayName;
  }

  getOffset(): number {
    return this.offset;
  }

  getOffsetHours(): number {
    return this.offset / 60;
  }
}

/**
 * API #11: Calendar/Date - Time calculations
 * Simplified Date API for JavaScript compatibility
 */
export class CalendarDate {
  private date: Date;

  constructor() {
    this.date = new Date();
  }

  static getInstance(): CalendarDate {
    return new CalendarDate();
  }

  getTime(): Date {
    return new Date(this.date.getTime());
  }

  setTime(date: Date): void {
    this.date = new Date(date.getTime());
  }

  get(field: number): number {
    switch (field) {
      case 5: // DAY_OF_MONTH
        return this.date.getDate();
      case 10: // HOUR
        return this.date.getHours() % 12;
      case 11: // HOUR_OF_DAY
        return this.date.getHours();
      case 12: // MINUTE
        return this.date.getMinutes();
      case 13: // SECOND
        return this.date.getSeconds();
      case 14: // MILLISECOND
        return this.date.getMilliseconds();
      case 1: // YEAR
        return this.date.getFullYear();
      case 2: // MONTH
        return this.date.getMonth();
      case 7: // DAY_OF_WEEK
        return this.date.getDay();
      default:
        return 0;
    }
  }

  set(field: number, value: number): void {
    switch (field) {
      case 5: // DAY_OF_MONTH
        this.date.setDate(value);
        break;
      case 10: // HOUR
        this.date.setHours(value % 12);
        break;
      case 11: // HOUR_OF_DAY
        this.date.setHours(value);
        break;
      case 12: // MINUTE
        this.date.setMinutes(value);
        break;
      case 13: // SECOND
        this.date.setSeconds(value);
        break;
      case 14: // MILLISECOND
        this.date.setMilliseconds(value);
        break;
      case 1: // YEAR
        this.date.setFullYear(value);
        break;
      case 2: // MONTH
        this.date.setMonth(value);
        break;
    }
  }

  toString(): string {
    return this.date.toString();
  }

  getTimeInMillis(): number {
    return this.date.getTime();
  }
}

// Calendar field constants
export const YEAR = 1;
export const MONTH = 2;
export const DAY_OF_MONTH = 5;
export const HOUR = 10;
export const HOUR_OF_DAY = 11;
export const MINUTE = 12;
export const SECOND = 13;
export const MILLISECOND = 14;
export const DAY_OF_WEEK = 7;

/**
 * API #12: Intent - Inter-component communication
 */
export class Intent {
  private extras: Bundle;
  private action: string = '';
  private component: string = '';

  constructor(action?: string, component?: string) {
    this.extras = new Bundle();
    if (action) this.action = action;
    if (component) this.component = component;
  }

  putExtra(name: string, value: any): Intent {
    this.extras.putString(name, String(value));
    return this;
  }

  getStringExtra(name: string): string {
    return this.extras.getString(name, '');
  }

  getIntExtra(name: string, defaultValue?: number): number {
    return this.extras.getInt(name, defaultValue || 0);
  }

  getExtras(): Bundle {
    return this.extras;
  }

  setAction(action: string): Intent {
    this.action = action;
    return this;
  }

  getAction(): string {
    return this.action;
  }

  setComponent(component: string): Intent {
    this.component = component;
    return this;
  }

  getComponent(): string {
    return this.component;
  }
}

/**
 * API #3 Extended: setContentView - Layout inflation handler
 */
export class LayoutInflater {
  static inflate(layoutId: string): LayoutResource {
    // In real Android, this would parse XML layout file
    // For testing, we return a pre-configured layout
    const layout = new ConstraintLayout();

    // Default TextClock layout structure
    switch (layoutId) {
      case 'activity_text_clock':
        layout.addView('text_clock', new TextClock('text_clock'));
        layout.addView('location_text', new TextView('location_text'));
        layout.addView('refresh_button', new Button('refresh_button'));
        break;
      default:
        break;
    }

    return layout;
  }
}

/**
 * Complete TextClock Application Adapter
 * Combines all 12 APIs into a unified interface
 */
export class TextClockAppAdapter {
  private activity: any;
  private layout: LayoutResource | null = null;
  private bundle: Bundle = new Bundle();
  private intent: Intent | null = null;
  private textClockComponent: TextClock | null = null;

  constructor(activity?: any) {
    this.activity = activity;
  }

  // API #3: Load layout (setContentView)
  setContentView(layoutId: string): void {
    this.layout = LayoutInflater.inflate(layoutId);

    // Initialize TextClock for auto-ticking
    if (layoutId === 'activity_text_clock') {
      const layout = this.layout as ConstraintLayout;
      this.textClockComponent = layout.getView('text_clock') as TextClock;
      if (this.textClockComponent) {
        this.textClockComponent.setFormat12Hour('hh:mm:ss a');
        this.textClockComponent.setTimeZone('UTC');
        this.textClockComponent.startTicking();
      }
    }
  }

  // API #9: Find view by ID
  findViewById(id: string): UIComponent | null {
    if (!this.layout) return null;
    const layout = this.layout as ConstraintLayout;
    return layout.getView(id) || null;
  }

  // API #2: Work with Bundle
  getBundle(): Bundle {
    return this.bundle;
  }

  saveInstanceState(outState: Bundle): void {
    const textClock = this.findViewById('text_clock');
    if (textClock) {
      outState.putString('time_text', textClock.getText());
    }
    const location = this.findViewById('location_text');
    if (location) {
      outState.putString('location_text', location.getText());
    }
  }

  restoreInstanceState(savedInstanceState: Bundle): void {
    if (savedInstanceState.containsKey('time_text')) {
      const textClock = this.findViewById('text_clock');
      if (textClock) {
        textClock.setText(savedInstanceState.getString('time_text', ''));
      }
    }
    if (savedInstanceState.containsKey('location_text')) {
      const location = this.findViewById('location_text');
      if (location) {
        location.setText(savedInstanceState.getString('location_text', ''));
      }
    }
  }

  // API #12: Work with Intent
  setIntent(intent: Intent): void {
    this.intent = intent;
  }

  getIntent(): Intent | null {
    return this.intent;
  }

  // Lifecycle methods
  onCreate(savedInstanceState?: Bundle): void {
    this.setContentView('activity_text_clock');
    if (savedInstanceState) {
      this.restoreInstanceState(savedInstanceState);
    }
  }

  onResume(): void {
    if (this.textClockComponent) {
      this.textClockComponent.startTicking();
    }
  }

  onPause(): void {
    if (this.textClockComponent) {
      this.textClockComponent.stopTicking();
    }
  }

  onDestroy(): void {
    this.onPause();
    if (this.layout) {
      const layout = this.layout as ConstraintLayout;
      layout.removeView('text_clock');
      layout.removeView('location_text');
      layout.removeView('refresh_button');
    }
  }

  // Utility methods
  setLocationText(location: string): void {
    const locationView = this.findViewById('location_text');
    if (locationView) {
      locationView.setText(location);
    }
    this.bundle.putString('location', location);
  }

  getLocationText(): string {
    return this.bundle.getString('location', 'Default Location');
  }

  setRefreshButtonListener(listener: OnClickListener): void {
    const refreshButton = this.findViewById('refresh_button');
    if (refreshButton) {
      refreshButton.setOnClickListener(listener);
    }
  }

  handleRefreshClick(): void {
    // Update time manually
    if (this.textClockComponent) {
      this.textClockComponent.startTicking();
    }
  }
}

// Export all APIs for testing
export {
  LayoutInflater,
  VISIBLE,
  INVISIBLE,
  GONE,
  YEAR,
  MONTH,
  DAY_OF_MONTH,
  HOUR,
  HOUR_OF_DAY,
  MINUTE,
  SECOND,
  MILLISECOND,
  DAY_OF_WEEK,
};
