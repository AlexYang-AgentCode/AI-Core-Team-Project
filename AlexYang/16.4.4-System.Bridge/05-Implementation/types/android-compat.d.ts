/**
 * android-compat.d.ts
 * Android API类型定义文件
 * 
 * 为桥接组件提供TypeScript类型支持
 */

// ============================================
// Android Context 类型
// ============================================

/**
 * Android Context接口
 */
export interface Context {
  getApplicationContext(): Context;
  getResources(): Resources;
  getString(resId: number): string;
  getColor(resId: number): number;
  getDrawable(resId: number): Drawable;
  getPackageName(): string;
}

/**
 * Android Resources接口
 */
export interface Resources {
  getString(id: number): string;
  getString(id: number, ...formatArgs: any[]): string;
  getText(id: number): string;
  getQuantityString(id: number, quantity: number): string;
  getColor(id: number): number;
  getColorStateList(id: number): ColorStateList;
  getDimension(id: number): number;
  getDimensionPixelSize(id: number): number;
  getDrawable(id: number): Drawable;
  getBoolean(id: number): boolean;
  getInteger(id: number): number;
  getIntArray(id: number): number[];
  getStringArray(id: number): string[];
  getTextArray(id: number): string[];
}

/**
 * Drawable接口
 */
export interface Drawable {
  setAlpha(alpha: number): void;
  setColorFilter(color: number, mode: PorterDuffMode): void;
  getIntrinsicWidth(): number;
  getIntrinsicHeight(): number;
}

/**
 * ColorStateList接口
 */
export interface ColorStateList {
  getDefaultColor(): number;
  getColorForState(stateSet: number[], defaultColor: number): number;
}

/**
 * PorterDuff混合模式
 */
export type PorterDuffMode = 
  | 'CLEAR' | 'SRC' | 'DST' | 'SRC_OVER' | 'DST_OVER'
  | 'SRC_IN' | 'DST_IN' | 'SRC_OUT' | 'DST_OUT'
  | 'SRC_ATOP' | 'DST_ATOP' | 'XOR' | 'DARKEN'
  | 'LIGHTEN' | 'MULTIPLY' | 'SCREEN' | 'ADD' | 'OVERLAY';

// ============================================
// Android View 类型
// ============================================

/**
 * View接口
 */
export interface View {
  getId(): number;
  setId(id: number): void;
  getVisibility(): number;
  setVisibility(visibility: number): void;
  getWidth(): number;
  getHeight(): number;
  getMeasuredWidth(): number;
  getMeasuredHeight(): number;
  getX(): number;
  getY(): number;
  setX(x: number): void;
  setY(y: number): void;
  getAlpha(): number;
  setAlpha(alpha: number): void;
  getTranslationX(): number;
  getTranslationY(): number;
  setTranslationX(x: number): void;
  setTranslationY(y: number): void;
  getScaleX(): number;
  getScaleY(): number;
  setScaleX(scaleX: number): void;
  setScaleY(scaleY: number): void;
  getRotation(): number;
  setRotation(rotation: number): void;
  getRotationX(): number;
  getRotationY(): number;
  setRotationX(rotation: number): void;
  setRotationY(rotation: number): void;
  isEnabled(): boolean;
  setEnabled(enabled: boolean): void;
  isClickable(): boolean;
  setClickable(clickable: boolean): void;
  isFocusable(): boolean;
  setFocusable(focusable: boolean): void;
  requestFocus(): boolean;
  clearFocus(): void;
  invalidate(): void;
  post(runnable: () => void): boolean;
  postDelayed(runnable: () => void, delayMillis: number): boolean;
  removeCallbacks(runnable: () => void): boolean;
}

/**
 * View可见性常量
 */
export declare const View: {
  VISIBLE: 0;
  INVISIBLE: 4;
  GONE: 8;
};

/**
 * MotionEvent接口
 */
export interface MotionEvent {
  getAction(): number;
  getActionMasked(): number;
  getActionIndex(): number;
  getX(): number;
  getY(): number;
  getRawX(): number;
  getRawY(): number;
  getPointerCount(): number;
  getPointerId(pointerIndex: number): number;
  getPressure(): number;
  getSize(): number;
  getEventTime(): number;
  getDownTime(): number;
}

/**
 * MotionEvent动作常量
 */
