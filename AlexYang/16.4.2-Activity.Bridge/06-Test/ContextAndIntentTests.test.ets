/**
 * Context and Intent Unit Tests
 *
 * Tests for Context, Intent, and ComponentName classes.
 */

import { describe, it, expect } from '@ohos/hypium';
import {
  Context,
  Intent,
  ComponentName,
  Bundle,
  RESULT_OK,
  RESULT_CANCELED,
  FLAG_ACTIVITY_NEW_TASK
} from '../ets/content/Context';

export default function contextAndIntentTests() {
  describe('Context and Intent Tests', () => {

    describe('Intent Tests', () => {
      it('should create empty intent', 0, () => {
        const intent = new Intent();
        expect(intent.getAction()).assertEqual('');
      });

      it('should create intent with action', 0, () => {
        const intent = new Intent('android.intent.action.VIEW');
        expect(intent.getAction()).assertEqual('android.intent.action.VIEW');
      });

      it('should set and get action', 0, () => {
        const intent = new Intent();
        intent.setAction('android.intent.action.MAIN');
        expect(intent.getAction()).assertEqual('android.intent.action.MAIN');
      });

      it('should set and get component', 0, () => {
        const intent = new Intent();
        const component = new ComponentName('com.example', 'MainActivity');

        intent.setComponent(component);
        const retrieved = intent.getComponent();

        expect(retrieved?.getPackageName()).assertEqual('com.example');
        expect(retrieved?.getClassName()).assertEqual('MainActivity');
      });

      it('should support method chaining', 0, () => {
        const intent = new Intent();
        const component = new ComponentName('com.example', 'MainActivity');

        const result = intent
          .setAction('android.intent.action.MAIN')
          .setComponent(component);

        expect(result).assertEqual(intent);
        expect(intent.getAction()).assertEqual('android.intent.action.MAIN');
      });

      it('should put and get string extra', 0, () => {
        const intent = new Intent();
        intent.putExtra('key', 'value');
        expect(intent.getStringExtra('key')).assertEqual('value');
      });

      it('should put and get int extra', 0, () => {
        const intent = new Intent();
        intent.putExtra('count', 42);
        expect(intent.getIntExtra('count', 0)).assertEqual(42);
      });

      it('should put and get boolean extra', 0, () => {
        const intent = new Intent();
        intent.putExtra('enabled', true);
        expect(intent.getBooleanExtra('enabled', false)).assertTrue();
      });

      it('should return default values for missing extras', 0, () => {
        const intent = new Intent();
        expect(intent.getStringExtra('missing')).assertNull();
        expect(intent.getIntExtra('missing', -1)).assertEqual(-1);
        expect(intent.getBooleanExtra('missing', true)).assertTrue();
      });

      it('should get extras bundle', 0, () => {
        const intent = new Intent();
        intent.putExtra('key', 'value');
        const extras = intent.getExtras();
        expect(extras).not().assertNull();
      });
    });

    describe('ComponentName Tests', () => {
      it('should store package and class names', 0, () => {
        const component = new ComponentName('com.example.app', 'MainActivity');
        expect(component.getPackageName()).assertEqual('com.example.app');
        expect(component.getClassName()).assertEqual('MainActivity');
      });

      it('should format as short string', 0, () => {
        const component = new ComponentName('com.example', 'MainActivity');
        const shortString = component.toShortString();
        expect(shortString).assertContain('com.example');
        expect(shortString).assertContain('MainActivity');
      });
    });

    describe('Context Tests', () => {
      it('should have default values for Resources', 0, () => {
        const { Resources } = require('../ets/content/Context');
        const resources = new Resources();
        expect(resources.getString(0)).assertEqual('');
        expect(resources.getColor(0)).assertEqual(0);
        expect(resources.getDimension(0)).assertEqual(0);
      });

      it('should support SharedPreferences operations', 0, () => {
        const { SharedPreferences } = require('../ets/content/Context');
        const prefs = new SharedPreferences('test_prefs');

        prefs.putString('key', 'value');
        expect(prefs.getString('key', null)).assertEqual('value');

        prefs.putInt('count', 42);
        expect(prefs.getInt('count', 0)).assertEqual(42);

        prefs.putBoolean('flag', true);
        expect(prefs.getBoolean('flag', false)).assertTrue();
      });

      it('should return default values from SharedPreferences', 0, () => {
        const { SharedPreferences } = require('../ets/content/Context');
        const prefs = new SharedPreferences('test_prefs');

        expect(prefs.getString('missing', 'default')).assertEqual('default');
        expect(prefs.getInt('missing', -1)).assertEqual(-1);
        expect(prefs.getBoolean('missing', true)).assertTrue();
      });

      it('should commit SharedPreferences', 0, () => {
        const { SharedPreferences } = require('../ets/content/Context');
        const prefs = new SharedPreferences('test_prefs');
        expect(prefs.commit()).assertTrue();
      });
    });

    describe('Intent Constants Tests', () => {
      it('should have correct result constants', 0, () => {
        expect(RESULT_OK).assertEqual(-1);
        expect(RESULT_CANCELED).assertEqual(0);
      });

      it('should have correct flag constants', 0, () => {
        expect(FLAG_ACTIVITY_NEW_TASK).assertEqual(0x10000000);
        expect(FLAG_ACTIVITY_NEW_TASK).assertEqual(268435456);
      });
    });

  });
}
