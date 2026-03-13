/**
 * System.Bridge — Module exports
 *
 * Central barrel file for the 16.4.4-System.Bridge package.
 * Import from this file to get all bridge classes:
 *
 *   import { ContextBridge, LogBridge, ExpressionEvaluator } from '../05-Implementation';
 */

// -- context/ -----------------------------------------------------------------
export { ContextBridge, ResourcesBridge } from './context/ContextBridge';
export { ToastBridge } from './context/ToastBridge';
export { LogBridge } from './context/LogBridge';

// -- r-mapper/ ----------------------------------------------------------------
export { ResourceConverter } from './r-mapper/ResourceConverter';
export { R } from './r-mapper/RClass';

// -- expr-engine/ -------------------------------------------------------------
export { ExpressionEvaluator, Token, TokenType } from './expr-engine/ExpressionEvaluator';
export { NumberNode, UnaryNode, BinaryNode } from './expr-engine/ExpressionEvaluator';
export type { ASTNode } from './expr-engine/ExpressionEvaluator';
export { DecimalBridge } from './expr-engine/DecimalBridge';

// -- java-compat/ -------------------------------------------------------------
export { TimeZoneBridge } from './java-compat/TimeZoneBridge';
export { TextUtils } from './java-compat/TextUtils';
