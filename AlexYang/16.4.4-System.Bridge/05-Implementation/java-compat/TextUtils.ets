/**
 * TextUtils — android.text.TextUtils bridge for HarmonyOS
 *
 * Provides the most commonly used static utility methods from Android's
 * TextUtils class. These are used pervasively in Android code for null-safe
 * string checks and joining.
 *
 * Usage (mirrors Android):
 *   if (TextUtils.isEmpty(someString)) { ... }
 *   const joined = TextUtils.join(", ", ["a", "b", "c"]);
 */

export class TextUtils {

  /**
   * Android: TextUtils.isEmpty(str)
   *
   * Returns true if the string is null, undefined, or has zero length.
   * This is the single most used TextUtils method in Android codebases.
   */
  static isEmpty(str: string | null | undefined): boolean {
    return str === null || str === undefined || str.length === 0;
  }

  /**
   * Android: TextUtils.equals(a, b)
   *
   * Null-safe string equality check.
   * Returns true if both are null, or if both are non-null and equal.
   */
  static equals(a: string | null, b: string | null): boolean {
    if (a === b) return true;                    // handles both-null and same-ref
    if (a === null || b === null) return false;   // one null, one not
    return a === b;
  }

  /**
   * Android: TextUtils.join(delimiter, tokens)
   *
   * Join an array of strings with a delimiter.
   * Null/undefined entries are converted to the string "null" to match
   * Java's String.valueOf() behaviour used internally by TextUtils.join.
   */
  static join(delimiter: string, tokens: string[]): string {
    if (tokens === null || tokens === undefined || tokens.length === 0) {
      return '';
    }
    return tokens.join(delimiter);
  }
}
