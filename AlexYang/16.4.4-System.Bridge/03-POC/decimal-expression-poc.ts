/**
 * DecimalBridge + ExpressionEvaluator POC
 * 替代Android BigDecimal和Rhino ScriptEngine
 * 
 * Calculator核心需求:
 * 1. new BigDecimal(result).setScale(8, ROUND_HALF_UP).toPlainString()
 * 2. scriptEngine.eval(expression) 用于计算数学表达式
 */

// ============================================
// DecimalBridge - BigDecimal的鸿蒙兼容实现
// ============================================

export class DecimalBridge {
  // Android BigDecimal常量
  static readonly ROUND_HALF_UP = 'ROUND_HALF_UP';
  static readonly ROUND_HALF_DOWN = 'ROUND_HALF_DOWN';
  static readonly ROUND_CEILING = 'ROUND_CEILING';
  static readonly ROUND_FLOOR = 'ROUND_FLOOR';
  
  private value: number;
  private scale: number = 0;
  
  /**
   * 构造函数 - 对应 new BigDecimal(string|number)
   */
  constructor(value: string | number) {
    if (typeof value === 'string') {
      this.value = parseFloat(value);
    } else {
      this.value = value;
    }
    
    if (isNaN(this.value)) {
      throw new Error(`Invalid number: ${value}`);
    }
  }
  
   /**
    * 设置精度和小数位数 - 对应 setScale(scale, roundingMode)
    * Calculator使用: decimal.setScale(8, BigDecimal.ROUND_HALF_UP)
    */
  setScale(scale: number, roundingMode: string): DecimalBridge {
    this.scale = scale;
    const multiplier = Math.pow(10, scale);
    
    switch (roundingMode) {
      case DecimalBridge.ROUND_HALF_UP:
        // 四舍五入
        this.value = Math.round(this.value * multiplier) / multiplier;
        break;
      case DecimalBridge.ROUND_HALF_DOWN:
        // 五舍六入
        this.value = Math.floor(this.value * multiplier + 0.5) / multiplier;
        break;
      case DecimalBridge.ROUND_CEILING:
        // 向正无穷取整
        this.value = Math.ceil(this.value * multiplier) / multiplier;
        break;
      case DecimalBridge.ROUND_FLOOR:
        // 向负无穷取整
        this.value = Math.floor(this.value * multiplier) / multiplier;
        break;
      default:
        throw new Error(`Unsupported rounding mode: ${roundingMode}`);
    }
    
    return this;
  }
  
  /**
   * 转换为普通字符串 - 对应 toPlainString()
   * 去除末尾多余的0
   */
  toPlainString(): string {
    let result: string;
    
    if (this.scale > 0) {
      result = this.value.toFixed(this.scale);
      // 去除末尾的0 (与Android BigDecimal行为一致)
      result = result.replace(/\.?0+$/, '');
    } else {
      result = this.value.toString();
    }
    
    return result;
  }
  
  /**
   * 基础运算 (可选扩展)
   */
  add(other: DecimalBridge): DecimalBridge {
    return new DecimalBridge(this.value + other.value);
  }
  
  subtract(other: DecimalBridge): DecimalBridge {
    return new DecimalBridge(this.value - other.value);
  }
  
  multiply(other: DecimalBridge): DecimalBridge {
    return new DecimalBridge(this.value * other.value);
  }
  
  divide(other: DecimalBridge): DecimalBridge {
    if (other.value === 0) {
      // Android行为: 返回Infinity
      return new DecimalBridge(this.value > 0 ? Infinity : -Infinity);
    }
    return new DecimalBridge(this.value / other.value);
  }
  
  /**
   * 获取原始数值
   */
  toNumber(): number {
    return this.value;
  }
}

// ============================================
// ExpressionEvaluator - 安全的数学表达式求值器
// 替代 javax.script.ScriptEngine (Rhino)
// ============================================

