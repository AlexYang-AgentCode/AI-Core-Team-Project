/**
 * ColorBridge.test.ets
 *
 * Unit tests for ColorBridge - Android color integer to ArkUI hex string conversion.
 */

import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { ColorBridge, PorterDuff } from '../05-Implementation/widgets/ColorBridge';

export default function colorBridgeTest() {
  describe('ColorBridge Tests', () => {

    describe('Color Constants', () => {
      it('should have correct color constant values', () => {
        expect(ColorBridge.BLACK).assertEqual(0xFF000000);
        expect(ColorBridge.WHITE).assertEqual(0xFFFFFFFF);
        expect(ColorBridge.RED).assertEqual(0xFFFF0000);
        expect(ColorBridge.GREEN).assertEqual(0xFF00FF00);
        expect(ColorBridge.BLUE).assertEqual(0xFF0000FF);
        expect(ColorBridge.TRANSPARENT).assertEqual(0x00000000);
      });
    });

    describe('toHexString', () => {
      it('should convert black to hex string', () => {
        const result = ColorBridge.toHexString(ColorBridge.BLACK);
        expect(result).assertEqual('#FF000000');
      });

      it('should convert white to hex string', () => {
        const result = ColorBridge.toHexString(ColorBridge.WHITE);
        expect(result).assertEqual('#FFFFFFFF');
      });

      it('should convert red to hex string', () => {
        const result = ColorBridge.toHexString(ColorBridge.RED);
        expect(result).assertEqual('#FFFF0000');
      });

      it('should handle transparent color', () => {
        const result = ColorBridge.toHexString(ColorBridge.TRANSPARENT);
        expect(result).assertEqual('#00000000');
      });

      it('should handle semi-transparent colors', () => {
        const semiRed = 0x80FF0000; // 50% transparent red
        const result = ColorBridge.toHexString(semiRed);
        expect(result).assertEqual('#80FF0000');
      });
    });

    describe('toArkUIColor', () => {
      it('should return short hex for opaque colors', () => {
        const result = ColorBridge.toArkUIColor(ColorBridge.RED);
        expect(result).assertEqual('#FF0000');
      });

      it('should return long hex for transparent colors', () => {
        const semiBlue = 0x800000FF;
        const result = ColorBridge.toArkUIColor(semiBlue);
        expect(result).assertEqual('#800000FF');
      });

      it('should handle white correctly', () => {
        const result = ColorBridge.toArkUIColor(ColorBridge.WHITE);
        expect(result).assertEqual('#FFFFFF');
      });

      it('should handle fully transparent', () => {
        const result = ColorBridge.toArkUIColor(ColorBridge.TRANSPARENT);
        expect(result).assertEqual('#00000000');
      });
    });

    describe('parseColor', () => {
      it('should parse named color "red"', () => {
        const result = ColorBridge.parseColor('red');
        expect(result).assertEqual(ColorBridge.RED);
      });

      it('should parse named color "blue"', () => {
        const result = ColorBridge.parseColor('blue');
        expect(result).assertEqual(ColorBridge.BLUE);
      });

      it('should parse hex #RGB format', () => {
        const result = ColorBridge.parseColor('#F00');
        expect(result).assertEqual(0xFFFF0000);
      });

      it('should parse hex #RRGGBB format', () => {
        const result = ColorBridge.parseColor('#FF0000');
        expect(result).assertEqual(0xFFFF0000);
      });

      it('should parse hex #AARRGGBB format', () => {
        const result = ColorBridge.parseColor('#80FF0000');
        expect(result).assertEqual(0x80FF0000);
      });

      it('should throw error for unknown color', () => {
        try {
          ColorBridge.parseColor('unknown');
          expect().assertFail('Should have thrown error');
        } catch (e) {
          expect(e.message).assertContain('Unknown color');
        }
      });

      it('should throw error for invalid format', () => {
        try {
          ColorBridge.parseColor('#GGG');
          expect().assertFail('Should have thrown error');
        } catch (e) {
          expect(e.message).assertContain('Invalid');
        }
      });
    });

    describe('PorterDuff Modes', () => {
      it('should have correct mode constants', () => {
        expect(PorterDuff.Mode.CLEAR).assertEqual(0);
        expect(PorterDuff.Mode.SRC).assertEqual(1);
        expect(PorterDuff.Mode.DST).assertEqual(2);
        expect(PorterDuff.Mode.SRC_OVER).assertEqual(3);
        expect(PorterDuff.Mode.SRC_ATOP).assertEqual(9);
        expect(PorterDuff.Mode.MULTIPLY).assertEqual(14);
        expect(PorterDuff.Mode.SCREEN).assertEqual(15);
      });
    });

    describe('System Colors', () => {
      it('should contain black system color', () => {
        expect(ColorBridge.SYSTEM_COLORS.has('@android:color/black')).assertTrue();
        expect(ColorBridge.SYSTEM_COLORS.get('@android:color/black')).assertEqual('#000000');
      });

      it('should contain holo blue light', () => {
        expect(ColorBridge.SYSTEM_COLORS.has('@android:color/holo_blue_light')).assertTrue();
      });
    });
  });
}
