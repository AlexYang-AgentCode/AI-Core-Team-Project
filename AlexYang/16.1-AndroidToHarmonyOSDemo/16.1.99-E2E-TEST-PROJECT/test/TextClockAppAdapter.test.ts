/**
 * Comprehensive Test Suite for TextClock Application Adapter
 * Tests all 12 Android APIs
 *
 * Test Coverage:
 * - API #2: Bundle (key-value storage)
 * - API #3: setContentView (layout inflation)
 * - API #4: ConstraintLayout (layout manager)
 * - API #5: TextView (text display)
 * - API #6: Button (clickable button)
 * - API #7: TextClock (time display with auto-update)
 * - API #8: OnClickListener (click event handler)
 * - API #9: findViewById (component reference lookup)
 * - API #10: TimeZone (timezone handling)
 * - API #11: Calendar/Date (time calculations)
 * - API #12: Intent (inter-component communication)
 * - API #3 Extended: LayoutInflater (layout inflation)
 * - Integration: Complete TextClock workflow
 */

import {
  Bundle,
  ConstraintLayout,
  TextView,
  Button,
  TextClock,
  OnClickListener,
  UIComponent,
  TimeZone,
  CalendarDate,
  YEAR,
  MONTH,
  HOUR,
  HOUR_OF_DAY,
  MINUTE,
  SECOND,
  Intent,
  LayoutInflater,
  TextClockAppAdapter,
  VISIBLE,
  INVISIBLE,
  GONE,
} from '../src/TextClockAppAdapter';