export class ExpressionEvaluator {
  /**
   * 评估数学表达式 - 对应 scriptEngine.eval(expression)
   * 
   * 支持的运算符: +, -, *, /, %
   * 支持的函数: 括号 ()
   * 
   * Calculator使用场景:
   * - input: "(1+2)*3" → output: "9"
   * - input: "1÷3" (转换后: "1/3") → output: "0.3333333333333333"
   * - input: "10%" (转换后: "10/100") → output: "0.1"
   */
  static eval(expression: string): string {
    try {
      // 1. 预处理: 替换Calculator使用的特殊符号
      let processed = expression
        .replace(/x/g, '*')           // 乘号: x → *
        .replace(/÷/g, '/')           // 除号: ÷ → /
        .replace(/%/g, '/100')        // 百分号: % → /100
        .replace(/[^\x00-\x7F]/g, '/'); // 非ASCII字符转除号
      
      // 2. 安全验证: 只允许数字和基本运算符
      if (!/^[\d\s\+\-\*\/\(\)\.]+$/.test(processed)) {
        throw new Error(`Invalid characters in expression: ${processed}`);
      }
      
      // 3. 分词
      const tokens = ExpressionEvaluator.tokenize(processed);
      console.log(`  Tokens: ${tokens.join(' ')}`);
      
      // 4. 中缀表达式转后缀表达式 (Shunting Yard算法)
      const postfix = ExpressionEvaluator.infixToPostfix(tokens);
      console.log(`  Postfix: ${postfix.join(' ')}`);
      
      // 5. 计算后缀表达式
      const result = ExpressionEvaluator.evaluatePostfix(postfix);
      
      return result.toString();
    } catch (error: any) {
      console.error(`Expression evaluation error: ${error.message}`);
      throw error;
    }
  }
  
