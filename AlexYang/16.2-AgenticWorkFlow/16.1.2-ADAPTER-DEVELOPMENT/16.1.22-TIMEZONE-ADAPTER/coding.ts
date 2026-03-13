// coding.ts - TimeZoneAdapter Implementation
export class TimeZoneAdapter {
  private timeZoneId: string;
  constructor(timeZoneId?: string) { this.timeZoneId = timeZoneId || Intl.DateTimeFormat().resolvedOptions().timeZone || 'UTC'; }
  static getDefault(): TimeZoneAdapter { return new TimeZoneAdapter(); }
  getID(): string { return this.timeZoneId; }
  getDisplayName(short: boolean = true): string { const formatter = new Intl.DateTimeFormat('zh-CN', { timeZone: this.timeZoneId, timeZoneName: short ? 'short' : 'long' }); const parts = formatter.formatToParts(new Date()); const tzPart = parts.find(p => p.type === 'timeZoneName'); return tzPart?.value || this.timeZoneId; }
  getOffset(date: Date = new Date()): number { const utc = new Date(date.toLocaleString('en-US', { timeZone: 'UTC' })); const tz = new Date(date.toLocaleString('en-US', { timeZone: this.timeZoneId })); return (tz.getTime() - utc.getTime()) / (1000 * 60); }
}
export default TimeZoneAdapter;
