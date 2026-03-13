/**
 * CharSequence.ets
 *
 * Bridge for Java's CharSequence interface.
 * In Android, TextView.getText() returns a CharSequence.
 * This class wraps a plain string to provide the same API surface.
 */

export class CharSequence {
  private _value: string;

  constructor(value: string) {
    this._value = value;
  }

  /**
   * Returns the string representation of this CharSequence.
   */
  toString(): string {
    return this._value;
  }

  /**
   * Returns the number of characters in this sequence.
   */
  length(): number {
    return this._value.length;
  }

  /**
   * Returns the character at the specified index.
   * @param index - zero-based position
   * @throws RangeError if index is out of bounds
   */
  charAt(index: number): string {
    if (index < 0 || index >= this._value.length) {
      throw new RangeError(`Index ${index} out of range [0, ${this._value.length})`);
    }
    return this._value.charAt(index);
  }

  /**
   * Returns a sub-sequence from start (inclusive) to end (exclusive).
   * Mirrors Java's CharSequence.subSequence(int start, int end).
   * @param start - inclusive start index
   * @param end - exclusive end index
   */
  subSequence(start: number, end: number): string {
    if (start < 0 || end > this._value.length || start > end) {
      throw new RangeError(`Invalid range [${start}, ${end}) for length ${this._value.length}`);
    }
    return this._value.substring(start, end);
  }
}
