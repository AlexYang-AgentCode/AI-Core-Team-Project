/**
 * index.ts
 * System Bridge 统一导出
 * 
 * 集中导出所有桥接组件，便于统一导入
 */

// ============================================
// Bridge 组件
// ============================================

export { Toast } from './bridges/ToastBridge';
export { ContextBridge, Context } from './bridges/ContextBridge';
export { BigDecimal, RoundingMode } from './bridges/DecimalBridge';
export { ExpressionEvaluator, ScriptEngine } from './bridges/ExpressionEvaluator';
export { TimeZoneBridge, TimeZone } from './bridges/TimeZoneBridge';
export { TouchEventBridge, MotionEvent, MotionEventCompat } from './bridges/TouchEventBridge';

// ============================================
// 工具类
// ============================================

export { Color, SystemColors } from './utils/SystemColors';
export { ResourceMapper, R, ResourceMapping, ResourceType } from './utils/ResourceMapper';

// ============================================
// 类型定义
// ============================================

export type {
  Context as IContext,
  Resources,
  Drawable,
  ColorStateList,
  PorterDuffMode,
  View,
  MotionEvent as IMotionEvent,
  TextView,
  Button,
  EditText,
  ImageView,
  ScaleType,
  Typeface,
  Editable,
  InputFilter,
  TextUtilsTruncateAt,
  MovementMethod,
  Bitmap,
  BitmapConfig,
  Animation,
  AnimationListener,
  Interpolator,
  Log,
  TextUtils,
  Intent,
  Uri,
  ComponentName,
  Bundle,
  Parcelable,
  Handler,
  Runnable,
  Message,
  Messenger,
  Resource,
  DisplayMetrics
} from './types/android-compat';

// ============================================
// 版本信息
// ============================================

export const VERSION = '1.0.0';
export const VERSION_NAME = 'System Bridge v1.0.0';

// ============================================
// 初始化辅助函数
// ============================================

import { ContextBridge } from './bridges/ContextBridge';
import { ResourceMapper } from './utils/ResourceMapper';

/**
 * 初始化System Bridge
 * @param context UIAbilityContext实例
 */
export function initialize(context: any): void {
  ContextBridge.initialize(context);
  console.log('[System Bridge] Initialized successfully');
}

/**
 * 检查System Bridge是否已初始化
 */
export function isInitialized(): boolean {
  return ContextBridge.isInitialized();
}

// ============================================
// 默认导出
// ============================================

export default {
  VERSION,
  VERSION_NAME,
  initialize,
  isInitialized
};
