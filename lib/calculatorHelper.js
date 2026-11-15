/**
 * calculatorHelper.js - Pure, safe mathematical expression parser & evaluator for KuroNotch.
 * Safe alternative to eval() supporting precedence, percentages, exponents, and roots.
 */

/**
 * Format a number cleanly with comma thousand-separators and trimmed trailing decimal zeros.
 * @param {number} num
 * @returns {string}
 */
function formatNumber(num) {
    if (typeof num !== "number" || isNaN(num)) return "0";
    if (!isFinite(num)) return num > 0 ? "Infinity" : "-Infinity";
    const parts = num.toString().split(".");
    parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
    return parts.join(".");
}

/**
 * Tokenize a mathematical expression string.
 * @param {string} raw
 * @returns {Array<{ type: string, value: string|number }>}
 */
function tokenize(raw) {
    let expr = (raw || "").trim();
    // Replace "of" with "*"
    expr = expr.replace(/\bof\b/gi, "*");
    // Replace "x" or "×" with "*"
    expr = expr.replace(/[x×]/g, "*");
    // Replace "÷" with "/"
    expr = expr.replace(/÷/g, "/");

    const tokens = [];
    let i = 0;

    while (i < expr.length) {
        const c = expr[i];

        if (/\s/.test(c)) {
            i++;
            continue;
        }

        // Numbers (with optional decimal point)
        if (/[0-9]/.test(c) || (c === "." && i + 1 < expr.length && /[0-9]/.test(expr[i + 1]))) {
            let numStr = "";
            while (i < expr.length && /[0-9.]/.test(expr[i])) {
                numStr += expr[i];
                i++;
            }
            tokens.push({ type: "NUMBER", value: parseFloat(numStr) });
            continue;
        }

        // Words / Functions (sqrt, abs, etc.)
        if (/[a-zA-Z]/.test(c)) {
            let fn = "";
            while (i < expr.length && /[a-zA-Z]/.test(expr[i])) {
                fn += expr[i];
                i++;
            }
            tokens.push({ type: "FUNC", value: fn.toLowerCase() });
            continue;
        }

        // Operators & Parentheses
        if ("+-*/^%()".indexOf(c) !== -1) {
            tokens.push({ type: "OP", value: c });
            i++;
            continue;
        }

        // Unknown character
        throw new Error(`Unexpected character: '${c}'`);
    }

    return tokens;
}

/**
 * Safe Recursive Descent Parser & Evaluator
 */
class Parser {
    constructor(tokens) {
        this.tokens = tokens;
        this.pos = 0;
    }

    peek() {
        return this.tokens[this.pos] || null;
    }

    consume(expectedValue) {
        const t = this.peek();
        if (!t) throw new Error("Unexpected end of expression");
        if (expectedValue !== undefined && t.value !== expectedValue) {
            throw new Error(`Expected '${expectedValue}' but found '${t.value}'`);
        }
        this.pos++;
        return t;
    }

    parse() {
        if (this.tokens.length === 0) {
            throw new Error("Empty expression");
        }
        const result = this.parseAdditive();
        if (this.pos < this.tokens.length) {
            throw new Error(`Unexpected token '${this.tokens[this.pos].value}'`);
        }
        return result;
    }

    // Additive: + and -
    parseAdditive() {
        let left = this.parseMultiplicative();

        while (this.pos < this.tokens.length) {
            const t = this.peek();
            if (t && t.type === "OP" && (t.value === "+" || t.value === "-")) {
                this.consume();
                
                // Track if the next term has a percentage
                const beforePos = this.pos;
                let right = this.parseMultiplicative();

                // If the right operand was written as a percentage (e.g. 100 + 10%)
                // check if the tokens in that operand ended with %
                let operandHadPercent = false;
                for (let k = beforePos; k < this.pos; k++) {
                    if (this.tokens[k]?.type === "OP" && this.tokens[k]?.value === "%") {
                        operandHadPercent = true;
                        break;
                    }
                }

                if (operandHadPercent) {
                    // right was already divided by 100 in parsePrimary, so right is (P/100)
                    // in additive context, it is left * (P/100)
                    right = left * right;
                }

                if (t.value === "+") left += right;
                else left -= right;
            } else {
                break;
            }
        }

        return left;
    }

