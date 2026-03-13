/**
 * index.ets
 *
 * Module barrel exports for the View.Bridge view components package.
 *
 * Usage:
 *   import { AndroidTextView, AndroidButton, AndroidEditText } from './view';
 */

// Base View and Proxy
export { AndroidView, ViewProxy, ViewConstants } from './AndroidView';

// Text components
export { AndroidTextView, TextViewProxy } from './AndroidTextView';
export { AndroidEditText, EditTextProxy, InputTypeConstants } from './AndroidEditText';
export { AndroidTextClock, TextClockProxy } from './AndroidTextClock';

// Button components
export { AndroidButton, ButtonProxy } from './AndroidButton';

// Image components
export { AndroidImageView, ImageViewProxy, ScaleType } from './AndroidImageView';

// CheckBox components
export { AndroidCheckBox, CheckBoxProxy, OnCheckedChangeListener, CompoundButton } from './AndroidCheckBox';

// Layout parameters
export {
  Margin,
  Padding,
  Gravity,
  LayoutParams,
  LinearLayoutParams,
  RelativeLayoutParams,
  FrameLayoutParams,
  DimensionUtils
} from './LayoutParams';
