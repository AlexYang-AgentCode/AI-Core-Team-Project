/**
 * API #1 Implementation: Android AppCompatActivity
 *
 * File: MainActivity.harmony.java
 * Package: com.w.homework2.adapter
 * API ID: API-131-001
 * Status: Implementation Complete
 * Date: 2026-03-09
 *
 * Purpose:
 *   This is the Android implementation of AppCompatActivity for TextClock.
 *   It serves as the base Activity for the TextClock application and handles
 *   the lifecycle management, UI initialization, and event handling.
 *
 * Key Responsibilities:
 *   1. Manage Activity lifecycle (onCreate, onResume, onPause, onDestroy)
 *   2. Load and manage UI layout
 *   3. Initialize UI components (TextClock, Button, TextView)
 *   4. Handle user interactions (button clicks)
 *   5. Manage time updates through TextClock
 *
 * @author Claudian
 * @version 1.0
 * @since 2026-03-09
 */

package com.w.homework2.adapter;

import androidx.appcompat.app.AppCompatActivity;
import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;
import android.widget.TextClock;
import android.util.Log;
import java.util.TimeZone;

/**
 * Main Activity for TextClock Application.
 *
 * This Activity implements the basic structure for displaying a TextClock
 * with additional UI elements and functionality. It demonstrates the core
 * AppCompatActivity lifecycle and UI management patterns.
 *
 * Layout: activity_main.xml
 *
 * Features:
 * - TextClock display with 12-hour format
 * - Refresh button to manually update time
 * - Location display TextView
 * - Automatic time updates on resume/pause
 * - State preservation on configuration changes
 *
 * Lifecycle Flow:
 * 1. onCreate() - Initialize UI and data
 * 2. onStart() - Register listeners
 * 3. onResume() - Start time updates
 * 4. onPause() - Stop time updates
 * 5. onStop() - Unregister listeners
 * 6. onDestroy() - Clean up resources
 */
public class MainActivity extends AppCompatActivity {

    // ============ Class Constants ============
    private static final String TAG = "MainActivity";
    private static final String KEY_LOCATION = "location_state";
    private static final long UPDATE_INTERVAL_MS = 1000; // 1 second

    // ============ UI Component References ============
    /** TextClock: Displays current time in 12-hour format */
    private TextClock textClock;

    /** Button: Allows user to manually refresh time display */
    private Button refreshButton;

    /** TextView: Displays location information */
    private TextView locationView;

    // ============ State Variables ============
    /** Flag to track if time updates are running */
    private boolean isUpdatingTime = false;

    /** Thread handle for time updates (if using Thread instead of Timer) */
    private Thread updateThread;

    /** Current location string */
    private String currentLocation = "Default Location";

    // ============ Lifecycle Methods ============

    /**
     * Called when the Activity is first created.
     *
     * This is the entry point for the Activity. During this call:
     * - The Activity is created and initialized
     * - The UI layout is loaded from XML
     * - UI components are referenced and configured
     * - Event listeners are attached
     * - Initial data is loaded
     *
     * @param savedInstanceState Bundle containing previously saved state,
     *                          or null if this is a fresh start
     */
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        // Call parent onCreate to handle proper lifecycle
        super.onCreate(savedInstanceState);

        // Set the layout for this Activity
        // This inflates the XML layout (activity_main.xml) and sets it as the view
        setContentView(R.layout.activity_main);

        Log.d(TAG, "onCreate: Activity created");

        // Initialize UI components from the loaded layout
        initializeViews();

        // Setup event listeners for user interactions
        setupEventListeners();

        // Restore previous state if available
        restoreInstanceState(savedInstanceState);

