/**
 * ExpressionEvaluator.ts
 * 安全的数学表达式解析器
 * 
 * 替代Android Rhino JS引擎 (ScriptEngine.eval)
 * 实现Shunting Yard算法进行安全解析，无eval风险
 */

import { BigDecimal, RoundingMode } from './DecimalBridge';

/**
 * 表达式求值结果
 */
export interface EvaluationResult {
  value: number;
  stringValue: string;
  error?: string;
}

/**
 * 表达式求值器
 * 支持: +, -, *, /, %, ^, 括号, 函数
 */
export class ExpressionEvaluator {
  // 运算符优先级
  private static readonly PRECEDENCE: Record<string, number> = {
    '+': 1,
    '-': 1,
    '*': 2,
    '/': 2,
    '÷': 2,
    'x': 2,
    '×': 2,
    '%': 3,
    '^': 4,
    '√': 5,
    'sin': 5,
    'cos': 5,
    'tan': 5,
    'log': 5,
    'ln': 5,
    'abs': 5
  };

  // 函数列表
  private static readonly FUNCTIONS = ['sin', 'cos', 'tan', 'log', 'ln', 'abs', '√'];

  /**
   * 求值表达式
   * @param expression 数学表达式字符串
   * @param scale 结果精度（小数位数）
   * @returns 求值结果
   */
  static eval(expression: string, scale: number = 8): string {
    try {
      // 预处理
      const processed = this.preprocess(expression);
      
      // 分词
      const tokens = this.tokenize(processed);
      
      // 中缀转后缀
      const postfix = this.infixToPostfix(tokens);
      
      // 求值
      const result = this.evaluatePostfix(postfix);
      
      // 格式化
      const bd = new BigDecimal(result);
      return bd.setScale(scale, RoundingMode.HALF_UP).toPlainString();
    } catch (error) {
      throw new Error(`Expression evaluation error: ${error}`);
    }
  }

  /**
   * 快速求值（不格式化）
   */
  static evalRaw(expression: string): number {
    const processed = this.preprocess(expression);
    const tokens = this.tokenize(processed);
    const postfix = this.infixToPostfix(tokens);
    return this.evaluatePostfix(postfix);
  }

  /**
   * 预处理表达式
   * - 替换特殊符号
   * - 处理隐式乘法
   * - 移除空白字符
   */
  private static preprocess(expression: string): string {
    let result = expression
      .replace(/\s+/g, '')  // 移除空白
      .replace(/[×x]/g, '*')  // 乘号统一
      .replace(/÷/g, '/')      // 除号统一
      .replace(/%/g, '/100');  // 百分号转换

    // 处理隐式乘法: 2(3+4) => 2*(3+4)
    result = result.replace(/(\d)(\()/g, '$1*$2');
    result = result.replace(/(\))(\d)/g, '$1*$2');

    return result;
  }

  /**
   * 分词
   */
  private static tokenize(expression: string): string[] {
    const tokens: string[] = [];
    let i = 0;

    while (i < expression.length) {
      const char = expression[i];

      // 数字（包括小数）
      if (/\d/.test(char) || (char === '.' && /\d/.test(expression[i + 1]))) {
        let num = '';
        while (i < expression.length && (/\d/.test(expression[i]) || expression[i] === '.')) {
          num += expression[i];
          i++;
        }
        tokens.push(num);
        continue;
      }

      // 函数名
      if (/[a-zA-Z]/.test(char)) {
        let func = '';
        while (i < expression.length && /[a-zA-Z]/.test(expression[i])) {
          func += expression[i];
          i++;
        }
        tokens.push(func.toLowerCase());
        continue;
      }

      // 运算符和括号
      if ('+-*/^()√'.includes(char)) {
        tokens.push(char);
        i++;
        continue;
      }

      // 未知字符，跳过
      i++;
    }

    return tokens;
  }

