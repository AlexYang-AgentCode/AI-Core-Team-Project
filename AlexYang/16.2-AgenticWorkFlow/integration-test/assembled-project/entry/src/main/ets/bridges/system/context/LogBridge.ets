/**
 * LogBridge — Android Log bridge for HarmonyOS
 *
 * Maps android.util.Log.d/i/w/e/v(tag, msg) to HarmonyOS hilog.
 * Android's verbose level has no direct hilog counterpart so it is
 * mapped to hilog.debug.
 *
 * Usage (mirrors Android):
 *   LogBridge.d("MyTag", "some debug info");
 *   LogBridge.e("MyTag", "something went wrong");
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

export class LogBridge {
  /**
   * HiLog domain — 0xFF00 is a user-space domain.
   * Adjust if you need per-module domains.
   */
  private static readonly DOMAIN: number = 0xFF00;

  /**
   * Android: Log.d(tag, msg) — debug level
   */
  static d(tag: string, msg: string): void {
    hilog.debug(LogBridge.DOMAIN, tag, '%{public}s', msg);
  }

  /**
   * Android: Log.i(tag, msg) — info level
   */
  static i(tag: string, msg: string): void {
    hilog.info(LogBridge.DOMAIN, tag, '%{public}s', msg);
  }

  /**
   * Android: Log.w(tag, msg) — warning level
   */
  static w(tag: string, msg: string): void {
    hilog.warn(LogBridge.DOMAIN, tag, '%{public}s', msg);
  }

  /**
   * Android: Log.e(tag, msg) — error level
   */
  static e(tag: string, msg: string): void {
    hilog.error(LogBridge.DOMAIN, tag, '%{public}s', msg);
  }

  /**
   * Android: Log.v(tag, msg) — verbose level
   * HarmonyOS hilog has no verbose level; mapped to debug.
   */
  static v(tag: string, msg: string): void {
    hilog.debug(LogBridge.DOMAIN, tag, '%{public}s', msg);
  }
}
