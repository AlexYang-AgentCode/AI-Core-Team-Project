/**
 * Android View LayoutParams 和 Gravity 支持
 * 模拟 android.view.ViewGroup.LayoutParams 和 android.view.Gravity
 */

// Margin 结构，用于存储四边边距
export class Margin {
  left: number = 0;
  top: number = 0;
  right: number = 0;
  bottom: number = 0;

  constructor(left?: number, top?: number, right?: number, bottom?: number) {
    this.left = left || 0;
    this.top = top || 0;
    this.right = right || 0;
    this.bottom = bottom || 0;
  }

  static all(value: number): Margin {
    return new Margin(value, value, value, value);
  }

  static horizontal(horizontal: number, vertical: number = 0): Margin {
    return new Margin(horizontal, vertical, horizontal, vertical);
  }

  static vertical(vertical: number, horizontal: number = 0): Margin {
    return new Margin(horizontal, vertical, horizontal, vertical);
  }

  static only(options: { left?: number, top?: number, right?: number, bottom?: number }): Margin {
    return new Margin(
      options.left || 0,
      options.top || 0,
      options.right || 0,
      options.bottom || 0
    );
  }
}

// Padding 结构，用于存储四边内边距
export class Padding {
  left: number = 0;
  top: number = 0;
  right: number = 0;
  bottom: number = 0;

  constructor(left?: number, top?: number, right?: number, bottom?: number) {
    this.left = left || 0;
    this.top = top || 0;
    this.right = right || 0;
    this.bottom = bottom || 0;
  }

  static all(value: number): Padding {
    return new Padding(value, value, value, value);
  }

  static horizontal(horizontal: number, vertical: number = 0): Padding {
    return new Padding(horizontal, vertical, horizontal, vertical);
  }

  static vertical(vertical: number, horizontal: number = 0): Padding {
    return new Padding(horizontal, vertical, horizontal, vertical);
  }

  static only(options: { left?: number, top?: number, right?: number, bottom?: number }): Padding {
    return new Padding(
      options.left || 0,
      options.top || 0,
      options.right || 0,
      options.bottom || 0
    );
  }
}

// Gravity 常量，匹配 android.view.Gravity
export class Gravity {
  // 基本方向
  static readonly LEFT = 0x01;
  static readonly TOP = 0x02;
  static readonly RIGHT = 0x04;
  static readonly BOTTOM = 0x08;
  
  // 中心位置
  static readonly CENTER = 0x11;
  static readonly CENTER_VERTICAL = 0x10;
  static readonly CENTER_HORIZONTAL = 0x01;
  
  // 填充
  static readonly FILL = 0x77;
  static readonly FILL_VERTICAL = 0x70;
  static readonly FILL_HORIZONTAL = 0x07;
  
  // 起始/结束（RTL支持）
  static readonly START = 0x00800001;
  static readonly END = 0x00800003;

  // 检查是否包含某个方向
  static has(gravity: number, direction: number): boolean {
    return (gravity & direction) === direction;
  }

  // 获取水平方向
  static getHorizontal(gravity: number): number {
    return gravity & 0x07;
  }

  // 获取垂直方向
  static getVertical(gravity: number): number {
    return gravity & 0x70;
  }
}

// LayoutParams 基类
export class LayoutParams {
  // 宽度
  width: number = LayoutParams.WRAP_CONTENT;
  // 高度
  height: number = LayoutParams.WRAP_CONTENT;
  
  // 特殊常量
  static readonly MATCH_PARENT = -1;
  static readonly WRAP_CONTENT = -2;

  constructor(width?: number, height?: number) {
    this.width = width !== undefined ? width : LayoutParams.WRAP_CONTENT;
    this.height = height !== undefined ? height : LayoutParams.WRAP_CONTENT;
  }

