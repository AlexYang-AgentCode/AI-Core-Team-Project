"use strict";
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
Object.defineProperty(exports, "__esModule", { value: true });
exports.TextClockAppAdapter = exports.LayoutInflater = exports.Intent = exports.DAY_OF_WEEK = exports.MILLISECOND = exports.SECOND = exports.MINUTE = exports.HOUR_OF_DAY = exports.HOUR = exports.DAY_OF_MONTH = exports.MONTH = exports.YEAR = exports.CalendarDate = exports.TimeZone = exports.TextClock = exports.Button = exports.TextView = exports.GONE = exports.INVISIBLE = exports.VISIBLE = exports.ConstraintLayout = exports.Bundle = void 0;
/**
 * API #2: Bundle - Key-value data container
 * Purpose: Store and retrieve application state data
 */
class Bundle {
    constructor() {
        this.data = new Map();
    }
    putString(key, value) {
        this.data.set(key, value);
    }
    getString(key, defaultValue) {
        return this.data.get(key) || defaultValue || '';
    }
    putInt(key, value) {
        this.data.set(key, Math.floor(value));
    }
    getInt(key, defaultValue) {
        return this.data.get(key) || defaultValue || 0;
    }
    putBoolean(key, value) {
        this.data.set(key, value);
    }
    getBoolean(key, defaultValue) {
        return this.data.get(key) ?? (defaultValue || false);
    }
    containsKey(key) {
        return this.data.has(key);
    }
    remove(key) {
        this.data.delete(key);
    }
    clear() {
        this.data.clear();
    }
    keySet() {
        return Array.from(this.data.keys());
    }
    getAll() {
        const result = {};
        this.data.forEach((value, key) => {
            result[key] = value;
        });
        return result;
    }
}
exports.Bundle = Bundle;
/**
 * API #4: ConstraintLayout - Layout manager
 * Purpose: Position views with constraints (simplified for TypeScript)
 */
class ConstraintLayout {
    constructor() {
        this.id = 'constraint_layout_0';
        this.components = new Map();
        this.width = 1080; // Default Android screen width
        this.height = 1920; // Default Android screen height
    }
    addView(id, component) {
        this.components.set(id, component);
    }
    getView(id) {
        return this.components.get(id) || null;
    }
    getViewById(id) {
        return this.components.get(id) || null;
    }
    removeView(id) {
        this.components.delete(id);
    }
    getMeasuredWidth() {
        return this.width;
    }
    getMeasuredHeight() {
        return this.height;
    }
    setMeasuredDimension(width, height) {
        this.width = width;
        this.height = height;
    }
}
exports.ConstraintLayout = ConstraintLayout;
exports.VISIBLE = 0;
exports.INVISIBLE = 4;
exports.GONE = 8;
/**
 * API #5: TextView - Text display component
 */
class TextView {
    constructor(id) {
        this.text = '';
        this.textSize = 14;
        this.textColor = 0xff000000; // Black
        this.visibility = exports.VISIBLE;
        this.clickListener = null;
        this.id = id;
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
    setTextSize(size) {
        this.textSize = size;
    }
    getTextSize() {
        return this.textSize;
    }
    setTextColor(color) {
        this.textColor = color;
    }
    getTextColor() {
        return this.textColor;
    }
    setVisibility(visibility) {
        this.visibility = visibility;
    }
    getVisibility() {
        return this.visibility;
    }
    setOnClickListener(listener) {
        this.clickListener = listener;
    }
    performClick() {
        if (this.clickListener) {
            this.clickListener.onClick(this);
        }
    }
}
exports.TextView = TextView;
/**
 * API #6: Button - Clickable button component
 */
class Button extends TextView {
    constructor(id) {
        super(id);
        this.setText('Button');
    }
}
exports.Button = Button;
/**
 * API #7: TextClock - Time display with automatic updates
 */
class TextClock extends TextView {
    constructor(id) {
        super(id);
        this.format12Hour = 'hh:mm:ss a';
        this.format24Hour = 'HH:mm:ss';
        this.timeZone = 'UTC';
        this.is24HourFormat = false;
        this.updateInterval = null;
        this.setText('00:00:00 AM');
    }
    setFormat12Hour(format) {
        this.format12Hour = format;
        this.is24HourFormat = false;
        this.updateTime();
    }
    getFormat12Hour() {
        return this.format12Hour;
    }
    setFormat24Hour(format) {
        this.format24Hour = format;
        this.is24HourFormat = true;
        this.updateTime();
    }
    getFormat24Hour() {
        return this.format24Hour;
    }
    setTimeZone(timeZone) {
        this.timeZone = timeZone;
        this.updateTime();
    }
    getTimeZone() {
        return this.timeZone;
    }
    updateTime() {
        const now = new Date();
        const hours = String(now.getHours() % 12 || 12).padStart(2, '0');
        const minutes = String(now.getMinutes()).padStart(2, '0');
        const seconds = String(now.getSeconds()).padStart(2, '0');
        const ampm = now.getHours() >= 12 ? 'PM' : 'AM';
        if (this.is24HourFormat) {
            const hours24 = String(now.getHours()).padStart(2, '0');
            this.setText(`${hours24}:${minutes}:${seconds}`);
        }
        else {
            this.setText(`${hours}:${minutes}:${seconds} ${ampm}`);
        }
    }
    startTicking() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
        }
        this.updateTime();
        this.updateInterval = setInterval(() => {
            this.updateTime();
        }, 1000);
    }
    stopTicking() {
        if (this.updateInterval) {
            clearInterval(this.updateInterval);
            this.updateInterval = null;
        }
    }
}
exports.TextClock = TextClock;
/**
 * API #10: TimeZone - Timezone handling
 */
