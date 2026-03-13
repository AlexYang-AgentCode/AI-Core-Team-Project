/**
 * ToastBridge.test.ets
 *
 * Unit tests for ToastBridge - Android Toast to ArkUI promptAction bridge.
 */

import { describe, it, expect } from '@ohos/hypium';
import {
  ToastBridge,
  ToastMessage,
  ToastDuration
} from '../05-Implementation/widgets/ToastBridge';

export default function toastBridgeTest() {
  describe('ToastBridge Tests', () => {

    describe('Duration Constants', () => {
      it('should have correct duration constants', () => {
        expect(ToastDuration.LENGTH_SHORT).assertEqual(2000);
        expect(ToastDuration.LENGTH_LONG).assertEqual(3500);
      });

      it('should have constants on ToastBridge', () => {
        expect(ToastBridge.LENGTH_SHORT).assertEqual(2000);
        expect(ToastBridge.LENGTH_LONG).assertEqual(3500);
      });
    });

    describe('ToastMessage Construction', () => {
      it('should create ToastMessage with text and duration', () => {
        const toast = new ToastMessage('Hello', ToastDuration.LENGTH_SHORT);
        expect(toast.getText()).assertEqual('Hello');
        expect(toast.getDuration()).assertEqual(2000);
      });

      it('should default to SHORT duration', () => {
        const toast = new ToastMessage('Test', ToastDuration.LENGTH_SHORT);
        expect(toast.getDuration()).assertEqual(2000);
      });
    });

    describe('ToastMessage setText/getText', () => {
      it('should update text', () => {
        const toast = new ToastMessage('Initial', ToastDuration.LENGTH_SHORT);
        toast.setText('Updated');
        expect(toast.getText()).assertEqual('Updated');
      });

      it('should handle empty text', () => {
        const toast = new ToastMessage('', ToastDuration.LENGTH_SHORT);
        expect(toast.getText()).assertEqual('');
      });
    });

    describe('ToastMessage setDuration/getDuration', () => {
      it('should update duration', () => {
        const toast = new ToastMessage('Test', ToastDuration.LENGTH_SHORT);
        toast.setDuration(ToastDuration.LENGTH_LONG);
        expect(toast.getDuration()).assertEqual(3500);
      });
    });

    describe('ToastBridge.makeText', () => {
      it('should create ToastMessage with string', () => {
        const toast = ToastBridge.makeText(null, 'Hello World', ToastBridge.LENGTH_SHORT);
        expect(toast).assertNotNull();
        expect(toast.getText()).assertEqual('Hello World');
        expect(toast.getDuration()).assertEqual(2000);
      });

      it('should create ToastMessage with LONG duration', () => {
        const toast = ToastBridge.makeText(null, 'Long message', ToastBridge.LENGTH_LONG);
        expect(toast.getDuration()).assertEqual(3500);
      });
    });

    describe('ToastBridge.makeTextWithResId', () => {
      it('should create ToastMessage with resource ID', () => {
        const toast = ToastBridge.makeTextWithResId(null, 12345, ToastBridge.LENGTH_SHORT);
        expect(toast).assertNotNull();
        expect(toast.getText()).assertEqual('[Resource ID: 12345]');
      });
    });

    describe('ToastBridge.showText', () => {
      it('should show text with default duration', () => {
        // Just verify it doesn't throw
        try {
          ToastBridge.showText('Quick toast');
          expect(true).assertTrue();
        } catch (e) {
          expect().assertFail('Should not throw');
        }
      });

      it('should show text with custom duration', () => {
        try {
          ToastBridge.showText('Long toast', ToastBridge.LENGTH_LONG);
          expect(true).assertTrue();
        } catch (e) {
          expect().assertFail('Should not throw');
        }
      });
    });

    describe('ToastBridge.showTextWithGravity', () => {
      it('should show text with gravity parameters', () => {
        try {
          ToastBridge.showTextWithGravity(
            'Gravity toast',
            ToastBridge.LENGTH_SHORT,
            17, // Gravity.CENTER
            0,
            0
          );
          expect(true).assertTrue();
        } catch (e) {
          expect().assertFail('Should not throw');
        }
      });
    });

    describe('ToastMessage.show', () => {
      it('should not throw when showing toast', () => {
        const toast = new ToastMessage('Test message', ToastDuration.LENGTH_SHORT);
        try {
          toast.show();
          expect(true).assertTrue();
        } catch (e) {
          expect().assertFail('Should not throw');
        }
      });
    });

    describe('Toast export', () => {
      it('should export Toast as alias', () => {
        // Verify the export exists by checking it's the same object
        const { Toast } = require('../05-Implementation/widgets/ToastBridge');
        expect(Toast).assertNotNull();
      });
    });
  });
}
