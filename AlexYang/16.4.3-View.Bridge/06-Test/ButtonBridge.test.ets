/**
 * ButtonBridge.test.ets
 *
 * Unit tests for ButtonBridge - Android Button implementation.
 */

import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { ButtonBridge } from '../05-Implementation/widgets/ButtonBridge';
import { ColorBridge } from '../05-Implementation/widgets/ColorBridge';

class TestableButtonBridge extends ButtonBridge {
  constructor(id: number) {
    super(id);
  }
}

export default function buttonBridgeTest() {
  describe('ButtonBridge Tests', () => {
    let button: TestableButtonBridge;

    beforeEach(() => {
      button = new TestableButtonBridge(2001);
    });

    describe('Pressed State', () => {
      it('should default to not pressed', () => {
        expect(button.isPressed()).assertFalse();
      });

      it('should set pressed state', () => {
        button.setPressed(true);
        expect(button.isPressed()).assertTrue();
      });

      it('should toggle pressed state', () => {
        button.setPressed(true);
        expect(button.isPressed()).assertTrue();
        button.setPressed(false);
        expect(button.isPressed()).assertFalse();
      });

      it('should handle dispatch touch for ACTION_DOWN', () => {
        button._dispatchTouch(0); // ACTION_DOWN
        expect(button.isPressed()).assertTrue();
      });

      it('should handle dispatch touch for ACTION_UP', () => {
        button.setPressed(true);
        button._dispatchTouch(1); // ACTION_UP
        expect(button.isPressed()).assertFalse();
      });

      it('should handle dispatch touch for ACTION_CANCEL', () => {
        button.setPressed(true);
        button._dispatchTouch(3); // ACTION_CANCEL
        expect(button.isPressed()).assertFalse();
      });
    });

    describe('Background Colors', () => {
      it('should set normal background color', () => {
        button.setBackgroundColor(ColorBridge.BLUE);
        expect(button.getBackgroundColorState()).assertEqual('#0000FF');
      });

      it('should set pressed color', () => {
        button.setPressedColor(ColorBridge.RED);
        expect(button.getPressedColorState()).assertEqual('#FF0000');
      });

      it('should return pressed color when pressed', () => {
        button.setBackgroundColor(ColorBridge.BLUE);
        button.setPressedColor(ColorBridge.RED);
        button.setPressed(true);
        expect(button.getBackgroundColorState()).assertEqual('#FF0000');
      });

      it('should return normal color when not pressed', () => {
        button.setBackgroundColor(ColorBridge.BLUE);
        button.setPressedColor(ColorBridge.RED);
        expect(button.getBackgroundColorState()).assertEqual('#0000FF');
      });
    });

    describe('Inheritance from TextViewBridge', () => {
      it('should inherit text functionality', () => {
        button.setText('Click Me');
        expect(button.getTextState()).assertEqual('Click Me');
      });

      it('should inherit text color functionality', () => {
        button.setTextColor(ColorBridge.GREEN);
        expect(button.getTextColorState()).assertEqual('#00FF00');
      });

      it('should inherit text size functionality', () => {
        button.setTextSize(0, 18);
        expect(button.getTextSizeState()).assertEqual(18);
      });
    });
  });
}
