import fs from "node:fs";
import vm from "node:vm";

/**
 * Normalizes values returned from cross-realm vm execution to host prototypes.
 *
 * @param {any} val
 * @returns {any}
 */
function normalizeRealm(val) {
    if (val === null || val === undefined) return val;
    if (typeof val === "object") {
        if (Array.isArray(val)) {
            return val.map(normalizeRealm);
        }
        const hostObj = {};
        for (const [k, v] of Object.entries(val)) {
            hostObj[k] = normalizeRealm(v);
        }
        return hostObj;
    }
    return val;
}

/**
 * Loads a QML .pragma library JavaScript file into a sandboxed V8 execution context.
 * Strips .pragma directives, exposes top-level functions and constants, and
 * normalizes return values so assertions across realms succeed seamlessly.
 *
 * @param {string} filePath - Absolute or relative path to the .js file.
 * @param {Record<string, any>} [extraGlobals={}] - Optional globals to inject into the sandbox.
 * @returns {Record<string, any>} The evaluated sandbox object.
 */
export function loadQmlJs(filePath, extraGlobals = {}) {
    const rawCode = fs.readFileSync(filePath, "utf8");
    // Strip QML .pragma library or .pragma ... directives
    let sanitizedCode = rawCode.replace(/^\s*\.pragma\s+.*$/gm, "");
    // Replace top-level const and let with var so properties attach to the sandbox
    sanitizedCode = sanitizedCode.replace(/^(\s*)(const|let)\s+/gm, "$1var ");

    const sandbox = {
        console,
        Math,
        Object,
        Array,
        String,
        Number,
        Boolean,
        JSON,
        Date,
        parseInt,
        parseFloat,
        isNaN,
        isFinite,
        ...extraGlobals,
    };

    vm.createContext(sandbox);
    vm.runInContext(sanitizedCode, sandbox, { filename: filePath });

    // Expose wrapped exports that normalize returned cross-realm objects
    const exports = {};
    for (const [key, value] of Object.entries(sandbox)) {
        if (typeof value === "function") {
            exports[key] = (...args) => normalizeRealm(value(...args));
        } else {
            exports[key] = normalizeRealm(value);
        }
    }

    return exports;
}
