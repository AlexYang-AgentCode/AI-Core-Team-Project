/**
 * Layout Inflater
 * 
 * Handles setContentView by loading ArkUI pages.
 * Maps Android R.layout.* to HarmonyOS page paths.
 */

import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { viewFinder, ViewIdRegistry } from './ViewFinder';
import { View } from './View';

const TAG = 'LayoutInflater';

/**
 * Layout loading interface
 */
export interface LayoutInflater {
  /**
   * Inflate a layout resource into the window
   * @param layoutId Android R.layout.* resource ID
   * @param windowStage HarmonyOS WindowStage
   * @returns Promise that resolves when layout is loaded
   */
  inflate(layoutId: number, windowStage: window.WindowStage): Promise<void>;

  /**
   * Register a layout mapping
   * @param layoutId Android R.layout.* ID
   * @param pagePath HarmonyOS page path (e.g., 'pages/MainPage')
   */
  registerLayout(layoutId: number, pagePath: string): void;

  /**
   * Get page path for a layout ID
   */
  getPagePath(layoutId: number): string | undefined;
}

/**
 * Implementation
 */
class LayoutInflaterImpl implements LayoutInflater {
  private _layoutToPage: Map<number, string> = new Map();

  async inflate(layoutId: number, windowStage: window.WindowStage): Promise<void> {
    const pagePath = this._layoutToPage.get(layoutId);
    
    if (!pagePath) {
      const error = `Layout not registered: 0x${layoutId.toString(16)}`;
      hilog.error(0x0000, TAG, error);
      throw new Error(error);
    }

    hilog.info(0x0000, TAG, `Inflating layout 0x${layoutId.toString(16)} -> ${pagePath}`);

    return new Promise((resolve, reject) => {
      windowStage.loadContent(pagePath, (err, data) => {
        if (err.code) {
          hilog.error(0x0000, TAG, `Failed to load content: ${JSON.stringify(err)}`);
          reject(err);
        } else {
          hilog.info(0x0000, TAG, `Content loaded successfully: ${pagePath}`);
          
          // Notify that page is loaded - 16.4.3 should register views now
          this._onPageLoaded(layoutId, pagePath);
          
          resolve();
        }
      });
    });
  }

  registerLayout(layoutId: number, pagePath: string): void {
    hilog.debug(0x0000, TAG, `Registering layout 0x${layoutId.toString(16)} -> ${pagePath}`);
    this._layoutToPage.set(layoutId, pagePath);
  }

  getPagePath(layoutId: number): string | undefined {
    return this._layoutToPage.get(layoutId);
  }

  /**
   * Called when a page is loaded
   * Subclasses can override to perform additional setup
   */
  private _onPageLoaded(layoutId: number, pagePath: string): void {
    // Notify 16.4.3 View.Bridge that page is loaded
    // View.Bridge should now register all views with their IDs
    PageLoadNotifier.notify(layoutId, pagePath);
  }
}

/**
 * Page Load Notifier
 * Allows 16.4.3 View.Bridge to register for page load events
 */
export class PageLoadNotifier {
  private static _listeners: Set<PageLoadListener> = new Set();

  static addListener(listener: PageLoadListener): void {
    PageLoadNotifier._listeners.add(listener);
  }

  static removeListener(listener: PageLoadListener): void {
    PageLoadNotifier._listeners.delete(listener);
  }

  static notify(layoutId: number, pagePath: string): void {
    PageLoadNotifier._listeners.forEach(listener => {
      try {
        listener.onPageLoaded(layoutId, pagePath);
      } catch (err) {
        hilog.error(0x0000, TAG, `Listener error: ${JSON.stringify(err)}`);
      }
    });
  }
}

export interface PageLoadListener {
  onPageLoaded(layoutId: number, pagePath: string): void;
}

// Singleton instance
export const layoutInflater: LayoutInflater = new LayoutInflaterImpl();

/**
 * Layout Registry
 * 
 * Static registry for layout mappings
 * Populated during app initialization
 */
export class LayoutRegistry {
  private static _layouts: Map<number, string> = new Map();

  static register(layoutId: number, pagePath: string): void {
    LayoutRegistry._layouts.set(layoutId, pagePath);
    // Also register with the inflater
    layoutInflater.registerLayout(layoutId, pagePath);
  }

  static getPagePath(layoutId: number): string | undefined {
    return LayoutRegistry._layouts.get(layoutId);
  }

  static hasLayout(layoutId: number): boolean {
    return LayoutRegistry._layouts.has(layoutId);
  }

  static getAllLayouts(): Map<number, string> {
    return new Map(LayoutRegistry._layouts);
  }
}
