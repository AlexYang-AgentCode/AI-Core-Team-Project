// test.ts - TimeZoneAdapter Test Suite
import { TimeZoneAdapter } from './coding';
describe('TimeZoneAdapter', () => {
  test('should create with default time zone', () => { const tz = TimeZoneAdapter.getDefault(); expect(tz.getID()).toBeDefined(); });
  test('should create with specific time zone', () => { const tz = new TimeZoneAdapter('Asia/Shanghai'); expect(tz.getID()).toBe('Asia/Shanghai'); });
  test('should get display name', () => { const tz = new TimeZoneAdapter('UTC'); expect(tz.getDisplayName()).toBeDefined(); });
  test('should calculate offset', () => { const tz = new TimeZoneAdapter('UTC'); expect(tz.getOffset()).toBe(0); });
});
