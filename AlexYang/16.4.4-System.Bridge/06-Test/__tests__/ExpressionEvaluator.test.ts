/**
 * __tests__/ExpressionEvaluator.test.ts
 * ExpressionEvaluator单元测试
 */

import { ExpressionEvaluator } from '../bridges/ExpressionEvaluator';

describe('ExpressionEvaluator', () => {
  describe('基本运算', () => {
    test('加法: 1+2+3 = 6', () => {
      const result = ExpressionEvaluator.eval('1+2+3');
      expect(result).toBe('6');
    });

    test('减法: 10-3 = 7', () => {
      const result = ExpressionEvaluator.eval('10-3');
      expect(result).toBe('7');
    });

    test('乘法: 3*4 = 12', () => {
      const result = ExpressionEvaluator.eval('3*4');
      expect(result).toBe('12');
    });

    test('除法: 10/2 = 5', () => {
      const result = ExpressionEvaluator.eval('10/2');
      expect(result).toBe('5');
    });
  });

  describe('优先级运算', () => {
    test('乘法优先: 2+3*4 = 14', () => {
      const result = ExpressionEvaluator.eval('2+3*4');
      expect(result).toBe('14');
    });

    test('括号优先: (2+3)*4 = 20', () => {
      const result = ExpressionEvaluator.eval('(2+3)*4');
      expect(result).toBe('20');
    });

    test('嵌套括号: (1+2)*(3+4) = 21', () => {
      const result = ExpressionEvaluator.eval('(1+2)*(3+4)');
      expect(result).toBe('21');
    });

    test('复杂表达式: 10-3*2+8/4 = 6', () => {
      const result = ExpressionEvaluator.eval('10-3*2+8/4');
      expect(result).toBe('6');
    });
  });

  describe('特殊符号转换', () => {
    test('×应转换为*: 3×4 = 12', () => {
      const result = ExpressionEvaluator.eval('3×4');
      expect(result).toBe('12');
    });

    test('x应转换为*: 3x4 = 12', () => {
      const result = ExpressionEvaluator.eval('3x4');
      expect(result).toBe('12');
    });

    test('÷应转换为/: 8÷2 = 4', () => {
      const result = ExpressionEvaluator.eval('8÷2');
      expect(result).toBe('4');
    });

    test('%应转换为/100: 10% = 0.1', () => {
      const result = ExpressionEvaluator.eval('10%');
      expect(result).toBe('0.1');
    });

    test('混合符号: 10%×5 = 0.5', () => {
      const result = ExpressionEvaluator.eval('10%×5');
      expect(result).toBe('0.5');
    });
  });

  describe('小数运算', () => {
    test('小数加法: 1.5+2.5 = 4', () => {
      const result = ExpressionEvaluator.eval('1.5+2.5');
      expect(result).toBe('4');
    });

    test('小数乘法: 0.5*0.5 = 0.25', () => {
      const result = ExpressionEvaluator.eval('0.5*0.5');
      expect(result).toBe('0.25');
    });

    test('精度格式化: 1/3 = 0.33333333（8位）', () => {
      const result = ExpressionEvaluator.eval('1/3');
      expect(result).toBe('0.33333333');
    });

    test('自定义精度: 1/3 = 0.33（2位）', () => {
      const result = ExpressionEvaluator.eval('1/3', 2);
      expect(result).toBe('0.33');
    });
  });

  describe('幂运算', () => {
    test('平方: 2^3 = 8', () => {
      const result = ExpressionEvaluator.eval('2^3');
      expect(result).toBe('8');
    });

    test('复杂幂: (2+1)^2 = 9', () => {
      const result = ExpressionEvaluator.eval('(2+1)^2');
      expect(result).toBe('9');
    });
  });

  describe('函数运算', () => {
    test('sin(0) = 0', () => {
      const result = ExpressionEvaluator.eval('sin(0)');
      expect(result).toBe('0');
    });

    test('cos(0) = 1', () => {
      const result = ExpressionEvaluator.eval('cos(0)');
      expect(result).toBe('1');
    });

    test('平方根: √16 = 4', () => {
      const result = ExpressionEvaluator.eval('√16');
      expect(result).toBe('4');
    });

    test('绝对值: abs(-5) = 5', () => {
      const result = ExpressionEvaluator.eval('abs(-5)');
      expect(result).toBe('5');
    });

    test('log(100) = 2', () => {
      const result = ExpressionEvaluator.eval('log(100)');
      expect(result).toBe('2');
    });
  });

  describe('错误处理', () => {
    test('除零应返回Infinity', () => {
      const result = ExpressionEvaluator.eval('1/0');
      expect(result).toBe('Infinity');
    });

    test('无效表达式应抛出错误', () => {
      expect(() => ExpressionEvaluator.eval('1+++')).toThrow();
    });

    test('括号不匹配应抛出错误', () => {
      expect(() => ExpressionEvaluator.eval('(1+2')).toThrow();
    });
  });

  describe('Calculator关键场景', () => {
    test('完整Calculator流程: (1+2)*3 = 9', () => {
      const input = '(1+2)*3';
      const result = ExpressionEvaluator.eval(input);
      expect(result).toBe('9');
    });

    test('百分比计算: 10% = 0.1', () => {
      const result = ExpressionEvaluator.eval('10%');
      expect(result).toBe('0.1');
    });

    test('连续运算: 1÷3 + 0.66666667 = 1', () => {
      const divResult = ExpressionEvaluator.eval('1÷3');
      const finalResult = ExpressionEvaluator.eval(`${divResult}+0.66666667`);
      expect(finalResult).toBe('1');
    });

    test('隐式乘法: 2(3+4) = 14', () => {
      const result = ExpressionEvaluator.eval('2(3+4)');
      expect(result).toBe('14');
    });
  });

  describe('validate方法', () => {
    test('有效表达式应返回valid: true', () => {
      const result = ExpressionEvaluator.validate('1+2');
      expect(result.valid).toBe(true);
    });

    test('无效表达式应返回valid: false', () => {
      const result = ExpressionEvaluator.validate('1+++');
      expect(result.valid).toBe(false);
      expect(result.error).toBeDefined();
    });
  });

  describe('raw求值', () => {
    test('evalRaw应返回数字', () => {
      const result = ExpressionEvaluator.evalRaw('1+2');
      expect(typeof result).toBe('number');
      expect(result).toBe(3);
    });
  });
});
