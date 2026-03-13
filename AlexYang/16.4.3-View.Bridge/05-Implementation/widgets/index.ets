/**
 * index.ets
 *
 * Module barrel exports for the View.Bridge widgets package.
 *
 * Usage:
 *   import { ViewBridge, TextViewBridge, ButtonBridge } from './widgets';
 */

// Core types
export { CharSequence } from './CharSequence';
export { ColorBridge, PorterDuff } from './ColorBridge';
export { DrawableBridge } from './DrawableBridge';
export { ToastBridge, ToastMessage, ToastDuration, Toast } from './ToastBridge';
export { AlertDialogBridge, AlertDialogBuilder, AlertDialog } from './AlertDialogBridge';

// View hierarchy
export { ViewBridge, OnClickListener, OnTouchListener, MotionEventType } from './ViewBridge';
export { TextViewBridge, TypedValue } from './TextViewBridge';
export { ButtonBridge } from './ButtonBridge';

// Layout containers and constants
export { LinearLayoutBridge, Gravity, ViewVisibility } from './LayoutBridge';

// MotionEvent system
export {
  MotionEvent,
  PointerProperties,
  PointerCoords,
  MotionEventActions,
  MotionEventAxis,
  MotionEventToolType,
  MotionEventButtonState,
  MotionEventFlags,
  MotionEventEdgeFlags,
  Actions,
  Axis,
  ToolType,
  ButtonState,
  Flags,
  EdgeFlags
} from './MotionEvent';
