/**
 * JIT Compiler Interface for Activity.Bridge
 * 
 * Defines the contract between 16.4.1 JIT.Performance and 16.4.2 Activity.Bridge
 * JIT compiler generates ArkTS code that implements Android Activity classes
 * and calls into the bridge layer.
 */

import { Activity } from '../ets/activity/Activity';
import { FragmentActivity } from '../ets/activity/FragmentActivity';
import { AppCompatActivity } from '../ets/activity/AppCompatActivity';
import { Bundle } from '../ets/os/Bundle';
import { viewFinder, ViewIdRegistry } from '../ets/view/ViewFinder';
import { layoutInflater, LayoutRegistry } from '../ets/view/LayoutInflater';
import { Intent, Context } from '../ets/content/Context';

/**
 * JIT Compiler Interface
 * 
 * This interface is called by the JIT compiler (16.4.1) to:
 * 1. Register generated Activity classes
 * 2. Map R.id.* to component IDs
 * 3. Map R.layout.* to page paths
 * 4. Bind Views to Activities
 */
export interface JITCompilerInterface {
  /**
   * Register a JIT-generated Activity class
   * @param className Fully qualified Android class name (e.g., "com.example.MainActivity")
   * @param activityClass The generated ArkTS Activity class
   */
  registerActivity(className: string, activityClass: new () => Activity): void;

  /**
   * Get a registered Activity class by name
   * @param className Android class name
   * @returns The Activity class or undefined
   */
  getActivityClass(className: string): (new () => Activity) | undefined;

  /**
   * Register R.id.* mappings
   * Called during app initialization to map Android resource IDs to component IDs
   * @param mappings Array of { id: number, componentId: string }
   */
  registerViewIds(mappings: Array<{ id: number; componentId: string }>): void;

  /**
   * Register R.layout.* mappings
   * Called during app initialization to map layout IDs to HarmonyOS page paths
   * @param mappings Array of { id: number, pagePath: string }
   */
  registerLayouts(mappings: Array<{ id: number; pagePath: string }>): void;

  /**
   * Create an Activity instance from Android class name
   * Used when launching Activities from Intents
   * @param className Android class name
   * @returns Activity instance
   */
  instantiateActivity(className: string): Activity;

  /**
   * Bind views to an Activity after setContentView
   * Called automatically after layout inflation
   * @param activity The Activity instance
   * @param viewBindings Map of R.id.* to view instances
   */
  bindViews(activity: Activity, viewBindings: Map<number, any>): void;
}

/**
 * Implementation of JIT Compiler Interface
 */
class JITCompilerInterfaceImpl implements JITCompilerInterface {
  private _activityRegistry: Map<string, new () => Activity> = new Map();

  registerActivity(className: string, activityClass: new () => Activity): void {
    console.log(`[JIT] Registering Activity: ${className}`);
    this._activityRegistry.set(className, activityClass);
  }

  getActivityClass(className: string): (new () => Activity) | undefined {
    return this._activityRegistry.get(className);
  }

  registerViewIds(mappings: Array<{ id: number; componentId: string }>): void {
    console.log(`[JIT] Registering ${mappings.length} view IDs`);
    mappings.forEach(mapping => {
      ViewIdRegistry.register(mapping.id, mapping.componentId);
    });
  }

  registerLayouts(mappings: Array<{ id: number; pagePath: string }>): void {
    console.log(`[JIT] Registering ${mappings.length} layouts`);
    mappings.forEach(mapping => {
      LayoutRegistry.register(mapping.id, mapping.pagePath);
    });
  }

  instantiateActivity(className: string): Activity {
    const ActivityClass = this._activityRegistry.get(className);
    if (!ActivityClass) {
      throw new Error(`Activity class not found: ${className}`);
    }
    return new ActivityClass();
  }

  bindViews(activity: Activity, viewBindings: Map<number, any>): void {
    viewBindings.forEach((view, id) => {
      viewFinder.registerView(id, view);
    });
  }
}

// Singleton instance
export const jitCompilerInterface: JITCompilerInterface = new JITCompilerInterfaceImpl();

/**
 * Activity Generator Helper
 * 
 * Functions to help JIT compiler generate Activity classes
 */
