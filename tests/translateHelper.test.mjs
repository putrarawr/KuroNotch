import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const {
    buildTranslateUrl,
    parseTranslationResponse,
    SUPPORTED_LANGUAGES
} = loadQmlJs(path.resolve(__dirname, "../lib/translateHelper.js"));

describe("translateHelper.js - Translation Query & Parser Helper", () => {
    it("builds valid translate endpoint URL with encoded query", () => {
        const url = buildTranslateUrl("Hello world, how are you?", "auto", "id");
        assert.match(url, /^https:\/\/translate\.googleapis\.com\/translate_a\/single/);
        assert.match(url, /client=gtx/);
        assert.match(url, /sl=auto/);
        assert.match(url, /tl=id/);
        assert.match(url, /q=Hello%20world%2C%20how%20are%20you%3F/);
    });

    it("parses single-sentence Google Translate API JSON response", () => {
        const rawJson = '[[["Halo dunia","Hello world",null,null,1]],null,"en"]';
        const parsed = parseTranslationResponse(rawJson);

        assert.equal(parsed.success, true);
        assert.equal(parsed.translatedText, "Halo dunia");
        assert.equal(parsed.detectedSource, "en");
    });

    it("parses multi-sentence Google Translate API response and joins chunks", () => {
        const rawJson = '[[["Selamat pagi. ","Good morning. ",null,null,1],["Semoga harimu menyenangkan.","Have a nice day.",null,null,1]],null,"en"]';
        const parsed = parseTranslationResponse(rawJson);

        assert.equal(parsed.success, true);
        assert.equal(parsed.translatedText, "Selamat pagi. Semoga harimu menyenangkan.");
        assert.equal(parsed.detectedSource, "en");
    });

    it("handles malformed JSON or empty response gracefully without throwing", () => {
        const parsedEmpty = parseTranslationResponse("");
        assert.equal(parsedEmpty.success, false);
        assert.equal(parsedEmpty.translatedText, "");

        const parsedInvalid = parseTranslationResponse("<html>Error 404</html>");
        assert.equal(parsedInvalid.success, false);
        assert.ok(parsedInvalid.error);
    });

    it("provides list of supported language options", () => {
        assert.ok(Array.isArray(SUPPORTED_LANGUAGES));
        assert.ok(SUPPORTED_LANGUAGES.length >= 6);
        assert.ok(SUPPORTED_LANGUAGES.some(l => l.code === "id"));
        assert.ok(SUPPORTED_LANGUAGES.some(l => l.code === "en"));
        assert.ok(SUPPORTED_LANGUAGES.some(l => l.code === "ja"));
    });
});
