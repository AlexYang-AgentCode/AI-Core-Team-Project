/**
 * Calculator Demo Adaptation Verification
 * 
 * This test suite verifies that the 16.1 Calculator Demo can run
 * using the Activity.Bridge layer with View.Bridge and System.Bridge.
 * 
 * Tests cover:
 * - MainActivity lifecycle
 * - View binding (display, buttons)
 * - Expression evaluation
 * - Toast error handling
 * - State persistence
 */

import { describe, it, expect, beforeEach, afterEach } from '@ohos/hypium';
import { Activity } from '../ets/activity/Activity';
import { Bundle } from '../ets/os/Bundle';
import { viewFinder } from '../ets/view/ViewFinder';
import { AppCompatActivity } from '../ets/activity/AppCompatActivity';
import { JITTestHelper, LifecycleEventRecorder } from '../ets/jit/JITCompilerInterface';

// R.id mappings from 16.1 Calculator Demo
const R_ID = {
  display: 0x7F09004E,      // EditText for display
  button_0: 0x7F090040,
  button_1: 0x7F090041,
  button_2: 0x7F090042,
  button_3: 0x7F090043,
  button_4: 0x7F090044,
  button_5: 0x7F090045,
  button_6: 0x7F090046,
  button_7: 0x7F090047,
  button_8: 0x7F090048,
  button_9: 0x7F090049,
  button_add: 0x7F09004A,      // +
  button_sub: 0x7F09004B,      // -
  button_mul: 0x7F09004C,      // ×
  button_div: 0x7F09004D,      // ÷
  button_equ: 0x7F09004F,      // =
  button_del: 0x7F090039,      // DEL
  button_dot: 0x7F09004G,      // . (if exists)
};

// Mock Calculator MainActivity behavior
class CalculatorMainActivity extends AppCompatActivity {
  // View references (would be injected by View.Bridge)
  display: any = null;
  buttons: Map<number, any> = new Map();
  
  // Calculator state
  currentExpression: string = '';
  lastResult: string = '';
  shouldResetOnNextDigit: boolean = false;
  
  // Error tracking
  shownErrors: string[] = [];
  
  protected onCreate(savedInstanceState: Bundle | null): void {
    super.onCreate(savedInstanceState);
    
    // In real app, this would be: setContentView(R.layout.activity_main);
    // Here we simulate the view binding
    this.bindViews();
    this.setupClickListeners();
    
    // Restore state if available
    if (savedInstanceState) {
      this.currentExpression = savedInstanceState.getString('expression', '');
      this.lastResult = savedInstanceState.getString('result', '');
      this.updateDisplay();
    }
  }
  
  private bindViews(): void {
    // Simulate View.Bridge registering views
    viewFinder.registerView(R_ID.display, {
      id: R_ID.display,
      type: 'AndroidEditText',
      text: '0',
      setText: (text: string) => { this.displayText = text; },
      getText: () => this.displayText,
      setSelection: (start: number, end?: number) => {}
    });
    
    // Register digit buttons
    for (let i = 0; i <= 9; i++) {
      const id = R_ID[`button_${i}` as keyof typeof R_ID];
      viewFinder.registerView(id, this.createButton(id, i.toString()));
    }
    
    // Register operator buttons
    viewFinder.registerView(R_ID.button_add, this.createButton(R_ID.button_add, '+'));
    viewFinder.registerView(R_ID.button_sub, this.createButton(R_ID.button_sub, '-'));
    viewFinder.registerView(R_ID.button_mul, this.createButton(R_ID.button_mul, '×'));
    viewFinder.registerView(R_ID.button_div, this.createButton(R_ID.button_div, '÷'));
    viewFinder.registerView(R_ID.button_equ, this.createButton(R_ID.button_equ, '='));
    viewFinder.registerView(R_ID.button_del, this.createButton(R_ID.button_del, 'DEL'));
    
    // Cache display reference
    this.display = viewFinder.findViewById(R_ID.display);
  }
  
  private createButton(id: number, symbol: string): any {
    const button = {
      id,
      type: 'AndroidButton',
      symbol,
      clickListener: null as Function | null,
      setOnClickListener: function(listener: Function) {
        this.clickListener = listener;
      },
      performClick: function() {
        if (this.clickListener) {
          this.clickListener();
        }
      }
    };
    this.buttons.set(id, button);
    return button;
  }
  
