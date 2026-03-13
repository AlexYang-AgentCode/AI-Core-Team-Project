/**
 * MotionEvent.ets
 *
 * Complete implementation of Android's MotionEvent for touch event handling.
 *
 * MotionEvent represents movement events such as finger touches on the screen.
 * It includes the position, pressure, size, and other properties of the touch.
 */

/**
 * Action constants matching Android's MotionEvent action codes.
 * The action code is stored in the low 8 bits of the action value.
 */
export class MotionEventActions {
  /** Bit mask for the action code itself. */
  static readonly ACTION_MASK: number = 0xff;

  /** Bits for the pointer index (used with ACTION_POINTER_DOWN/UP). */
  static readonly ACTION_POINTER_INDEX_MASK: number = 0xff00;
  static readonly ACTION_POINTER_INDEX_SHIFT: number = 8;

  /** Constant for ACTION_DOWN (0). */
  static readonly ACTION_DOWN: number = 0;

  /** Constant for ACTION_UP (1). */
  static readonly ACTION_UP: number = 1;

  /** Constant for ACTION_MOVE (2). */
  static readonly ACTION_MOVE: number = 2;

  /** Constant for ACTION_CANCEL (3). */
  static readonly ACTION_CANCEL: number = 3;

  /** Constant for ACTION_OUTSIDE (4). */
  static readonly ACTION_OUTSIDE: number = 4;

  /** Constant for ACTION_POINTER_DOWN (5). */
  static readonly ACTION_POINTER_DOWN: number = 5;

  /** Constant for ACTION_POINTER_UP (6). */
  static readonly ACTION_POINTER_UP: number = 6;

  /** Constant for ACTION_HOVER_MOVE (7). */
  static readonly ACTION_HOVER_MOVE: number = 7;

  /** Constant for ACTION_SCROLL (8). */
  static readonly ACTION_SCROLL: number = 8;

  /** Constant for ACTION_HOVER_ENTER (9). */
  static readonly ACTION_HOVER_ENTER: number = 9;

  /** Constant for ACTION_HOVER_EXIT (10). */
  static readonly ACTION_HOVER_EXIT: number = 10;

  /** Constant for ACTION_BUTTON_PRESS (11). */
  static readonly ACTION_BUTTON_PRESS: number = 11;

  /** Constant for ACTION_BUTTON_RELEASE (12). */
  static readonly ACTION_BUTTON_RELEASE: number = 12;
}

/**
 * Axis constants for motion event values.
 */
export class MotionEventAxis {
  static readonly AXIS_X: number = 0;
  static readonly AXIS_Y: number = 1;
  static readonly AXIS_PRESSURE: number = 2;
  static readonly AXIS_SIZE: number = 3;
  static readonly AXIS_TOUCH_MAJOR: number = 4;
  static readonly AXIS_TOUCH_MINOR: number = 5;
  static readonly AXIS_TOOL_MAJOR: number = 6;
  static readonly AXIS_TOOL_MINOR: number = 7;
  static readonly AXIS_ORIENTATION: number = 8;
  static readonly AXIS_VSCROLL: number = 9;
  static readonly AXIS_HSCROLL: number = 10;
  static readonly AXIS_Z: number = 11;
  static readonly AXIS_RX: number = 12;
  static readonly AXIS_RY: number = 13;
  static readonly AXIS_RZ: number = 14;
  static readonly AXIS_HAT_X: number = 15;
  static readonly AXIS_HAT_Y: number = 16;
  static readonly AXIS_LTRIGGER: number = 17;
  static readonly AXIS_RTRIGGER: number = 18;
  static readonly AXIS_THROTTLE: number = 19;
  static readonly AXIS_RUDDER: number = 20;
  static readonly AXIS_WHEEL: number = 21;
  static readonly AXIS_GAS: number = 22;
  static readonly AXIS_BRAKE: number = 23;
  static readonly AXIS_DISTANCE: number = 24;
  static readonly AXIS_TILT: number = 25;
  static readonly AXIS_GENERIC_1: number = 32;
  static readonly AXIS_GENERIC_2: number = 33;
  static readonly AXIS_GENERIC_3: number = 34;
  static readonly AXIS_GENERIC_4: number = 35;
  static readonly AXIS_GENERIC_5: number = 36;
  static readonly AXIS_GENERIC_6: number = 37;
  static readonly AXIS_GENERIC_7: number = 38;
  static readonly AXIS_GENERIC_8: number = 39;
  static readonly AXIS_GENERIC_9: number = 40;
  static readonly AXIS_GENERIC_10: number = 41;
  static readonly AXIS_GENERIC_11: number = 42;
  static readonly AXIS_GENERIC_12: number = 43;
  static readonly AXIS_GENERIC_13: number = 44;
  static readonly AXIS_GENERIC_14: number = 45;
  static readonly AXIS_GENERIC_15: number = 46;
  static readonly AXIS_GENERIC_16: number = 47;
}

