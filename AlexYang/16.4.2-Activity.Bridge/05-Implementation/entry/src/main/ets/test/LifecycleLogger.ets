/**
 * Lifecycle Logger
 * 
 * Helper class to log and display lifecycle events
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'LifecycleLogger';

export class LifecycleLogger {
  private _events: string[] = [];
  private _maxEvents: number = 100;

  log(event: string): void {
    const timestamp = new Date().toISOString();
    const logEntry = `[${timestamp}] ${event}`;
    
    this._events.push(logEntry);
    
    // Keep only last N events
    if (this._events.length > this._maxEvents) {
      this._events.shift();
    }
    
    hilog.info(0x0000, TAG, logEntry);
  }

  getEvents(): string[] {
    return [...this._events];
  }

  clear(): void {
    this._events = [];
  }

  export(): string {
    return this._events.join('\n');
  }
}

// Global instance for sharing between components
export const globalLifecycleLogger = new LifecycleLogger();