  /**
   * 中缀表达式转后缀表达式 (Shunting Yard算法)
   */
  private static infixToPostfix(tokens: string[]): string[] {
    const output: string[] = [];
    const operators: string[] = [];

    for (let i = 0; i < tokens.length; i++) {
      const token = tokens[i];

      // 数字直接输出
      if (/^\d+\.?\d*$/.test(token)) {
        output.push(token);
        continue;
      }

      // 函数压栈
      if (this.FUNCTIONS.includes(token)) {
        operators.push(token);
        continue;
      }

      // 左括号压栈
      if (token === '(') {
        operators.push(token);
        continue;
      }

      // 右括号 - 弹出到左括号
      if (token === ')') {
        while (operators.length > 0 && operators[operators.length - 1] !== '(') {
          output.push(operators.pop()!);
        }
        operators.pop(); // 弹出左括号
        
        // 如果栈顶是函数，也弹出
        if (operators.length > 0 && this.FUNCTIONS.includes(operators[operators.length - 1])) {
          output.push(operators.pop()!);
        }
        continue;
      }

      // 运算符
      if (this.PRECEDENCE[token]) {
        // 处理一元运算符
        if ((token === '+' || token === '-') && (i === 0 || tokens[i - 1] === '(' || this.PRECEDENCE[tokens[i - 1]])) {
          output.push('0'); // 将一元运算符转换为二元运算
        }

        while (operators.length > 0 && 
               operators[operators.length - 1] !== '(' &&
               this.PRECEDENCE[operators[operators.length - 1]] >= this.PRECEDENCE[token]) {
          output.push(operators.pop()!);
        }
        operators.push(token);
      }
    }

    // 弹出剩余运算符
    while (operators.length > 0) {
      const op = operators.pop()!;
      if (op !== '(') {
        output.push(op);
      }
    }

    return output;
  }

  /**
   * 求值后缀表达式
   */
  private static evaluatePostfix(tokens: string[]): number {
    const stack: number[] = [];

    for (const token of tokens) {
      // 数字入栈
      if (/^\d+\.?\d*$/.test(token)) {
        stack.push(parseFloat(token));
        continue;
      }

      // 函数
      if (this.FUNCTIONS.includes(token)) {
        const arg = stack.pop();
        if (arg === undefined) throw new Error(`Function ${token} requires argument`);
        
        let result: number;
        switch (token) {
          case 'sin':
            result = Math.sin(arg);
            break;
          case 'cos':
            result = Math.cos(arg);
            break;
          case 'tan':
            result = Math.tan(arg);
            break;
          case 'log':
            result = Math.log10(arg);
            break;
          case 'ln':
            result = Math.log(arg);
            break;
          case 'abs':
            result = Math.abs(arg);
            break;
          case '√':
            result = Math.sqrt(arg);
            break;
          default:
            throw new Error(`Unknown function: ${token}`);
        }
        stack.push(result);
        continue;
      }

      // 二元运算符
      const b = stack.pop();
      const a = stack.pop();
      
      if (a === undefined || b === undefined) {
        throw new Error(`Operator ${token} requires two operands`);
      }

      let result: number;
      switch (token) {
        case '+':
          result = a + b;
          break;
        case '-':
          result = a - b;
          break;
        case '*':
          result = a * b;
          break;
        case '/':
          result = b === 0 ? (a >= 0 ? Infinity : -Infinity) : a / b;
          break;
        case '^':
          result = Math.pow(a, b);
          break;
        default:
          throw new Error(`Unknown operator: ${token}`);
      }
      stack.push(result);
    }

    if (stack.length !== 1) {
      throw new Error('Invalid expression');
    }

    return stack[0];
  }

  /**
   * 验证表达式是否合法
   */
  static validate(expression: string): { valid: boolean; error?: string } {
    try {
      this.evalRaw(expression);
      return { valid: true };
    } catch (error) {
      return { valid: false, error: String(error) };
    }
  }
}

/**
 * 兼容Android ScriptEngine接口
 */
export class ScriptEngine {
  /**
   * 求值表达式
   * @param expression JavaScript表达式字符串
   * @returns 求值结果
   */
  eval(expression: string): string {
    return ExpressionEvaluator.eval(expression);
  }
}

export default ExpressionEvaluator;
