import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const {
    formatMessage,
    cleanAnsi,
    previewText,
    validateHistory
} = loadQmlJs(path.resolve(__dirname, "../lib/chatHelper.js"));

describe("chatHelper.js - Chat Notifier & ANSI Parser Helper", () => {
    it("formats message with role, text, and timestamp", () => {
        const msg = formatMessage("user", " Halo Kuro! ");
        assert.equal(msg.role, "user");
        assert.equal(msg.text, "Halo Kuro!");
        assert.ok(msg.time.length > 0);
        assert.equal(msg.isError, false);
    });

    it("cleans ANSI escape codes and terminal artifacts from LLM output", () => {
        const raw = "\u001b[32mHalo!\u001b[0m \u001b[1mSaya asisten Kuro.\u001b[0m\r\n";
        const clean = cleanAnsi(raw);
        assert.equal(clean, "Halo! Saya asisten Kuro.");
    });

    it("previews long text gracefully with ellipsis", () => {
        const longStr = "KuroNotch adalah dynamic island yang sangat powerful dan modular untuk Linux desktop";
        const preview = previewText(longStr, 30);
        assert.equal(preview, "KuroNotch adalah dynamic is...");
        assert.equal(previewText("Pendek", 30), "Pendek");
    });

    it("validates and filters chat history", () => {
        const history = [
            { role: "user", text: "Hai" },
            null,
            { role: "assistant", text: "" }, // empty text should be dropped
            { role: "assistant", text: "Halo juga!" },
            { invalid: "data" }
        ];

        const valid = validateHistory(history);
        assert.equal(valid.length, 2);
        assert.equal(valid[0].text, "Hai");
        assert.equal(valid[1].text, "Halo juga!");
    });
});
