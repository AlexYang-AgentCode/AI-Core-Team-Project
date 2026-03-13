/**
 * BridgedActivity.ets — Core Activity bridge class
 *
 * Extends HarmonyOS UIAbility and exposes Android-compatible lifecycle
 * methods (onCreate, onStart, onResume, onPause, onStop, onDestroy).
 *
 * Lifecycle mapping:
 *   UIAbility.onCreate         -> Android onCreate(bundle)
 *   UIAbility.onWindowStageCreate -> loadContent(layoutId), onStart(), onResume()
 *   UIAbility.onForeground     -> onStart(), onResume()  (skipped on first launch)
 *   UIAbility.onBackground     -> onPause(), onStop()
 *   UIAbility.onDestroy        -> Android onDestroy()
 *
 * Subclasses override the protected Android-style methods just as they
 * would in an Android Activity. The UIAbility callbacks are final (not
 * meant to be overridden by migration code).
 */

import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { Bundle } from './Bundle';
import { LayoutRegistry } from './LayoutRegistry';
import { ViewRegistry } from './ViewRegistry';

export class BridgedActivity extends UIAbility {
  /**
   * The layout id set by setContentView(). Consumed during
   * onWindowStageCreate to load the corresponding ArkUI page.
   */
  private _contentLayoutId: number = -1;

  /**
   * Tracks whether onWindowStageCreate has fired (i.e. the first
   * foreground cycle). Used to prevent duplicate onStart/onResume
   * calls when onForeground fires immediately after window stage creation.
   */
  private _initialLaunchComplete: boolean = false;

  /**
   * The saved instance state Bundle, built from the Want that launched
   * this Ability. Passed to the Android-compatible onCreate().
   */
  private _savedInstanceState: Bundle | null = null;

  // ==================================================================
  // Android-compatible lifecycle methods — override these in subclasses
  // ==================================================================

  /**
   * Called when the activity is first created.
   * Override this to initialise your activity, call setContentView(), etc.
   *
   * @param savedInstanceState data passed via Want parameters, or null
   */
  protected onCreate(savedInstanceState: Bundle | null): void {
    // Subclass override point — intentionally empty
  }

  /**
   * Called when the activity becomes visible.
   */
  protected onStart(): void {
    // Subclass override point
  }

  /**
   * Called when the activity starts interacting with the user.
   */
  protected onResume(): void {
    // Subclass override point
  }

  /**
   * Called when the activity is going into the background but has not
   * yet been stopped.
   */
  protected onPause(): void {
    // Subclass override point
  }

  /**
   * Called when the activity is no longer visible.
   */
  protected onStop(): void {
    // Subclass override point
  }

  /**
   * Called before the activity is destroyed.
   * Clean up resources here.
   */
  protected onActivityDestroy(): void {
    // Subclass override point
  }

  // ==================================================================
  // Android-compatible utility methods
  // ==================================================================

  /**
   * Records the layout id to load. The actual page loading happens
   * in onWindowStageCreate when the window stage becomes available.
   *
   * Call this from your onCreate() override, just like in Android:
   *   setContentView(R.layout.activity_main)
   *
   * @param layoutId numeric layout id registered in LayoutRegistry
   */
  setContentView(layoutId: number): void {
    this._contentLayoutId = layoutId;
  }

  /**
   * Look up a component by its numeric id from the ViewRegistry.
   * Mirrors Android's Activity.findViewById().
   *
   * @param id the numeric id (mirrors R.id.*)
   * @returns the component cast to T, or throws if not found
   */
  findViewById<T>(id: number): T {
    const view = ViewRegistry.find<T>(id);
    if (view === null) {
      throw new Error(
        `BridgedActivity.findViewById: no view registered for id=${id}. ` +
        `Ensure the ArkUI page registers components via ViewRegistry.register().`
      );
    }
    return view;
  }

  /**
   * Returns the UIAbility context, mirroring Android's getApplicationContext().
   */
  getApplicationContext(): Context {
    return this.context;
  }

  // ==================================================================
  // UIAbility lifecycle callbacks — internal mapping, do not override
  // ==================================================================

  /**
   * UIAbility.onCreate — maps to Android onCreate(bundle).
   */
  onAbilityCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    super.onCreate(want, launchParam);

    // Build a Bundle from the Want parameters
    this._savedInstanceState = want.parameters ? Bundle.fromWant(want) : null;

    // Invoke Android-compatible onCreate
    this.onCreate(this._savedInstanceState);
  }

  /**
   * UIAbility.onWindowStageCreate — loads the ArkUI page registered
   * via setContentView(), then fires onStart() and onResume().
   */
  onWindowStageCreate(windowStage: window.WindowStage): void {
    if (this._contentLayoutId < 0) {
      console.warn(
        'BridgedActivity: onWindowStageCreate called but no layout set. ' +
        'Did you forget to call setContentView() in onCreate()?'
      );
      return;
    }

    // Resolve the layout id to an ArkUI page path
    const pagePath = LayoutRegistry.getPagePath(this._contentLayoutId);

    // Load the ArkUI page into the window stage
    windowStage.loadContent(pagePath, (err) => {
      if (err) {
        console.error(
          `BridgedActivity: failed to load page "${pagePath}" ` +
          `for layoutId=${this._contentLayoutId}: ${JSON.stringify(err)}`
        );
        return;
      }

      // Page loaded successfully — fire the remaining lifecycle callbacks
      this.onStart();
      this.onResume();
      this._initialLaunchComplete = true;
    });
  }

  /**
   * UIAbility.onForeground — fires onStart() + onResume() when
   * returning from background. Skipped on the very first launch
   * because onWindowStageCreate already handled it.
   */
  onAbilityForeground(): void {
    if (!this._initialLaunchComplete) {
      // First launch — onWindowStageCreate will handle onStart/onResume
      return;
    }
    this.onStart();
    this.onResume();
  }

  /**
   * UIAbility.onBackground — fires onPause() + onStop().
   */
  onAbilityBackground(): void {
    this.onPause();
    this.onStop();
  }

  /**
   * UIAbility.onDestroy — fires Android onDestroy() and cleans up
   * the ViewRegistry to prevent memory leaks.
   */
  onAbilityDestroy(): void {
    this.onActivityDestroy();
    ViewRegistry.clear();
  }
}
