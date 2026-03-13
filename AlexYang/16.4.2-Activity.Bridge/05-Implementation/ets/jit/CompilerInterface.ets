/**
 * JIT Compiler Interface
 * 
 * Provides hooks for 16.4.1 JIT compiler to register mappings
 * and configure the bridge layer during app initialization.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { LayoutRegistry } from '../view/LayoutInflater';
import { ViewIdRegistry } from '../view/ViewFinder';

const TAG = 'JITInterface';

/**
 * Interface for JIT compiler to register Activity classes and resource mappings
 */
export class ActivityCompilerInterface {
  
  /**
   * Initialize the bridge layer
   * Called once at app startup by JIT-generated initialization code
   */
  static initialize(): void {
    hilog.info(0x0000, TAG, 'Activity Bridge initialized');
    // Any global initialization can go here
  }

  /**
   * Register an Activity class mapping
   * 
   * @param javaClassName Original Java class name (e.g., "com.example.MainActivity")
   * @param abilityName Generated HarmonyOS Ability name (e.g., "MainActivity")
   * @param pagePath Associated ArkUI page path
   */
  static registerActivityClass(
    javaClassName: string, 
    abilityName: string, 
    pagePath: string
  ): void {
    hilog.debug(0x0000, TAG, `Registering Activity: ${javaClassName} -> ${abilityName}`);
    ActivityClassRegistry.register(javaClassName, abilityName, pagePath);
  }

  /**
   * Register a layout resource mapping
   * 
   * @param layoutId Android R.layout.* integer ID
   * @param pagePath HarmonyOS page path (e.g., "pages/MainPage")
   */
  static registerLayoutMapping(layoutId: number, pagePath: string): void {
    hilog.debug(0x0000, TAG, `Registering layout: 0x${layoutId.toString(16)} -> ${pagePath}`);
    LayoutRegistry.register(layoutId, pagePath);
  }

  /**
   * Register a view ID mapping
   * 
   * @param viewId Android R.id.* integer ID
   * @param componentId Component identifier string
   */
  static registerViewIdMapping(viewId: number, componentId: string): void {
    hilog.debug(0x0000, TAG, `Registering view ID: 0x${viewId.toString(16)} -> ${componentId}`);
    ViewIdRegistry.register(viewId, componentId);
  }

  /**
   * Batch register multiple mappings
   * Used for efficiency when registering many resources at once
   */
  static batchRegister(registrations: RegistrationBatch): void {
    hilog.info(0x0000, TAG, `Batch registering: ${registrations.activities.length} activities, ` +
      `${registrations.layouts.length} layouts, ${registrations.viewIds.length} view IDs`);

    // Register activities
    registrations.activities.forEach(act => {
      this.registerActivityClass(act.javaClassName, act.abilityName, act.pagePath);
    });

    // Register layouts
    registrations.layouts.forEach(layout => {
      this.registerLayoutMapping(layout.id, layout.pagePath);
    });

    // Register view IDs
    registrations.viewIds.forEach(view => {
      this.registerViewIdMapping(view.id, view.componentId);
    });
  }

  /**
   * Get version of the bridge API
   */
  static getVersion(): string {
    return '1.0.0';
  }
}

/**
 * Data structures for batch registration
 */
export interface RegistrationBatch {
  activities: ActivityRegistration[];
  layouts: LayoutRegistration[];
  viewIds: ViewIdRegistration[];
}

export interface ActivityRegistration {
  javaClassName: string;
  abilityName: string;
  pagePath: string;
}

export interface LayoutRegistration {
  id: number;
  pagePath: string;
}

export interface ViewIdRegistration {
  id: number;
  componentId: string;
}

/**
 * Activity Class Registry
 * Maps Java class names to HarmonyOS Ability names
 */
export class ActivityClassRegistry {
  private static _registry: Map<string, ActivityInfo> = new Map();

  static register(javaClassName: string, abilityName: string, pagePath: string): void {
    ActivityClassRegistry._registry.set(javaClassName, {
      abilityName,
      pagePath
    });
  }

  static getActivityInfo(javaClassName: string): ActivityInfo | undefined {
    return ActivityClassRegistry._registry.get(javaClassName);
  }

  static getAbilityName(javaClassName: string): string | undefined {
    return ActivityClassRegistry._registry.get(javaClassName)?.abilityName;
  }

  static getPagePath(javaClassName: string): string | undefined {
    return ActivityClassRegistry._registry.get(javaClassName)?.pagePath;
  }

  static getAllActivities(): string[] {
    return Array.from(ActivityClassRegistry._registry.keys());
  }
}

interface ActivityInfo {
  abilityName: string;
  pagePath: string;
}
