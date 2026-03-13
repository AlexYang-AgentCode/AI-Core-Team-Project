/**
 * TextViewBridge.test.ets
 *
 * Unit tests for TextViewBridge - Android TextView implementation.
 */

import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { TextViewBridge, TypedValue } from '../05-Implementation/widgets/TextViewBridge';
import { CharSequence } from '../05-Implementation/widgets/CharSequence';
import { ColorBridge } from '../05-Implementation/widgets/ColorBridge';

class TestableTextViewBridge extends TextViewBridge {
  constructor(id: number) {
    super(id);
  }
}

export default function textViewBridgeTest() {
  describe('TextViewBridge Tests', () => {
    let textView: TestableTextViewBridge;

    beforeEach(() => {
      textView = new TestableTextViewBridge(1001);
    });

    describe('Text Management', () => {
      it('should set and get text as string', () => {
        textView.setText('Hello World');
        expect(textView.getTextState()).assertEqual('Hello World');
        expect(textView.getText().toString()).assertEqual('Hello World');
      });

      it('should handle numeric text value', () => {
        textView.setText(12345);
        expect(textView.getTextState()).assertEqual('12345');
      });

      it('should handle empty text', () => {
        textView.setText('');
        expect(textView.getTextState()).assertEqual('');
      });

      it('should return CharSequence from getText', () => {
        textView.setText('Test');
        const cs = textView.getText();
        expect(cs instanceof CharSequence).assertTrue();
        expect(cs.length()).assertEqual(4);
      });
    });

    describe('Text Color', () => {
      it('should set text color', () => {
        textView.setTextColor(ColorBridge.RED);
        expect(textView.getTextColorState()).assertEqual('#FF0000');
      });

      it('should handle transparent text color', () => {
        textView.setTextColor(0x800000FF);
        expect(textView.getTextColorState()).assertEqual('#800000FF');
      });

      it('should default to black', () => {
        expect(textView.getTextColorState()).assertEqual('#000000');
      });
    });

    describe('Text Size', () => {
      it('should set text size', () => {
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 16);
        expect(textView.getTextSizeState()).assertEqual(16);
      });

      it('should set different sizes', () => {
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, 24);
        expect(textView.getTextSizeState()).assertEqual(24);
      });

      it('should default to 16', () => {
        expect(textView.getTextSizeState()).assertEqual(16);
      });
    });

    describe('Gravity / Alignment', () => {
      it('should handle LEFT gravity', () => {
        textView.setGravity(3); // Gravity.LEFT
        expect(textView.getGravityState()).assertEqual(0); // TextAlign.Start
      });

      it('should handle CENTER gravity', () => {
        textView.setGravity(17); // Gravity.CENTER
        expect(textView.getGravityState()).assertEqual(1); // TextAlign.Center
      });

      it('should handle RIGHT gravity', () => {
        textView.setGravity(5); // Gravity.RIGHT
        expect(textView.getGravityState()).assertEqual(2); // TextAlign.End
      });

      it('should handle END gravity', () => {
        textView.setGravity(8388613); // Gravity.END
        expect(textView.getGravityState()).assertEqual(2); // TextAlign.End
      });

      it('should handle CENTER_HORIZONTAL', () => {
        textView.setGravity(1); // Gravity.CENTER_HORIZONTAL
        expect(textView.getGravityState()).assertEqual(1); // TextAlign.Center
      });
    });

    describe('TypedValue Constants', () => {
      it('should have correct unit constants', () => {
        expect(TypedValue.COMPLEX_UNIT_PX).assertEqual(0);
        expect(TypedValue.COMPLEX_UNIT_DIP).assertEqual(1);
        expect(TypedValue.COMPLEX_UNIT_SP).assertEqual(2);
        expect(TypedValue.COMPLEX_UNIT_PT).assertEqual(3);
        expect(TypedValue.COMPLEX_UNIT_IN).assertEqual(4);
        expect(TypedValue.COMPLEX_UNIT_MM).assertEqual(5);
      });
    });
  });
}
