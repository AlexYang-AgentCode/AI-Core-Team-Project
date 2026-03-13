/**
 * __tests__/SystemColors.test.ts
 * SystemColors单元测试
 */

import { Color } from '../utils/SystemColors';

describe('SystemColors', () => {
  describe('基本颜色常量', () => {
    test('BLACK应为0xFF000000', () => {
      expect(Color.BLACK).toBe(0xFF000000);
    });

    test('WHITE应为0xFFFFFFFF', () => {
      expect(Color.WHITE).toBe(0xFFFFFFFF);
    });

    test('RED应为0xFFFF0000', () => {
      expect(Color.RED).toBe(0xFFFF0000);
    });

    test('GREEN应为0xFF00FF00', () => {
      expect(Color.GREEN).toBe(0xFF00FF00);
    });

    test('BLUE应为0xFF0000FF', () => {
      expect(Color.BLUE).toBe(0xFF0000FF);
    });

    test('TRANSPARENT应为0x00000000', () => {
      expect(Color.TRANSPARENT).toBe(0x00000000);
    });
  });

  describe('Holo主题颜色', () => {
    test('HOLO_RED_LIGHT应定义', () => {
      expect(Color.HOLO_RED_LIGHT).toBeDefined();
    });

    test('HOLO_BLUE_LIGHT应定义', () => {
      expect(Color.HOLO_BLUE_LIGHT).toBeDefined();
    });
  });

  describe('toArgbString', () => {
    test('BLACK应转换为#000000', () => {
      expect(Color.toArgbString(Color.BLACK)).toBe('#000000');
    });

    test('WHITE应转换为#FFFFFF', () => {
      expect(Color.toArgbString(Color.WHITE)).toBe('#FFFFFF');
    });

    test('RED应转换为#FF0000', () => {
      expect(Color.toArgbString(Color.RED)).toBe('#FF0000');
    });

    test('半透明红色应包含Alpha', () => {
      const semiRed = 0x80FF0000;
      expect(Color.toArgbString(semiRed)).toBe('#80FF0000');
    });
  });

  describe('parseColor', () => {
    test('应解析#RGB格式', () => {
      expect(Color.parseColor('#F00')).toBe(Color.RED);
    });

    test('应解析#RRGGBB格式', () => {
      expect(Color.parseColor('#FF0000')).toBe(Color.RED);
    });

    test('应解析#AARRGGBB格式', () => {
      const semiRed = 0x80FF0000;
      expect(Color.parseColor('#80FF0000')).toBe(semiRed);
    });

    test('无#前缀应正常解析', () => {
      expect(Color.parseColor('FF0000')).toBe(Color.RED);
    });

    test('无效格式应抛出错误', () => {
      expect(() => Color.parseColor('not a color')).toThrow();
    });
  });

  describe('通道提取', () => {
    test('alpha: 半透明红色应返回128', () => {
      const semiRed = 0x80FF0000;
      expect(Color.alpha(semiRed)).toBe(128);
    });

    test('red: RED应返回255', () => {
      expect(Color.red(Color.RED)).toBe(255);
    });

    test('green: GREEN应返回255', () => {
      expect(Color.green(Color.GREEN)).toBe(255);
    });

    test('blue: BLUE应返回255', () => {
      expect(Color.blue(Color.BLUE)).toBe(255);
    });
  });

  describe('setAlpha', () => {
    test('应设置Alpha通道', () => {
      const semiRed = Color.setAlpha(Color.RED, 128);
      expect(Color.alpha(semiRed)).toBe(128);
      expect(Color.red(semiRed)).toBe(255);
    });
  });

  describe('blend', () => {
    test('混合黑色和白色应产生灰色', () => {
      const gray = Color.blend(Color.BLACK, Color.WHITE, 0.5);
      expect(Color.red(gray)).toBe(128);
      expect(Color.green(gray)).toBe(128);
      expect(Color.blue(gray)).toBe(128);
    });
  });

  describe('darker', () => {
    test('变暗红色', () => {
      const darkerRed = Color.darker(Color.RED, 0.5);
      expect(Color.red(darkerRed)).toBe(128);
    });
  });

  describe('lighter', () => {
    test('变亮红色', () => {
      const lighterRed = Color.lighter(Color.RED, 0.5);
      expect(Color.red(lighterRed)).toBe(255);
    });
  });

  describe('getColorName', () => {
    test('应返回BLACK的颜色名', () => {
      expect(Color.getColorName(Color.BLACK)).toBe('BLACK');
    });

    test('未知颜色应返回null', () => {
      expect(Color.getColorName(0x12345678)).toBeNull();
    });
  });
});
