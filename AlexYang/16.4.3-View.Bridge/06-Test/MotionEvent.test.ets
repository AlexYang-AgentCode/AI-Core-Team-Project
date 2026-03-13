/**
 * MotionEvent.test.ets
 *
 * Unit tests for MotionEvent - Complete Android MotionEvent implementation.
 */

import { describe, it, expect } from '@ohos/hypium';
import {
  MotionEvent,
  PointerProperties,
  PointerCoords,
  MotionEventActions,
  MotionEventAxis,
  MotionEventToolType,
  MotionEventButtonState
} from '../05-Implementation/widgets/MotionEvent';

export default function motionEventTest() {
  describe('MotionEvent Tests', () => {

    describe('Action Constants', () => {
      it('should have correct action constants', () => {
        expect(MotionEventActions.ACTION_DOWN).assertEqual(0);
        expect(MotionEventActions.ACTION_UP).assertEqual(1);
        expect(MotionEventActions.ACTION_MOVE).assertEqual(2);
        expect(MotionEventActions.ACTION_CANCEL).assertEqual(3);
        expect(MotionEventActions.ACTION_OUTSIDE).assertEqual(4);
        expect(MotionEventActions.ACTION_POINTER_DOWN).assertEqual(5);
        expect(MotionEventActions.ACTION_POINTER_UP).assertEqual(6);
      });

      it('should have correct action masks', () => {
        expect(MotionEventActions.ACTION_MASK).assertEqual(0xff);
        expect(MotionEventActions.ACTION_POINTER_INDEX_MASK).assertEqual(0xff00);
      });
    });

    describe('Tool Type Constants', () => {
      it('should have correct tool type constants', () => {
        expect(MotionEventToolType.TOOL_TYPE_UNKNOWN).assertEqual(0);
        expect(MotionEventToolType.TOOL_TYPE_FINGER).assertEqual(1);
        expect(MotionEventToolType.TOOL_TYPE_STYLUS).assertEqual(2);
        expect(MotionEventToolType.TOOL_TYPE_MOUSE).assertEqual(3);
      });
    });

    describe('Button State Constants', () => {
      it('should have correct button state constants', () => {
        expect(MotionEventButtonState.BUTTON_PRIMARY).assertEqual(1);
        expect(MotionEventButtonState.BUTTON_SECONDARY).assertEqual(2);
        expect(MotionEventButtonState.BUTTON_TERTIARY).assertEqual(4);
      });
    });

    describe('PointerProperties', () => {
      it('should create with default values', () => {
        const props = new PointerProperties();
        expect(props.id).assertEqual(0);
        expect(props.toolType).assertEqual(MotionEventToolType.TOOL_TYPE_FINGER);
      });

      it('should create with custom values', () => {
        const props = new PointerProperties(5, MotionEventToolType.TOOL_TYPE_STYLUS);
        expect(props.id).assertEqual(5);
        expect(props.toolType).assertEqual(MotionEventToolType.TOOL_TYPE_STYLUS);
      });

      it('should copy from another properties', () => {
        const props1 = new PointerProperties(10, MotionEventToolType.TOOL_TYPE_MOUSE);
        const props2 = new PointerProperties();
        props2.copyFrom(props1);
        expect(props2.id).assertEqual(10);
        expect(props2.toolType).assertEqual(MotionEventToolType.TOOL_TYPE_MOUSE);
      });
    });

    describe('PointerCoords', () => {
      it('should have default values', () => {
        const coords = new PointerCoords();
        expect(coords.x).assertEqual(0);
        expect(coords.y).assertEqual(0);
        expect(coords.pressure).assertEqual(1.0);
      });

      it('should clear values', () => {
        const coords = new PointerCoords();
        coords.x = 100;
        coords.y = 200;
        coords.clear();
        expect(coords.x).assertEqual(0);
        expect(coords.y).assertEqual(0);
      });

      it('should get axis values', () => {
        const coords = new PointerCoords();
        coords.x = 50;
        coords.y = 100;
        coords.pressure = 0.5;

        expect(coords.getAxisValue(MotionEventAxis.AXIS_X)).assertEqual(50);
        expect(coords.getAxisValue(MotionEventAxis.AXIS_Y)).assertEqual(100);
        expect(coords.getAxisValue(MotionEventAxis.AXIS_PRESSURE)).assertEqual(0.5);
      });

      it('should set axis values', () => {
        const coords = new PointerCoords();
        coords.setAxisValue(MotionEventAxis.AXIS_X, 75);
        coords.setAxisValue(MotionEventAxis.AXIS_SIZE, 0.8);

        expect(coords.x).assertEqual(75);
        expect(coords.size).assertEqual(0.8);
      });
    });

    describe('MotionEvent Creation', () => {
      it('should create with obtain factory method', () => {
        const event = MotionEvent.obtain(
          1000, // downTime
          2000, // eventTime
          MotionEventActions.ACTION_DOWN,
          100,  // x
          200,  // y
          0     // metaState
        );

        expect(event.getAction()).assertEqual(MotionEventActions.ACTION_DOWN);
        expect(event.getX()).assertEqual(100);
        expect(event.getY()).assertEqual(200);
      });

      it('should calculate action masked correctly', () => {
        const action = MotionEventActions.ACTION_POINTER_DOWN |
                       (1 << MotionEventActions.ACTION_POINTER_INDEX_SHIFT);
        const props = new PointerProperties();
        const coords = new PointerCoords();

        const event = new MotionEvent(
          0, 0, action, 2, [props, props], [coords, coords],
          0, 0, 0, 0, 0, 0, 0, 0
        );

        expect(event.getActionMasked()).assertEqual(MotionEventActions.ACTION_POINTER_DOWN);
        expect(event.getActionIndex()).assertEqual(1);
      });
    });

    describe('MotionEvent Timing', () => {
      it('should store and return times', () => {
        const event = MotionEvent.obtain(1000, 2000, MotionEventActions.ACTION_DOWN, 0, 0);
        expect(event.getDownTime()).assertEqual(1000);
        expect(event.getEventTime()).assertEqual(2000);
        expect(event.getEventTimeDelta()).assertEqual(1000);
      });
    });

    describe('MotionEvent Coordinates', () => {
      it('should return correct coordinates', () => {
        const event = MotionEvent.obtain(0, 0, MotionEventActions.ACTION_DOWN, 50, 75);
        expect(event.getX()).assertEqual(50);
        expect(event.getY()).assertEqual(75);
        expect(event.getRawX()).assertEqual(50);
        expect(event.getRawY()).assertEqual(75);
      });

      it('should apply coordinate offset', () => {
        const event = MotionEvent.obtain(0, 0, MotionEventActions.ACTION_DOWN, 100, 100);
        event.setLocation(10, 20);
        expect(event.getX()).assertEqual(110);
        expect(event.getY()).assertEqual(120);
      });
    });

    describe('MotionEvent Action to String', () => {
      it('should convert ACTION_DOWN to string', () => {
        const event = MotionEvent.obtain(0, 0, MotionEventActions.ACTION_DOWN, 0, 0);
        expect(event.actionToString(MotionEventActions.ACTION_DOWN)).assertEqual('ACTION_DOWN');
      });

      it('should convert ACTION_MOVE to string', () => {
        const event = MotionEvent.obtain(0, 0, MotionEventActions.ACTION_MOVE, 0, 0);
        expect(event.actionToString(MotionEventActions.ACTION_MOVE)).assertEqual('ACTION_MOVE');
      });

      it('should handle unknown action', () => {
        const event = MotionEvent.obtain(0, 0, 999, 0, 0);
        expect(event.actionToString(999)).assertEqual('ACTION_999');
      });

      it('should have correct toString format', () => {
        const event = MotionEvent.obtain(0, 100, MotionEventActions.ACTION_DOWN, 50, 75);
        const str = event.toString();
        expect(str.includes('ACTION_DOWN')).assertTrue();
        expect(str.includes('x=50')).assertTrue();
        expect(str.includes('y=75')).assertTrue();
      });
    });

    describe('Recycle', () => {
      it('should not throw when recycled', () => {
        const event = MotionEvent.obtain(0, 0, MotionEventActions.ACTION_DOWN, 0, 0);
        event.recycle(); // Should be no-op
        expect(true).assertTrue();
      });
    });
  });
}