export declare const MotionEvent: {
  ACTION_DOWN: 0;
  ACTION_UP: 1;
  ACTION_MOVE: 2;
  ACTION_CANCEL: 3;
  ACTION_OUTSIDE: 4;
  ACTION_POINTER_DOWN: 5;
  ACTION_POINTER_UP: 6;
};

// ============================================
// Android Widget 类型
// ============================================

/**
 * TextView接口
 */
export interface TextView extends View {
  getText(): string;
  setText(text: string | number): void;
  setTextColor(color: number): void;
  getTextColors(): ColorStateList;
  setTextSize(size: number): void;
  setTextSize(unit: number, size: number): void;
  getTypeface(): Typeface;
  setTypeface(tf: Typeface): void;
  setTypeface(tf: Typeface, style: number): void;
  setGravity(gravity: number): void;
  getGravity(): number;
  setMaxLines(maxLines: number): void;
  getMaxLines(): number;
  setSingleLine(singleLine: boolean): void;
  setEllipsize(where: TextUtilsTruncateAt): void;
  setHorizontallyScrolling(whether: boolean): void;
  setMovementMethod(movement: MovementMethod): void;
}

/**
 * Button接口
 */
export interface Button extends TextView {
  // Button继承TextView，无额外方法
}

/**
 * EditText接口
 */
export interface EditText extends TextView {
  getText(): Editable;
  setText(text: string): void;
  setHint(hint: string): void;
  getHint(): string;
  setInputType(type: number): void;
  getInputType(): number;
  setSelection(index: number): void;
  setSelection(start: number, stop: number): void;
  getSelectionStart(): number;
  getSelectionEnd(): number;
  setFilters(filters: InputFilter[]): void;
  getFilters(): InputFilter[];
}

/**
 * ImageView接口
 */
export interface ImageView extends View {
  setImageResource(resId: number): void;
  setImageDrawable(drawable: Drawable): void;
  setImageBitmap(bm: Bitmap): void;
  setScaleType(scaleType: ScaleType): void;
  getScaleType(): ScaleType;
  setColorFilter(color: number): void;
  setColorFilter(color: number, mode: PorterDuffMode): void;
  clearColorFilter(): void;
}

/**
 * ScaleType枚举
 */
export type ScaleType = 
  | 'MATRIX' | 'FIT_XY' | 'FIT_START' | 'FIT_CENTER' 
  | 'FIT_END' | 'CENTER' | 'CENTER_CROP' | 'CENTER_INSIDE';

/**
 * 字体类型
 */
export interface Typeface {
  // 字体类型标记
}

/**
 * 可编辑文本
 */
export interface Editable {
  toString(): string;
  append(text: string): Editable;
  insert(where: number, text: string): Editable;
  delete(start: number, end: number): Editable;
  clear(): void;
  clearSpans(): void;
}

/**
 * 输入过滤器
 */
export interface InputFilter {
  filter(source: string, start: number, end: number, dest: string, dstart: number, dend: number): string | null;
}

/**
 * 文本截断位置
 */
export type TextUtilsTruncateAt = 'START' | 'MIDDLE' | 'END' | 'MARQUEE';

/**
 * 移动方法
 */
export interface MovementMethod {
  // 移动方法接口
}

/**
 * 位图
 */
export interface Bitmap {
  getWidth(): number;
  getHeight(): number;
  getConfig(): BitmapConfig;
  isRecycled(): boolean;
  recycle(): void;
}

/**
 * 位图配置
 */
export type BitmapConfig = 'ALPHA_8' | 'RGB_565' | 'ARGB_4444' | 'ARGB_8888';

// ============================================
// Android Animation 类型
// ============================================

/**
 * 动画接口
 */
export interface Animation {
  setDuration(durationMillis: number): void;
  getDuration(): number;
  setStartOffset(startOffset: number): void;
  getStartOffset(): number;
  setRepeatCount(repeatCount: number): void;
  getRepeatCount(): number;
  setRepeatMode(repeatMode: number): void;
  getRepeatMode(): number;
  setInterpolator(interpolator: Interpolator): void;
  setAnimationListener(listener: AnimationListener): void;
  start(): void;
  cancel(): void;
  isRunning(): boolean;
}

/**
 * 动画监听器
 */
