// test.ts - ConstraintAdapter Test Suite
import { ConstraintAdapter } from './coding';
describe('ConstraintAdapter', () => {
  test('should create layout', () => { const layout = ConstraintAdapter.createLayout([{ id: 1 }]); expect(layout.type).toBe('Stack'); });
  test('should set constraints', () => { const view = {}; ConstraintAdapter.setConstraints(view, { top: 0 }); expect(view['constraints']).toEqual({ top: 0 }); });
});
