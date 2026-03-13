/**
 * TimeZoneBridge — java.util.TimeZone bridge for HarmonyOS
 *
 * Maps Android's TimeZone.getDefault(), getDisplayName(), getID() to
 * HarmonyOS i18n.getTimeZone() API.
 *
 * Usage (mirrors Java):
 *   const tz = TimeZoneBridge.getDefault();
 *   console.log(tz.getID());           // "Asia/Shanghai"
 *   console.log(tz.getDisplayName());   // "China Standard Time"
 */

import { i18n } from '@kit.LocalizationKit';

export class TimeZoneBridge {
  // Display style constants (match Java's TimeZone.SHORT / TimeZone.LONG)
  static readonly SHORT: number = 0;
  static readonly LONG: number = 1;

  private _id: string;
  private _displayName: string;
  private _timezone: i18n.TimeZone;

  private constructor(timezone: i18n.TimeZone) {
    this._timezone = timezone;
    this._id = timezone.getID();
    this._displayName = timezone.getDisplayName();
  }

  // ===========================================================================
  // Factory
  // ===========================================================================

  /**
   * Android: TimeZone.getDefault()
   * Returns the system default time zone.
   */
  static getDefault(): TimeZoneBridge {
    const sysTimezone = i18n.getTimeZone();
    return new TimeZoneBridge(sysTimezone);
  }

  // ===========================================================================
  // Public API
  // ===========================================================================

  /**
   * Android: timeZone.getID()
   * Returns the Olson time zone ID, e.g. "Asia/Shanghai".
   */
  getID(): string {
    return this._id;
  }

  /**
   * Android: timeZone.getDisplayName(daylight, style)
   *
   * @param daylight - if true, return daylight saving name (default: false)
   * @param style    - SHORT (0) or LONG (1) (default: LONG)
   * @returns human-readable time zone name
   */
  getDisplayName(daylight?: boolean, style?: number): string {
    // HarmonyOS i18n.TimeZone.getDisplayName() accepts locale but not
    // daylight/style in the same way as Java. We approximate:
    // - For the basic case, return the cached display name.
    // - For short style, attempt to return the abbreviation from getRawOffset.
    const useDaylight = daylight !== undefined ? daylight : false;
    const useStyle = style !== undefined ? style : TimeZoneBridge.LONG;

    if (useStyle === TimeZoneBridge.SHORT) {
      // Build a short form like "GMT+8" from raw offset
      const offsetMs = this._timezone.getRawOffset();
      return TimeZoneBridge._formatGmtOffset(offsetMs, useDaylight);
    }

    // LONG style — use the display name from the system
    return this._displayName;
  }

  // ===========================================================================
  // Internal helpers
  // ===========================================================================

  /**
   * Format a raw offset in milliseconds to a GMT offset string.
   * e.g. 28800000 → "GMT+08:00"
   */
  private static _formatGmtOffset(offsetMs: number, _daylight: boolean): string {
    const totalMinutes = Math.round(offsetMs / 60000);
    const sign = totalMinutes >= 0 ? '+' : '-';
    const absMinutes = Math.abs(totalMinutes);
    const hours = Math.floor(absMinutes / 60);
    const minutes = absMinutes % 60;

    const hh = hours < 10 ? '0' + hours : '' + hours;
    const mm = minutes < 10 ? '0' + minutes : '' + minutes;

    return `GMT${sign}${hh}:${mm}`;
  }
}