export namespace ActivityGenerator {
  /**
   * Generate an Activity class from Android bytecode analysis
   * @param className Android class name
   * @param lifecycleCallbacks Object containing lifecycle method implementations
   * @returns Generated Activity class
   */
  export function generateActivity(
    className: string,
    lifecycleCallbacks: {
      onCreate?: (savedInstanceState: Bundle | null) => void;
      onStart?: () => void;
      onResume?: () => void;
      onPause?: () => void;
      onStop?: () => void;
      onDestroy?: () => void;
      onSaveInstanceState?: (outState: Bundle) => void;
    }
  ): new () => Activity {
    // Generate a class that extends Activity
    class GeneratedActivity extends Activity {
      protected onCreate(savedInstanceState: Bundle | null): void {
        super.onCreate(savedInstanceState);
        lifecycleCallbacks.onCreate?.(savedInstanceState);
      }

      protected onStart(): void {
        super.onStart();
        lifecycleCallbacks.onStart?.();
      }

      protected onResume(): void {
        super.onResume();
        lifecycleCallbacks.onResume?.();
      }

      protected onPause(): void {
        super.onPause();
        lifecycleCallbacks.onPause?.();
      }

      protected onStop(): void {
        super.onStop();
        lifecycleCallbacks.onStop?.();
      }

      protected onDestroy(): void {
        super.onDestroy();
        lifecycleCallbacks.onDestroy?.();
      }

      protected onSaveInstanceState(outState: Bundle): void {
        super.onSaveInstanceState(outState);
        lifecycleCallbacks.onSaveInstanceState?.(outState);
      }
    }

    // Register the generated class
    jitCompilerInterface.registerActivity(className, GeneratedActivity);

    return GeneratedActivity;
  }

  /**
   * Generate an AppCompatActivity class
   * For Activities that extend AppCompatActivity in Android
   */
  export function generateAppCompatActivity(
    className: string,
    lifecycleCallbacks: {
      onCreate?: (savedInstanceState: Bundle | null) => void;
      onStart?: () => void;
      onResume?: () => void;
      onPause?: () => void;
      onStop?: () => void;
      onDestroy?: () => void;
    }
  ): new () => AppCompatActivity {
    class GeneratedAppCompatActivity extends AppCompatActivity {
      protected onCreate(savedInstanceState: Bundle | null): void {
        super.onCreate(savedInstanceState);
        lifecycleCallbacks.onCreate?.(savedInstanceState);
      }

      protected onStart(): void {
        super.onStart();
        lifecycleCallbacks.onStart?.();
      }

      protected onResume(): void {
        super.onResume();
        lifecycleCallbacks.onResume?.();
      }

      protected onPause(): void {
        super.onPause();
        lifecycleCallbacks.onPause?.();
      }

      protected onStop(): void {
        super.onStop();
        lifecycleCallbacks.onStop?.();
      }

      protected onDestroy(): void {
        super.onDestroy();
        lifecycleCallbacks.onDestroy?.();
      }
    }

    jitCompilerInterface.registerActivity(className, GeneratedAppCompatActivity);
    return GeneratedAppCompatActivity;
  }

  /**
   * Generate view binding code for an Activity
   * @param activityClass The Activity class
   * @param viewMappings Map of field names to R.id.* values
   */
  export function generateViewBindings(
    activityClass: new () => Activity,
    viewMappings: Record<string, number>
  ): void {
    // Store the mappings so they can be used after setContentView
    const activityProto = activityClass.prototype as any;
    activityProto._viewMappings = viewMappings;

    // Override onCreate to perform view binding
    const originalOnCreate = activityProto.onCreate;
    activityProto.onCreate = function(savedInstanceState: Bundle | null) {
      originalOnCreate.call(this, savedInstanceState);
      
      // Bind views after setContentView has been called
      if (this._viewMappings) {
        Object.entries(this._viewMappings).forEach(([fieldName, viewId]) => {
          (this as any)[fieldName] = this.findViewById(viewId as number);
        });
      }
    };
  }
}

/**
 * Lifecycle Event Recorder
 * 
 * Utility for debugging lifecycle transitions
 */
export class LifecycleEventRecorder {
  private _events: Array<{ event: string; timestamp: number; data?: any }> = [];

  record(event: string, data?: any): void {
    this._events.push({
      event,
      timestamp: Date.now(),
      data
    });
  }

