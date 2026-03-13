/**
 * Activity Bridge - Core Implementation
 * 
 * This module provides Android Activity API compatibility for HarmonyOS.
 * It is designed to be used by 16.4.1 JIT compiler generated code.
 * 
 * Dependencies:
 * - 16.4.3 View.Bridge: View/Widget implementations
 * - 16.4.4 System.Bridge: Context/Resources/Log
 */

// ===== Activity Classes =====
export { Activity } from './activity/Activity';
export { FragmentActivity } from './activity/FragmentActivity';
export { AppCompatActivity } from './activity/AppCompatActivity';

// ===== Lifecycle =====
export { Bundle } from './os/Bundle';
export { Lifecycle } from './lifecycle/Lifecycle';
export { LifecycleOwner } from './lifecycle/LifecycleOwner';
export { LifecycleState } from './lifecycle/LifecycleState';

// ===== Content =====
export { Context } from './content/Context';
export { Intent } from './content/Intent';
export { ComponentName } from './content/ComponentName';

// ===== View Callbacks =====
export { 
  View,
  OnClickListener, 
  OnTouchListener, 
  OnKeyListener,
  OnLongClickListener 
} from './view/View';

// ===== Widgets =====
export { Toast } from './widget/Toast';

// ===== Constants =====
export {
  RESULT_OK,
  RESULT_CANCELED,
  FLAG_ACTIVITY_NEW_TASK,
  FLAG_ACTIVITY_CLEAR_TOP,
  FLAG_ACTIVITY_SINGLE_TOP
} from './content/Intent';

// ===== JIT Compiler Interface =====
export { ActivityCompilerInterface } from './jit/CompilerInterface';

// ===== Version Info =====
export const VERSION = '1.0.0';
export const VERSION_CODE = 1;