export interface AnimationListener {
  onAnimationStart(animation: Animation): void;
  onAnimationEnd(animation: Animation): void;
  onAnimationRepeat(animation: Animation): void;
}

/**
 * 插值器
 */
export interface Interpolator {
  getInterpolation(input: number): number;
}

// ============================================
// Android Util 类型
// ============================================

/**
 * Log接口
 */
export interface Log {
  v(tag: string, msg: string): number;
  d(tag: string, msg: string): number;
  i(tag: string, msg: string): number;
  w(tag: string, msg: string): number;
  e(tag: string, msg: string): number;
}

/**
 * TextUtils接口
 */
export interface TextUtils {
  isEmpty(str: string | null | undefined): boolean;
  equals(a: string, b: string): boolean;
  getTrimmedLength(s: string): number;
}

// ============================================
// Android Content 类型
// ============================================

/**
 * Intent接口
 */
export interface Intent {
  setAction(action: string): Intent;
  getAction(): string | null;
  setData(data: Uri): Intent;
  getData(): Uri | null;
  setType(type: string): Intent;
  getType(): string | null;
  putExtra(name: string, value: any): Intent;
  getStringExtra(name: string): string | null;
  getIntExtra(name: string, defaultValue: number): number;
  getBooleanExtra(name: string, defaultValue: boolean): boolean;
  setComponent(component: ComponentName): Intent;
  getComponent(): ComponentName | null;
  setClass(context: Context, cls: any): Intent;
}

/**
 * URI接口
 */
export interface Uri {
  toString(): string;
  getScheme(): string | null;
  getAuthority(): string | null;
  getPath(): string | null;
  getQuery(): string | null;
  getFragment(): string | null;
}

/**
 * 组件名称
 */
export interface ComponentName {
  getPackageName(): string;
  getClassName(): string;
}

// ============================================
// Android OS 类型
// ============================================

/**
 * Bundle接口
 */
export interface Bundle {
  putString(key: string, value: string): void;
  getString(key: string): string | null;
  getString(key: string, defaultValue: string): string;
  putInt(key: string, value: number): void;
  getInt(key: string): number;
  getInt(key: string, defaultValue: number): number;
  putBoolean(key: string, value: boolean): void;
  getBoolean(key: string): boolean;
  getBoolean(key: string, defaultValue: boolean): boolean;
  putDouble(key: string, value: number): void;
  getDouble(key: string): number;
  getDouble(key: string, defaultValue: number): number;
  putStringArrayList(key: string, value: string[]): void;
  getStringArrayList(key: string): string[] | null;
  isEmpty(): boolean;
  size(): number;
  clear(): void;
  remove(key: string): void;
  containsKey(key: string): boolean;
  keySet(): string[];
}

/**
 * Parcelable接口
 */
export interface Parcelable {
  // 标记接口，用于可序列化对象
}

/**
 * Handler接口
 */
export interface Handler {
  post(r: Runnable): boolean;
  postDelayed(r: Runnable, delayMillis: number): boolean;
  removeCallbacks(r: Runnable): void;
  sendMessage(msg: Message): boolean;
}

/**
 * Runnable接口
 */
export interface Runnable {
  run(): void;
}

/**
 * Message接口
 */
export interface Message {
  what: number;
  arg1: number;
  arg2: number;
  obj: any;
  replyTo: Messenger | null;
}

/**
 * Messenger接口
 */
export interface Messenger {
  send(message: Message): void;
}

// ============================================
// 通用工具类型
// ============================================

/**
 * 资源引用类型
 */
export interface Resource {
  id: number;
  name: string;
  type: string;
  toString(): string;
}

/**
 * 尺寸单位转换
 */
export declare const TypedValue: {
  COMPLEX_UNIT_PX: 0;
  COMPLEX_UNIT_DIP: 1;
  COMPLEX_UNIT_SP: 2;
  COMPLEX_UNIT_PT: 3;
  COMPLEX_UNIT_IN: 4;
  COMPLEX_UNIT_MM: 5;
  applyDimension(unit: number, value: number, metrics: DisplayMetrics): number;
};

/**
 * 显示指标
 */
export interface DisplayMetrics {
  density: number;
  densityDpi: number;
  scaledDensity: number;
  widthPixels: number;
  heightPixels: number;
  xdpi: number;
  ydpi: number;
}

// 默认导出
export {};