/**
 * Pointer properties - represents properties of a single pointer.
 */
export class PointerProperties {
  id: number = 0;
  toolType: number = MotionEventToolType.TOOL_TYPE_FINGER;

  constructor(id?: number, toolType?: number) {
    if (id !== undefined) this.id = id;
    if (toolType !== undefined) this.toolType = toolType;
  }

  copyFrom(other: PointerProperties): void {
    this.id = other.id;
    this.toolType = other.toolType;
  }
}

/**
 * Pointer coordinates - represents coordinates of a single pointer.
 */
export class PointerCoords {
  x: number = 0;
  y: number = 0;
  pressure: number = 1.0;
  size: number = 0;
  touchMajor: number = 0;
  touchMinor: number = 0;
  toolMajor: number = 0;
  toolMinor: number = 0;
  orientation: number = 0;

  /** Additional axis values. */
  private axisValues: Map<number, number> = new Map();

  clear(): void {
    this.x = 0;
    this.y = 0;
    this.pressure = 1.0;
    this.size = 0;
    this.touchMajor = 0;
    this.touchMinor = 0;
    this.toolMajor = 0;
    this.toolMinor = 0;
    this.orientation = 0;
    this.axisValues.clear();
  }

  copyFrom(other: PointerCoords): void {
    this.x = other.x;
    this.y = other.y;
    this.pressure = other.pressure;
    this.size = other.size;
    this.touchMajor = other.touchMajor;
    this.touchMinor = other.touchMinor;
    this.toolMajor = other.toolMajor;
    this.toolMinor = other.toolMinor;
    this.orientation = other.orientation;
    this.axisValues = new Map(other.axisValues);
  }

  getAxisValue(axis: number): number {
    if (this.axisValues.has(axis)) {
      return this.axisValues.get(axis)!;
    }
    // Return default values for known axes
    switch (axis) {
      case MotionEventAxis.AXIS_X: return this.x;
      case MotionEventAxis.AXIS_Y: return this.y;
      case MotionEventAxis.AXIS_PRESSURE: return this.pressure;
      case MotionEventAxis.AXIS_SIZE: return this.size;
      case MotionEventAxis.AXIS_TOUCH_MAJOR: return this.touchMajor;
      case MotionEventAxis.AXIS_TOUCH_MINOR: return this.touchMinor;
      case MotionEventAxis.AXIS_TOOL_MAJOR: return this.toolMajor;
      case MotionEventAxis.AXIS_TOOL_MINOR: return this.toolMinor;
      case MotionEventAxis.AXIS_ORIENTATION: return this.orientation;
      default: return 0;
    }
  }

  setAxisValue(axis: number, value: number): void {
    this.axisValues.set(axis, value);
    switch (axis) {
      case MotionEventAxis.AXIS_X: this.x = value; break;
      case MotionEventAxis.AXIS_Y: this.y = value; break;
      case MotionEventAxis.AXIS_PRESSURE: this.pressure = value; break;
      case MotionEventAxis.AXIS_SIZE: this.size = value; break;
      case MotionEventAxis.AXIS_TOUCH_MAJOR: this.touchMajor = value; break;
      case MotionEventAxis.AXIS_TOUCH_MINOR: this.touchMinor = value; break;
      case MotionEventAxis.AXIS_TOOL_MAJOR: this.toolMajor = value; break;
      case MotionEventAxis.AXIS_TOOL_MINOR: this.toolMinor = value; break;
      case MotionEventAxis.AXIS_ORIENTATION: this.orientation = value; break;
    }
  }
}

