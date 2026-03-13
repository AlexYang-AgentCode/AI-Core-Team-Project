import { hilog } from '@kit.PerformanceAnalysisKit';

// Re-export all public APIs from ets directory
export { Activity } from '../ets/activity/Activity';
export { AppCompatActivity } from '../ets/activity/AppCompatActivity';
export { FragmentActivity, Fragment, FragmentManager, FragmentTransaction } from '../ets/activity/FragmentActivity';

export { Bundle } from '../ets/os/Bundle';
export { ActivityState, LifecycleStateMachine, LifecycleEvent, stateToEvent } from '../ets/lifecycle/LifecycleState';
export { Lifecycle, LifecycleObserver, DefaultLifecycleObserver } from '../ets/lifecycle/Lifecycle';
export { LifecycleOwner, LifecycleOwnerBase } from '../ets/lifecycle/LifecycleOwner';

export {
  View,
  OnClickListener,
  OnTouchListener,
  OnLongClickListener,
  OnKeyListener,
  MotionEvent,
  KeyEvent
} from '../ets/view/View';

export { viewFinder, ViewIdRegistry, ViewFinder } from '../ets/view/ViewFinder';
export { layoutInflater, LayoutRegistry, PageLoadNotifier, PageLoadListener, LayoutInflater } from '../ets/view/LayoutInflater';

export {
  Context,
  Intent,
  ComponentName,
  Resources,
  Drawable,
  AssetManager,
  ClassLoader,
  SharedPreferences,
  Theme,
  Bundle as ContextBundle,
  RESULT_OK,
  RESULT_CANCELED,
  FLAG_ACTIVITY_NEW_TASK,
  FLAG_ACTIVITY_CLEAR_TOP,
  FLAG_ACTIVITY_SINGLE_TOP,
  FLAG_ACTIVITY_NO_HISTORY,
  MODE_PRIVATE,
  MODE_WORLD_READABLE,
  MODE_WORLD_WRITEABLE,
  MODE_MULTI_PROCESS
} from '../ets/content/Context';

export { Toast, GRAVITY_TOP, GRAVITY_BOTTOM, GRAVITY_CENTER, GRAVITY_LEFT, GRAVITY_RIGHT, GRAVITY_CENTER_VERTICAL, GRAVITY_CENTER_HORIZONTAL } from '../ets/widget/Toast';

export {
  ActivityCompilerInterface,
  ActivityClassRegistry,
  RegistrationBatch,
  ActivityRegistration,
  LayoutRegistration,
  ViewIdRegistration
} from '../ets/jit/CompilerInterface';
export { ActivityGenerator, LifecycleEventRecorder, JITTestHelper, JITCompilerInterface } from '../ets/jit/JITCompilerInterface';

// Test utilities
export { LifecycleLogger, globalLifecycleLogger } from '../ets/test/LifecycleLogger';

// Version
export const VERSION = '1.0.0';
export const VERSION_CODE = 1;

hilog.info(0x0000, 'ActivityBridge', `Activity Bridge v${VERSION} initialized`);