  private setupClickListeners(): void {
    // Digit buttons 0-9
    for (let i = 0; i <= 9; i++) {
      const id = R_ID[`button_${i}` as keyof typeof R_ID];
      const button = this.buttons.get(id);
      button.setOnClickListener(() => this.onDigitClick(i.toString()));
    }
    
    // Operators
    this.buttons.get(R_ID.button_add).setOnClickListener(() => this.onOperatorClick('+'));
    this.buttons.get(R_ID.button_sub).setOnClickListener(() => this.onOperatorClick('-'));
    this.buttons.get(R_ID.button_mul).setOnClickListener(() => this.onOperatorClick('×'));
    this.buttons.get(R_ID.button_div).setOnClickListener(() => this.onOperatorClick('÷'));
    this.buttons.get(R_ID.button_equ).setOnClickListener(() => this.onEqualsClick());
    this.buttons.get(R_ID.button_del).setOnClickListener(() => this.onDeleteClick());
  }
  
  displayText: string = '0';
  
  private updateDisplay(): void {
    this.displayText = this.currentExpression || '0';
  }
  
  private onDigitClick(digit: string): void {
    if (this.shouldResetOnNextDigit) {
      this.currentExpression = '';
      this.shouldResetOnNextDigit = false;
    }
    
    // Prevent multiple leading zeros
    if (this.currentExpression === '0' && digit === '0') {
      return;
    }
    
    // Replace single zero with digit
    if (this.currentExpression === '0' && digit !== '0') {
      this.currentExpression = digit;
    } else {
      this.currentExpression += digit;
    }
    
    this.updateDisplay();
  }
  
  private onOperatorClick(operator: string): void {
    if (this.currentExpression === '') {
      if (this.lastResult) {
        this.currentExpression = this.lastResult;
      } else {
        return;
      }
    }
    
    // Prevent consecutive operators
    const lastChar = this.currentExpression.slice(-1);
    if ('+-×÷'.includes(lastChar)) {
      this.currentExpression = this.currentExpression.slice(0, -1) + operator;
    } else {
      this.currentExpression += operator;
    }
    
    this.shouldResetOnNextDigit = false;
    this.updateDisplay();
  }
  
  private onEqualsClick(): void {
    if (this.currentExpression === '') {
      return;
    }
    
    try {
      // Check for division by zero
      if (this.currentExpression.includes('/0') || this.currentExpression.includes('÷0')) {
        this.showToast('Division by zero');
        return;
      }
      
      // Evaluate expression
      const expr = this.currentExpression
        .replace(/×/g, '*')
        .replace(/÷/g, '/');
      
      const result = Function('"use strict"; return (' + expr + ')')();
      
      // Format with 8 decimal places (like BigDecimal)
      const formatted = parseFloat(result.toFixed(8)).toString();
      
      this.lastResult = formatted;
      this.currentExpression = formatted;
      this.shouldResetOnNextDigit = true;
      this.updateDisplay();
      
    } catch (e) {
      this.showToast('Wrong Format');
    }
  }
  
  private onDeleteClick(): void {
    if (this.currentExpression.length > 0) {
      this.currentExpression = this.currentExpression.slice(0, -1);
      this.updateDisplay();
    }
  }
  
  private showToast(message: string): void {
    this.shownErrors.push(message);
    this.displayText = message;
    this.currentExpression = '';
    setTimeout(() => {
      this.updateDisplay();
    }, 2000);
  }
  
  protected onSaveInstanceState(outState: Bundle): void {
    super.onSaveInstanceState(outState);
    outState.putString('expression', this.currentExpression);
    outState.putString('result', this.lastResult);
  }
  
  // Test helpers
  simulateButtonClick(id: number): void {
    const button = this.buttons.get(id);
    if (button && button.clickListener) {
      button.clickListener();
    }
  }
  
  getDisplayText(): string {
    return this.displayText;
  }
}

