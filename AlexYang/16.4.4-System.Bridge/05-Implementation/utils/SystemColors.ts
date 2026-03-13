/**
 * SystemColors.ts
 * Android 系统颜色常量映射
 * 
 * 提供Android系统颜色的HarmonyOS兼容实现
 */

/**
 * Android 系统颜色常量
 */
export class Color {
  // 基本颜色
  static readonly BLACK = 0xFF000000;
  static readonly DKGRAY = 0xFF444444;
  static readonly GRAY = 0xFF888888;
  static readonly LTGRAY = 0xFFCCCCCC;
  static readonly WHITE = 0xFFFFFFFF;
  static readonly RED = 0xFFFF0000;
  static readonly GREEN = 0xFF00FF00;
  static readonly BLUE = 0xFF0000FF;
  static readonly YELLOW = 0xFFFFFF00;
  static readonly CYAN = 0xFF00FFFF;
  static readonly MAGENTA = 0xFFFF00FF;
  static readonly TRANSPARENT = 0x00000000;

  // Holo主题颜色
  static readonly HOLO_BLUE_BRIGHT = 0xFF00DDFF;
  static readonly HOLO_BLUE_LIGHT = 0xFF33B5E5;
  static readonly HOLO_BLUE_DARK = 0xFF0099CC;
  static readonly HOLO_GREEN_LIGHT = 0xFF99CC00;
  static readonly HOLO_GREEN_DARK = 0xFF669900;
  static readonly HOLO_RED_LIGHT = 0xFFFF4444;
  static readonly HOLO_RED_DARK = 0xFFCC0000;
  static readonly HOLO_ORANGE_LIGHT = 0xFFFFBB33;
  static readonly HOLO_ORANGE_DARK = 0xFFFF8800;
  static readonly HOLO_PURPLE = 0xFFAA66CC;

  // Material Design颜色
  static readonly MATERIAL_BLUE_500 = 0xFF2196F3;
  static readonly MATERIAL_BLUE_700 = 0xFF1976D2;
  static readonly MATERIAL_RED_500 = 0xFFF44336;
  static readonly MATERIAL_GREEN_500 = 0xFF4CAF50;
  static readonly MATERIAL_AMBER_500 = 0xFFFFC107;
  static readonly MATERIAL_GREY_500 = 0xFF9E9E9E;
  static readonly MATERIAL_GREY_700 = 0xFF616161;

  /**
   * 将颜色整数转换为ARGB字符串
   * @param color 颜色整数
   * @returns ARGB字符串（如"#FF0000FF"）
   */
  static toArgbString(color: number): string {
    const alpha = (color >>> 24) & 0xFF;
    const red = (color >>> 16) & 0xFF;
    const green = (color >>> 8) & 0xFF;
    const blue = color & 0xFF;
    
    if (alpha === 255) {
      return `#${red.toString(16).padStart(2, '0')}${green.toString(16).padStart(2, '0')}${blue.toString(16).padStart(2, '0')}`;
    }
    return `#${alpha.toString(16).padStart(2, '0')}${red.toString(16).padStart(2, '0')}${green.toString(16).padStart(2, '0')}${blue.toString(16).padStart(2, '0')}`;
  }

  /**
   * 将颜色整数转换为RGB字符串（不带Alpha）
   * @param color 颜色整数
   * @returns RGB字符串（如"#0000FF"）
   */
  static toRgbString(color: number): string {
    const red = (color >>> 16) & 0xFF;
    const green = (color >>> 8) & 0xFF;
    const blue = color & 0xFF;
    return `#${red.toString(16).padStart(2, '0')}${green.toString(16).padStart(2, '0')}${blue.toString(16).padStart(2, '0')}`;
  }

  /**
   * 解析颜色字符串为整数
   * @param colorString 颜色字符串（支持#RGB, #ARGB, #RRGGBB, #AARRGGBB）
   * @returns 颜色整数
   */
  static parseColor(colorString: string): number {
    let color = colorString.trim();
    
    if (color.startsWith('#')) {
      color = color.substring(1);
    }

    if (color.length === 3) {
      // #RGB
      const r = parseInt(color[0] + color[0], 16);
      const g = parseInt(color[1] + color[1], 16);
      const b = parseInt(color[2] + color[2], 16);
      return (255 << 24) | (r << 16) | (g << 8) | b;
    } else if (color.length === 4) {
      // #ARGB
      const a = parseInt(color[0] + color[0], 16);
      const r = parseInt(color[1] + color[1], 16);
      const g = parseInt(color[2] + color[2], 16);
      const b = parseInt(color[3] + color[3], 16);
      return (a << 24) | (r << 16) | (g << 8) | b;
    } else if (color.length === 6) {
      // #RRGGBB
      return (255 << 24) | parseInt(color, 16);
    } else if (color.length === 8) {
      // #AARRGGBB
      return parseInt(color, 16);
    }

    throw new Error(`Invalid color format: ${colorString}`);
  }