        // Initial data update
        updateUIData();
    }

    /**
     * Called when the Activity is about to become visible.
     *
     * At this point:
     * - The Activity is visible but may not have focus
     * - Other Activities may still be visible
     *
     * This is a good place to register broadcast receivers,
     * animate views, etc.
     */
    @Override
    protected void onStart() {
        super.onStart();
        Log.d(TAG, "onStart: Activity becoming visible");
    }

    /**
     * Called when the Activity is about to interact with the user.
     *
     * At this point:
     * - The Activity has focus and is ready for user interaction
     * - The Activity is fully visible
     *
     * This is where we should start ongoing operations like
     * - Time updates
     * - Location tracking
     * - Sensor monitoring
     * - Animation loops
     *
     * Important: Resources started here MUST be stopped in onPause()
     */
    @Override
    protected void onResume() {
        super.onResume();
        Log.d(TAG, "onResume: Activity gaining focus");

        // Start time updates when Activity is visible
        startTimeUpdates();

        // Update UI with current data
        updateUIData();
    }

    /**
     * Called when the Activity is about to lose focus.
     *
     * At this point:
     * - Another Activity is about to be placed on top
     * - The Activity is still visible but losing focus
     * - This is NOT a good time for heavy operations
     *
     * This is where we should:
     * - Stop time updates (to save battery)
     * - Stop location updates
     * - Pause animations
     * - Release resources
     *
     * Important: Anything started in onResume() should be stopped here
     */
    @Override
    protected void onPause() {
        super.onPause();
        Log.d(TAG, "onPause: Activity losing focus");

        // Stop time updates to conserve battery
        stopTimeUpdates();

        // Save current state
        saveInstanceState();
    }

    /**
     * Called when the Activity is no longer visible.
     *
     * At this point:
     * - The Activity is no longer visible to the user
     * - Another Activity is fully in foreground
     * - The Activity may be killed by the system
     *
     * This is a good time to:
     * - Unregister broadcast receivers
     * - Release resources
     * - Close file handles
     */
    @Override
    protected void onStop() {
        super.onStop();
        Log.d(TAG, "onStop: Activity no longer visible");

        // Unregister any listeners
        // Stop background operations
    }

    /**
     * Called when the Activity is about to be destroyed.
     *
     * This may happen because:
     * - The user explicitly closed the Activity
     * - The system is reclaiming memory
     * - A configuration change occurred
     *
     * This is the last chance to clean up:
     * - Close database connections
     * - Release file handles
     * - Cancel async operations
     */
    @Override
    protected void onDestroy() {
        super.onDestroy();
        Log.d(TAG, "onDestroy: Activity being destroyed");

        // Stop any ongoing updates
        stopTimeUpdates();

        // Clean up resources
        cleanup();
    }

    /**
     * Called to save the current state of the Activity.
     *
     * This is called when the Activity may be destroyed due to:
     * - Configuration changes (rotation, locale change)
     * - System memory pressure
     * - User action
     *
     * The Bundle saved here is restored in onCreate() or onRestoreInstanceState()
     *
     * @param outState Bundle to save state into
     */
    @Override
    protected void onSaveInstanceState(Bundle outState) {
        super.onSaveInstanceState(outState);
        Log.d(TAG, "onSaveInstanceState: Saving state");

        // Save location string
        outState.putString(KEY_LOCATION, currentLocation);
    }

    // ============ UI Initialization Methods ============

    /**
     * Initialize UI component references from the loaded layout.
     *
     * This method uses findViewById() to get references to UI components
     * defined in the XML layout. This must be called after setContentView().
     *
     * Components initialized:
     * - textClock: Displays time
     * - refreshButton: User action button
     * - locationView: Info display
     */
    private void initializeViews() {
        Log.d(TAG, "initializeViews: Initializing UI components");

        try {
            // Get reference to TextClock from layout
            textClock = findViewById(R.id.text_clock);
            if (textClock != null) {
                Log.d(TAG, "initializeViews: TextClock found");

                // Configure TextClock for 12-hour format
                textClock.setFormat12Hour("hh:mm:ss a");

                // Set timezone (optional, default is system timezone)
                textClock.setTimeZone(TimeZone.getDefault().getID());
            } else {
                Log.w(TAG, "initializeViews: TextClock not found in layout");
            }

            // Get reference to Refresh Button from layout
            refreshButton = findViewById(R.id.refresh_button);
            if (refreshButton != null) {
                Log.d(TAG, "initializeViews: Refresh button found");
            } else {
                Log.w(TAG, "initializeViews: Refresh button not found in layout");
            }

            // Get reference to Location TextView from layout
            locationView = findViewById(R.id.location_text);
            if (locationView != null) {
                Log.d(TAG, "initializeViews: Location view found");
            } else {
                Log.w(TAG, "initializeViews: Location view not found in layout");
            }
        } catch (Exception e) {
            Log.e(TAG, "initializeViews: Error initializing views", e);
        }
    }

    /**
     * Setup event listeners for user interactions.
     *
     * This method attaches listeners to UI components to handle user actions:
     * - Button clicks
     * - Text input
     * - Long presses
     * - etc.
     */
    private void setupEventListeners() {
        Log.d(TAG, "setupEventListeners: Setting up listeners");

        if (refreshButton != null) {
            // Set click listener for refresh button
            refreshButton.setOnClickListener(v -> {
                Log.d(TAG, "setupEventListeners: Refresh button clicked");
                onRefreshButtonClicked();
            });

            // Optionally set long click listener
            refreshButton.setOnLongClickListener(v -> {
                Log.d(TAG, "setupEventListeners: Refresh button long clicked");
                onRefreshButtonLongClicked();
                return true;
            });
        }
    }

    // ============ Event Handler Methods ============

    /**
     * Handle refresh button click event.
     *
     * This is called when the user clicks the refresh button.
     * Updates the UI with current time and location information.
     */
    private void onRefreshButtonClicked() {
        Log.d(TAG, "onRefreshButtonClicked: Refreshing UI");

        // Update UI data
        updateUIData();

        // Optional: Show toast or visual feedback
        // Toast.makeText(this, "Updated", Toast.LENGTH_SHORT).show();
    }

    /**
     * Handle refresh button long click event.
     *
     * This is called when the user long clicks the refresh button.
     * Could be used for additional actions or settings.
     */
    private boolean onRefreshButtonLongClicked() {
        Log.d(TAG, "onRefreshButtonLongClicked: Long click detected");

        // Could show menu or dialog
        // For now, just log the event

        return true;
    }

    // ============ Time Update Management ============

    /**
     * Start time update loop.
     *
     * This starts a background task that periodically updates the UI.
     * Should be called from onResume() and stopped in onPause().
     */
    private void startTimeUpdates() {
        if (!isUpdatingTime) {
            Log.d(TAG, "startTimeUpdates: Starting time updates");
            isUpdatingTime = true;

            // Start a thread to update time periodically
            updateThread = new Thread(() -> {
                while (isUpdatingTime) {
                    try {
                        // Wait for UPDATE_INTERVAL_MS before updating
                        Thread.sleep(UPDATE_INTERVAL_MS);

                        // Update UI on main thread
                        runOnUiThread(this::updateUIData);
                    } catch (InterruptedException e) {
                        Log.d(TAG, "startTimeUpdates: Update thread interrupted");
                        Thread.currentThread().interrupt();
                        break;
                    }
                }
            });

            updateThread.setName("TimeUpdateThread");
            updateThread.setDaemon(true);
            updateThread.start();
        }
    }

    /**
     * Stop time update loop.
     *
     * This stops the background update task.
     * Should be called from onPause().
     */
    private void stopTimeUpdates() {
        if (isUpdatingTime) {
            Log.d(TAG, "stopTimeUpdates: Stopping time updates");
            isUpdatingTime = false;

            if (updateThread != null) {
                try {
                    updateThread.interrupt();
                    updateThread.join(5000); // Wait up to 5 seconds
                } catch (InterruptedException e) {
                    Log.e(TAG, "stopTimeUpdates: Error stopping update thread", e);
                    Thread.currentThread().interrupt();
                }
                updateThread = null;
            }
        }
    }

    // ============ UI Update Methods ============

    /**
     * Update all UI data.
     *
     * This method updates the display with current information:
     * - Time (handled by TextClock automatically)
     * - Location information
     * - Other dynamic content
     *
     * This must be called from the main thread.
     */
    private void updateUIData() {
        Log.d(TAG, "updateUIData: Updating UI");

        // TextClock updates itself automatically
        // Update additional UI elements
        if (locationView != null) {
            locationView.setText(currentLocation);
        }
    }

    // ============ State Management Methods ============

    /**
     * Restore instance state from saved Bundle.
     *
     * This is called from onCreate() to restore any previously saved state.
     *
     * @param savedInstanceState Bundle containing saved state, or null
     */
    private void restoreInstanceState(Bundle savedInstanceState) {
        if (savedInstanceState != null) {
            Log.d(TAG, "restoreInstanceState: Restoring saved state");

            // Restore location
            currentLocation = savedInstanceState.getString(KEY_LOCATION, "Default Location");
        } else {
            Log.d(TAG, "restoreInstanceState: No saved state available");
        }
    }

    /**
     * Save current instance state.
     *
     * This is called from onPause() to prepare state for saving.
     * (Actual saving happens in onSaveInstanceState())
     */
    private void saveInstanceState() {
        Log.d(TAG, "saveInstanceState: Preparing state for save");
        // Actual saving happens in onSaveInstanceState()
    }

    // ============ Cleanup Methods ============

    /**
     * Clean up resources before Activity destruction.
     *
     * This is called from onDestroy() to release any resources
     * held by the Activity.
     */
    private void cleanup() {
        Log.d(TAG, "cleanup: Cleaning up resources");

        // Stop any running threads
        stopTimeUpdates();

        // Release UI component references
        textClock = null;
        refreshButton = null;
        locationView = null;
    }

    // ============ Getter Methods ============

    /**
     * Get current location string.
     *
     * @return Current location
     */
    public String getLocation() {
        return currentLocation;
    }

    /**
     * Get TextClock component.
     *
     * @return TextClock instance
     */
    public TextClock getTextClock() {
        return textClock;
    }

    /**
     * Get Refresh button.
     *
     * @return Button instance
     */
    public Button getRefreshButton() {
        return refreshButton;
    }

    /**
     * Get Location view.
     *
     * @return TextView instance
     */
    public TextView getLocationView() {
        return locationView;
    }

    /**
     * Check if time updates are running.
     *
     * @return true if updates are active
     */
    public boolean isUpdatingTime() {
        return isUpdatingTime;
    }

    // ============ Setter Methods ============

    /**
     * Set current location string.
     *
     * @param location Location string to display
     */
    public void setLocation(String location) {
        this.currentLocation = location;
        updateUIData();
    }
}
