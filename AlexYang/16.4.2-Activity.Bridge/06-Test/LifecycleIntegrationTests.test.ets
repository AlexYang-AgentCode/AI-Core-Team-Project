/**
 * Lifecycle Integration Tests
 * 
 * Tests the mapping between HarmonyOS UIAbility lifecycle and Android Activity lifecycle.
 */

import { describe, it, expect } from '@ohos/hypium';
import { ActivityState, LifecycleStateMachine } from '../ets/lifecycle/LifecycleState';

export default function lifecycleIntegrationTests() {
  describe('Lifecycle Integration Tests', () => {
    
    describe('State Machine Tests', () => {
      it('should start in INITIALIZED state', 0, () => {
        const sm = new LifecycleStateMachine();
        expect(sm.getState()).assertEqual(ActivityState.INITIALIZED);
      });
      
      it('should transition to CREATED', 0, () => {
        const sm = new LifecycleStateMachine();
        const result = sm.transitionTo(ActivityState.CREATED);
        expect(result).assertTrue();
        expect(sm.getState()).assertEqual(ActivityState.CREATED);
      });
      
      it('should reject invalid transitions', 0, () => {
        const sm = new LifecycleStateMachine();
        
        // Cannot go from INITIALIZED to STARTED directly
        const result = sm.transitionTo(ActivityState.STARTED);
        expect(result).assertFalse();
        
        // Cannot go from INITIALIZED to DESTROYED directly
        const result2 = sm.transitionTo(ActivityState.DESTROYED);
        expect(result2).assertFalse();
      });
      
      it('should follow complete lifecycle', 0, () => {
        const sm = new LifecycleStateMachine();
        const transitions = [
          ActivityState.CREATED,
          ActivityState.STARTED,
          ActivityState.RESUMED,
          ActivityState.PAUSED,
          ActivityState.STOPPED,
          ActivityState.DESTROYED
        ];
        
        transitions.forEach(state => {
          const result = sm.transitionTo(state);
          expect(result).assertTrue();
          expect(sm.getState()).assertEqual(state);
        });
      });
      
      it('should handle restart cycle', 0, () => {
        const sm = new LifecycleStateMachine();
        
        // Initial launch
        sm.transitionTo(ActivityState.CREATED);
        sm.transitionTo(ActivityState.STARTED);
        sm.transitionTo(ActivityState.RESUMED);
        
        // Go to background
        sm.transitionTo(ActivityState.PAUSED);
        sm.transitionTo(ActivityState.STOPPED);
        
        // Restart
        sm.transitionTo(ActivityState.STARTED);
        sm.transitionTo(ActivityState.RESUMED);
        
        expect(sm.getState()).assertEqual(ActivityState.RESUMED);
      });
    });
    
    describe('State Check Tests', () => {
      it('should correctly report isInState', 0, () => {
        const sm = new LifecycleStateMachine();
        sm.transitionTo(ActivityState.CREATED);
        
        expect(sm.isInState(ActivityState.CREATED)).assertTrue();
        expect(sm.isInState(ActivityState.STARTED)).assertFalse();
      });
      
      it('should correctly report isAtLeast', 0, () => {
        const sm = new LifecycleStateMachine();
        sm.transitionTo(ActivityState.CREATED);
        sm.transitionTo(ActivityState.STARTED);
        
        expect(sm.isAtLeast(ActivityState.CREATED)).assertTrue();
        expect(sm.isAtLeast(ActivityState.STARTED)).assertTrue();
        expect(sm.isAtLeast(ActivityState.RESUMED)).assertFalse();
      });
    });
    
    describe('Listener Tests', () => {
      it('should notify listeners of state changes', 0, () => {
        const sm = new LifecycleStateMachine();
        const changes: string[] = [];
        
        sm.addListener({
          onStateChanged: (oldState, newState) => {
            changes.push(`${oldState} -> ${newState}`);
          }
        });
        
        sm.transitionTo(ActivityState.CREATED);
        sm.transitionTo(ActivityState.STARTED);
        
        expect(changes.length).assertEqual(2);
        expect(changes[0]).assertEqual('INITIALIZED -> CREATED');
        expect(changes[1]).assertEqual('CREATED -> STARTED');
      });
    });
    
  });
}