/**
 * Tool type constants.
 */
export class MotionEventToolType {
  static readonly TOOL_TYPE_UNKNOWN: number = 0;
  static readonly TOOL_TYPE_FINGER: number = 1;
  static readonly TOOL_TYPE_STYLUS: number = 2;
  static readonly TOOL_TYPE_MOUSE: number = 3;
  static readonly TOOL_TYPE_ERASER: number = 4;
  static readonly TOOL_TYPE_BRUSH: number = 5;
  static readonly TOOL_TYPE_PENCIL: number = 6;
  static readonly TOOL_TYPE_AIRBRUSH: number = 7;
  static readonly TOOL_TYPE_LENS: number = 8;
  static readonly TOOL_TYPE_PALM: number = 9;
}

/**
 * Button state constants.
 */
export class MotionEventButtonState {
  static readonly BUTTON_PRIMARY: number = 1 << 0;
  static readonly BUTTON_SECONDARY: number = 1 << 1;
  static readonly BUTTON_TERTIARY: number = 1 << 2;
  static readonly BUTTON_BACK: number = 1 << 3;
  static readonly BUTTON_FORWARD: number = 1 << 4;
  static readonly BUTTON_STYLUS_PRIMARY: number = 1 << 5;
  static readonly BUTTON_STYLUS_SECONDARY: number = 1 << 6;
}

/**
 * Flags for the motion event.
 */
export class MotionEventFlags {
  static readonly FLAG_WINDOW_IS_OBSCURED: number = 0x1;
  static readonly FLAG_WINDOW_IS_PARTIALLY_OBSCURED: number = 0x2;
}

/**
 * Edge constants.
 */
export class MotionEventEdgeFlags {
  static readonly EDGE_TOP: number = 0x01;
  static readonly EDGE_BOTTOM: number = 0x02;
  static readonly EDGE_LEFT: number = 0x04;
  static readonly EDGE_RIGHT: number = 0x08;
}

/**
 * Historical event data for batching.
 */
class HistoricalEvent {
  eventTime: number = 0;
  pointerCoords: PointerCoords[] = [];

  constructor(eventTime: number, pointerCoords: PointerCoords[]) {
    this.eventTime = eventTime;
    this.pointerCoords = pointerCoords.map(pc => {
      const newPc = new PointerCoords();
      newPc.copyFrom(pc);
      return newPc;
    });
  }
}

/**
 * Complete MotionEvent implementation matching Android's MotionEvent.
 */
export class MotionEvent {
  // Action information
  private action: number = MotionEventActions.ACTION_DOWN;
  private actionMasked: number = MotionEventActions.ACTION_DOWN;
  private actionIndex: number = 0;

  // Event timing
  private downTime: number = 0;
  private eventTime: number = 0;

  // Pointer information
  private pointerCount: number = 1;
  private pointerProperties: PointerProperties[] = [];
  private pointerCoords: PointerCoords[] = [];

  // Meta state and flags
  private metaState: number = 0;
  private buttonState: number = 0;
  private flags: number = 0;
  private edgeFlags: number = 0;

  // Device information
  private deviceId: number = 0;
  private source: number = 0;

  // Historical events for batching
  private historicalEvents: HistoricalEvent[] = [];

  // Raw coordinates (before offset)
  private rawX: number = 0;
  private rawY: number = 0;

  // Coordinate offset
  private xOffset: number = 0;
  private yOffset: number = 0;

  // Precision values
  private xPrecision: number = 0;
  private yPrecision: number = 0;

