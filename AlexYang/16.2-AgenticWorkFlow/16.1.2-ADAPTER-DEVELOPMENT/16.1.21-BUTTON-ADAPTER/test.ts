// test.ts - ButtonAdapter Test Suite
import { ButtonAdapter } from './coding';
describe('ButtonAdapter', () => {
  let button: ButtonAdapter;
  beforeEach(() => { button = new ButtonAdapter(); });
  test('should set and get text', () => { button.setText('Click'); expect(button.getText()).toBe('Click'); });
  test('should handle click', () => { const listener = jest.fn(); button.setOnClickListener(listener); button.performClick(); expect(listener).toHaveBeenCalled(); });
  test('should respect enabled state', () => { const listener = jest.fn(); button.setOnClickListener(listener); button.setEnabled(false); button.performClick(); expect(listener).not.toHaveBeenCalled(); });
});
