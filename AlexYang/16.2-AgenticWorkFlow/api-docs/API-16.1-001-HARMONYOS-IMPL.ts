/**
 * API #1 Implementation: HarmonyOS Page (AppCompatActivity Mapping)
 *
 * File: MainPage.harmony.ts
 * Module: MainPage
 * API ID: API-16.1-001
 * Status: Implementation Complete
 * Date: 2026-03-09
 *
 * Purpose:
 *   This is the HarmonyOS implementation of AppCompatActivity for TextClock.
 *   It maps the Android Activity pattern to HarmonyOS Page with @Entry and @Component
 *   decorators, demonstrating how to handle UI state, lifecycle, and user interactions.
 *
 * Key Responsibilities:
 *   1. Manage page lifecycle (onPageShow, onPageHide)
 *   2. Build and manage UI layout
 *   3. Handle state management with @State
 *   4. Initialize UI components
 *   5. Handle user interactions (button clicks)
 *   6. Manage time updates through Timer
 *
 * Architecture:
 *   @Entry         - Makes this page the entry point
 *   @Component     - Makes this a reusable component
 *   @State         - Manages reactive state variables
 *   build()        - Declares the UI structure
 *   onPageShow()   - Lifecycle hook when page appears
 *   onPageHide()   - Lifecycle hook when page disappears
 *
 * @author Claudian
 * @version 1.0
 * @since 2026-03-09
 */

import { router } from '@ohos.router';
import { hilog } from '@ohos.hilog';

/**
 * Main page for TextClock Application (HarmonyOS).
 *
 * This Page component demonstrates the basic structure for displaying a TextClock
 * equivalent in HarmonyOS using ArkUI framework. It shows how to:
 * - Manage reactive state with @State
 * - Handle lifecycle events
 * - Build declarative UI
 * - Respond to user interactions
 * - Update UI based on state changes
 *
 * State Variables:
 * - textClockValue: Current time as string
 * - locationText: Location information
 * - isRunning: Whether updates are active
 * - timerHandle: Handle to the timer for cleanup
 * - format12Hour: Time format pattern
 *
 * Features:
 * - Displays current time in 12-hour format
 * - Refresh button to manually update time
 * - Location display area
 * - Automatic time updates on page show
 * - Cleanup on page hide
 * - Proper lifecycle management
 *
 * Lifecycle Flow:
 * 1. Page created - Instance created
 * 2. onPageShow() - Page becomes visible, start updates
 * 3. Page visible - User can interact, updates running
 * 4. onPageHide() - Page becomes hidden, stop updates
 * 5. Page destroyed - Instance destroyed, cleanup
 */
@Entry
@Component
struct MainPage {

  // ============ Logging Constants ============
  /** Module name for logging */
  private static readonly TAG: string = 'MainPage';

  /** Domain for logging */
  private static readonly DOMAIN: number = 0x0001;

  // ============ State Variables ============
  /**
   * Current time displayed in TextClock format.
   * This is reactive - any change triggers UI re-render.
   *
   * @type {string}
   * @default "00:00:00 AM"
   */
  @State textClockValue: string = '00:00:00 AM';

  /**
   * Location information string.
   * Updates whenever the value changes.
   *
   * @type {string}
   * @default "Default Location"
   */
  @State locationText: string = 'Default Location';

  /**
   * Flag indicating if time updates are running.
   * Used to control the update loop.
   *
   * @type {boolean}
   * @default false
   */
  @State isRunning: boolean = false;

  /**
   * Timer handle for cleanup.
   * Used to cancel the timer when page hides.
   *
   * @type {number}
   * @default -1
   */
  @State timerHandle: number = -1;

  /**
   * Time format pattern for 12-hour display.
   * HH:mm:ss format with AM/PM indicator.
   *
   * @type {string}
   * @default "HH:mm:ss"
   */
  private format12Hour: string = 'HH:mm:ss';

  /**
   * Update interval in milliseconds.
   * Time between consecutive updates.
   *
   * @type {number}
   * @default 1000
   */
  private updateIntervalMs: number = 1000;

  // ============ UI Build Method ============

  /**
   * Build the UI structure declaratively.
   *
   * This method declares how the UI should look based on the current state.
   * Any changes to @State variables will trigger a re-render of the UI.
   *
   * UI Structure:
   * - Column: Vertical layout container
   *   - Text: Time display (textClockValue)
   *   - Button: Refresh button
   *   - Text: Location display (locationText)
   *
   * @returns {void}
   */
  build() {
    Column({ space: 20 }) {
      // ============ Time Display ============
      /**
       * TextClock equivalent: Display current time.
       *
       * In Android, this would be:
       *   <android.widget.TextClock ... />
       *
       * In HarmonyOS, we use Text with @State:
       *   - Displays the textClockValue state
       *   - Updates automatically when state changes
       *   - Font size set to 48sp equivalent
       */
      Text(this.textClockValue)
        .fontSize('48sp')
        .fontColor(Color.Black)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })
        .textAlign(TextAlign.Center)
        .accessibilityLabel('Time Display')
        .accessibilityHint('Shows current time in 12-hour format');

