/**
 * JIT Compiler Interface Unit Tests
 *
 * Tests for JIT compiler integration interfaces.
 */

import { describe, it, expect } from '@ohos/hypium';
import {
  ActivityCompilerInterface,
  ActivityClassRegistry,
  RegistrationBatch
} from '../ets/jit/CompilerInterface';
import { LayoutRegistry } from '../ets/view/LayoutInflater';
import { ViewIdRegistry } from '../ets/view/ViewFinder';

export default function jitCompilerInterfaceTests() {
  describe('JIT Compiler Interface Tests', () => {

    describe('ActivityCompilerInterface Tests', () => {
      it('should initialize without error', 0, () => {
        ActivityCompilerInterface.initialize();
        expect(true).assertTrue();
      });

      it('should register activity class', 0, () => {
        ActivityCompilerInterface.registerActivityClass(
          'com.example.MainActivity',
          'MainAbility',
          'pages/MainPage'
        );

        const info = ActivityClassRegistry.getActivityInfo('com.example.MainActivity');
        expect(info).not().assertNull();
        expect(info?.abilityName).assertEqual('MainAbility');
        expect(info?.pagePath).assertEqual('pages/MainPage');
      });

      it('should register layout mapping', 0, () => {
        ActivityCompilerInterface.registerLayoutMapping(0x7F0A0001, 'pages/HomePage');
        const pagePath = LayoutRegistry.getPagePath(0x7F0A0001);
        expect(pagePath).assertEqual('pages/HomePage');
      });

      it('should register view ID mapping', 0, () => {
        ActivityCompilerInterface.registerViewIdMapping(0x7F050001, 'button_submit');
        const componentId = ViewIdRegistry.getComponentId(0x7F050001);
        expect(componentId).assertEqual('button_submit');
      });

      it('should batch register multiple items', 0, () => {
        const batch: RegistrationBatch = {
          activities: [
            { javaClassName: 'com.example.A', abilityName: 'AbilityA', pagePath: 'pages/A' },
            { javaClassName: 'com.example.B', abilityName: 'AbilityB', pagePath: 'pages/B' }
          ],
          layouts: [
            { id: 0x7F0A0010, pagePath: 'pages/Page1' },
            { id: 0x7F0A0011, pagePath: 'pages/Page2' }
          ],
          viewIds: [
            { id: 0x7F050010, componentId: 'view1' },
            { id: 0x7F050011, componentId: 'view2' }
          ]
        };

        ActivityCompilerInterface.batchRegister(batch);

        expect(ActivityClassRegistry.getAllActivities().length).assertLargerOrEqual(2);
        expect(LayoutRegistry.hasLayout(0x7F0A0010)).assertTrue();
        expect(LayoutRegistry.hasLayout(0x7F0A0011)).assertTrue();
        expect(ViewIdRegistry.hasId(0x7F050010)).assertTrue();
        expect(ViewIdRegistry.hasId(0x7F050011)).assertTrue();
      });

      it('should return version', 0, () => {
        const version = ActivityCompilerInterface.getVersion();
        expect(version).assertEqual('1.0.0');
      });
    });

    describe('ActivityClassRegistry Tests', () => {
      it('should get ability name by class name', 0, () => {
        ActivityClassRegistry.register('com.test.Activity', 'TestAbility', 'pages/Test');
        const abilityName = ActivityClassRegistry.getAbilityName('com.test.Activity');
        expect(abilityName).assertEqual('TestAbility');
      });

      it('should get page path by class name', 0, () => {
        ActivityClassRegistry.register('com.test.Activity2', 'TestAbility2', 'pages/Test2');
        const pagePath = ActivityClassRegistry.getPagePath('com.test.Activity2');
        expect(pagePath).assertEqual('pages/Test2');
      });

      it('should return undefined for unregistered class', 0, () => {
        const abilityName = ActivityClassRegistry.getAbilityName('com.unknown.Activity');
        expect(abilityName).assertUndefined();
      });

      it('should return all registered activities', 0, () => {
        const activities = ActivityClassRegistry.getAllActivities();
        expect(Array.isArray(activities)).assertTrue();
        expect(activities.length).assertLargerOrEqual(0);
      });
    });

    describe('LayoutRegistry Tests', () => {
      it('should check if layout exists', 0, () => {
        LayoutRegistry.register(0x7F0A0100, 'pages/TestLayout');
        expect(LayoutRegistry.hasLayout(0x7F0A0100)).assertTrue();
        expect(LayoutRegistry.hasLayout(0x99999999)).assertFalse();
      });

      it('should get all layouts', 0, () => {
        const layouts = LayoutRegistry.getAllLayouts();
        expect(layouts instanceof Map).assertTrue();
      });
    });

    describe('ViewIdRegistry Tests', () => {
      it('should get all registered IDs', 0, () => {
        const ids = ViewIdRegistry.getAllIds();
        expect(Array.isArray(ids)).assertTrue();
      });
    });

  });
}