  // 检查是否为 MATCH_PARENT
  isMatchParent(dimension: 'width' | 'height'): boolean {
    return dimension === 'width' ? this.width === LayoutParams.MATCH_PARENT : this.height === LayoutParams.MATCH_PARENT;
  }

  // 检查是否为 WRAP_CONTENT
  isWrapContent(dimension: 'width' | 'height'): boolean {
    return dimension === 'width' ? this.width === LayoutParams.WRAP_CONTENT : this.height === LayoutParams.WRAP_CONTENT;
  }
}

// LinearLayout.LayoutParams
export class LinearLayoutParams extends LayoutParams {
  // 权重
  weight: number = 0;
  // 重力
  gravity: number = Gravity.TOP | Gravity.START;

  constructor(width?: number, height?: number, weight?: number) {
    super(width, height);
    this.weight = weight || 0;
  }
}

// RelativeLayout.LayoutParams
export class RelativeLayoutParams extends LayoutParams {
  // 相对于父布局的规则
  alignParentTop: boolean = false;
  alignParentBottom: boolean = false;
  alignParentLeft: boolean = false;
  alignParentRight: boolean = false;
  centerInParent: boolean = false;
  centerHorizontal: boolean = false;
  centerVertical: boolean = false;

  // 相对于其他View的规则
  above: number = 0;
  below: number = 0;
  toLeftOf: number = 0;
  toRightOf: number = 0;
  alignTop: number = 0;
  alignBottom: number = 0;
  alignLeft: number = 0;
  alignRight: number = 0;
  alignBaseline: number = 0;

  constructor(width?: number, height?: number) {
    super(width, height);
  }
}

// FrameLayout.LayoutParams
export class FrameLayoutParams extends LayoutParams {
  // 重力
  gravity: number = Gravity.TOP | Gravity.START;

  constructor(width?: number, height?: number, gravity?: number) {
    super(width, height);
    this.gravity = gravity || (Gravity.TOP | Gravity.START);
  }
}

// 尺寸单位转换工具
export class DimensionUtils {
  // dp 到 px 的转换（简化，假设屏幕密度为 3.0）
  static dpToPx(dp: number): number {
    const density = 3.0; // 假设标准密度
    return Math.round(dp * density);
  }

  // px 到 dp 的转换
  static pxToDp(px: number): number {
    const density = 3.0;
    return Math.round(px / density);
  }

  // 将 LayoutParams 宽度转换为 ArkUI 尺寸值
  static toArkUIWidth(params: LayoutParams): string | number {
    if (params.isMatchParent('width')) {
      return '100%';
    }
    if (params.isWrapContent('width')) {
      return 'auto';
    }
    return params.width;
  }

  // 将 LayoutParams 高度转换为 ArkUI 尺寸值
  static toArkUIHeight(params: LayoutParams): string | number {
    if (params.isMatchParent('height')) {
      return '100%';
    }
    if (params.isWrapContent('height')) {
      return 'auto';
    }
    return params.height;
  }

  // 将 Gravity 转换为 ArkUI 的 Alignment
  static toArkUIAlignment(gravity: number): { horizontal: number, vertical: number } {
    let horizontal = 0; // Alignment.Start
    let vertical = 0;   // Alignment.Top

    // 水平方向
    if (Gravity.has(gravity, Gravity.CENTER_HORIZONTAL) || Gravity.has(gravity, Gravity.CENTER)) {
      horizontal = 2; // Alignment.Center
    } else if (Gravity.has(gravity, Gravity.RIGHT) || Gravity.has(gravity, Gravity.END)) {
      horizontal = 1; // Alignment.End
    }

    // 垂直方向
    if (Gravity.has(gravity, Gravity.CENTER_VERTICAL) || Gravity.has(gravity, Gravity.CENTER)) {
      vertical = 2; // Alignment.Center
    } else if (Gravity.has(gravity, Gravity.BOTTOM)) {
      vertical = 1; // Alignment.Bottom
    }

    return { horizontal, vertical };
  }
}
