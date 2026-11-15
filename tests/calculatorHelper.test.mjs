import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const { evaluateExpression, formatNumber } = loadQmlJs(path.resolve(__dirname, "../lib/calculatorHelper.js"));

describe("calculatorHelper.js - Safe Math Evaluator", () => {
    it("evaluates standard arithmetic expressions adhering to operator precedence", () => {
        const res1 = evaluateExpression("2 + 3 * 4");
        assert.equal(res1.success, true);
        assert.equal(res1.result, 14);

        const res2 = evaluateExpression("(10 - 2) / 4 + 7");
        assert.equal(res2.success, true);
        assert.equal(res2.result, 9);

        const res3 = evaluateExpression("15.5 + 4.5 * 2");
        assert.equal(res3.success, true);
        assert.equal(res3.result, 24.5);
    });

    it("evaluates percentages and 'of' syntax", () => {
        const res1 = evaluateExpression("50% * 200");
        assert.equal(res1.success, true);
        assert.equal(res1.result, 100);

        const res2 = evaluateExpression("20% of 150000");
        assert.equal(res2.success, true);
        assert.equal(res2.result, 30000);

        const res3 = evaluateExpression("100 + 10%");
        assert.equal(res3.success, true);
        assert.equal(res3.result, 110);
    });

    it("evaluates exponents, square roots, and absolute values", () => {
        const res1 = evaluateExpression("2^10");
        assert.equal(res1.success, true);
        assert.equal(res1.result, 1024);

        const res2 = evaluateExpression("sqrt(144)");
        assert.equal(res2.success, true);
        assert.equal(res2.result, 12);

        const res3 = evaluateExpression("abs(-42)");
        assert.equal(res3.success, true);
        assert.equal(res3.result, 42);
    });

    it("handles division by zero gracefully without throwing", () => {
        const res = evaluateExpression("42 / 0");
        assert.equal(res.success, false);
        assert.match(res.error, /division by zero/i);
    });

    it("handles invalid syntax and empty input gracefully without throwing", () => {
        const resEmpty = evaluateExpression("");
        assert.equal(resEmpty.success, false);
        assert.equal(resEmpty.result, 0);

        const resInvalid = evaluateExpression("2 + * 4");
        assert.equal(resInvalid.success, false);
        assert.ok(resInvalid.error);

        const resUnbalanced = evaluateExpression("(2 + 3");
        assert.equal(resUnbalanced.success, false);
    });

    it("formats thousands separators cleanly in formatted string", () => {
        const res = evaluateExpression("1000 * 2500");
        assert.equal(res.success, true);
        assert.equal(res.result, 2500000);
        assert.equal(res.formatted, "2,500,000");
    });
});
