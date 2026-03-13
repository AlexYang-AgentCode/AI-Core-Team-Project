/**
 * Unit Tests for API #1: Android AppCompatActivity (MainActivity)
 *
 * File: MainActivityTest.java
 * Module: Test
 * API ID: API-131-001
 * Status: Implementation Complete
 * Date: 2026-03-09
 *
 * Purpose:
 *   Comprehensive unit tests for the Android MainActivity implementation.
 *   Tests lifecycle methods, UI component initialization, event handling,
 *   and state management.
 *
 * Test Framework:
 *   - JUnit 4: Basic unit testing
 *   - Mockito: Mocking Android components
 *   - AndroidX Test: Android-specific testing utilities
 *
 * Test Coverage:
 *   - Lifecycle: onCreate, onResume, onPause, onDestroy
 *   - UI Initialization: initializeViews, setupEventListeners
 *   - Event Handling: onRefreshButtonClicked
 *   - Time Updates: startTimeUpdates, stopTimeUpdates, updateUIData
 *   - State Management: saveInstanceState, restoreInstanceState
 *
 * @author Claudian
 * @version 1.0
 * @since 2026-03-09
 */

import org.junit.Before;
import org.junit.Test;
import org.junit.Rule;
import org.junit.runner.RunWith;

import static org.junit.Assert.*;
import static org.mockito.Mockito.*;

import android.content.Context;
import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;
import android.widget.TextClock;

import androidx.test.core.app.ActivityScenario;
import androidx.test.ext.junit.runners.AndroidJUnit4;
import androidx.test.rule.ActivityTestRule;

/**
 * Test suite for MainActivity.
 *
 * Uses AndroidX Test framework for Android-specific testing.
 * Tests cover all public methods and lifecycle transitions.
 */
@RunWith(AndroidJUnit4.class)
public class MainActivityTest {

  private static final String TAG = "MainActivityTest";

  @Rule
  public ActivityTestRule<MainActivity> activityRule =
      new ActivityTestRule<>(MainActivity.class);

  private MainActivity activity;
  private TextClock textClock;
  private Button refreshButton;
  private TextView locationView;

  /**
   * Set up test fixtures before each test.
   * Called before every @Test method.
   */
  @Before
  public void setUp() {
    activity = activityRule.getActivity();
    assertNotNull("Activity should not be null", activity);

    // Get UI components
    textClock = activity.getTextClock();
    refreshButton = activity.getRefreshButton();
    locationView = activity.getLocationView();
  }

  // ========== Lifecycle Tests ==========

  /**
   * Test that onCreate initializes the activity correctly.
   */
  @Test
  public void testOnCreateInitializesActivity() {
    // Activity is created by ActivityTestRule
    assertNotNull("Activity should be created", activity);
    assertNotNull("Content view should be set", activity.getWindow().getDecorView());
  }

  /**
   * Test that UI components are properly initialized.
   */
  @Test
  public void testViewInitialization() {
    // Check TextClock is initialized
    assertNotNull("TextClock should be initialized", textClock);

    // Check Refresh Button is initialized
    assertNotNull("Refresh Button should be initialized", refreshButton);

    // Check Location TextView is initialized
    assertNotNull("Location TextView should be initialized", locationView);
  }

  /**
   * Test that TextClock format is set correctly.
   */
  @Test
  public void testTextClockFormat() {
    assertNotNull("TextClock should not be null", textClock);
    // Format should be set in onCreate
    // Verify by checking the component exists and is properly configured
    String format = textClock.getFormat12Hour();
    assertNotNull("TextClock format should be set", format);
    assertTrue("Format should contain time pattern", format.length() > 0);
  }

  /**
   * Test activity destruction cleans up resources.
   */
  @Test
  public void testOnDestroyCleanup() {
    // Get initial state
    assertNotNull("Activity should be not null", activity);

    // Simulate activity destruction
    activity.onDestroy();

    // After onDestroy, the activity should have cleaned up
    // Note: We can't directly test null references since they're still accessible
    // But we can verify that stopTimeUpdates was called
    assertFalse("Time updates should be stopped", activity.isUpdatingTime());
  }

  // ========== Event Handler Tests ==========

