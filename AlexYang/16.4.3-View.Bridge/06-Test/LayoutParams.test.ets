/**
 * LayoutParams.test.ets
 *
 * Unit tests for LayoutParams - Android ViewGroup LayoutParams implementation.
 */

import { describe, it, expect } from '@ohos/hypium';
import {
  Margin,
  Padding,
  Gravity,
  LayoutParams,
  LinearLayoutParams,
  RelativeLayoutParams,
  FrameLayoutParams,
  DimensionUtils
} from '../05-Implementation/view/LayoutParams';

export default function layoutParamsTest() {
  describe('LayoutParams Tests', () => {

    describe('Margin', () => {
      it('should create with default values', () => {
        const margin = new Margin();
        expect(margin.left).assertEqual(0);
        expect(margin.top).assertEqual(0);
        expect(margin.right).assertEqual(0);
        expect(margin.bottom).assertEqual(0);
      });

      it('should create with custom values', () => {
        const margin = new Margin(10, 20, 30, 40);
        expect(margin.left).assertEqual(10);
        expect(margin.top).assertEqual(20);
        expect(margin.right).assertEqual(30);
        expect(margin.bottom).assertEqual(40);
      });

      it('should create with all() static method', () => {
        const margin = Margin.all(15);
        expect(margin.left).assertEqual(15);
        expect(margin.top).assertEqual(15);
        expect(margin.right).assertEqual(15);
        expect(margin.bottom).assertEqual(15);
      });

      it('should create with horizontal() static method', () => {
        const margin = Margin.horizontal(20, 10);
        expect(margin.left).assertEqual(20);
        expect(margin.right).assertEqual(20);
        expect(margin.top).assertEqual(10);
        expect(margin.bottom).assertEqual(10);
      });

      it('should create with vertical() static method', () => {
        const margin = Margin.vertical(20, 10);
        expect(margin.top).assertEqual(20);
        expect(margin.bottom).assertEqual(20);
        expect(margin.left).assertEqual(10);
        expect(margin.right).assertEqual(10);
      });

      it('should create with only() static method', () => {
        const margin = Margin.only({ left: 10, right: 20 });
        expect(margin.left).assertEqual(10);
        expect(margin.right).assertEqual(20);
        expect(margin.top).assertEqual(0);
        expect(margin.bottom).assertEqual(0);
      });
    });

    describe('Padding', () => {
      it('should create with default values', () => {
        const padding = new Padding();
        expect(padding.left).assertEqual(0);
        expect(padding.top).assertEqual(0);
        expect(padding.right).assertEqual(0);
        expect(padding.bottom).assertEqual(0);
      });

      it('should create with custom values', () => {
        const padding = new Padding(5, 10, 15, 20);
        expect(padding.left).assertEqual(5);
        expect(padding.top).assertEqual(10);
        expect(padding.right).assertEqual(15);
        expect(padding.bottom).assertEqual(20);
      });

      it('should create with all() static method', () => {
        const padding = Padding.all(12);
        expect(padding.left).assertEqual(12);
        expect(padding.top).assertEqual(12);
        expect(padding.right).assertEqual(12);
        expect(padding.bottom).assertEqual(12);
      });
    });

    describe('Gravity', () => {
      it('should have basic direction constants', () => {
        expect(Gravity.LEFT).assertEqual(0x01);
        expect(Gravity.TOP).assertEqual(0x02);
        expect(Gravity.RIGHT).assertEqual(0x04);
        expect(Gravity.BOTTOM).assertEqual(0x08);
      });

      it('should have center constants', () => {
        expect(Gravity.CENTER).assertEqual(0x11);
        expect(Gravity.CENTER_VERTICAL).assertEqual(0x10);
        expect(Gravity.CENTER_HORIZONTAL).assertEqual(0x01);
      });

      it('should have fill constants', () => {
        expect(Gravity.FILL).assertEqual(0x77);
        expect(Gravity.FILL_VERTICAL).assertEqual(0x70);
        expect(Gravity.FILL_HORIZONTAL).assertEqual(0x07);
      });

      it('should have RTL constants', () => {
        expect(Gravity.START).assertEqual(0x00800001);
        expect(Gravity.END).assertEqual(0x00800003);
      });

      it('should correctly check has() method', () => {
        const gravity = Gravity.CENTER; // 0x11 = CENTER_VERTICAL | CENTER_HORIZONTAL
        expect(Gravity.has(gravity, Gravity.CENTER_VERTICAL)).assertTrue();
        expect(Gravity.has(gravity, Gravity.CENTER_HORIZONTAL)).assertTrue();
        expect(Gravity.has(gravity, Gravity.TOP)).assertFalse();
      });

      it('should get horizontal component', () => {
        const gravity = Gravity.LEFT | Gravity.TOP;
        const horizontal = Gravity.getHorizontal(gravity);
        expect(horizontal).assertEqual(Gravity.LEFT);
      });

      it('should get vertical component', () => {
        const gravity = Gravity.LEFT | Gravity.TOP;
        const vertical = Gravity.getVertical(gravity);
        expect(vertical).assertEqual(Gravity.TOP);
      });
    });

    describe('LayoutParams Base', () => {
      it('should default to WRAP_CONTENT', () => {
        const params = new LayoutParams();
        expect(params.width).assertEqual(LayoutParams.WRAP_CONTENT);
        expect(params.height).assertEqual(LayoutParams.WRAP_CONTENT);
      });

      it('should create with custom dimensions', () => {
        const params = new LayoutParams(100, 200);
        expect(params.width).assertEqual(100);
        expect(params.height).assertEqual(200);
      });

      it('should have MATCH_PARENT constant', () => {
        expect(LayoutParams.MATCH_PARENT).assertEqual(-1);
      });

      it('should have WRAP_CONTENT constant', () => {
        expect(LayoutParams.WRAP_CONTENT).assertEqual(-2);
      });

      it('should check MATCH_PARENT correctly', () => {
        const params = new LayoutParams(LayoutParams.MATCH_PARENT, 100);
        expect(params.isMatchParent('width')).assertTrue();
        expect(params.isMatchParent('height')).assertFalse();
      });

      it('should check WRAP_CONTENT correctly', () => {
        const params = new LayoutParams(100, LayoutParams.WRAP_CONTENT);
        expect(params.isWrapContent('width')).assertFalse();
        expect(params.isWrapContent('height')).assertTrue();
      });
    });

    describe('LinearLayoutParams', () => {
      it('should create with default weight 0', () => {
        const params = new LinearLayoutParams();
        expect(params.weight).assertEqual(0);
      });

      it('should create with custom weight', () => {
        const params = new LinearLayoutParams(100, 100, 1.5);
        expect(params.weight).assertEqual(1.5);
      });

      it('should inherit from LayoutParams', () => {
        const params = new LinearLayoutParams();
        expect(params.width).assertEqual(LayoutParams.WRAP_CONTENT);
        expect(params.height).assertEqual(LayoutParams.WRAP_CONTENT);
      });

      it('should have default gravity', () => {
        const params = new LinearLayoutParams();
        expect(params.gravity).assertEqual(Gravity.TOP | Gravity.START);
      });
    });

    describe('RelativeLayoutParams', () => {
      it('should create with default rules', () => {
        const params = new RelativeLayoutParams();
        expect(params.alignParentTop).assertFalse();
        expect(params.alignParentBottom).assertFalse();
        expect(params.centerInParent).assertFalse();
      });

      it('should set relative rules', () => {
        const params = new RelativeLayoutParams();
        params.above = 1001;
        params.below = 1002;
        params.toLeftOf = 1003;
        params.toRightOf = 1004;

        expect(params.above).assertEqual(1001);
        expect(params.below).assertEqual(1002);
        expect(params.toLeftOf).assertEqual(1003);
        expect(params.toRightOf).assertEqual(1004);
      });

      it('should set alignment rules', () => {
        const params = new RelativeLayoutParams();
        params.centerInParent = true;
        params.centerHorizontal = true;
        params.alignParentLeft = true;

        expect(params.centerInParent).assertTrue();
        expect(params.centerHorizontal).assertTrue();
        expect(params.alignParentLeft).assertTrue();
      });
    });

    describe('FrameLayoutParams', () => {
      it('should create with default gravity', () => {
        const params = new FrameLayoutParams();
        expect(params.gravity).assertEqual(Gravity.TOP | Gravity.START);
      });

      it('should create with custom gravity', () => {
        const params = new FrameLayoutParams(100, 100, Gravity.CENTER);
        expect(params.gravity).assertEqual(Gravity.CENTER);
      });
    });

    describe('DimensionUtils', () => {
      it('should convert dp to px', () => {
        const px = DimensionUtils.dpToPx(10);
        expect(px).assertEqual(30); // 10 * 3.0
      });

      it('should convert px to dp', () => {
        const dp = DimensionUtils.pxToDp(30);
        expect(dp).assertEqual(10); // 30 / 3.0
      });

      it('should convert MATCH_PARENT to percentage', () => {
        const params = new LayoutParams(LayoutParams.MATCH_PARENT, 100);
        expect(DimensionUtils.toArkUIWidth(params)).assertEqual('100%');
      });

      it('should convert WRAP_CONTENT to auto', () => {
        const params = new LayoutParams(LayoutParams.WRAP_CONTENT, 100);
        expect(DimensionUtils.toArkUIWidth(params)).assertEqual('auto');
      });

      it('should return numeric value for fixed size', () => {
        const params = new LayoutParams(200, 100);
        expect(DimensionUtils.toArkUIWidth(params)).assertEqual(200);
        expect(DimensionUtils.toArkUIHeight(params)).assertEqual(100);
      });

      it('should convert Gravity to ArkUI Alignment', () => {
        const result = DimensionUtils.toArkUIAlignment(Gravity.CENTER);
        expect(result.horizontal).assertEqual(2); // Center
        expect(result.vertical).assertEqual(2);   // Center
      });

      it('should convert left gravity to start alignment', () => {
        const result = DimensionUtils.toArkUIAlignment(Gravity.LEFT | Gravity.TOP);
        expect(result.horizontal).assertEqual(0); // Start
        expect(result.vertical).assertEqual(0);   // Top
      });

      it('should convert right gravity to end alignment', () => {
        const result = DimensionUtils.toArkUIAlignment(Gravity.RIGHT | Gravity.TOP);
        expect(result.horizontal).assertEqual(1); // End
        expect(result.vertical).assertEqual(0);   // Top
      });

      it('should convert bottom gravity correctly', () => {
        const result = DimensionUtils.toArkUIAlignment(Gravity.LEFT | Gravity.BOTTOM);
        expect(result.horizontal).assertEqual(0); // Start
        expect(result.vertical).assertEqual(1);   // Bottom
      });
    });
  });
}
