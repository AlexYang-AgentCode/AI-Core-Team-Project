/**
 * DrawableBridge.test.ets
 *
 * Unit tests for DrawableBridge - Android Drawable color filter simulation.
 */

import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { DrawableBridge } from '../05-Implementation/widgets/DrawableBridge';
import { ColorBridge, PorterDuff } from '../05-Implementation/widgets/ColorBridge';

// Mock ViewBridgeLike for testing
class MockViewBridge {
  private id: number;
  constructor(id: number) { this.id = id; }
  getId(): number { return this.id; }
}

export default function drawableBridgeTest() {
  describe('DrawableBridge Tests', () => {
    let mockView: MockViewBridge;
    let drawable: DrawableBridge;

    beforeEach(() => {
      mockView = new MockViewBridge(123);
      drawable = new DrawableBridge(mockView as any);
    });

    describe('Construction', () => {
      it('should create DrawableBridge with view reference', () => {
        expect(drawable).assertNotNull();
      });

      it('should have no color filter initially', () => {
        expect(drawable.getColorFilter()).assertNull();
      });

      it('should have -1 as initial filter mode', () => {
        expect(drawable.getFilterMode()).assertEqual(-1);
      });
    });

    describe('setColorFilter', () => {
      it('should set color filter with SRC_ATOP mode', () => {
        drawable.setColorFilter(ColorBridge.RED, PorterDuff.Mode.SRC_ATOP);
        expect(drawable.getColorFilter()).assertEqual('#FF0000');
        expect(drawable.getFilterMode()).assertEqual(PorterDuff.Mode.SRC_ATOP);
      });

      it('should set color filter with MULTIPLY mode', () => {
        drawable.setColorFilter(ColorBridge.BLUE, PorterDuff.Mode.MULTIPLY);
        expect(drawable.getColorFilter()).assertEqual('#0000FF');
        expect(drawable.getFilterMode()).assertEqual(PorterDuff.Mode.MULTIPLY);
      });

      it('should handle transparent colors', () => {
        const semiGreen = 0x8000FF00;
        drawable.setColorFilter(semiGreen, PorterDuff.Mode.SRC_OVER);
        expect(drawable.getColorFilter()).assertEqual('#8000FF00');
      });
    });

    describe('clearColorFilter', () => {
      it('should clear color filter', () => {
        drawable.setColorFilter(ColorBridge.RED, PorterDuff.Mode.SRC_ATOP);
        expect(drawable.getColorFilter()).assertNotNull();

        drawable.clearColorFilter();
        expect(drawable.getColorFilter()).assertNull();
        expect(drawable.getFilterMode()).assertEqual(-1);
      });

      it('should be safe to clear when no filter set', () => {
        drawable.clearColorFilter();
        expect(drawable.getColorFilter()).assertNull();
      });
    });

    describe('Multiple filters', () => {
      it('should override previous filter', () => {
        drawable.setColorFilter(ColorBridge.RED, PorterDuff.Mode.SRC_ATOP);
        drawable.setColorFilter(ColorBridge.BLUE, PorterDuff.Mode.MULTIPLY);

        expect(drawable.getColorFilter()).assertEqual('#0000FF');
        expect(drawable.getFilterMode()).assertEqual(PorterDuff.Mode.MULTIPLY);
      });
    });
  });
}
