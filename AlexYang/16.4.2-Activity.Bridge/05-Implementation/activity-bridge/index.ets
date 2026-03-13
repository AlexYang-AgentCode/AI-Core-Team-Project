/**
 * index.ets — Module exports for activity-bridge
 *
 * Centralises all public API exports so consumers can import from
 * a single entry point:
 *
 *   import { BridgedActivity, Bundle, LayoutRegistry } from './activity-bridge';
 */

// Core Activity bridge
export { BridgedActivity } from './BridgedActivity';

// Bundle (Want parameter wrapper)
export { Bundle } from './Bundle';

// Registry: layout id -> ArkUI page path
export { LayoutRegistry } from './LayoutRegistry';

// Registry: view id -> component reference
export { ViewRegistry } from './ViewRegistry';

// Event interfaces and base View/MotionEvent classes
export { OnClickListener, OnTouchListener, MotionEvent, View } from './OnClickListener';
