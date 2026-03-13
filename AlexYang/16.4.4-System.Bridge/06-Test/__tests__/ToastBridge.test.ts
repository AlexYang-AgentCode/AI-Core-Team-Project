/**
 * __tests__/ToastBridge.test.ts
 * ToastBridge单元测试
 */

import { Toast } from '../bridges/ToastBridge';

describe('ToastBridge', () => {
  // 模拟promptAction
  const mockShowToast = jest.fn();
  
  beforeEach(() => {
    jest.clearAllMocks();
    // 在实际鸿蒙环境中，promptAction由系统提供
    // 这里使用mock进行测试
  });

  describe('常量定义', () => {
    test('LENGTH_SHORT应为2000ms', () => {
      expect(Toast.LENGTH_SHORT).toBe(2000);
    });

    test('LENGTH_LONG应为3500ms', () => {
      expect(Toast.LENGTH_LONG).toBe(3500);
    });
  });

  describe('makeText工厂方法', () => {
    test('应创建Toast实例', () => {
      const toast = Toast.makeText(null, 'Test message', Toast.LENGTH_SHORT);
      expect(toast).toBeInstanceOf(Toast);
    });

    test('应存储消息内容', () => {
      const toast = Toast.makeText(null, 'Hello World', Toast.LENGTH_SHORT);
      expect(toast.getMessage()).toBe('Hello World');
    });

    test('应存储显示时长', () => {
      const toast = Toast.makeText(null, 'Test', Toast.LENGTH_LONG);
      expect(toast.getDuration()).toBe(3500);
    });

    test('应支持Resource类型消息', () => {
      const resource = { toString: () => 'Resource String' };
      const toast = Toast.makeText(null, resource as any, Toast.LENGTH_SHORT);
      expect(toast.getMessage()).toBe('Resource String');
    });
  });

  describe('setText方法', () => {
    test('应能更新消息内容', () => {
      const toast = Toast.makeText(null, 'Original', Toast.LENGTH_SHORT);
      toast.setText('Updated');
      expect(toast.getMessage()).toBe('Updated');
    });
  });

  describe('setDuration方法', () => {
    test('应能更新显示时长', () => {
      const toast = Toast.makeText(null, 'Test', Toast.LENGTH_SHORT);
      toast.setDuration(Toast.LENGTH_LONG);
      expect(toast.getDuration()).toBe(3500);
    });
  });

  describe('静态show方法', () => {
    test('应显示短时长Toast', () => {
      // 注意：实际测试需要mock promptAction
      // 这里仅测试方法存在性
      expect(typeof Toast.show).toBe('function');
    });
  });
});