  /**
   * 分词: 将表达式字符串拆分为token数组
   */
  private static tokenize(expr: string): string[] {
    const tokens: string[] = [];
    let currentNumber = '';
    
    for (let i = 0; i < expr.length; i++) {
      const char = expr[i];
      
      if (char === ' ') {
        continue; // 跳过空格
      }
      
      if (/[\d\.]/.test(char)) {
        currentNumber += char;
      } else if (char === '-' && (i === 0 || /[\+\-\*\/\(]/.test(expr[i-1]))) {
        // 处理负数 (开头或运算符后的-)
        currentNumber += char;
      } else {
        if (currentNumber) {
          tokens.push(currentNumber);
          currentNumber = '';
        }
        tokens.push(char);
      }
    }
    
    if (currentNumber) {
      tokens.push(currentNumber);
    }
    
    return tokens;
  }
  
  /**
   * 中缀表达式转后缀表达式 (Shunting Yard算法)
   */
  private static infixToPostfix(tokens: string[]): string[] {
    const output: string[] = [];
    const operatorStack: string[] = [];
    
    const precedence: { [key: string]: number } = {
      '+': 1,
      '-': 1,
      '*': 2,
      '/': 2
    };
    
    for (const token of tokens) {
      if (/^-?\d+\.?\d*$/.test(token)) {
        // 数字直接输出
        output.push(token);
      } else if (token === '(') {
        // 左括号入栈
        operatorStack.push(token);
      } else if (token === ')') {
        // 右括号: 弹出到左括号
        while (operatorStack.length > 0 && operatorStack[operatorStack.length - 1] !== '(') {
          output.push(operatorStack.pop()!);
        }
        operatorStack.pop(); // 弹出左括号
      } else {
        // 运算符
        while (
          operatorStack.length > 0 &&
          operatorStack[operatorStack.length - 1] !== '(' &&
          precedence[operatorStack[operatorStack.length - 1]] >= precedence[token]
        ) {
          output.push(operatorStack.pop()!);
        }
        operatorStack.push(token);
      }
    }
    
    // 弹出栈中剩余运算符
    while (operatorStack.length > 0) {
      output.push(operatorStack.pop()!);
    }
    
    return output;
  }
  
  /**
   * 计算后缀表达式
   */
  private static evaluatePostfix(tokens: string[]): number {
    const stack: number[] = [];
    
    for (const token of tokens) {
      if (/^-?\d+\.?\d*$/.test(token)) {
        stack.push(parseFloat(token));
      } else {
        const b = stack.pop()!;
        const a = stack.pop()!;
        
        switch (token) {
          case '+':
            stack.push(a + b);
            break;
          case '-':
            stack.push(a - b);
            break;
          case '*':
            stack.push(a * b);
            break;
          case '/':
            if (b === 0) {
              stack.push(a >= 0 ? Infinity : -Infinity);
            } else {
              stack.push(a / b);
            }
            break;
        }
      }
    }
    
    return stack[0];
  }
}

// ============================================
// POC测试
// ============================================

console.log("=== DecimalBridge + ExpressionEvaluator POC测试 ===\n");

// 测试1: DecimalBridge基本功能
console.log("测试1: DecimalBridge");
console.log("--------------------");

const testCases = [
  { input: "3.14159265358979", scale: 8, expected: "3.14159265" },
  { input: "1.234567891234", scale: 8, expected: "1.23456789" },
  { input: "1.5", scale: 0, expected: "2" },  // 四舍五入到整数
  { input: "1.4", scale: 0, expected: "1" },  // 四舍五入到整数
  { input: "10", scale: 8, expected: "10" },  // 整数保留精度
];

testCases.forEach(({ input, scale, expected }) => {
  const decimal = new DecimalBridge(input).setScale(scale, DecimalBridge.ROUND_HALF_UP);
  const result = decimal.toPlainString();
  const status = result === expected ? '✓' : '✗';
  console.log(`${status} BigDecimal(${input}).setScale(${scale}) = ${result} (expected: ${expected})`);
});

// 测试2: ExpressionEvaluator基本运算
console.log("\n测试2: ExpressionEvaluator");
console.log("---------------------------");

const exprCases = [
  { expr: "1+2+3", expected: "6" },
  { expr: "(1+2)*3", expected: "9" },
  { expr: "10-3*2", expected: "4" },  // 优先级测试
  { expr: "(10-3)*2", expected: "14" },
  { expr: "1x3", expected: "3" },     // x → * 转换
  { expr: "10%", expected: "0.1" },   // % → /100 转换
  { expr: "8÷2", expected: "4" },     // ÷ → / 转换
];

exprCases.forEach(({ expr, expected }) => {
  console.log(`\n表达式: ${expr}`);
  const result = ExpressionEvaluator.eval(expr);
  const status = result === expected ? '✓' : '✗';
  console.log(`${status} 结果: ${result} (expected: ${expected})`);
});

// 测试3: Calculator完整计算流程模拟
console.log("\n测试3: Calculator完整流程模拟");
console.log("------------------------------");

function calculateCalculatorStyle(input: string): string {
  console.log(`输入: ${input}`);
  
  // 步骤1: 表达式求值 (替代 scriptEngine.eval())
  const rawResult = ExpressionEvaluator.eval(input);
  console.log(`原始结果: ${rawResult}`);
  
  // 步骤2: BigDecimal格式化 (替代 new BigDecimal().setScale())
  const formatted = new DecimalBridge(rawResult)
    .setScale(8, DecimalBridge.ROUND_HALF_UP)
    .toPlainString();
  console.log(`格式化结果: ${formatted}`);
  
  // 步骤3: 去除末尾0 (与Calculator一致)
  const finalResult = formatted.replace(/\.?0*$/, '');
  console.log(`最终结果: ${finalResult}`);
  
  return finalResult;
}

const calcCases = [
  "1+2",
  "1÷3",
  "10%",
  "(1+2)*3",
  "3.1415926535+2.7182818284"
];

calcCases.forEach(expr => {
  console.log(`\n>>> 计算: ${expr}`);
  const result = calculateCalculatorStyle(expr);
  console.log(`<<< 输出: ${result}\n`);
});

// 测试4: 除以零场景
console.log("测试4: 除以零处理");
console.log("------------------");

try {
  const divByZero = ExpressionEvaluator.eval("1÷0");
  console.log(`1÷0 = ${divByZero}`);
  if (divByZero === "Infinity") {
    console.log("✓ 正确处理Infinity (与Android一致)");
  }
} catch (e: any) {
  console.log("✗ 错误: " + e.message);
}

console.log("\n=== 所有POC测试完成 ===");