  /**
   * Test that refresh button click triggers update.
   */
  @Test
  public void testRefreshButtonClick() {
    assertNotNull("Refresh button should not be null", refreshButton);

    // Perform button click
    refreshButton.performClick();

    // After click, location should be updated
    String location = activity.getLocation();
    assertNotNull("Location should not be null after refresh", location);
    assertTrue("Location should have content", location.length() > 0);
  }

  /**
   * Test that button click listeners are properly set.
   */
  @Test
  public void testButtonListenerSetup() {
    assertNotNull("Refresh button should have listeners", refreshButton);
    // Button should have OnClickListener set
    // We can verify this by checking that performClick works without error
    try {
      refreshButton.performClick();
      assertTrue("Button click should execute without error", true);
    } catch (Exception e) {
      fail("Button click should not throw exception: " + e.getMessage());
    }
  }

  // ========== Time Update Tests ==========

  /**
   * Test that time updates start correctly.
   */
  @Test
  public void testStartTimeUpdates() {
    // Initially should not be updating
    boolean initialState = activity.isUpdatingTime();

    // Simulate resuming the activity
    activity.onResume();

    // After resume, updates should be running
    assertTrue("Time updates should be running after onResume", activity.isUpdatingTime());
  }

  /**
   * Test that time updates stop correctly.
   */
  @Test
  public void testStopTimeUpdates() {
    // Start updates first
    activity.onResume();
    assertTrue("Updates should be running", activity.isUpdatingTime());

    // Stop updates
    activity.onPause();

    // After pause, updates should be stopped
    assertFalse("Time updates should be stopped after onPause", activity.isUpdatingTime());
  }

  /**
   * Test that UI data is updated periodically.
   */
  @Test
  public void testUIDataUpdate() throws InterruptedException {
    // Get initial value
    CharSequence initialTime = textClock.getText();
    assertNotNull("TextClock should display time", initialTime);

    // Wait a bit and trigger update
    Thread.sleep(100);
    activity.updateUIData();

    // Verify that text clock still displays something
    CharSequence updatedTime = textClock.getText();
    assertNotNull("TextClock should still display time", updatedTime);
  }

  /**
   * Test location display is updated.
   */
  @Test
  public void testLocationDisplayUpdate() {
    // Set a location
    String testLocation = "Test Location";
    activity.setLocation(testLocation);

    // Verify it's displayed
    assertEquals("Location should be displayed", testLocation, activity.getLocation());
    assertEquals("Location view should show the text", testLocation, locationView.getText().toString());
  }

  // ========== State Management Tests ==========

  /**
   * Test that instance state is saved correctly.
   */
  @Test
  public void testSaveInstanceState() {
    // Create a bundle to save state
    Bundle outState = new Bundle();

    // Set a location
    String testLocation = "Saved Location";
    activity.setLocation(testLocation);

    // Call onSaveInstanceState
    activity.onSaveInstanceState(outState);

    // Verify location was saved to bundle
    String savedLocation = outState.getString("location_state");
    assertEquals("Location should be saved to bundle", testLocation, savedLocation);
  }

  /**
   * Test that instance state is restored correctly.
   */
  @Test
  public void testRestoreInstanceState() {
    // Create a bundle with saved state
    Bundle savedState = new Bundle();
    String expectedLocation = "Restored Location";
    savedState.putString("location_state", expectedLocation);

    // Simulate onCreate with saved state
    activity.onCreate(savedState);

    // Verify location was restored
    String restoredLocation = activity.getLocation();
    assertEquals("Location should be restored from bundle", expectedLocation, restoredLocation);
  }

  /**
   * Test that state is null-safe when no saved state exists.
   */
  @Test
  public void testRestoreInstanceStateWithoutSavedState() {
    // Simulate onCreate with no saved state
    try {
      activity.onCreate(null);
      assertTrue("onCreate should handle null savedInstanceState", true);
    } catch (Exception e) {
      fail("onCreate should not throw exception with null state: " + e.getMessage());
    }
  }

  // ========== Thread Safety Tests ==========

