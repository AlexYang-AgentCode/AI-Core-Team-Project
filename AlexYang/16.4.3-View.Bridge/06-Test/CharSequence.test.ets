/**
 * CharSequence.test.ets
 *
 * Unit tests for CharSequence - Java CharSequence interface simulation.
 */

import { describe, it, expect } from '@ohos/hypium';
import { CharSequence } from '../05-Implementation/widgets/CharSequence';

export default function charSequenceTest() {
  describe('CharSequence Tests', () => {

    describe('Construction and toString', () => {
      it('should create CharSequence with string value', () => {
        const cs = new CharSequence('Hello');
        expect(cs.toString()).assertEqual('Hello');
      });

      it('should create CharSequence with empty string', () => {
        const cs = new CharSequence('');
        expect(cs.toString()).assertEqual('');
      });

      it('should handle special characters', () => {
        const cs = new CharSequence('Hello\nWorld\t!');
        expect(cs.toString()).assertEqual('Hello\nWorld\t!');
      });
    });

    describe('length', () => {
      it('should return correct length', () => {
        const cs = new CharSequence('Hello');
        expect(cs.length()).assertEqual(5);
      });

      it('should return 0 for empty string', () => {
        const cs = new CharSequence('');
        expect(cs.length()).assertEqual(0);
      });

      it('should handle Unicode characters', () => {
        const cs = new CharSequence('Hello世界');
        expect(cs.length()).assertEqual(7);
      });
    });

    describe('charAt', () => {
      it('should return correct character at index', () => {
        const cs = new CharSequence('Hello');
        expect(cs.charAt(0)).assertEqual('H');
        expect(cs.charAt(1)).assertEqual('e');
        expect(cs.charAt(4)).assertEqual('o');
      });

      it('should throw for negative index', () => {
        const cs = new CharSequence('Hello');
        try {
          cs.charAt(-1);
          expect().assertFail('Should have thrown RangeError');
        } catch (e) {
          expect(e instanceof RangeError).assertTrue();
        }
      });

      it('should throw for index out of bounds', () => {
        const cs = new CharSequence('Hello');
        try {
          cs.charAt(5);
          expect().assertFail('Should have thrown RangeError');
        } catch (e) {
          expect(e instanceof RangeError).assertTrue();
        }
      });
    });

    describe('subSequence', () => {
      it('should return correct subsequence', () => {
        const cs = new CharSequence('Hello World');
        const result = cs.subSequence(0, 5);
        expect(result).assertEqual('Hello');
      });

      it('should return substring in middle', () => {
        const cs = new CharSequence('Hello World');
        const result = cs.subSequence(6, 11);
        expect(result).assertEqual('World');
      });

      it('should return empty string for equal indices', () => {
        const cs = new CharSequence('Hello');
        const result = cs.subSequence(2, 2);
        expect(result).assertEqual('');
      });

      it('should throw for invalid range', () => {
        const cs = new CharSequence('Hello');
        try {
          cs.subSequence(3, 2); // start > end
          expect().assertFail('Should have thrown RangeError');
        } catch (e) {
          expect(e instanceof RangeError).assertTrue();
        }
      });

      it('should throw for end out of bounds', () => {
        const cs = new CharSequence('Hello');
        try {
          cs.subSequence(0, 10);
          expect().assertFail('Should have thrown RangeError');
        } catch (e) {
          expect(e instanceof RangeError).assertTrue();
        }
      });
    });
  });
}