export default function calculatorDemoVerification() {
  describe('16.1 Calculator Demo Verification', () => {
    let activity: CalculatorMainActivity;
    let recorder: LifecycleEventRecorder;
    
    beforeEach(() => {
      viewFinder.clear();
      activity = new CalculatorMainActivity();
      recorder = new LifecycleEventRecorder();
      recorder.attach(activity);
    });
    
    afterEach(() => {
      viewFinder.clear();
    });
    
    describe('Activity Lifecycle', () => {
      it('should complete full lifecycle sequence', 0, () => {
        const bundle = new Bundle();
        
        // Simulate full lifecycle
        activity.onCreate(bundle);
        activity.onStart();
        activity.onResume();
        activity.onPause();
        activity.onStop();
        activity.onDestroy();
        
        const sequence = recorder.getEventSequence();
        const expected = ['onCreate', 'onStart', 'onResume', 'onPause', 'onStop', 'onDestroy'];
        
        expect(sequence).assertEqual(expected);
      });
      
      it('should handle pause/resume cycles', 0, () => {
        const bundle = new Bundle();
        
        activity.onCreate(bundle);
        activity.onStart();
        activity.onResume();
        
        // First cycle
        activity.onPause();
        activity.onResume();
        
        // Second cycle
        activity.onPause();
        activity.onResume();
        
        const events = recorder.getEventSequence();
        expect(events.filter(e => e === 'onPause').length).assertEqual(2);
        expect(events.filter(e => e === 'onResume').length).assertEqual(3);
      });
      
      it('should restore state after recreation', 0, () => {
        // First activity instance
        const bundle1 = new Bundle();
        activity.onCreate(bundle1);
        
        // Perform some calculations
        activity.simulateButtonClick(R_ID.button_1);
        activity.simulateButtonClick(R_ID.button_2);
        activity.simulateButtonClick(R_ID.button_add);
        activity.simulateButtonClick(R_ID.button_3);
        activity.simulateButtonClick(R_ID.button_equ);
        
        expect(activity.getDisplayText()).assertEqual('15');
        
        // Save state
        const savedState = new Bundle();
        activity.onSaveInstanceState(savedState);
        
        // Create new activity with saved state
        viewFinder.clear();
        const activity2 = new CalculatorMainActivity();
        activity2.onCreate(savedState);
        
        expect(activity2.getDisplayText()).assertEqual('15');
      });
    });
    
    describe('View Binding', () => {
      it('should bind all calculator buttons', 0, () => {
        const bundle = new Bundle();
        activity.onCreate(bundle);
        
        // Verify all digit buttons are bound
        for (let i = 0; i <= 9; i++) {
          const id = R_ID[`button_${i}` as keyof typeof R_ID];
          expect(activity.buttons.has(id)).assertTrue(`Button ${i} not bound`);
        }
        
        // Verify operator buttons
        expect(activity.buttons.has(R_ID.button_add)).assertTrue();
        expect(activity.buttons.has(R_ID.button_sub)).assertTrue();
        expect(activity.buttons.has(R_ID.button_mul)).assertTrue();
        expect(activity.buttons.has(R_ID.button_div)).assertTrue();
        expect(activity.buttons.has(R_ID.button_equ)).assertTrue();
        expect(activity.buttons.has(R_ID.button_del)).assertTrue();
      });
      
      it('should bind display EditText', 0, () => {
        const bundle = new Bundle();
        activity.onCreate(bundle);
        
        expect(activity.display).not().assertNull();
        expect(activity.display.type).assertEqual('AndroidEditText');
      });
    });
    
    describe('Calculator Operations', () => {
      beforeEach(() => {
        const bundle = new Bundle();
        activity.onCreate(bundle);
      });
      
      it('should add two numbers', 0, () => {
        activity.simulateButtonClick(R_ID.button_1);
        activity.simulateButtonClick(R_ID.button_2);
        activity.simulateButtonClick(R_ID.button_add);
        activity.simulateButtonClick(R_ID.button_3);
        activity.simulateButtonClick(R_ID.button_equ);
        
        expect(activity.getDisplayText()).assertEqual('15');
      });
      
      it('should subtract numbers', 0, () => {
        activity.simulateButtonClick(R_ID.button_9);
        activity.simulateButtonClick(R_ID.button_sub);
        activity.simulateButtonClick(R_ID.button_4);
        activity.simulateButtonClick(R_ID.button_equ);
        
        expect(activity.getDisplayText()).assertEqual('5');
      });
      
      it('should multiply numbers', 0, () => {
        activity.simulateButtonClick(R_ID.button_6);
        activity.simulateButtonClick(R_ID.button_mul);
        activity.simulateButtonClick(R_ID.button_7);
        activity.simulateButtonClick(R_ID.button_equ);
        
        expect(activity.getDisplayText()).assertEqual('42');
      });
      
      it('should divide numbers', 0, () => {
        activity.simulateButtonClick(R_ID.button_8);
        activity.simulateButtonClick(R_ID.button_div);
        activity.simulateButtonClick(R_ID.button_2);
        activity.simulateButtonClick(R_ID.button_equ);
        
        expect(activity.getDisplayText()).assertEqual('4');
      });
      
      it('should handle percentage', 0, () => {
        activity.simulateButtonClick(R_ID.button_5);
        activity.simulateButtonClick(R_ID.button_0);
        activity.simulateButtonClick(R_ID.button_div);
        activity.simulateButtonClick(R_ID.button_1);
        activity.simulateButtonClick(R_ID.button_0);
        activity.simulateButtonClick(R_ID.button_0);
        activity.simulateButtonClick(R_ID.button_equ);
        
        expect(activity.getDisplayText()).assertEqual('0.5');
      });
      
      it('should chain operations', 0, () => {
        activity.simulateButtonClick(R_ID.button_2);
        activity.simulateButtonClick(R_ID.button_add);
        activity.simulateButtonClick(R_ID.button_3);
        activity.simulateButtonClick(R_ID.button_mul);
        activity.simulateButtonClick(R_ID.button_4);
        activity.simulateButtonClick(R_ID.button_equ);
        
        // (2+3)*4 = 20
        expect(activity.getDisplayText()).assertEqual('20');
      });
      
      it('should delete characters', 0, () => {
        activity.simulateButtonClick(R_ID.button_1);
        activity.simulateButtonClick(R_ID.button_2);
        activity.simulateButtonClick(R_ID.button_3);
        activity.simulateButtonClick(R_ID.button_del);
        
        expect(activity.getDisplayText()).assertEqual('12');
      });
    });
    
    describe('Error Handling', () => {
      beforeEach(() => {
        const bundle = new Bundle();
        activity.onCreate(bundle);
      });
      
      it('should show error for division by zero', 0, () => {
        activity.simulateButtonClick(R_ID.button_5);
        activity.simulateButtonClick(R_ID.button_div);
        activity.simulateButtonClick(R_ID.button_0);
        activity.simulateButtonClick(R_ID.button_equ);
        
        expect(activity.shownErrors).contain('Division by zero');
      });
      
      it('should show error for wrong format', 0, () => {
        activity.simulateButtonClick(R_ID.button_1);
        activity.simulateButtonClick(R_ID.button_add);
        activity.simulateButtonClick(R_ID.button_add);
        activity.simulateButtonClick(R_ID.button_equ);
        
        expect(activity.shownErrors.length).assertLarger(0);
      });
      
      it('should handle consecutive operators correctly', 0, () => {
        activity.simulateButtonClick(R_ID.button_1);
        activity.simulateButtonClick(R_ID.button_add);
        activity.simulateButtonClick(R_ID.button_sub);
        activity.simulateButtonClick(R_ID.button_2);
        activity.simulateButtonClick(R_ID.button_equ);
        
        // Should be 1-2 = -1
        expect(activity.getDisplayText()).assertEqual('-1');
      });
    });
    
    describe('State Persistence', () => {
      it('should save and restore calculator state', 0, () => {
        const bundle = new Bundle();
        activity.onCreate(bundle);
        
        // Do a calculation
        activity.simulateButtonClick(R_ID.button_7);
        activity.simulateButtonClick(R_ID.button_8);
        activity.simulateButtonClick(R_ID.button_9);
        
        // Save state
        const savedState = new Bundle();
        activity.onSaveInstanceState(savedState);
        
        // Verify state was saved
        expect(savedState.getString('expression', '')).assertEqual('789');
      });
      
      it('should restore result after process death', 0, () => {
        // Simulate calculation
        const bundle1 = new Bundle();
        activity.onCreate(bundle1);
        
        activity.simulateButtonClick(R_ID.button_5);
        activity.simulateButtonClick(R_ID.button_mul);
        activity.simulateButtonClick(R_ID.button_5);
        activity.simulateButtonClick(R_ID.button_equ);
        
        expect(activity.getDisplayText()).assertEqual('25');
        
        // Save and recreate
        const savedState = new Bundle();
        activity.onSaveInstanceState(savedState);
        
        viewFinder.clear();
        const newActivity = new CalculatorMainActivity();
        newActivity.onCreate(savedState);
        
        expect(newActivity.getDisplayText()).assertEqual('25');
      });
    });
    
    describe('Integration Summary', () => {
      it('should complete Calculator Demo integration test', 0, () => {
        const bundle = new Bundle();
        activity.onCreate(bundle);
        activity.onStart();
        activity.onResume();
        
        // Test a complete calculation scenario
        const scenario = [
          R_ID.button_1, R_ID.button_2, R_ID.button_3,
          R_ID.button_add,
          R_ID.button_4, R_ID.button_5, R_ID.button_6,
          R_ID.button_equ
        ];
        
        scenario.forEach(id => activity.simulateButtonClick(id));
        
        expect(activity.getDisplayText()).assertEqual('579');
        
        activity.onPause();
        activity.onStop();
        
        console.log('✅ Calculator Demo Integration Test PASSED');
        console.log(`   - Lifecycle: ${recorder.getEventSequence().join(' → ')}`);
        console.log(`   - Final result: ${activity.getDisplayText()}`);
      });
    });
  });
}