      // ============ Refresh Button ============
      /**
       * Button: Allow user to manually refresh time display.
       *
       * In Android, this would be:
       *   <android.widget.Button
       *     android:id="@+id/refresh_button"
       *     android:onClick="onRefreshButtonClicked" />
       *
       * In HarmonyOS, we use Button with onClick handler:
       *   - Calls onRefreshButtonClicked() when tapped
       *   - Styled with appropriate margins and sizing
       */
      Button('Refresh')
        .type(ButtonType.Capsule)
        .fontSize('18sp')
        .fontColor(Color.White)
        .backgroundColor(Color.Blue)
        .margin({ bottom: 20 })
        .width('80%')
        .height('50sp')
        .onClick(() => this.onRefreshButtonClicked())
        .accessibilityLabel('Refresh Button')
        .accessibilityHint('Tapping refreshes the time display');

      // ============ Location Display ============
      /**
       * TextView equivalent: Display location information.
       *
       * In Android, this would be:
       *   <android.widget.TextView
       *     android:id="@+id/location_text" />
       *
       * In HarmonyOS, we use Text with @State:
       *   - Displays the locationText state
       *   - Updates when state changes
       *   - Secondary text styling
       */
      Text(this.locationText)
        .fontSize('14sp')
        .fontColor(Color.Gray)
        .margin({ bottom: 20 })
        .textAlign(TextAlign.Center)
        .accessibilityLabel('Location Text')
        .accessibilityHint('Shows current location information');
    }
    .padding(20)
    .justifyContent(FlexAlign.Start)
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }

  // ============ Lifecycle Hooks ============

  /**
   * Called when page becomes visible.
   *
   * This maps to Android's onCreate() + onResume() lifecycle:
   * - Initialize data and UI
   * - Start background updates
   * - Register listeners
   *
   * Important: Must clean up in onPageHide() what was started here.
   *
   * @returns {void}
   */
  onPageShow(): void {
    hilog.info(DOMAIN, TAG, 'onPageShow: Page showing');

    // Initialize UI data
    this.initializeData();

    // Start time updates
    this.startTimeUpdates();
  }

  /**
   * Called when page is about to become hidden.
   *
   * This maps to Android's onPause() + onStop() lifecycle:
   * - Stop background updates
   * - Unregister listeners
   * - Save state if needed
   *
   * Important: Clean up everything that was started in onPageShow().
   *
   * @returns {void}
   */
  onPageHide(): void {
    hilog.info(DOMAIN, TAG, 'onPageHide: Page hiding');

    // Stop time updates
    this.stopTimeUpdates();

    // Save any state if needed
    this.saveState();
  }

  // ============ Initialization Methods ============

  /**
   * Initialize UI data with current values.
   *
   * This is called:
   * - From onPageShow() when page first appears
   * - From onRefreshButtonClicked() when user refreshes
   *
   * Performs initial data loading and UI setup.
   *
   * @returns {void}
   */
  private initializeData(): void {
    hilog.info(DOMAIN, TAG, 'initializeData: Initializing data');

    // Update time display
    this.updateTimeDisplay();

    // Update location display
    this.updateLocationDisplay();
  }

  // ============ Event Handler Methods ============

  /**
   * Handle refresh button click event.
   *
   * This is called when user taps the refresh button.
   * Updates the UI with current time and location.
   *
   * Maps to Android's onRefreshButtonClicked():
   *   - Get current time
   *   - Update UI elements
   *   - Optional: Show feedback
   *
   * @returns {void}
   */
  private onRefreshButtonClicked(): void {
    hilog.info(DOMAIN, TAG, 'onRefreshButtonClicked: Refresh clicked');

    // Update all UI data
    this.initializeData();

    // Optional: Show visual feedback (toast, animation, etc.)
    // showToast('Updated');
  }

  // ============ Time Update Methods ============

  /**
   * Start automatic time update loop.
   *
   * Sets up a timer that:
   * - Calls updateTimeDisplay() periodically
   * - Runs at updateIntervalMs interval
   * - Is stopped in stopTimeUpdates()
   *
   * Maps to Android's startTimeUpdates().
   *
   * @returns {void}
   */
  private startTimeUpdates(): void {
    if (!this.isRunning) {
      hilog.info(DOMAIN, TAG, 'startTimeUpdates: Starting updates');

      this.isRunning = true;

      // Set up timer for periodic updates
      this.timerHandle = setInterval(() => {
        this.updateTimeDisplay();
      }, this.updateIntervalMs);

      // Set a long-term handler if needed
      hilog.info(DOMAIN, TAG, `startTimeUpdates: Timer started with interval ${this.updateIntervalMs}ms`);
    }
  }

  /**
   * Stop automatic time update loop.
   *
   * Clears the timer started in startTimeUpdates().
   * Should be called from onPageHide() or when stopping updates.
   *
   * Maps to Android's stopTimeUpdates().
   *
   * @returns {void}
   */
  private stopTimeUpdates(): void {
    if (this.isRunning && this.timerHandle !== -1) {
      hilog.info(DOMAIN, TAG, 'stopTimeUpdates: Stopping updates');

      this.isRunning = false;

      // Clear the timer
      clearInterval(this.timerHandle);
      this.timerHandle = -1;

      hilog.info(DOMAIN, TAG, 'stopTimeUpdates: Timer cleared');
    }
  }

  // ============ UI Update Methods ============

  /**
   * Update time display with current time.
   *
   * Gets the current time and formats it as 12-hour time string,
   * then updates the textClockValue @State variable.
   *
   * Since textClockValue is @State, this automatically triggers
   * a UI re-render of the Text component displaying the time.
   *
   * @returns {void}
   */
  private updateTimeDisplay(): void {
    // Get current time
    const now = new Date();

    // Format as HH:mm:ss AM/PM
    const hours = String(now.getHours() % 12 || 12).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    const seconds = String(now.getSeconds()).padStart(2, '0');
    const ampm = now.getHours() >= 12 ? 'PM' : 'AM';

    // Update @State variable (triggers UI re-render)
    this.textClockValue = `${hours}:${minutes}:${seconds} ${ampm}`;

    hilog.debug(DOMAIN, TAG, `updateTimeDisplay: Updated to ${this.textClockValue}`);
  }

  /**
   * Update location display.
   *
   * Gets location information and updates the locationText @State variable.
   *
   * Maps to Android's updateLocationDisplay():
   *   - Fetch location data
   *   - Format for display
   *   - Update UI through @State
   *
   * @returns {void}
   */
  private updateLocationDisplay(): void {
    // In a real app, would fetch location from system
    // For now, use placeholder
    const location = 'Current Location';

    // Update @State variable (triggers UI re-render)
    this.locationText = location;

    hilog.debug(DOMAIN, TAG, `updateLocationDisplay: Updated to ${location}`);
  }

  // ============ State Management Methods ============

  /**
   * Save current page state.
   *
   * This is called from onPageHide() to save any state that
   * needs to persist across page hide/show cycles.
   *
   * Maps to Android's saveInstanceState().
   *
   * @returns {void}
   */
  private saveState(): void {
    hilog.info(DOMAIN, TAG, 'saveState: Saving page state');

    // In HarmonyOS, @State variables are automatically managed
    // but we can add custom save logic if needed

    // Example: Save to AppStorage if needed
    // AppStorage.SetOrCreate('locationKey', this.locationText);
  }

  // ============ Cleanup Methods ============

  /**
   * Clean up resources on page destruction.
   *
   * This is called when the page is about to be destroyed.
   * Makes sure all resources are properly released.
   *
   * Maps to Android's cleanup().
   *
   * @returns {void}
   */
  private cleanup(): void {
    hilog.info(DOMAIN, TAG, 'cleanup: Cleaning up resources');

    // Stop any running updates
    this.stopTimeUpdates();

    // Clear references
    this.timerHandle = -1;
  }

  // ============ Getter Methods ============

  /**
   * Get current time value.
   *
   * @returns {string} Current time string
   */
  public getTimeValue(): string {
    return this.textClockValue;
  }

  /**
   * Get current location value.
   *
   * @returns {string} Current location string
   */
  public getLocationValue(): string {
    return this.locationText;
  }

  /**
   * Check if time updates are running.
   *
   * @returns {boolean} true if updates active
   */
  public isUpdating(): boolean {
    return this.isRunning;
  }

  // ============ Setter Methods ============

  /**
   * Set location text.
   *
   * @param location {string} New location string
   * @returns {void}
   */
  public setLocation(location: string): void {
    this.locationText = location;
  }

  /**
   * Set update interval.
   *
   * @param intervalMs {number} Interval in milliseconds
   * @returns {void}
   */
  public setUpdateInterval(intervalMs: number): void {
    this.updateIntervalMs = intervalMs;

    // If running, restart with new interval
    if (this.isRunning) {
      this.stopTimeUpdates();
      this.startTimeUpdates();
    }
  }
}
