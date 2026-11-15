pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/calculatorHelper.js" as Calc

Singleton {
    id: root

    property string expression: ""
    property string resultText: "0"
    property string formattedResult: "0"
    property string lastError: ""
    property bool hasError: false
    property var history: []

    function evaluate(expr: string): var {
        const target = (expr !== undefined && expr !== null) ? expr : root.expression;
        const res = Calc.evaluateExpression(target);

        if (res.success) {
            root.resultText = res.result.toString();
            root.formattedResult = res.formatted;
            root.lastError = "";
            root.hasError = false;

            // Prepend to history if non-empty
            if (target.trim().length > 0 && target.trim() !== res.result.toString()) {
                const hist = root.history.slice();
                hist.unshift({
                    expr: target.trim(),
                    result: res.formatted,
                    rawResult: res.result,
                    time: Qt.formatTime(new Date(), "hh:mm")
                });
                root.history = hist.slice(0, 20);
            }
            return res;
        } else {
            root.lastError = res.error || "Error";
            root.hasError = true;
            return res;
        }
    }

    function appendChar(c: string): void {
        root.hasError = false;
        root.expression += c;
        // Live preview if valid expression
        if (root.expression.length > 0) {
            const preview = Calc.evaluateExpression(root.expression);
            if (preview.success) {
                root.resultText = preview.result.toString();
                root.formattedResult = preview.formatted;
            }
        }
    }

    function backspace(): void {
        if (root.expression.length > 0) {
            root.expression = root.expression.slice(0, -1);
            if (root.expression.length > 0) {
                const preview = Calc.evaluateExpression(root.expression);
                if (preview.success) {
                    root.resultText = preview.result.toString();
                    root.formattedResult = preview.formatted;
                }
            } else {
                root.resultText = "0";
                root.formattedResult = "0";
            }
        }
    }

    function clear(): void {
        root.expression = "";
        root.resultText = "0";
        root.formattedResult = "0";
        root.lastError = "";
        root.hasError = false;
    }

    function clearHistory(): void {
        root.history = [];
    }

    function copyResult(): void {
        const txt = root.resultText || "0";
        const copyCmd = (Quickshell.env("WAYLAND_DISPLAY") && Quickshell.env("WAYLAND_DISPLAY").length > 0)
            ? ["wl-copy", txt]
            : ["xclip", "-selection", "clipboard"];

        if (copyCmd[0] === "wl-copy") {
            Quickshell.execDetached(copyCmd);
        } else {
            Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | xclip -selection clipboard", "_", txt]);
        }

        if (typeof NotchController !== "undefined" && NotchController.triggerPeek) {
            NotchController.triggerPeek("osd", 1, {
                title: root.formattedResult,
                subtitle: "Disalin ke papan klip",
                icon: "calculate",
                progress: 1
            });
        }
    }
}
