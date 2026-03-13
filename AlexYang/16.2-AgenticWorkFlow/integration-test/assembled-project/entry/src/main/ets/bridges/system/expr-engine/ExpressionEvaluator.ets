/**
 * ExpressionEvaluator — Complete math expression parser and evaluator
 *
 * Replaces javax.script.ScriptEngine.eval() / Rhino that Android Calculator
 * apps commonly use for evaluating arithmetic expressions at runtime.
 *
 * Supported operators: + - * / % (modulo)
 * Supported grouping:  parentheses ()
 * Supports: negative numbers, decimal numbers, nested parentheses
 *
 * Operator precedence (high → low):
 *   1. ()          — parentheses
 *   2. unary -/+   — sign
 *   3. * / %       — multiplication, division, modulo
 *   4. + -         — addition, subtraction
 *
 * Implementation: recursive descent parser that builds an AST, then evaluates.
 * This approach is clearer than shunting-yard for maintenance and produces
 * good error messages.
 *
 * Usage:
 *   const evaluator = new ExpressionEvaluator();
 *   const result = evaluator.evaluate("3 + 4 * 2 / (1 - 5) % 3");
 */

// =============================================================================
// Token types
// =============================================================================

export enum TokenType {
  NUMBER,
  PLUS,
  MINUS,
  MULTIPLY,
  DIVIDE,
  MODULO,
  LPAREN,
  RPAREN,
  EOF
}

export class Token {
  type: TokenType;
  value: string;

  constructor(type: TokenType, value: string) {
    this.type = type;
    this.value = value;
  }

  toString(): string {
    return `Token(${this.type}, "${this.value}")`;
  }
}

// =============================================================================
// AST node types
// =============================================================================

export interface ASTNode {
  kind: string;
}

/** A literal numeric value. */
export class NumberNode implements ASTNode {
  kind: string = 'number';
  value: number;

  constructor(value: number) {
    this.value = value;
  }
}

/** A unary operation (e.g. -x, +x). */
export class UnaryNode implements ASTNode {
  kind: string = 'unary';
  operator: string;
  operand: ASTNode;

  constructor(operator: string, operand: ASTNode) {
    this.operator = operator;
    this.operand = operand;
  }
}

/** A binary operation (e.g. x + y). */
export class BinaryNode implements ASTNode {
  kind: string = 'binary';
  operator: string;
  left: ASTNode;
  right: ASTNode;

  constructor(operator: string, left: ASTNode, right: ASTNode) {
    this.operator = operator;
    this.left = left;
    this.right = right;
  }
}

// =============================================================================
// ExpressionEvaluator
// =============================================================================

export class ExpressionEvaluator {

  /**
   * Evaluate a mathematical expression string and return the numeric result.
   *
   * @param expression - e.g. "3 + 4 * 2 / (1 - 5)"
   * @returns the computed number
   * @throws Error on syntax errors or division by zero
   */
  evaluate(expression: string): number {
    if (expression === null || expression === undefined || expression.trim().length === 0) {
      throw new Error('Expression is empty');
    }

    const tokens = this.tokenize(expression);
    const ast = this.parse(tokens);
    return this.eval(ast);
  }

  // ===========================================================================
  // Tokenizer
  // ===========================================================================

  /**
   * Convert the expression string into a list of tokens.
   * Whitespace is skipped. Numbers can be integers or decimals.
   */
  private tokenize(expr: string): Token[] {
    const tokens: Token[] = [];
    let pos = 0;

    while (pos < expr.length) {
      const ch = expr[pos];

      // Skip whitespace
      if (ch === ' ' || ch === '\t' || ch === '\n' || ch === '\r') {
        pos++;
        continue;
      }

      // Number: digits and optional decimal point
      if (this._isDigit(ch) || (ch === '.' && pos + 1 < expr.length && this._isDigit(expr[pos + 1]))) {
        let numStr = '';
        let hasDot = false;

        while (pos < expr.length && (this._isDigit(expr[pos]) || expr[pos] === '.')) {
          if (expr[pos] === '.') {
            if (hasDot) {
              throw new Error(`Unexpected second decimal point at position ${pos}`);
            }
            hasDot = true;
          }
          numStr += expr[pos];
          pos++;
        }
        tokens.push(new Token(TokenType.NUMBER, numStr));
        continue;
      }

      // Single-character operators and parentheses
      switch (ch) {
        case '+':
          tokens.push(new Token(TokenType.PLUS, '+'));
          break;
        case '-':
          tokens.push(new Token(TokenType.MINUS, '-'));
          break;
        case '*':
          tokens.push(new Token(TokenType.MULTIPLY, '*'));
          break;
        case '/':
          tokens.push(new Token(TokenType.DIVIDE, '/'));
          break;
        case '%':
          tokens.push(new Token(TokenType.MODULO, '%'));
          break;
        case '(':
          tokens.push(new Token(TokenType.LPAREN, '('));
          break;
        case ')':
          tokens.push(new Token(TokenType.RPAREN, ')'));
          break;
        default:
          throw new Error(`Unexpected character '${ch}' at position ${pos}`);
      }
      pos++;
    }

    tokens.push(new Token(TokenType.EOF, ''));
    return tokens;
  }