  /**
   * Creates a new MotionEvent.
   */
  constructor(
    downTime: number,
    eventTime: number,
    action: number,
    pointerCount: number,
    pointerProperties: PointerProperties[],
    pointerCoords: PointerCoords[],
    metaState: number,
    buttonState: number,
    xPrecision: number,
    yPrecision: number,
    deviceId: number,
    edgeFlags: number,
    source: number,
    flags: number
  ) {
    this.downTime = downTime;
    this.eventTime = eventTime;
    this.action = action;
    this.pointerCount = pointerCount;
    this.pointerProperties = pointerProperties;
    this.pointerCoords = pointerCoords;
    this.metaState = metaState;
    this.buttonState = buttonState;
    this.xPrecision = xPrecision;
    this.yPrecision = yPrecision;
    this.deviceId = deviceId;
    this.edgeFlags = edgeFlags;
    this.source = source;
    this.flags = flags;

    // Calculate masked action and index
    this.actionMasked = action & MotionEventActions.ACTION_MASK;
    this.actionIndex = (action & MotionEventActions.ACTION_POINTER_INDEX_MASK)
      >> MotionEventActions.ACTION_POINTER_INDEX_SHIFT;

    // Set raw coordinates from first pointer
    if (pointerCoords.length > 0) {
      this.rawX = pointerCoords[0].x;
      this.rawY = pointerCoords[0].y;
    }
  }

  /**
   * Factory method to create a simple MotionEvent (simplified API).
   */
  static obtain(
    downTime: number,
    eventTime: number,
    action: number,
    x: number,
    y: number,
    metaState: number = 0
  ): MotionEvent {
    const props = new PointerProperties(0, MotionEventToolType.TOOL_TYPE_FINGER);
    const coords = new PointerCoords();
    coords.x = x;
    coords.y = y;

    return new MotionEvent(
      downTime,
      eventTime,
      action,
      1, // pointerCount
      [props],
      [coords],
      metaState,
      0, // buttonState
      0, // xPrecision
      0, // yPrecision
      0, // deviceId
      0, // edgeFlags
      0, // source
      0  // flags
    );
  }

  /**
   * Recycles the motion event (no-op in bridge, for API compatibility).
   */
  recycle(): void {
    // No-op in bridge implementation
  }

  // ---- Action methods ----

  /**
   * Returns the kind of action being performed.
   */
  getAction(): number {
    return this.action;
  }

  /**
   * Returns the masked action being performed, without pointer index info.
   */
  getActionMasked(): number {
    return this.actionMasked;
  }

  /**
   * Returns the associated pointer index for ACTION_POINTER_DOWN/UP.
   */
  getActionIndex(): number {
    return this.actionIndex;
  }

  // ---- Timing methods ----

  /**
   * Returns the time (in ms) when the user originally pressed down.
   */
  getDownTime(): number {
    return this.downTime;
  }

  /**
   * Returns the time (in ms) when this specific event occurred.
   */
  getEventTime(): number {
    return this.eventTime;
  }

  /**
   * Returns the time delta since the down event.
   */
  getEventTimeDelta(): number {
    return this.eventTime - this.downTime;
  }

  // ---- Coordinate methods ----

  /**
   * Returns the X coordinate of this event for the first pointer index.
   */
  getX(pointerIndex: number = 0): number {
    if (pointerIndex >= 0 && pointerIndex < this.pointerCoords.length) {
      return this.pointerCoords[pointerIndex].x + this.xOffset;
    }
    return 0;
  }

  /**
   * Returns the Y coordinate of this event for the first pointer index.
   */
  getY(pointerIndex: number = 0): number {
    if (pointerIndex >= 0 && pointerIndex < this.pointerCoords.length) {
      return this.pointerCoords[pointerIndex].y + this.yOffset;
    }
    return 0;
  }

  /**
   * Returns the raw X coordinate without offset.
   */
  getRawX(): number {
    return this.rawX;
  }

  /**
   * Returns the raw Y coordinate without offset.
   */
  getRawY(): number {
    return this.rawY;
  }

  /**
   * Returns the raw X coordinate for a specific pointer.
   */
  getRawXForPointer(pointerIndex: number): number {
    if (pointerIndex >= 0 && pointerIndex < this.pointerCoords.length) {
      return this.pointerCoords[pointerIndex].x;
    }
    return 0;
  }