    // Multiplicative: * and /
    parseMultiplicative() {
        let left = this.parsePower();

        while (this.pos < this.tokens.length) {
            const t = this.peek();
            if (t && t.type === "OP" && (t.value === "*" || t.value === "/")) {
                this.consume();
                const right = this.parsePower();
                if (t.value === "*") {
                    left *= right;
                } else {
                    if (right === 0) {
                        throw new Error("Division by zero");
                    }
                    left /= right;
                }
            } else {
                break;
            }
        }

        return left;
    }

    // Power: ^
    parsePower() {
        let left = this.parseUnary();

        while (this.pos < this.tokens.length) {
            const t = this.peek();
            if (t && t.type === "OP" && t.value === "^") {
                this.consume();
                const right = this.parsePower(); // right-associative
                left = Math.pow(left, right);
            } else {
                break;
            }
        }

        return left;
    }

    // Unary: -x, +x, sqrt(x), abs(x)
    parseUnary() {
        const t = this.peek();
        if (t && t.type === "OP" && (t.value === "+" || t.value === "-")) {
            this.consume();
            const val = this.parseUnary();
            return t.value === "-" ? -val : val;
        }

        if (t && t.type === "FUNC") {
            const fnName = this.consume().value;
            this.consume("(");
            const arg = this.parseAdditive();
            this.consume(")");

            switch (fnName) {
                case "sqrt":
                    if (arg < 0) throw new Error("Square root of negative number");
                    return Math.sqrt(arg);
                case "abs":
                    return Math.abs(arg);
                case "sin":
                    return Math.sin(arg * Math.PI / 180);
                case "cos":
                    return Math.cos(arg * Math.PI / 180);
                case "tan":
                    return Math.tan(arg * Math.PI / 180);
                case "round":
                    return Math.round(arg);
                case "floor":
                    return Math.floor(arg);
                case "ceil":
                    return Math.ceil(arg);
                default:
                    throw new Error(`Unknown function: '${fnName}'`);
            }
        }

        return this.parsePrimary();
    }

    // Primary: numbers, (expression), and trailing % (e.g. 50% -> 0.5)
    parsePrimary() {
        const t = this.peek();
        if (!t) throw new Error("Unexpected end of expression");

        let val = 0;
        if (t.type === "NUMBER") {
            val = this.consume().value;
        } else if (t.type === "OP" && t.value === "(") {
            this.consume("(");
            val = this.parseAdditive();
            this.consume(")");
        } else {
            throw new Error(`Unexpected token: '${t.value}'`);
        }

        // Check if immediately followed by % (as postfix: e.g. 50% -> 0.5)
        if (this.pos < this.tokens.length && this.peek()?.value === "%") {
            // Only consume if not followed by an additive operator where contextual % applies
            this.consume("%");
            val = val / 100;
        }

        return val;
    }
}

/**
 * Evaluates a mathematical expression safely.
 *
 * @param {string} expr
 * @returns {{ success: boolean, result: number, formatted: string, error?: string }}
 */
function evaluateExpression(expr) {
    if (!expr || typeof expr !== "string" || expr.trim().length === 0) {
        return {
            success: false,
            result: 0,
            formatted: "0",
            error: "Empty expression"
        };
    }

    try {
        const tokens = tokenize(expr);
        const parser = new Parser(tokens);
        let res = parser.parse();

        if (typeof res !== "number" || isNaN(res)) {
            return {
                success: false,
                result: 0,
                formatted: "0",
                error: "Invalid result"
            };
        }

        // Round floating precision artifacts (e.g. 0.1 + 0.2 = 0.30000000000000004)
        res = Math.round(res * 1e10) / 1e10;

        return {
            success: true,
            result: res,
            formatted: formatNumber(res)
        };
    } catch (err) {
        return {
            success: false,
            result: 0,
            formatted: "0",
            error: err.message || "Syntax error"
        };
    }
}

// Universal export for Node.js test runner and QML
if (typeof module !== "undefined" && module.exports) {
    module.exports = { evaluateExpression, formatNumber };
}