  getEvents(): Array<{ event: string; timestamp: number; data?: any }> {
    return [...this._events];
  }

  getEventSequence(): string[] {
    return this._events.map(e => e.event);
  }

  clear(): void {
    this._events = [];
  }

  /**
   * Attach to an Activity to record all lifecycle events
   */
  attach(activity: Activity): void {
    const recorder = this;
    
    // Wrap lifecycle methods
    const originalOnCreate = (activity as any).onCreate.bind(activity);
    (activity as any).onCreate = function(savedInstanceState: Bundle | null) {
      recorder.record('onCreate', { hasState: !!savedInstanceState });
      originalOnCreate(savedInstanceState);
    };

    const originalOnStart = (activity as any).onStart.bind(activity);
    (activity as any).onStart = function() {
      recorder.record('onStart');
      originalOnStart();
    };

    const originalOnResume = (activity as any).onResume.bind(activity);
    (activity as any).onResume = function() {
      recorder.record('onResume');
      originalOnResume();
    };

    const originalOnPause = (activity as any).onPause.bind(activity);
    (activity as any).onPause = function() {
      recorder.record('onPause');
      originalOnPause();
    };

    const originalOnStop = (activity as any).onStop.bind(activity);
    (activity as any).onStop = function() {
      recorder.record('onStop');
      originalOnStop();
    };

    const originalOnDestroy = (activity as any).onDestroy.bind(activity);
    (activity as any).onDestroy = function() {
      recorder.record('onDestroy');
      originalOnDestroy();
    };
  }
}

/**
 * Integration Test Helper for JIT Compiler
 * 
 * Provides utilities for testing JIT-generated Activities
 */
export namespace JITTestHelper {
  /**
   * Create a test Activity with lifecycle tracking
   */
  export function createTestActivity(
    lifecycleCallbacks?: {
      onCreate?: (savedInstanceState: Bundle | null) => void;
      onStart?: () => void;
      onResume?: () => void;
      onPause?: () => void;
      onStop?: () => void;
      onDestroy?: () => void;
    }
  ): { activity: Activity; recorder: LifecycleEventRecorder } {
    const recorder = new LifecycleEventRecorder();
    
    class TestActivity extends Activity {
      protected onCreate(savedInstanceState: Bundle | null): void {
        super.onCreate(savedInstanceState);
        lifecycleCallbacks?.onCreate?.(savedInstanceState);
      }

      protected onStart(): void {
        super.onStart();
        lifecycleCallbacks?.onStart?.();
      }

      protected onResume(): void {
        super.onResume();
        lifecycleCallbacks?.onResume?.();
      }

      protected onPause(): void {
        super.onPause();
        lifecycleCallbacks?.onPause?.();
      }

      protected onStop(): void {
        super.onStop();
        lifecycleCallbacks?.onStop?.();
      }

      protected onDestroy(): void {
        super.onDestroy();
        lifecycleCallbacks?.onDestroy?.();
      }
    }

    const activity = new TestActivity();
    recorder.attach(activity);

    return { activity, recorder };
  }

  /**
   * Simulate full lifecycle of an Activity
   */
  export function simulateFullLifecycle(activity: Activity): void {
    const bundle = new Bundle();
    
    // Create
    activity.onCreate(bundle);
    
    // Start
    activity.onStart();
    
    // Resume
    activity.onResume();
    
    // Pause
    activity.onPause();
    
    // Stop
    activity.onStop();
    
    // Destroy
    activity.onDestroy();
  }

  /**
   * Verify lifecycle sequence
   */
  export function verifyLifecycleSequence(
    recorder: LifecycleEventRecorder,
    expectedSequence: string[]
  ): boolean {
    const actualSequence = recorder.getEventSequence();
    
    if (actualSequence.length !== expectedSequence.length) {
      console.error(`Lifecycle sequence length mismatch: expected ${expectedSequence.length}, got ${actualSequence.length}`);
      return false;
    }

    for (let i = 0; i < expectedSequence.length; i++) {
      if (actualSequence[i] !== expectedSequence[i]) {
        console.error(`Lifecycle mismatch at position ${i}: expected ${expectedSequence[i]}, got ${actualSequence[i]}`);
        return false;
      }
    }

    return true;
  }
}
