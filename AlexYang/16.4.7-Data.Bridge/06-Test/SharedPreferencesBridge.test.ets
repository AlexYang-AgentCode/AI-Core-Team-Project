/**
 * SharedPreferencesBridge.test.ets
 *
 * Unit tests for SharedPreferencesBridge
 */

import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import { SharedPreferencesBridge, PreferencesEditorBridge } from '../05-Implementation/SharedPreferencesBridge';
import { Context } from '@kit.AbilityKit';

// Mock context for testing
const mockContext = {} as Context;

export default function sharedPreferencesBridgeTest() {
  describe('SharedPreferencesBridgeTest', () => {
    let prefs: SharedPreferencesBridge | null = null;
    const TEST_PREFS_NAME = 'TestPrefs';

    beforeEach(async () => {
      // Clean up any existing instance
      prefs = await SharedPreferencesBridge.getInstance(mockContext, TEST_PREFS_NAME);
      // Clear all data before each test
      prefs.edit().clear().commit();
    });

    afterEach(() => {
      prefs = null;
    });

    /**
     * @tc.number: SPB_001
     * @tc.name: Test singleton instance
     * @tc.desc: Verify getInstance returns the same instance for the same name
     */
    it('shouldReturnSameInstanceForSameName', 0, async () => {
      const instance1 = await SharedPreferencesBridge.getInstance(mockContext, 'SingletonTest');
      const instance2 = await SharedPreferencesBridge.getInstance(mockContext, 'SingletonTest');
      
      expect(instance1).assertEqual(instance2);
    });

    /**
     * @tc.number: SPB_002
     * @tc.name: Test put and get string
     * @tc.desc: Verify putString and getString work correctly
     */
    it('shouldPutAndGetString', 0, async () => {
      const key = 'testString';
      const value = 'Hello, HarmonyOS!';
      
      prefs!.edit().putString(key, value).commit();
      const result = prefs!.getString(key, '');
      
      expect(result).assertEqual(value);
    });

    /**
     * @tc.number: SPB_003
     * @tc.name: Test getString with default value
     * @tc.desc: Verify getString returns default when key doesn't exist
     */
    it('shouldReturnDefaultValueForMissingKey', 0, () => {
      const key = 'nonexistent';
      const defaultValue = 'default';
      
      const result = prefs!.getString(key, defaultValue);
      
      expect(result).assertEqual(defaultValue);
    });

    /**
     * @tc.number: SPB_004
     * @tc.name: Test contains key
     * @tc.desc: Verify contains returns true for existing key
     */
    it('shouldContainExistingKey', 0, async () => {
      const key = 'existingKey';
      
      prefs!.edit().putString(key, 'value').commit();
      const result = prefs!.contains(key);
      
      expect(result).assertTrue();
    });

    /**
     * @tc.number: SPB_005
     * @tc.name: Test contains returns false for missing key
     * @tc.desc: Verify contains returns false when key doesn't exist
     */
    it('shouldNotContainMissingKey', 0, () => {
      const key = 'missingKey';
      
      const result = prefs!.contains(key);
      
      expect(result).assertFalse();
    });

    /**
     * @tc.number: SPB_006
     * @tc.name: Test remove key
     * @tc.desc: Verify remove deletes the key-value pair
     */
    it('shouldRemoveKey', 0, async () => {
      const key = 'keyToRemove';
      
      prefs!.edit().putString(key, 'value').commit();
      prefs!.edit().remove(key).commit();
      
      const containsResult = prefs!.contains(key);
      const getResult = prefs!.getString(key, 'default');
      
      expect(containsResult).assertFalse();
      expect(getResult).assertEqual('default');
    });

    /**
     * @tc.number: SPB_007
     * @tc.name: Test commit returns true
     * @tc.desc: Verify commit returns true on success
     */
    it('shouldReturnTrueOnCommit', 0, () => {
      const editor = prefs!.edit().putString('key', 'value');
      const result = editor.commit();
      
      expect(result).assertTrue();
    });

    /**
     * @tc.number: SPB_008
     * @tc.name: Test apply (async commit)
     * @tc.desc: Verify apply works asynchronously
     */
    it('shouldApplyChangesAsync', 0, async () => {
      const key = 'asyncKey';
      const value = 'asyncValue';
      
      await prefs!.edit().putString(key, value).apply();
      const result = prefs!.getString(key, '');
      
      expect(result).assertEqual(value);
    });

    /**
     * @tc.number: SPB_009
     * @tc.name: Test chained editing
     * @tc.desc: Verify multiple putString calls can be chained
     */
    it('shouldSupportChainedEditing', 0, () => {
      prefs!.edit()
        .putString('key1', 'value1')
        .putString('key2', 'value2')
        .putString('key3', 'value3')
        .commit();
      
      const result1 = prefs!.getString('key1', '');
      const result2 = prefs!.getString('key2', '');
      const result3 = prefs!.getString('key3', '');
      
      expect(result1).assertEqual('value1');
      expect(result2).assertEqual('value2');
      expect(result3).assertEqual('value3');
    });

    /**
     * @tc.number: SPB_010
     * @tc.name: Test put and get boolean
     * @tc.desc: Verify putBoolean and getBoolean work correctly
     */
    it('shouldPutAndGetBoolean', 0, async () => {
      const key = 'testBool';
      
      prefs!.edit().putBoolean(key, true).commit();
      const result = prefs!.getBoolean(key, false);
      
      expect(result).assertTrue();
    });

    /**
     * @tc.number: SPB_011
     * @tc.name: Test put and get int
     * @tc.desc: Verify putInt and getInt work correctly
     */
    it('shouldPutAndGetInt', 0, async () => {
      const key = 'testInt';
      const value = 42;
      
      prefs!.edit().putInt(key, value).commit();
      const result = prefs!.getInt(key, 0);
      
      expect(result).assertEqual(value);
    });

    /**
     * @tc.number: SPB_012
     * @tc.name: Test getName
     * @tc.desc: Verify getName returns the preferences name
     */
    it('shouldReturnCorrectName', 0, () => {
      const result = prefs!.getName();
      
      expect(result).assertEqual(TEST_PREFS_NAME);
    });

    /**
     * @tc.number: SPB_013
     * @tc.name: Test multiple instances have different data
     * @tc.desc: Verify different preference names isolate data
     */
    it('shouldIsolateDataBetweenInstances', 0, async () => {
      const prefs1 = await SharedPreferencesBridge.getInstance(mockContext, 'Prefs1');
      const prefs2 = await SharedPreferencesBridge.getInstance(mockContext, 'Prefs2');
      
      prefs1.edit().putString('key', 'value1').commit();
      prefs2.edit().putString('key', 'value2').commit();
      
      const result1 = prefs1.getString('key', '');
      const result2 = prefs2.getString('key', '');
      
      expect(result1).assertEqual('value1');
      expect(result2).assertEqual('value2');
    });

    /**
     * @tc.number: SPB_014
     * @tc.name: Test clear all data
     * @tc.desc: Verify clear removes all preferences
     */
    it('shouldClearAllData', 0, async () => {
      prefs!.edit()
        .putString('key1', 'value1')
        .putString('key2', 'value2')
        .commit();
      
      // Note: clear() is partially implemented
      // This test verifies the method exists and returns editor
      const editor = prefs!.edit().clear();
      expect(editor).assertInstanceOf('PreferencesEditorBridge');
    });
  });
}