  /**
   * Returns the raw Y coordinate for a specific pointer.
   */
  getRawYForPointer(pointerIndex: number): number {
    if (pointerIndex >= 0 && pointerIndex < this.pointerCoords.length) {
      return this.pointerCoords[pointerIndex].y;
    }
    return 0;
  }

  /**
   * Sets the coordinate offset.
   */
  setLocation(xOffset: number, yOffset: number): void {
    this.xOffset = xOffset;
    this.yOffset = yOffset;
  }

  /**
   * Returns the X precision.
   */
  getXPrecision(): number {
    return this.xPrecision;
  }

  /**
   * Returns the Y precision.
   */
  getYPrecision(): number {
    return this.yPrecision;
  }

  // ---- Pointer methods ----

  /**
   * Returns the number of pointers of data contained in this event.
   */
  getPointerCount(): number {
    return this.pointerCount;
  }

  /**
   * Returns the pointer identifier associated with a pointer index.
   */
  getPointerId(pointerIndex: number): number {
    if (pointerIndex >= 0 && pointerIndex < this.pointerProperties.length) {
      return this.pointerProperties[pointerIndex].id;
    }
    return -1;
  }

  /**
   * Gets the tool type of a pointer.
   */
  getToolType(pointerIndex: number): number {
    if (pointerIndex >= 0 && pointerIndex < this.pointerProperties.length) {
      return this.pointerProperties[pointerIndex].toolType;
    }
    return MotionEventToolType.TOOL_TYPE_UNKNOWN;
  }

  /**
   * Finds the pointer index of a pointer identifier.
   */
  findPointerIndex(pointerId: number): number {
    for (let i = 0; i < this.pointerProperties.length; i++) {
      if (this.pointerProperties[i].id === pointerId) {
        return i;
      }
    }
    return -1;
  }

  // ---- Axis value methods ----

  /**
   * Returns the value of the requested axis for a given pointer.
   */
  getAxisValue(axis: number, pointerIndex: number = 0): number {
    if (pointerIndex >= 0 && pointerIndex < this.pointerCoords.length) {
      return this.pointerCoords[pointerIndex].getAxisValue(axis);
    }
    return 0;
  }

  /**
   * Returns the current pressure.
   */
  getPressure(pointerIndex: number = 0): number {
    return this.getAxisValue(MotionEventAxis.AXIS_PRESSURE, pointerIndex);
  }

  /**
   * Returns the current size.
   */
  getSize(pointerIndex: number = 0): number {
    return this.getAxisValue(MotionEventAxis.AXIS_SIZE, pointerIndex);
  }

  /**
   * Returns the touch major axis.
   */
  getTouchMajor(pointerIndex: number = 0): number {
    return this.getAxisValue(MotionEventAxis.AXIS_TOUCH_MAJOR, pointerIndex);
  }

  /**
   * Returns the touch minor axis.
   */
  getTouchMinor(pointerIndex: number = 0): number {
    return this.getAxisValue(MotionEventAxis.AXIS_TOUCH_MINOR, pointerIndex);
  }

  /**
   * Returns the tool major axis.
   */
  getToolMajor(pointerIndex: number = 0): number {
    return this.getAxisValue(MotionEventAxis.AXIS_TOOL_MAJOR, pointerIndex);
  }

  /**
   * Returns the tool minor axis.
   */
  getToolMinor(pointerIndex: number = 0): number {
    return this.getAxisValue(MotionEventAxis.AXIS_TOOL_MINOR, pointerIndex);
  }

  /**
   * Returns the orientation.
   */
  getOrientation(pointerIndex: number = 0): number {
    return this.getAxisValue(MotionEventAxis.AXIS_ORIENTATION, pointerIndex);
  }

  // ---- State methods ----

  /**
   * Returns the current state of modifier keys.
   */
  getMetaState(): number {
    return this.metaState;
  }

  /**
   * Returns the current button state.
   */
  getButtonState(): number {
    return this.buttonState;
  }

  /**
   * Returns the current flags.
   */
  getFlags(): number {
    return this.flags;
  }

  /**
   * Returns the edge flags.
   */
  getEdgeFlags(): number {
    return this.edgeFlags;
  }