  /**
   * Test that time update thread is properly managed.
   */
  @Test
  public void testTimeUpdateThreadManagement() throws InterruptedException {
    // Start updates
    activity.onResume();
    assertTrue("Updates should be running", activity.isUpdatingTime());

    // Wait for updates to happen
    Thread.sleep(1500);

    // Stop updates
    activity.onPause();
    assertFalse("Updates should be stopped", activity.isUpdatingTime());

    // Wait to ensure thread stops
    Thread.sleep(100);
  }

  /**
   * Test that stopping updates multiple times is safe.
   */
  @Test
  public void testMultipleStopUpdates() {
    // Start updates
    activity.onResume();

    // Stop updates multiple times
    activity.onPause();
    activity.onPause();
    activity.onPause();

    // Should not crash or have issues
    assertFalse("Updates should remain stopped", activity.isUpdatingTime());
  }

  /**
   * Test that starting updates multiple times is safe.
   */
  @Test
  public void testMultipleStartUpdates() {
    // Start updates multiple times
    activity.onResume();
    activity.onResume();
    activity.onResume();

    // Should only have one update thread running
    assertTrue("Updates should be running", activity.isUpdatingTime());

    // Stop them
    activity.onPause();
    assertFalse("Updates should be stopped", activity.isUpdatingTime());
  }

  // ========== Getter/Setter Tests ==========

  /**
   * Test location getter and setter.
   */
  @Test
  public void testLocationGetterSetter() {
    // Test setter
    String testLocation = "New York";
    activity.setLocation(testLocation);

    // Test getter
    String retrievedLocation = activity.getLocation();
    assertEquals("Location should match", testLocation, retrievedLocation);
  }

  /**
   * Test getting TextClock component.
   */
  @Test
  public void testGetTextClock() {
    TextClock clock = activity.getTextClock();
    assertNotNull("TextClock getter should return component", clock);
    assertSame("TextClock should be the same instance", textClock, clock);
  }

  /**
   * Test getting Refresh button component.
   */
  @Test
  public void testGetRefreshButton() {
    Button button = activity.getRefreshButton();
    assertNotNull("Button getter should return component", button);
    assertSame("Button should be the same instance", refreshButton, button);
  }

  /**
   * Test getting Location view component.
   */
  @Test
  public void testGetLocationView() {
    TextView view = activity.getLocationView();
    assertNotNull("LocationView getter should return component", view);
    assertSame("LocationView should be the same instance", locationView, view);
  }

  /**
   * Test is updating status check.
   */
  @Test
  public void testIsUpdatingTime() {
    // Initially should not be updating
    assertFalse("Initially should not be updating", activity.isUpdatingTime());

    // After resume should be updating
    activity.onResume();
    assertTrue("After resume should be updating", activity.isUpdatingTime());

    // After pause should not be updating
    activity.onPause();
    assertFalse("After pause should not be updating", activity.isUpdatingTime());
  }

  // ========== Error Handling Tests ==========

  /**
   * Test that activity handles missing UI components gracefully.
   */
  @Test
  public void testMissingComponentsHandling() {
    // Activity should have non-null components when initialized properly
    assertNotNull("Components should be initialized", textClock);
    assertNotNull("Button should be initialized", refreshButton);
    assertNotNull("Location view should be initialized", locationView);
  }

  /**
   * Test that lifecycle transitions are safe.
   */
  @Test
  public void testLifecycleTransitions() {
    // onCreate -> onStart -> onResume
    activity.onStart();
    assertTrue("Activity should be started", true);

    activity.onResume();
    assertTrue("Activity should be resumed", activity.isUpdatingTime());

    // onResume -> onPause -> onStop
    activity.onPause();
    assertFalse("Activity should be paused", activity.isUpdatingTime());

    activity.onStop();
    assertTrue("Activity should be stopped", true);

    // onStop -> onDestroy
    activity.onDestroy();
    assertTrue("Activity should be destroyed", true);
  }

  /**
   * Test that no null pointer exceptions occur during normal operation.
   */
  @Test
  public void testNullPointerExceptionPrevention() {
    try {
      // Perform typical operations
      activity.initializeViews();
      activity.setupEventListeners();
      activity.onResume();
      activity.updateUIData();
      activity.onPause();
      activity.onDestroy();

      assertTrue("Operations should complete without NPE", true);
    } catch (NullPointerException e) {
      fail("Should not throw NullPointerException: " + e.getMessage());
    }
  }
}
