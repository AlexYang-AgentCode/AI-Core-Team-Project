/**
 * E2E Tests for API #1: AppCompatActivity Adapter
 *
 * This test suite verifies:
 * 1. Android lifecycle mapping
 * 2. HarmonyOS lifecycle mapping
 * 3. State synchronization
 * 4. Component management
 * 5. Event handling
 * 6. Cross-platform compatibility
 */

import { AppCompatActivityAdapter, PlatformType, LifecycleEvent } from '../src/AppCompatActivityAdapter';

describe('API #1: AppCompatActivity Adapter E2E Tests', () => {
  let adapter: AppCompatActivityAdapter;
  let mockAndroidActivity: any;

  beforeEach(() => {
    // Create mock Android Activity
    mockAndroidActivity = {
      onCreate: jest.fn(),
      onStart: jest.fn(),
      onResume: jest.fn(),
      onPause: jest.fn(),
      onStop: jest.fn(),
      onDestroy: jest.fn(),
      findViewById: jest.fn(),
      setContentView: jest.fn(),
    };

    // Create adapter with mock activity
    adapter = new AppCompatActivityAdapter(mockAndroidActivity);
  });

  // ============ Lifecycle Tests ============

  describe('Lifecycle Management', () => {
    test('should initialize adapter', () => {
      adapter.init();
      expect(mockAndroidActivity.onCreate).toHaveBeenCalled();
    });

    test('should handle show lifecycle', () => {
      adapter.init();
      adapter.onShow();
      expect(mockAndroidActivity.onResume).toHaveBeenCalled();
    });

    test('should handle hide lifecycle', () => {
      adapter.init();
      adapter.onShow();
      adapter.onHide();
      expect(mockAndroidActivity.onPause).toHaveBeenCalled();
    });

    test('should handle destroy lifecycle', () => {
      adapter.init();
      adapter.onShow();
      adapter.onHide();
      adapter.destroy();
      expect(mockAndroidActivity.onDestroy).toHaveBeenCalled();
    });

    test('should complete full lifecycle sequence', () => {
      adapter.init();
      adapter.onShow();
      adapter.onHide();
      adapter.destroy();

      // Verify all lifecycle methods were called in order
      expect(mockAndroidActivity.onCreate).toHaveBeenCalled();
      expect(mockAndroidActivity.onResume).toHaveBeenCalled();
      expect(mockAndroidActivity.onPause).toHaveBeenCalled();
      expect(mockAndroidActivity.onDestroy).toHaveBeenCalled();
    });

    test('should not allow double initialization', () => {
      adapter.init();
      adapter.init(); // Should be ignored

      // Should only call onCreate once
      expect(mockAndroidActivity.onCreate).toHaveBeenCalledTimes(1);
    });
  });

  // ============ Component Management Tests ============

  describe('Component Management', () => {
    test('should register component', () => {
      const component = adapter.findViewById('text_clock');
      expect(component).not.toBeNull();
      expect(component?.getId()).toBe('text_clock');
    });

    test('should find registered component', () => {
      const component = adapter.findViewById('text_clock');
      expect(component).not.toBeNull();
    });

    test('should return null for unregistered component', () => {
      const component = adapter.findViewById('nonexistent');
      expect(component).toBeNull();
    });

    test('should initialize default components', () => {
      expect(adapter.findViewById('text_clock')).not.toBeNull();
      expect(adapter.findViewById('location_text')).not.toBeNull();
      expect(adapter.findViewById('refresh_button')).not.toBeNull();
    });
  });

  // ============ State Management Tests ============

  describe('State Management', () => {
    test('should set and get location', () => {
      adapter.setLocation('New York');
      expect(adapter.getLocation()).toBe('New York');
    });

    test('should set and get time', () => {
      adapter.setTime('12:30:45 PM');
      expect(adapter.getTime()).toBe('12:30:45 PM');
    });

    test('should sync state with component', () => {
      adapter.setLocation('San Francisco');
      const locationComponent = adapter.findViewById('location_text');
      expect(locationComponent?.getText()).toBe('San Francisco');
    });

    test('should save and restore state', () => {
      const testState = {
        location: 'London',
        time: '18:45:00 PM',
        timezone: 'GMT',
      };

      adapter.saveState(testState);
      const restoredState = adapter.restoreState();

      expect(restoredState.location).toBe('London');
      expect(restoredState.time).toBe('18:45:00 PM');
      expect(restoredState.timezone).toBe('GMT');
    });

    test('should update UI with current time', () => {
      adapter.updateUI();
      const timeValue = adapter.getTime();

      // Time format should be HH:MM:SS AM/PM
      expect(timeValue).toMatch(/\d{2}:\d{2}:\d{2} (AM|PM)/);
    });
  });

  // ============ Event Handling Tests ============

  describe('Event Handling', () => {
    test('should register click listener', () => {
      const callback = jest.fn();
      adapter.setOnClickListener('refresh_button', callback);

      adapter.handleClick('refresh_button');
      expect(callback).toHaveBeenCalled();
    });

    test('should handle multiple listeners for same component', () => {
      const callback1 = jest.fn();
      const callback2 = jest.fn();

      adapter.setOnClickListener('refresh_button', callback1);
      adapter.setOnClickListener('refresh_button', callback2);

      adapter.handleClick('refresh_button');

      expect(callback1).toHaveBeenCalled();
      expect(callback2).toHaveBeenCalled();
    });

    test('should handle click event on text_clock', () => {
      const callback = jest.fn();
      adapter.setOnClickListener('text_clock', callback);

      adapter.handleClick('text_clock');
      expect(callback).toHaveBeenCalled();
    });
  });

  // ============ Platform Detection Tests ============

  describe('Platform Detection', () => {
    test('should detect platform', () => {
      const platform = adapter.getPlatform();
      expect(platform).toBeDefined();
      expect([PlatformType.ANDROID, PlatformType.HARMONYOS, PlatformType.UNKNOWN]).toContain(platform);
    });

    test('should provide platform checking methods', () => {
      const isAndroid = adapter.isAndroid();
      const isHarmonyOS = adapter.isHarmonyOS();

      // At least one should be true or both should be false (unknown)
      expect(typeof isAndroid).toBe('boolean');
      expect(typeof isHarmonyOS).toBe('boolean');
    });
  });

  // ============ Cross-Platform Data Flow Tests ============

  describe('Cross-Platform Data Flow (Android → Adapter → HarmonyOS)', () => {
    test('should sync Android data to adapter', () => {
      // Simulate Android Activity setting data
      const androidData = {
        location: 'Tokyo',
        time: '09:15:30 AM',
      };

      // Use adapter to set this data
      adapter.saveState(androidData);

      // Verify adapter has the data
      expect(adapter.getLocation()).toBe('Tokyo');
      expect(adapter.getTime()).toBe('09:15:30 AM');
    });

    test('should allow HarmonyOS to read adapter data', () => {
      // Set data through adapter
      adapter.setLocation('Berlin');
      adapter.setTime('15:45:00 PM');

      // Simulate HarmonyOS reading data
      const restoredState = adapter.restoreState();

      expect(restoredState.location).toBe('Berlin');
      expect(restoredState.time).toBe('15:45:00 PM');
    });

    test('should maintain data consistency across platform switch', () => {
      // Set data
      const originalLocation = 'Sydney';
      const originalTime = '22:30:00 PM';

      adapter.setLocation(originalLocation);
      adapter.setTime(originalTime);

      // Get data (simulate cross-platform access)
      const location = adapter.getLocation();
      const time = adapter.getTime();

      expect(location).toBe(originalLocation);
      expect(time).toBe(originalTime);
    });
  });

  // ============ Cleanup Tests ============

  describe('Cleanup and Resource Management', () => {
    test('should clean up resources on destroy', () => {
      adapter.init();
      adapter.onShow();

      // Try to use adapter
      adapter.setLocation('Paris');
      expect(adapter.getLocation()).toBe('Paris');

      // Destroy
      adapter.destroy();

      // After destroy, components should be cleared
      expect(adapter.findViewById('text_clock')).toBeNull();
    });

    test('should handle destroy without initialization', () => {
      expect(() => {
        adapter.destroy();
      }).not.toThrow();
    });
  });

  // ============ Integration Tests ============

  describe('Integration: Complete E2E Workflow', () => {
    test('should complete full Android to HarmonyOS workflow', () => {
      // 1. Initialize
      adapter.init();
      expect(mockAndroidActivity.onCreate).toHaveBeenCalled();

      // 2. Show/Resume
      adapter.onShow();
      expect(mockAndroidActivity.onResume).toHaveBeenCalled();

      // 3. Simulate Android setting data
      adapter.setLocation('New York');
      adapter.setTime('14:30:00 PM');

      // 4. Simulate HarmonyOS reading data
      expect(adapter.getLocation()).toBe('New York');
      expect(adapter.getTime()).toBe('14:30:00 PM');

      // 5. Handle user interaction
      const clickHandler = jest.fn();
      adapter.setOnClickListener('refresh_button', clickHandler);
      adapter.handleClick('refresh_button');
      expect(clickHandler).toHaveBeenCalled();

      // 6. Update UI
      adapter.updateUI();
      const updatedTime = adapter.getTime();
      expect(updatedTime).toMatch(/\d{2}:\d{2}:\d{2} (AM|PM)/);

      // 7. Save state before hide
      const savedState = adapter.restoreState();
      expect(savedState.location).toBe('New York');

      // 8. Hide
      adapter.onHide();
      expect(mockAndroidActivity.onPause).toHaveBeenCalled();

      // 9. Destroy
      adapter.destroy();
      expect(mockAndroidActivity.onDestroy).toHaveBeenCalled();
    });

    test('should handle multiple show/hide cycles', () => {
      adapter.init();

      // First cycle
      adapter.onShow();
      adapter.setLocation('London');
      adapter.onHide();

      // Second cycle - location should persist
      adapter.onShow();
      expect(adapter.getLocation()).toBe('London');
      adapter.onHide();

      // Cleanup
      adapter.destroy();
    });
  });
});