  /**
   * 获取Alpha通道值
   * @param color 颜色整数
   * @returns Alpha值（0-255）
   */
  static alpha(color: number): number {
    return (color >>> 24) & 0xFF;
  }

  /**
   * 获取红色通道值
   * @param color 颜色整数
   * @returns Red值（0-255）
   */
  static red(color: number): number {
    return (color >>> 16) & 0xFF;
  }

  /**
   * 获取绿色通道值
   * @param color 颜色整数
   * @returns Green值（0-255）
   */
  static green(color: number): number {
    return (color >>> 8) & 0xFF;
  }

  /**
   * 获取蓝色通道值
   * @param color 颜色整数
   * @returns Blue值（0-255）
   */
  static blue(color: number): number {
    return color & 0xFF;
  }

  /**
   * 设置Alpha通道值
   * @param color 颜色整数
   * @param alpha Alpha值（0-255）
   * @returns 新的颜色整数
   */
  static setAlpha(color: number, alpha: number): number {
    return (alpha << 24) | (color & 0x00FFFFFF);
  }

  /**
   * 颜色混合
   * @param color1 第一个颜色
   * @param color2 第二个颜色
   * @param ratio 混合比例（0.0-1.0）
   * @returns 混合后的颜色
   */
  static blend(color1: number, color2: number, ratio: number): number {
    const a1 = Color.alpha(color1);
    const r1 = Color.red(color1);
    const g1 = Color.green(color1);
    const b1 = Color.blue(color1);

    const a2 = Color.alpha(color2);
    const r2 = Color.red(color2);
    const g2 = Color.green(color2);
    const b2 = Color.blue(color2);

    const a = Math.round(a1 + (a2 - a1) * ratio);
    const r = Math.round(r1 + (r2 - r1) * ratio);
    const g = Math.round(g1 + (g2 - g1) * ratio);
    const b = Math.round(b1 + (b2 - b1) * ratio);

    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /**
   * 变暗颜色
   * @param color 颜色整数
   * @param factor 变暗因子（0.0-1.0）
   * @returns 变暗后的颜色
   */
  static darker(color: number, factor: number = 0.7): number {
    const a = Color.alpha(color);
    const r = Math.round(Color.red(color) * factor);
    const g = Math.round(Color.green(color) * factor);
    const b = Math.round(Color.blue(color) * factor);
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /**
   * 变亮颜色
   * @param color 颜色整数
   * @param factor 变亮因子（0.0-1.0）
   * @returns 变亮后的颜色
   */
  static lighter(color: number, factor: number = 0.3): number {
    const a = Color.alpha(color);
    const r = Math.min(255, Math.round(Color.red(color) + (255 - Color.red(color)) * factor));
    const g = Math.min(255, Math.round(Color.green(color) + (255 - Color.green(color)) * factor));
    const b = Math.min(255, Math.round(Color.blue(color) + (255 - Color.blue(color)) * factor));
    return (a << 24) | (r << 16) | (g << 8) | b;
  }

  /**
   * 获取颜色名称（如果有）
   * @param color 颜色整数
   * @returns 颜色名称或null
   */
  static getColorName(color: number): string | null {
    const colorNames: Record<number, string> = {
      [Color.BLACK]: 'BLACK',
      [Color.WHITE]: 'WHITE',
      [Color.RED]: 'RED',
      [Color.GREEN]: 'GREEN',
      [Color.BLUE]: 'BLUE',
      [Color.YELLOW]: 'YELLOW',
      [Color.CYAN]: 'CYAN',
      [Color.MAGENTA]: 'MAGENTA',
      [Color.GRAY]: 'GRAY',
      [Color.TRANSPARENT]: 'TRANSPARENT'
    };
    return colorNames[color] || null;
  }
}

/**
 * 简化的系统颜色访问
 */
export const SystemColors = Color;

export default Color;
