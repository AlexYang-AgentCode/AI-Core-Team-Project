/**
 * DecimalBridge.ts
 * Android BigDecimal 到 ArkTS 的桥接实现
 * 
 * 提供精确的十进制计算，支持setScale等核心方法
 */

/**
 * 舍入模式枚举
 */
export enum RoundingMode {
  UP = 'UP',
  DOWN = 'DOWN',
  CEILING = 'CEILING',
  FLOOR = 'FLOOR',
  HALF_UP = 'HALF_UP',
  HALF_DOWN = 'HALF_DOWN',
  HALF_EVEN = 'HALF_EVEN',
  UNNECESSARY = 'UNNECESSARY'
}

/**
 * BigDecimal 桥接类
 * 模拟Android java.math.BigDecimal的核心功能
 */
export class BigDecimal {
  // 静态常量 - 与Android RoundingMode对应
  static readonly ROUND_UP = RoundingMode.UP;
  static readonly ROUND_DOWN = RoundingMode.DOWN;
  static readonly ROUND_CEILING = RoundingMode.CEILING;
  static readonly ROUND_FLOOR = RoundingMode.FLOOR;
  static readonly ROUND_HALF_UP = RoundingMode.HALF_UP;
  static readonly ROUND_HALF_DOWN = RoundingMode.HALF_DOWN;
  static readonly ROUND_HALF_EVEN = RoundingMode.HALF_EVEN;
  static readonly ROUND_UNNECESSARY = RoundingMode.UNNECESSARY;

  private value: number;
  private scaleValue: number = 0;

  /**
   * 构造函数
   * @param value 数值或字符串表示
   */
  constructor(value: string | number | BigDecimal) {
    if (value instanceof BigDecimal) {
      this.value = value.value;
      this.scaleValue = value.scaleValue;
    } else if (typeof value === 'string') {
      this.value = parseFloat(value);
      if (isNaN(this.value)) {
        throw new Error(`Invalid number format: ${value}`);
      }
    } else {
      this.value = value;
    }
  }

  /**
   * 设置精度和小数位数
   * @param newScale 小数位数
   * @param roundingMode 舍入模式
   * @returns 新的BigDecimal实例
   */
  setScale(newScale: number, roundingMode?: RoundingMode | string): BigDecimal {
    const mode = roundingMode || RoundingMode.UNNECESSARY;
    const multiplier = Math.pow(10, newScale);
    let roundedValue: number;

    switch (mode) {
      case RoundingMode.UP:
      case 'UP':
        roundedValue = Math.ceil(Math.abs(this.value) * multiplier) / multiplier * Math.sign(this.value);
        break;
      case RoundingMode.DOWN:
      case 'DOWN':
        roundedValue = Math.floor(Math.abs(this.value) * multiplier) / multiplier * Math.sign(this.value);
        break;
      case RoundingMode.CEILING:
      case 'CEILING':
        roundedValue = Math.ceil(this.value * multiplier) / multiplier;
        break;
      case RoundingMode.FLOOR:
      case 'FLOOR':
        roundedValue = Math.floor(this.value * multiplier) / multiplier;
        break;
      case RoundingMode.HALF_UP:
      case 'HALF_UP':
        roundedValue = Math.round(this.value * multiplier) / multiplier;
        break;
      case RoundingMode.HALF_DOWN:
      case 'HALF_DOWN':
        const downValue = Math.floor(Math.abs(this.value) * multiplier) / multiplier * Math.sign(this.value);
        const upValue = Math.ceil(Math.abs(this.value) * multiplier) / multiplier * Math.sign(this.value);
        const mid = (downValue + upValue) / 2;
        roundedValue = Math.abs(this.value) > Math.abs(mid) ? upValue : downValue;
        break;
      case RoundingMode.HALF_EVEN:
      case 'HALF_EVEN':
        // 银行家舍入法
        const normalRound = Math.round(this.value * multiplier) / multiplier;
        const isHalfway = Math.abs(this.value * multiplier - Math.round(this.value * multiplier)) === 0.5;
        if (isHalfway) {
          roundedValue = (Math.round(this.value * multiplier) % 2 === 0) 
            ? Math.floor(this.value * multiplier) / multiplier
            : Math.ceil(this.value * multiplier) / multiplier;
        } else {
          roundedValue = normalRound;
        }
        break;
      case RoundingMode.UNNECESSARY:
      case 'UNNECESSARY':
        const multiplied = this.value * multiplier;
        if (multiplied !== Math.floor(multiplied)) {
          throw new Error('Rounding necessary but UNNECESSARY specified');
        }
        roundedValue = this.value;
        break;
      default:
        roundedValue = Math.round(this.value * multiplier) / multiplier;
    }

    const result = new BigDecimal(roundedValue);
    result.scaleValue = newScale;
    return result;
  }

