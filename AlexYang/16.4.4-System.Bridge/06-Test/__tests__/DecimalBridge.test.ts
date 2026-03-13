/**
 * __tests__/DecimalBridge.test.ts
 * DecimalBridge (BigDecimal)单元测试
 */

import { BigDecimal, RoundingMode } from '../bridges/DecimalBridge';

describe('DecimalBridge', () => {
  describe('构造函数', () => {
    test('应支持字符串参数', () => {
      const bd = new BigDecimal('123.456');
      expect(bd.doubleValue()).toBe(123.456);
    });

    test('应支持数字参数', () => {
      const bd = new BigDecimal(123.456);
      expect(bd.doubleValue()).toBe(123.456);
    });

    test('应支持BigDecimal参数', () => {
      const bd1 = new BigDecimal('123.456');
      const bd2 = new BigDecimal(bd1);
      expect(bd2.doubleValue()).toBe(123.456);
    });

    test('无效字符串应抛出错误', () => {
      expect(() => new BigDecimal('not a number')).toThrow();
    });
  });

  describe('setScale - HALF_UP舍入', () => {
    test('1.5应舍入为2（整数）', () => {
      const bd = new BigDecimal('1.5');
      const result = bd.setScale(0, RoundingMode.HALF_UP);
      expect(result.toPlainString()).toBe('2');
    });

    test('1.4应舍入为1（整数）', () => {
      const bd = new BigDecimal('1.4');
      const result = bd.setScale(0, RoundingMode.HALF_UP);
      expect(result.toPlainString()).toBe('1');
    });

    test('3.14159265应保留8位小数', () => {
      const bd = new BigDecimal('3.14159265358979');
      const result = bd.setScale(8, RoundingMode.HALF_UP);
      expect(result.toPlainString()).toBe('3.14159265');
    });

    test('1.23456789应保留8位小数', () => {
      const bd = new BigDecimal('1.234567891234');
      const result = bd.setScale(8, RoundingMode.HALF_UP);
      expect(result.toPlainString()).toBe('1.23456789');
    });

    test('10应保留8位小数', () => {
      const bd = new BigDecimal('10');
      const result = bd.setScale(8, RoundingMode.HALF_UP);
      expect(result.toPlainString()).toBe('10');
    });
  });

  describe('setScale - 其他舍入模式', () => {
    test('UP模式：1.1应向上舍入为2', () => {
      const bd = new BigDecimal('1.1');
      const result = bd.setScale(0, RoundingMode.UP);
      expect(result.toPlainString()).toBe('2');
    });

    test('DOWN模式：1.9应向下舍入为1', () => {
      const bd = new BigDecimal('1.9');
      const result = bd.setScale(0, RoundingMode.DOWN);
      expect(result.toPlainString()).toBe('1');
    });

    test('CEILING模式：-1.1应向上舍入为-1', () => {
      const bd = new BigDecimal('-1.1');
      const result = bd.setScale(0, RoundingMode.CEILING);
      expect(result.toPlainString()).toBe('-1');
    });

    test('FLOOR模式：-1.1应向下舍入为-2', () => {
      const bd = new BigDecimal('-1.1');
      const result = bd.setScale(0, RoundingMode.FLOOR);
      expect(result.toPlainString()).toBe('-2');
    });

    test('UNNECESSARY模式：1.0应正常返回', () => {
      const bd = new BigDecimal('1.0');
      const result = bd.setScale(0, RoundingMode.UNNECESSARY);
      expect(result.toPlainString()).toBe('1');
    });

    test('UNNECESSARY模式：1.1应抛出错误', () => {
      const bd = new BigDecimal('1.1');
      expect(() => bd.setScale(0, RoundingMode.UNNECESSARY)).toThrow();
    });
  });

  describe('数学运算', () => {
    test('add: 1.5 + 2.5 = 4', () => {
      const bd1 = new BigDecimal('1.5');
      const bd2 = new BigDecimal('2.5');
      const result = bd1.add(bd2);
      expect(result.doubleValue()).toBe(4);
    });

    test('subtract: 5 - 3 = 2', () => {
      const bd1 = new BigDecimal('5');
      const bd2 = new BigDecimal('3');
      const result = bd1.subtract(bd2);
      expect(result.doubleValue()).toBe(2);
    });

    test('multiply: 2.5 * 4 = 10', () => {
      const bd1 = new BigDecimal('2.5');
      const bd2 = new BigDecimal('4');
      const result = bd1.multiply(bd2);
      expect(result.doubleValue()).toBe(10);
    });

    test('divide: 10 / 3 = 3.333', () => {
      const bd1 = new BigDecimal('10');
      const bd2 = new BigDecimal('3');
      const result = bd1.divide(bd2, 3, RoundingMode.HALF_UP);
      expect(result.toPlainString()).toBe('3.333');
    });

    test('divide by zero应返回Infinity', () => {
      const bd1 = new BigDecimal('10');
      const bd2 = new BigDecimal('0');
      const result = bd1.divide(bd2);
      expect(result.doubleValue()).toBe(Infinity);
    });

    test('abs: -5.abs() = 5', () => {
      const bd = new BigDecimal('-5');
      const result = bd.abs();
      expect(result.doubleValue()).toBe(5);
    });

    test('negate: 5.negate() = -5', () => {
      const bd = new BigDecimal('5');
      const result = bd.negate();
      expect(result.doubleValue()).toBe(-5);
    });

    test('remainder: 10 % 3 = 1', () => {
      const bd1 = new BigDecimal('10');
      const bd2 = new BigDecimal('3');
      const result = bd1.remainder(bd2);
      expect(result.doubleValue()).toBe(1);
    });
  });

  describe('比较操作', () => {
    test('compareTo: 5 < 10', () => {
      const bd1 = new BigDecimal('5');
      const bd2 = new BigDecimal('10');
      expect(bd1.compareTo(bd2)).toBe(-1);
    });

    test('compareTo: 10 > 5', () => {
      const bd1 = new BigDecimal('10');
      const bd2 = new BigDecimal('5');
      expect(bd1.compareTo(bd2)).toBe(1);
    });

    test('compareTo: 5 = 5', () => {
      const bd1 = new BigDecimal('5');
      const bd2 = new BigDecimal('5');
      expect(bd1.compareTo(bd2)).toBe(0);
    });

    test('equals: 5 = 5', () => {
      const bd1 = new BigDecimal('5');
      const bd2 = new BigDecimal('5');
      expect(bd1.equals(bd2)).toBe(true);
    });

    test('equals: 5 != 10', () => {
      const bd1 = new BigDecimal('5');
      const bd2 = new BigDecimal('10');
      expect(bd1.equals(bd2)).toBe(false);
    });
  });

  describe('工具方法', () => {
    test('scale: 设置后应正确返回', () => {
      const bd = new BigDecimal('1.23456');
      const scaled = bd.setScale(2, RoundingMode.HALF_UP);
      expect(scaled.scale()).toBe(2);
    });

    test('isZero: 0应为true', () => {
      const bd = new BigDecimal('0');
      expect(bd.isZero()).toBe(true);
    });

    test('isZero: 1应为false', () => {
      const bd = new BigDecimal('1');
      expect(bd.isZero()).toBe(false);
    });

    test('isPositive: 5应为true', () => {
      const bd = new BigDecimal('5');
      expect(bd.isPositive()).toBe(true);
    });

    test('isPositive: -5应为false', () => {
      const bd = new BigDecimal('-5');
      expect(bd.isPositive()).toBe(false);
    });

    test('isNegative: -5应为true', () => {
      const bd = new BigDecimal('-5');
      expect(bd.isNegative()).toBe(true);
    });

    test('intValue: 123.456应返回123', () => {
      const bd = new BigDecimal('123.456');
      expect(bd.intValue()).toBe(123);
    });

    test('isInteger: 123.0应为true', () => {
      const bd = new BigDecimal('123.0');
      expect(bd.isInteger()).toBe(true);
    });
  });

  describe('Calculator关键场景', () => {
    test('1÷3 = 0.33333333（8位精度）', () => {
      const bd = new BigDecimal('1').divide(new BigDecimal('3'), 8, RoundingMode.HALF_UP);
      expect(bd.toPlainString()).toBe('0.33333333');
    });

    test('复杂计算并格式化', () => {
      const result = new BigDecimal('3.1415926535')
        .add(new BigDecimal('2.7182818284'))
        .setScale(8, RoundingMode.HALF_UP);
      expect(result.toPlainString()).toBe('5.85987448');
    });
  });
});