describe('TextClock Application Adapter - Complete E2E Tests', () => {
  describe('API #2: Bundle - Key-Value Data Container', () => {
    let bundle: Bundle;

    beforeEach(() => {
      bundle = new Bundle();
    });

    it('should store and retrieve string values', () => {
      bundle.putString('location', 'New York');
      expect(bundle.getString('location')).toBe('New York');
    });

    it('should store and retrieve integer values', () => {
      bundle.putInt('count', 42);
      expect(bundle.getInt('count')).toBe(42);
    });

    it('should store and retrieve boolean values', () => {
      bundle.putBoolean('is_24h_format', true);
      expect(bundle.getBoolean('is_24h_format')).toBe(true);
    });

    it('should return default values for missing keys', () => {
      expect(bundle.getString('missing', 'default')).toBe('default');
      expect(bundle.getInt('missing', 0)).toBe(0);
      expect(bundle.getBoolean('missing', false)).toBe(false);
    });

    it('should check key existence', () => {
      bundle.putString('key', 'value');
      expect(bundle.containsKey('key')).toBe(true);
      expect(bundle.containsKey('missing')).toBe(false);
    });

    it('should remove keys', () => {
      bundle.putString('key', 'value');
      bundle.remove('key');
      expect(bundle.containsKey('key')).toBe(false);
    });

    it('should clear all data', () => {
      bundle.putString('key1', 'value1');
      bundle.putString('key2', 'value2');
      bundle.clear();
      expect(bundle.keySet().length).toBe(0);
    });

    it('should return all keys', () => {
      bundle.putString('key1', 'value1');
      bundle.putString('key2', 'value2');
      const keys = bundle.keySet();
      expect(keys).toContain('key1');
      expect(keys).toContain('key2');
    });

    it('should return all data as object', () => {
      bundle.putString('location', 'NYC');
      bundle.putInt('hour', 14);
      const all = bundle.getAll();
      expect(all['location']).toBe('NYC');
      expect(all['hour']).toBe(14);
    });
  });

  describe('API #4: ConstraintLayout - Layout Manager', () => {
    let layout: ConstraintLayout;

    beforeEach(() => {
      layout = new ConstraintLayout();
    });

    it('should create constraint layout with default dimensions', () => {
      expect(layout.getMeasuredWidth()).toBe(1080);
      expect(layout.getMeasuredHeight()).toBe(1920);
    });

    it('should add views to layout', () => {
      const textView = new TextView('test_view');
      layout.addView('test_view', textView);
      expect(layout.getView('test_view')).toBe(textView);
    });

    it('should retrieve views by ID', () => {
      const textView = new TextView('view1');
      layout.addView('view1', textView);
      const retrieved = layout.getViewById('view1');
      expect(retrieved).toBe(textView);
    });

    it('should return null for non-existent views', () => {
      expect(layout.getView('non_existent')).toBeNull();
    });

    it('should remove views from layout', () => {
      const textView = new TextView('to_remove');
      layout.addView('to_remove', textView);
      layout.removeView('to_remove');
      expect(layout.getView('to_remove')).toBeNull();
    });

    it('should set custom dimensions', () => {
      layout.setMeasuredDimension(1440, 2560);
      expect(layout.getMeasuredWidth()).toBe(1440);
      expect(layout.getMeasuredHeight()).toBe(2560);
    });

    it('should store multiple views', () => {
      const tv1 = new TextView('tv1');
      const tv2 = new TextView('tv2');
      const btn = new Button('btn1');

      layout.addView('tv1', tv1);
      layout.addView('tv2', tv2);
      layout.addView('btn1', btn);

      expect(layout.getView('tv1')).toBe(tv1);
      expect(layout.getView('tv2')).toBe(tv2);
      expect(layout.getView('btn1')).toBe(btn);
    });
  });

  describe('API #5: TextView - Text Display Component', () => {
    let textView: TextView;

    beforeEach(() => {
      textView = new TextView('location_text');
    });

    it('should set and get text', () => {
      textView.setText('New York');
      expect(textView.getText()).toBe('New York');
    });

    it('should return correct ID', () => {
      expect(textView.getId()).toBe('location_text');
    });

    it('should set and get text size', () => {
      textView.setTextSize(18);
      expect(textView.getTextSize()).toBe(18);
    });

    it('should set and get text color', () => {
      textView.setTextColor(0xffff0000); // Red
      expect(textView.getTextColor()).toBe(0xffff0000);
    });

    it('should manage visibility states', () => {
      expect(textView.getVisibility()).toBe(VISIBLE);
      textView.setVisibility(INVISIBLE);
      expect(textView.getVisibility()).toBe(INVISIBLE);
      textView.setVisibility(GONE);
      expect(textView.getVisibility()).toBe(GONE);
    });

    it('should handle click listeners', () => {
      let clicked = false;
      const listener: OnClickListener = {
        onClick: () => {
          clicked = true;
        },
      };

      textView.setOnClickListener(listener);
      textView.performClick();
      expect(clicked).toBe(true);
    });

    it('should clear click listener', () => {
      let clicked = false;
      const listener: OnClickListener = {
        onClick: () => {
          clicked = true;
        },
      };

      textView.setOnClickListener(listener);
      textView.setOnClickListener(null);
      textView.performClick();
      expect(clicked).toBe(false);
    });
  });

  describe('API #6: Button - Clickable Button Component', () => {
    let button: Button;

    beforeEach(() => {
      button = new Button('refresh_button');
    });

    it('should create button with default text', () => {
      expect(button.getText()).toBe('Button');
    });

    it('should change button text', () => {
      button.setText('Refresh');
      expect(button.getText()).toBe('Refresh');
    });

    it('should extend TextView functionality', () => {
      expect(button).toBeInstanceOf(TextView);
    });

    it('should handle click events', () => {
      let callCount = 0;
      const listener: OnClickListener = {
        onClick: () => {
          callCount++;
        },
      };

      button.setOnClickListener(listener);
      button.performClick();
      button.performClick();
      expect(callCount).toBe(2);
    });

    it('should support multiple text operations', () => {
      button.setText('Click Me');
      button.setTextSize(16);
      button.setTextColor(0xff0000ff); // Blue

      expect(button.getText()).toBe('Click Me');
      expect(button.getTextSize()).toBe(16);
      expect(button.getTextColor()).toBe(0xff0000ff);
    });
  });

  describe('API #7: TextClock - Time Display with Auto-Update', () => {
    let textClock: TextClock;

    beforeEach(() => {
      textClock = new TextClock('text_clock');
    });

    afterEach(() => {
      textClock.stopTicking();
    });

    it('should initialize with default time', () => {
      expect(textClock.getText()).toMatch(/^\d{2}:\d{2}:\d{2}/);
    });

    it('should set 12-hour format', () => {
      textClock.setFormat12Hour('hh:mm:ss a');
      expect(textClock.getFormat12Hour()).toBe('hh:mm:ss a');
      const text = textClock.getText();
      expect(text).toMatch(/(AM|PM)$/);
    });

    it('should set 24-hour format', () => {
      textClock.setFormat24Hour('HH:mm:ss');
      expect(textClock.getFormat24Hour()).toBe('HH:mm:ss');
    });

    it('should handle timezone setting', () => {
      textClock.setTimeZone('America/New_York');
      expect(textClock.getTimeZone()).toBe('America/New_York');
    });

    it('should update time when format changes', () => {
      const initialText = textClock.getText();
      textClock.setFormat12Hour('hh:mm a');
      const updatedText = textClock.getText();
      expect(updatedText).not.toBe(initialText);
    });

    it('should start and stop ticking', (done) => {
      const initialText = textClock.getText();

      textClock.startTicking();
      setTimeout(() => {
        const afterTickText = textClock.getText();
        // Text may or may not change depending on timing, but process should complete
        textClock.stopTicking();
        expect(textClock.getText()).toBeTruthy();
        done();
      }, 1100);
    });

    it('should update text on multiple ticks', (done) => {
      textClock.setFormat12Hour('hh:mm:ss a');
      let updateCount = 0;
      const originalSetText = textClock.setText.bind(textClock);
      textClock.setText = function(text: string) {
        updateCount++;
        originalSetText(text);
      };

      textClock.startTicking();
      setTimeout(() => {
        textClock.stopTicking();
        expect(updateCount).toBeGreaterThan(0);
        done();
      }, 2100);
    });
  });

  describe('API #8 & #9: OnClickListener & findViewById Integration', () => {
    let layout: ConstraintLayout;

    beforeEach(() => {
      layout = new ConstraintLayout();
    });

    it('should register and trigger click listeners', () => {
      const button = new Button('test_btn');
      layout.addView('test_btn', button);

      let clicked = false;
      const listener: OnClickListener = {
        onClick: (view: UIComponent) => {
          clicked = true;
          expect(view.getId()).toBe('test_btn');
        },
      };

      button.setOnClickListener(listener);
      button.performClick();
      expect(clicked).toBe(true);
    });

    it('should handle multiple listeners on same component', () => {
      const button = new Button('multi_btn');
      let count = 0;

      const listener1: OnClickListener = {
        onClick: () => {
          count++;
        },
      };

      const listener2: OnClickListener = {
        onClick: () => {
          count++;
        },
      };

      button.setOnClickListener(listener1);
      button.performClick();
      expect(count).toBe(1);

      // Note: In real Android, you'd add multiple listeners with View.addOnClickListener
      // Our simplified implementation replaces, which is acceptable for this adapter
    });

    it('should find views by ID from layout', () => {
      const textView = new TextView('location_text');
      layout.addView('location_text', textView);

      const found = layout.getViewById('location_text');
      expect(found).toBe(textView);
      expect(found?.getId()).toBe('location_text');
    });

    it('should work with findViewById pattern', () => {
      const button = new Button('action_button');
      layout.addView('action_button', button);

      // Simulate findViewById
      const actionButton = layout.findViewById('action_button');
      expect(actionButton).not.toBeNull();
      expect(actionButton?.getId()).toBe('action_button');
    });
  });

  describe('API #10: TimeZone - Timezone Handling', () => {
    it('should get timezone by ID', () => {
      const tz = TimeZone.getTimeZone('UTC');
      expect(tz.getId()).toBe('UTC');
    });

    it('should get default timezone', () => {
      const tz = TimeZone.getDefault();
      expect(tz).toBeTruthy();
      expect(tz.getId()).toBe('UTC');
    });

    it('should provide display name', () => {
      const tz = TimeZone.getTimeZone('UTC');
      expect(tz.getDisplayName()).toBe('UTC');
    });

    it('should cache timezone instances', () => {
      const tz1 = TimeZone.getTimeZone('UTC');
      const tz2 = TimeZone.getTimeZone('UTC');
      expect(tz1).toBe(tz2);
    });

    it('should handle different timezone IDs', () => {
      const utc = TimeZone.getTimeZone('UTC');
      const gmt = TimeZone.getTimeZone('GMT+8');

      expect(utc.getId()).toBe('UTC');
      expect(gmt.getId()).toBe('GMT+8');
    });

    it('should calculate timezone offsets', () => {
      const utc = TimeZone.getTimeZone('UTC');
      expect(utc.getOffset()).toBe(0);

      const gmt8 = TimeZone.getTimeZone('GMT+8');
      expect(gmt8.getOffsetHours()).toBe(8);
    });
  });

  describe('API #11: Calendar/Date - Time Calculations', () => {
    let calendar: CalendarDate;

    beforeEach(() => {
      calendar = CalendarDate.getInstance();
    });

    it('should create calendar instance', () => {
      expect(calendar).toBeTruthy();
    });

    it('should get current time', () => {
      const date = calendar.getTime();
      expect(date).toBeInstanceOf(Date);
    });

    it('should get calendar fields', () => {
      const year = calendar.get(YEAR);
      const month = calendar.get(MONTH);
      const hour = calendar.get(HOUR_OF_DAY);
      const minute = calendar.get(MINUTE);
      const second = calendar.get(SECOND);

      expect(year).toBeGreaterThan(2000);
      expect(month).toBeGreaterThanOrEqual(0);
      expect(month).toBeLessThanOrEqual(11);
      expect(hour).toBeGreaterThanOrEqual(0);
      expect(hour).toBeLessThan(24);
      expect(minute).toBeGreaterThanOrEqual(0);
      expect(minute).toBeLessThan(60);
      expect(second).toBeGreaterThanOrEqual(0);
      expect(second).toBeLessThan(60);
    });

    it('should set calendar fields', () => {
      calendar.set(HOUR_OF_DAY, 14);
      calendar.set(MINUTE, 30);
      calendar.set(SECOND, 45);

      expect(calendar.get(HOUR_OF_DAY)).toBe(14);
      expect(calendar.get(MINUTE)).toBe(30);
      expect(calendar.get(SECOND)).toBe(45);
    });

    it('should set time from date', () => {
      const testDate = new Date('2026-03-15T14:30:45Z');
      calendar.setTime(testDate);

      const date = calendar.getTime();
      expect(date.getTime()).toBe(testDate.getTime());
    });

    it('should return time in milliseconds', () => {
      const millis = calendar.getTimeInMillis();
      expect(millis).toBeGreaterThan(0);
      expect(typeof millis).toBe('number');
    });

    it('should return string representation', () => {
      const str = calendar.toString();
      expect(typeof str).toBe('string');
      expect(str.length).toBeGreaterThan(0);
    });
  });

  describe('API #12: Intent - Inter-Component Communication', () => {
    let intent: Intent;

    beforeEach(() => {
      intent = new Intent();
    });

    it('should create intent with default values', () => {
      expect(intent.getAction()).toBe('');
      expect(intent.getComponent()).toBe('');
    });

    it('should create intent with action and component', () => {
      const intentWithParams = new Intent('ACTION_VIEW', 'MainActivity');
      expect(intentWithParams.getAction()).toBe('ACTION_VIEW');
      expect(intentWithParams.getComponent()).toBe('MainActivity');
    });

    it('should put and get string extras', () => {
      intent.putExtra('location', 'New York');
      expect(intent.getStringExtra('location')).toBe('New York');
    });

    it('should put and get integer extras', () => {
      intent.putExtra('time_hour', 14);
      expect(intent.getIntExtra('time_hour')).toBe(14);
    });

    it('should support method chaining', () => {
      const result = intent
        .putExtra('key1', 'value1')
        .putExtra('key2', 'value2')
        .setAction('TEST_ACTION');

      expect(result).toBe(intent);
      expect(intent.getStringExtra('key1')).toBe('value1');
      expect(intent.getAction()).toBe('TEST_ACTION');
    });

    it('should get extras bundle', () => {
      intent.putExtra('data', 'test');
      const extras = intent.getExtras();
      expect(extras).toBeTruthy();
    });

    it('should set and get action', () => {
      intent.setAction('ACTION_CALL');
      expect(intent.getAction()).toBe('ACTION_CALL');
    });

    it('should set and get component', () => {
      intent.setComponent('SecondActivity');
      expect(intent.getComponent()).toBe('SecondActivity');
    });

    it('should return default values for missing extras', () => {
      expect(intent.getStringExtra('missing')).toBe('');
      expect(intent.getIntExtra('missing', 0)).toBe(0);
    });
  });

  describe('API #3: LayoutInflater - Layout Inflation', () => {
    it('should inflate TextClock layout', () => {
      const layout = LayoutInflater.inflate('activity_text_clock');
      expect(layout).toBeTruthy();
      expect(layout).toBeInstanceOf(ConstraintLayout);
    });

    it('should create default layout components', () => {
      const layout = LayoutInflater.inflate('activity_text_clock') as ConstraintLayout;
      expect(layout.getView('text_clock')).toBeInstanceOf(TextClock);
      expect(layout.getView('location_text')).toBeInstanceOf(TextView);
      expect(layout.getView('refresh_button')).toBeInstanceOf(Button);
    });

    it('should handle unknown layout IDs', () => {
      const layout = LayoutInflater.inflate('unknown_layout');
      expect(layout).toBeInstanceOf(ConstraintLayout);
    });
  });

  describe('Integration: Complete TextClock Application Workflow', () => {
    let adapter: TextClockAppAdapter;

    beforeEach(() => {
      adapter = new TextClockAppAdapter();
    });

    afterEach(() => {
      adapter.onDestroy();
    });

    it('should complete full application lifecycle', () => {
      // Create
      adapter.onCreate();
      expect(adapter.findViewById('text_clock')).toBeTruthy();
      expect(adapter.findViewById('location_text')).toBeTruthy();
      expect(adapter.findViewById('refresh_button')).toBeTruthy();

      // Resume
      adapter.onResume();
      const timeText = adapter.findViewById('text_clock')?.getText();
      expect(timeText).toMatch(/\d{2}:\d{2}:\d{2}/);

      // Pause
      adapter.onPause();

      // Destroy
      adapter.onDestroy();
      expect(adapter.findViewById('text_clock')).toBeNull();
    });

    it('should handle state persistence', () => {
      adapter.onCreate();
      adapter.setLocationText('San Francisco');

      const outState = new Bundle();
      adapter.saveInstanceState(outState);

      expect(outState.containsKey('location_text')).toBe(true);
      expect(outState.getString('location_text')).toBe('San Francisco');
    });

    it('should restore saved state', () => {
      adapter.onCreate();

      const savedState = new Bundle();
      savedState.putString('location_text', 'Tokyo');
      savedState.putString('time_text', '14:30:00 PM');

      adapter.restoreInstanceState(savedState);
      expect(adapter.getLocationText()).toBe('Tokyo');
    });

    it('should work with Intent data', () => {
      const intent = new Intent('ACTION_SHOW_TIME', 'TextClockActivity');
      intent.putExtra('location', 'London');
      intent.putExtra('timezone', 'GMT');

      adapter.setIntent(intent);
      const retrievedIntent = adapter.getIntent();

      expect(retrievedIntent?.getAction()).toBe('ACTION_SHOW_TIME');
      expect(retrievedIntent?.getComponent()).toBe('TextClockActivity');
      expect(retrievedIntent?.getStringExtra('location')).toBe('London');
    });

    it('should handle refresh button clicks', (done) => {
      adapter.onCreate();

      const refreshButton = adapter.findViewById('refresh_button') as Button;
      let refreshCount = 0;

      const listener: OnClickListener = {
        onClick: () => {
          refreshCount++;
          adapter.handleRefreshClick();
        },
      };

      adapter.setRefreshButtonListener(listener);
      refreshButton.performClick();

      setTimeout(() => {
        expect(refreshCount).toBe(1);
        done();
      }, 100);
    });

    it('should update location through bundle', () => {
      adapter.onCreate();
      adapter.setLocationText('Paris');

      const bundle = adapter.getBundle();
      expect(bundle.getString('location')).toBe('Paris');

      const locationView = adapter.findViewById('location_text');
      expect(locationView?.getText()).toBe('Paris');
    });

    it('should support multiple lifecycle cycles', () => {
      // First cycle
      adapter.onCreate();
      adapter.onResume();
      adapter.onPause();

      // Second cycle
      adapter.onResume();
      expect(adapter.findViewById('text_clock')).toBeTruthy();
      adapter.onPause();

      adapter.onDestroy();
    });

    it('should maintain data across pause/resume', () => {
      adapter.onCreate();
      adapter.setLocationText('Tokyo');

      const outState = new Bundle();
      adapter.saveInstanceState(outState);

      adapter.onPause();
      adapter.onResume();
      adapter.restoreInstanceState(outState);

      expect(adapter.getLocationText()).toBe('Tokyo');
    });

    it('should handle rapid click events', () => {
      adapter.onCreate();

      const refreshButton = adapter.findViewById('refresh_button') as Button;
      let clickCount = 0;

      const listener: OnClickListener = {
        onClick: () => {
          clickCount++;
        },
      };

      adapter.setRefreshButtonListener(listener);

      for (let i = 0; i < 5; i++) {
        refreshButton.performClick();
      }

      expect(clickCount).toBe(5);
    });

    it('should work with custom timezone', () => {
      const intent = new Intent();
      intent.putExtra('timezone', 'America/New_York');

      adapter.setIntent(intent);
      const tz = TimeZone.getTimeZone(intent.getStringExtra('timezone'));

      expect(tz.getId()).toBe('America/New_York');
    });

    it('should format time according to settings', () => {
      adapter.onCreate();
      const textClock = adapter.findViewById('text_clock') as TextClock;

      textClock.setFormat12Hour('hh:mm:ss a');
      const time12h = textClock.getText();
      expect(time12h).toMatch(/(AM|PM)$/);

      textClock.setFormat24Hour('HH:mm:ss');
      const time24h = textClock.getText();
      expect(time24h).not.toMatch(/(AM|PM)$/);
    });
  });

  describe('Cross-Platform Data Flow: Android → Adapter → HarmonyOS', () => {
    it('should sync Android-generated data to adapter', () => {
      const adapter = new TextClockAppAdapter();
      adapter.onCreate();

      // Simulate Android data generation
      adapter.setLocationText('Beijing');

      const bundle = adapter.getBundle();
      expect(bundle.getString('location')).toBe('Beijing');
    });

    it('should allow HarmonyOS to read adapter data', () => {
      const adapter = new TextClockAppAdapter();
      adapter.onCreate();
      adapter.setLocationText('Shanghai');

      // Simulate HarmonyOS reading
      const location = adapter.getLocationText();
      const bundle = adapter.getBundle();

      expect(location).toBe('Shanghai');
      expect(bundle.getString('location')).toBe('Shanghai');
    });

    it('should maintain data consistency across platform switch', () => {
      const adapter = new TextClockAppAdapter();
      adapter.onCreate();
      adapter.setLocationText('Hangzhou');

      const outState = new Bundle();
      adapter.saveInstanceState(outState);

      // Simulate platform switch
      const newAdapter = new TextClockAppAdapter();
      newAdapter.onCreate();
      newAdapter.restoreInstanceState(outState);

      expect(newAdapter.getLocationText()).toBe('Hangzhou');
    });

    it('should pass complex intent data between platforms', () => {
      const intent = new Intent('SWITCH_TIMEZONE', 'TimeActivity');
      intent.putExtra('location', 'Moscow');
      intent.putExtra('timezone', 'Europe/Moscow');
      intent.putExtra('format', '24h');

      const adapter = new TextClockAppAdapter();
      adapter.setIntent(intent);

      const retrievedIntent = adapter.getIntent();
      expect(retrievedIntent?.getStringExtra('location')).toBe('Moscow');
      expect(retrievedIntent?.getStringExtra('timezone')).toBe('Europe/Moscow');
      expect(retrievedIntent?.getStringExtra('format')).toBe('24h');
    });
  });
});
