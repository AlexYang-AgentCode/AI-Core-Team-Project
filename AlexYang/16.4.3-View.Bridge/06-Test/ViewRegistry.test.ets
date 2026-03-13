/**
 * ViewRegistry.test.ets
 *
 * Unit tests for ViewRegistry - Android View ID to proxy mapping.
 */

import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { ViewRegistry } from '../05-Implementation/registry/ViewRegistry';

export default function viewRegistryTest() {
  describe('ViewRegistry Tests', () => {
    let registry: ViewRegistry;

    beforeEach(() => {
      registry = ViewRegistry.getInstance();
      registry.clear();
    });

    describe('Singleton Pattern', () => {
      it('should return same instance', () => {
        const instance1 = ViewRegistry.getInstance();
        const instance2 = ViewRegistry.getInstance();
        expect(instance1).assertEqual(instance2);
      });
    });

    describe('TextView Proxy', () => {
      it('should create TextView proxy', () => {
        const proxy = registry.getTextViewProxy(1001);
        expect(proxy).assertNotNull();
        expect(proxy.getId()).assertEqual(1001);
      });

      it('should return same proxy for same ID', () => {
        const proxy1 = registry.getTextViewProxy(1001);
        const proxy2 = registry.getTextViewProxy(1001);
        expect(proxy1).assertEqual(proxy2);
      });

      it('should find TextView via findViewById', () => {
        const created = registry.getTextViewProxy(1001);
        const found = registry.findViewById(1001, 'TextView');
        expect(found).assertNotNull();
        expect(found!.getId()).assertEqual(1001);
      });
    });

    describe('Button Proxy', () => {
      it('should create Button proxy', () => {
        const proxy = registry.getButtonProxy(2001);
        expect(proxy).assertNotNull();
        expect(proxy.getId()).assertEqual(2001);
      });

      it('should find Button via findViewById', () => {
        registry.getButtonProxy(2001);
        const found = registry.findViewById(2001, 'Button');
        expect(found).assertNotNull();
      });
    });

    describe('EditText Proxy', () => {
      it('should create EditText proxy', () => {
        const proxy = registry.getEditTextProxy(3001);
        expect(proxy).assertNotNull();
        expect(proxy.getId()).assertEqual(3001);
      });

      it('should find EditText via findViewById', () => {
        registry.getEditTextProxy(3001);
        const found = registry.findViewById(3001, 'EditText');
        expect(found).assertNotNull();
      });
    });

    describe('TextClock Proxy', () => {
      it('should create TextClock proxy', () => {
        const proxy = registry.getTextClockProxy(4001);
        expect(proxy).assertNotNull();
        expect(proxy.getId()).assertEqual(4001);
      });

      it('should find TextClock via findViewById', () => {
        registry.getTextClockProxy(4001);
        const found = registry.findViewById(4001, 'TextClock');
        expect(found).assertNotNull();
      });
    });

    describe('LinearLayout Proxy', () => {
      it('should create LinearLayout proxy', () => {
        const proxy = registry.getLinearLayoutProxy(5001);
        expect(proxy).assertNotNull();
        expect(proxy.getId()).assertEqual(5001);
      });

      it('should find LinearLayout via findViewById', () => {
        registry.getLinearLayoutProxy(5001);
        const found = registry.findViewById(5001, 'LinearLayout');
        expect(found).assertNotNull();
      });
    });

    describe('RelativeLayout Proxy', () => {
      it('should create RelativeLayout proxy', () => {
        const proxy = registry.getRelativeLayoutProxy(6001);
        expect(proxy).assertNotNull();
        expect(proxy.getId()).assertEqual(6001);
      });

      it('should find RelativeLayout via findViewById', () => {
        registry.getRelativeLayoutProxy(6001);
        const found = registry.findViewById(6001, 'RelativeLayout');
        expect(found).assertNotNull();
      });
    });

    describe('FrameLayout Proxy', () => {
      it('should create FrameLayout proxy', () => {
        const proxy = registry.getFrameLayoutProxy(7001);
        expect(proxy).assertNotNull();
        expect(proxy.getId()).assertEqual(7001);
      });

      it('should find FrameLayout via findViewById', () => {
        registry.getFrameLayoutProxy(7001);
        const found = registry.findViewById(7001, 'FrameLayout');
        expect(found).assertNotNull();
      });
    });

    describe('ImageView Proxy', () => {
      it('should create ImageView proxy', () => {
        const proxy = registry.getImageViewProxy(8001);
        expect(proxy).assertNotNull();
        expect(proxy.getId()).assertEqual(8001);
      });

      it('should find ImageView via findViewById', () => {
        registry.getImageViewProxy(8001);
        const found = registry.findViewById(8001, 'ImageView');
        expect(found).assertNotNull();
      });
    });

    describe('CheckBox Proxy', () => {
      it('should create CheckBox proxy', () => {
        const proxy = registry.getCheckBoxProxy(9001);
        expect(proxy).assertNotNull();
        expect(proxy.getId()).assertEqual(9001);
      });

      it('should find CheckBox via findViewById', () => {
        registry.getCheckBoxProxy(9001);
        const found = registry.findViewById(9001, 'CheckBox');
        expect(found).assertNotNull();
      });
    });

    describe('Unknown View Type', () => {
      it('should return null for unknown view type', () => {
        const found = registry.findViewById(9999, 'UnknownType');
        expect(found).assertNull();
      });
    });

    describe('Clear Registry', () => {
      it('should clear all proxies', () => {
        registry.getTextViewProxy(1001);
        registry.getButtonProxy(2001);
        expect(registry.findViewById(1001, 'TextView')).assertNotNull();

        registry.clear();

        // After clear, getting proxy should create new one
        const newProxy = registry.getTextViewProxy(1001);
        expect(newProxy).assertNotNull();
      });
    });

    describe('Different IDs', () => {
      it('should create different proxies for different IDs', () => {
        const proxy1 = registry.getTextViewProxy(1001);
        const proxy2 = registry.getTextViewProxy(1002);
        expect(proxy1.getId()).assertEqual(1001);
        expect(proxy2.getId()).assertEqual(1002);
        expect(proxy1).assertNotEqual(proxy2);
      });
    });
  });
}
