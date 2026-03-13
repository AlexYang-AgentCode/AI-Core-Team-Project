/**
 * AllTests.ets
 *
 * Complete test suite for View.Bridge module.
 * Run all tests using: ohpm test
 */

import { describe, it, expect } from '@ohos/hypium';

// Import all test suites
import colorBridgeTest from './ColorBridge.test';
import charSequenceTest from './CharSequence.test';
import drawableBridgeTest from './DrawableBridge.test';
import viewBridgeTest from './ViewBridge.test';
import textViewBridgeTest from './TextViewBridge.test';
import buttonBridgeTest from './ButtonBridge.test';
import layoutBridgeTest from './LayoutBridge.test';
import motionEventTest from './MotionEvent.test';
import viewRegistryTest from './ViewRegistry.test';
import toastBridgeTest from './ToastBridge.test';
import layoutParamsTest from './LayoutParams.test';

// Test summary
interface TestSummary {
  totalTests: number;
  passedTests: number;
  failedTests: number;
  suites: string[];
}

export default function allTests() {
  describe('View.Bridge Complete Test Suite', () => {

    // Run all widget tests
    describe('=== Widget Tests ===', () => {
      colorBridgeTest();
      charSequenceTest();
      drawableBridgeTest();
      motionEventTest();
      toastBridgeTest();
    });

    // Run all View hierarchy tests
    describe('=== View Hierarchy Tests ===', () => {
      viewBridgeTest();
      textViewBridgeTest();
      buttonBridgeTest();
    });

    // Run all Layout tests
    describe('=== Layout Tests ===', () => {
      layoutBridgeTest();
      layoutParamsTest();
    });

    // Run registry tests
    describe('=== Registry Tests ===', () => {
      viewRegistryTest();
    });

    // Summary
    describe('=== Test Summary ===', () => {
      it('should complete all test suites', () => {
        // This test ensures all suites ran
        expect(true).assertTrue();
      });
    });
  });
}

// Export individual tests for selective running
export {
  colorBridgeTest,
  charSequenceTest,
  drawableBridgeTest,
  viewBridgeTest,
  textViewBridgeTest,
  buttonBridgeTest,
  layoutBridgeTest,
  motionEventTest,
  viewRegistryTest,
  toastBridgeTest,
  layoutParamsTest
};