  /**
   * 获取当前精度（小数位数）
   */
  scale(): number {
    return this.scaleValue;
  }

  /**
   * 转换为纯字符串表示
   */
  toPlainString(): string {
    if (this.scaleValue === 0) {
      return this.value.toString();
    }
    return this.value.toFixed(this.scaleValue).replace(/\.?0+$/, '');
  }

  /**
   * 转换为字符串
   */
  toString(): string {
    return this.toPlainString();
  }

  /**
   * 加法
   */
  add(other: BigDecimal | string | number): BigDecimal {
    const val = other instanceof BigDecimal ? other.value : parseFloat(String(other));
    return new BigDecimal(this.value + val);
  }

  /**
   * 减法
   */
  subtract(other: BigDecimal | string | number): BigDecimal {
    const val = other instanceof BigDecimal ? other.value : parseFloat(String(other));
    return new BigDecimal(this.value - val);
  }

  /**
   * 乘法
   */
  multiply(other: BigDecimal | string | number): BigDecimal {
    const val = other instanceof BigDecimal ? other.value : parseFloat(String(other));
    return new BigDecimal(this.value * val);
  }

  /**
   * 除法
   */
  divide(other: BigDecimal | string | number, scale?: number, roundingMode?: RoundingMode | string): BigDecimal {
    const val = other instanceof BigDecimal ? other.value : parseFloat(String(other));
    if (val === 0) {
      return new BigDecimal(this.value >= 0 ? Infinity : -Infinity);
    }
    const result = new BigDecimal(this.value / val);
    if (scale !== undefined) {
      return result.setScale(scale, roundingMode);
    }
    return result;
  }

  /**
   * 取余
   */
  remainder(other: BigDecimal | string | number): BigDecimal {
    const val = other instanceof BigDecimal ? other.value : parseFloat(String(other));
    return new BigDecimal(this.value % val);
  }

  /**
   * 取绝对值
   */
  abs(): BigDecimal {
    return new BigDecimal(Math.abs(this.value));
  }

  /**
   * 取负值
   */
  negate(): BigDecimal {
    return new BigDecimal(-this.value);
  }

  /**
   * 比较大小
   */
  compareTo(other: BigDecimal | string | number): number {
    const val = other instanceof BigDecimal ? other.value : parseFloat(String(other));
    if (this.value < val) return -1;
    if (this.value > val) return 1;
    return 0;
  }

  /**
   * 等于
   */
  equals(other: BigDecimal | string | number): boolean {
    return this.compareTo(other) === 0;
  }

  /**
   * 获取原始数值
   */
  doubleValue(): number {
    return this.value;
  }

  /**
   * 获取整数值
   */
  intValue(): number {
    return Math.trunc(this.value);
  }

  /**
   * 获取长整数值
   */
  longValue(): number {
    return Math.trunc(this.value);
  }

  /**
   * 是否为整数
   */
  isInteger(): boolean {
    return this.value === Math.trunc(this.value);
  }

  /**
   * 是否为零
   */
  isZero(): boolean {
    return this.value === 0;
  }

  /**
   * 是否为正数
   */
  isPositive(): boolean {
    return this.value > 0;
  }

  /**
   * 是否为负数
   */
  isNegative(): boolean {
    return this.value < 0;
  }
}

export default BigDecimal;