  // ===========================================================================
  // Parser — recursive descent
  //
  // Grammar:
  //   expression  →  term (('+' | '-') term)*
  //   term        →  unary (('*' | '/' | '%') unary)*
  //   unary       →  ('+' | '-') unary | primary
  //   primary     →  NUMBER | '(' expression ')'
  // ===========================================================================

  /** Current position in the token array during parsing. */
  private _tokens: Token[] = [];
  private _pos: number = 0;

  /**
   * Parse the token list into an AST.
   */
  private parse(tokens: Token[]): ASTNode {
    this._tokens = tokens;
    this._pos = 0;

    const node = this._parseExpression();

    // Make sure we consumed everything
    if (this._current().type !== TokenType.EOF) {
      throw new Error(`Unexpected token "${this._current().value}" at end of expression`);
    }

    return node;
  }

  /** expression → term (('+' | '-') term)* */
  private _parseExpression(): ASTNode {
    let left = this._parseTerm();

    while (
      this._current().type === TokenType.PLUS ||
      this._current().type === TokenType.MINUS
    ) {
      const op = this._current().value;
      this._advance();
      const right = this._parseTerm();
      left = new BinaryNode(op, left, right);
    }

    return left;
  }

  /** term → unary (('*' | '/' | '%') unary)* */
  private _parseTerm(): ASTNode {
    let left = this._parseUnary();

    while (
      this._current().type === TokenType.MULTIPLY ||
      this._current().type === TokenType.DIVIDE ||
      this._current().type === TokenType.MODULO
    ) {
      const op = this._current().value;
      this._advance();
      const right = this._parseUnary();
      left = new BinaryNode(op, left, right);
    }

    return left;
  }

  /** unary → ('+' | '-') unary | primary */
  private _parseUnary(): ASTNode {
    if (this._current().type === TokenType.MINUS) {
      this._advance();
      const operand = this._parseUnary();
      return new UnaryNode('-', operand);
    }
    if (this._current().type === TokenType.PLUS) {
      this._advance();
      const operand = this._parseUnary();
      return new UnaryNode('+', operand);
    }
    return this._parsePrimary();
  }

  /** primary → NUMBER | '(' expression ')' */
  private _parsePrimary(): ASTNode {
    const tok = this._current();

    // Number literal
    if (tok.type === TokenType.NUMBER) {
      this._advance();
      const num = parseFloat(tok.value);
      if (isNaN(num)) {
        throw new Error(`Invalid number: "${tok.value}"`);
      }
      return new NumberNode(num);
    }

    // Parenthesised sub-expression
    if (tok.type === TokenType.LPAREN) {
      this._advance(); // consume '('
      const node = this._parseExpression();
      if (this._current().type !== TokenType.RPAREN) {
        throw new Error('Missing closing parenthesis');
      }
      this._advance(); // consume ')'
      return node;
    }

    throw new Error(`Unexpected token "${tok.value}" — expected a number or '('`);
  }

  /** Get the current token without advancing. */
  private _current(): Token {
    return this._tokens[this._pos];
  }

  /** Advance to the next token. */
  private _advance(): void {
    if (this._pos < this._tokens.length - 1) {
      this._pos++;
    }
  }

  // ===========================================================================
  // Evaluator — walk the AST
  // ===========================================================================

  /**
   * Recursively evaluate an AST node to produce a number.
   */
  private eval(node: ASTNode): number {
    if (node.kind === 'number') {
      return (node as NumberNode).value;
    }

    if (node.kind === 'unary') {
      const u = node as UnaryNode;
      const operandVal = this.eval(u.operand);
      if (u.operator === '-') {
        return -operandVal;
      }
      return operandVal; // unary +
    }

    if (node.kind === 'binary') {
      const b = node as BinaryNode;
      const leftVal = this.eval(b.left);
      const rightVal = this.eval(b.right);

      switch (b.operator) {
        case '+':
          return leftVal + rightVal;
        case '-':
          return leftVal - rightVal;
        case '*':
          return leftVal * rightVal;
        case '/':
          if (rightVal === 0) {
            throw new Error('Division by zero');
          }
          return leftVal / rightVal;
        case '%':
          if (rightVal === 0) {
            throw new Error('Division by zero (modulo)');
          }
          return leftVal % rightVal;
        default:
          throw new Error(`Unknown operator: ${b.operator}`);
      }
    }

    throw new Error(`Unknown AST node kind: ${node.kind}`);
  }

  // ===========================================================================
  // Utility
  // ===========================================================================

  private _isDigit(ch: string): boolean {
    return ch >= '0' && ch <= '9';
  }
}