class TimeZone {
    constructor(id, displayName, offset) {
        this.id = id;
        this.displayName = displayName;
        this.offset = offset;
    }
    static getTimeZone(id) {
        if (!TimeZone.timeZones.has(id)) {
            // Default timezone with UTC offset
            const offsetHours = parseInt(id.split('GMT')[1] || '0', 10);
            const offset = offsetHours * 60;
            const tz = new TimeZone(id, id, offset);
            TimeZone.timeZones.set(id, tz);
        }
        return TimeZone.timeZones.get(id);
    }
    static getDefault() {
        // Return UTC as default in testing environment
        return TimeZone.getTimeZone('UTC');
    }
    getId() {
        return this.id;
    }
    getDisplayName() {
        return this.displayName;
    }
    getOffset() {
        return this.offset;
    }
    getOffsetHours() {
        return this.offset / 60;
    }
}
exports.TimeZone = TimeZone;
TimeZone.timeZones = new Map();
/**
 * API #11: Calendar/Date - Time calculations
 * Simplified Date API for JavaScript compatibility
 */
class CalendarDate {
    constructor() {
        this.date = new Date();
    }
    static getInstance() {
        return new CalendarDate();
    }
    getTime() {
        return new Date(this.date.getTime());
    }
    setTime(date) {
        this.date = new Date(date.getTime());
    }
    get(field) {
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
    set(field, value) {
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
    toString() {
        return this.date.toString();
    }
    getTimeInMillis() {
        return this.date.getTime();
    }
}
exports.CalendarDate = CalendarDate;
// Calendar field constants
exports.YEAR = 1;
exports.MONTH = 2;
exports.DAY_OF_MONTH = 5;
exports.HOUR = 10;
exports.HOUR_OF_DAY = 11;
exports.MINUTE = 12;
exports.SECOND = 13;
exports.MILLISECOND = 14;
exports.DAY_OF_WEEK = 7;
/**
 * API #12: Intent - Inter-component communication
 */
class Intent {
    constructor(action, component) {
        this.action = '';
        this.component = '';
        this.extras = new Bundle();
        if (action)
            this.action = action;
        if (component)
            this.component = component;
    }
    putExtra(name, value) {
        this.extras.putString(name, String(value));
        return this;
    }
    getStringExtra(name) {
        return this.extras.getString(name, '');
    }
    getIntExtra(name, defaultValue) {
        return this.extras.getInt(name, defaultValue || 0);
    }
    getExtras() {
        return this.extras;
    }
    setAction(action) {
        this.action = action;
        return this;
    }
    getAction() {
        return this.action;
    }
    setComponent(component) {
        this.component = component;
        return this;
    }
    getComponent() {
        return this.component;
    }
}
exports.Intent = Intent;
/**
 * API #3 Extended: setContentView - Layout inflation handler
 */
class LayoutInflater {
    static inflate(layoutId) {
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
exports.LayoutInflater = LayoutInflater;
/**
 * Complete TextClock Application Adapter
 * Combines all 12 APIs into a unified interface
 */
class TextClockAppAdapter {
    constructor(activity) {
        this.layout = null;
        this.bundle = new Bundle();
        this.intent = null;
        this.textClockComponent = null;
        this.activity = activity;
    }
    // API #3: Load layout (setContentView)
    setContentView(layoutId) {
        this.layout = LayoutInflater.inflate(layoutId);
        // Initialize TextClock for auto-ticking
        if (layoutId === 'activity_text_clock') {
            const layout = this.layout;
            this.textClockComponent = layout.getView('text_clock');
            if (this.textClockComponent) {
                this.textClockComponent.setFormat12Hour('hh:mm:ss a');
                this.textClockComponent.setTimeZone('UTC');
                this.textClockComponent.startTicking();
            }
        }
    }
    // API #9: Find view by ID
    findViewById(id) {
        if (!this.layout)
            return null;
        const layout = this.layout;
        return layout.getView(id) || null;
    }
    // API #2: Work with Bundle
    getBundle() {
        return this.bundle;
    }
    saveInstanceState(outState) {
        const textClock = this.findViewById('text_clock');
        if (textClock) {
            outState.putString('time_text', textClock.getText());
        }
        const location = this.findViewById('location_text');
        if (location) {
            outState.putString('location_text', location.getText());
        }
    }
    restoreInstanceState(savedInstanceState) {
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
    setIntent(intent) {
        this.intent = intent;
    }
    getIntent() {
        return this.intent;
    }
    // Lifecycle methods
    onCreate(savedInstanceState) {
        this.setContentView('activity_text_clock');
        if (savedInstanceState) {
            this.restoreInstanceState(savedInstanceState);
        }
    }
    onResume() {
        if (this.textClockComponent) {
            this.textClockComponent.startTicking();
        }
    }
    onPause() {
        if (this.textClockComponent) {
            this.textClockComponent.stopTicking();
        }
    }
    onDestroy() {
        this.onPause();
        if (this.layout) {
            const layout = this.layout;
            layout.removeView('text_clock');
            layout.removeView('location_text');
            layout.removeView('refresh_button');
        }
    }
    // Utility methods
    setLocationText(location) {
        const locationView = this.findViewById('location_text');
        if (locationView) {
            locationView.setText(location);
        }
        this.bundle.putString('location', location);
    }
    getLocationText() {
        return this.bundle.getString('location', 'Default Location');
    }
    setRefreshButtonListener(listener) {
        const refreshButton = this.findViewById('refresh_button');
        if (refreshButton) {
            refreshButton.setOnClickListener(listener);
        }
    }
    handleRefreshClick() {
        // Update time manually
        if (this.textClockComponent) {
            this.textClockComponent.startTicking();
        }
    }
}
exports.TextClockAppAdapter = TextClockAppAdapter;
//# sourceMappingURL=TextClockAppAdapter.js.map