  /**
   * Sets the edge flags.
   */
  setEdgeFlags(flags: number): void {
    this.edgeFlags = flags;
  }

  /**
   * Returns true if this is a touch event.
   */
  isTouchEvent(): boolean {
    return (this.source & 0x0002) !== 0; // SOURCE_CLASS_POINTER
  }

  // ---- Device methods ----

  /**
   * Returns the device ID.
   */
  getDeviceId(): number {
    return this.deviceId;
  }

  /**
   * Returns the input source.
   */
  getSource(): number {
    return this.source;
  }

  /**
   * Sets the input source.
   */
  setSource(source: number): void {
    this.source = source;
  }

  // ---- Historical methods ----

  /**
   * Returns the number of historical points in this event.
   */
  getHistorySize(): number {
    return this.historicalEvents.length;
  }

  /**
   * Returns the time of a historical event.
   */
  getHistoricalEventTime(pos: number): number {
    if (pos >= 0 && pos < this.historicalEvents.length) {
      return this.historicalEvents[pos].eventTime;
    }
    return 0;
  }

  /**
   * Returns a historical X coordinate.
   */
  getHistoricalX(pointerIndex: number, pos: number): number {
    if (pos >= 0 && pos < this.historicalEvents.length) {
      const event = this.historicalEvents[pos];
      if (pointerIndex >= 0 && pointerIndex < event.pointerCoords.length) {
        return event.pointerCoords[pointerIndex].x + this.xOffset;
      }
    }
    return 0;
  }

  /**
   * Returns a historical Y coordinate.
   */
  getHistoricalY(pointerIndex: number, pos: number): number {
    if (pos >= 0 && pos < this.historicalEvents.length) {
      const event = this.historicalEvents[pos];
      if (pointerIndex >= 0 && pointerIndex < event.pointerCoords.length) {
        return event.pointerCoords[pointerIndex].y + this.yOffset;
      }
    }
    return 0;
  }

  /**
   * Adds a historical event.
   */
  addHistoricalEvent(eventTime: number, coords: PointerCoords[]): void {
    this.historicalEvents.push(new HistoricalEvent(eventTime, coords));
  }

  // ---- Utility methods ----

  /**
   * Returns a string representation of the action.
   */
  actionToString(action: number): string {
    switch (action) {
      case MotionEventActions.ACTION_DOWN: return 'ACTION_DOWN';
      case MotionEventActions.ACTION_UP: return 'ACTION_UP';
      case MotionEventActions.ACTION_MOVE: return 'ACTION_MOVE';
      case MotionEventActions.ACTION_CANCEL: return 'ACTION_CANCEL';
      case MotionEventActions.ACTION_OUTSIDE: return 'ACTION_OUTSIDE';
      case MotionEventActions.ACTION_POINTER_DOWN: return 'ACTION_POINTER_DOWN';
      case MotionEventActions.ACTION_POINTER_UP: return 'ACTION_POINTER_UP';
      case MotionEventActions.ACTION_HOVER_MOVE: return 'ACTION_HOVER_MOVE';
      case MotionEventActions.ACTION_SCROLL: return 'ACTION_SCROLL';
      case MotionEventActions.ACTION_HOVER_ENTER: return 'ACTION_HOVER_ENTER';
      case MotionEventActions.ACTION_HOVER_EXIT: return 'ACTION_HOVER_EXIT';
      default: return `ACTION_${action}`;
    }
  }

  /**
   * Returns a debug string representation.
   */
  toString(): string {
    const actionStr = this.actionToString(this.actionMasked);
    return `MotionEvent { action=${actionStr}, x=${this.getX()}, y=${this.getY()}, ` +
           `pointerCount=${this.pointerCount}, eventTime=${this.eventTime} }`;
  }
}

// Re-export commonly used classes
export { PointerProperties, PointerCoords };
export { MotionEventActions as Actions };
export { MotionEventAxis as Axis };
export { MotionEventToolType as ToolType };
export { MotionEventButtonState as ButtonState };
export { MotionEventFlags as Flags };
export { MotionEventEdgeFlags as EdgeFlags };
