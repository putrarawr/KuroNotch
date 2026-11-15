/**
 * translateHelper.js - Pure translation URL builder and response parser for KuroNotch.
 */

const SUPPORTED_LANGUAGES = [
    { code: "auto", name: "Deteksi Otomatis" },
    { code: "id", name: "Indonesia" },
    { code: "en", name: "English" },
    { code: "ja", name: "Jepang" },
    { code: "ar", name: "Arab" },
    { code: "ko", name: "Korea" },
    { code: "zh", name: "Mandarin" },
    { code: "fr", name: "Prancis" },
    { code: "de", name: "Jerman" },
    { code: "es", name: "Spanyol" },
    { code: "ru", name: "Rusia" }
];

/**
 * Builds Google Translate public endpoint URL.
 *
 * @param {string} text
 * @param {string} [sourceLang="auto"]
 * @param {string} [targetLang="id"]
 * @returns {string}
 */
function buildTranslateUrl(text, sourceLang, targetLang) {
    const sl = (sourceLang || "auto").trim().toLowerCase();
    const tl = (targetLang || "id").trim().toLowerCase();
    const q = encodeURIComponent((text || "").trim());
    return `https://translate.googleapis.com/translate_a/single?client=gtx&sl=${sl}&tl=${tl}&dt=t&q=${q}`;
}

/**
 * Parses raw translation response.
 *
 * @param {string|Array} raw
 * @returns {{ success: boolean, translatedText: string, detectedSource: string, error?: string }}
 */
function parseTranslationResponse(raw) {
    if (!raw) {
        return { success: false, translatedText: "", detectedSource: "", error: "Empty response" };
    }

    let data = raw;
    if (typeof raw === "string") {
        const trimmed = raw.trim();
        if (trimmed.length === 0) {
            return { success: false, translatedText: "", detectedSource: "", error: "Empty string" };
        }
        try {
            data = JSON.parse(trimmed);
        } catch (e) {
            return { success: false, translatedText: "", detectedSource: "", error: `JSON Parse error: ${e.message}` };
        }
    }

    if (!Array.isArray(data) || !Array.isArray(data[0])) {
        return { success: false, translatedText: "", detectedSource: "", error: "Unexpected response structure" };
    }

    const chunks = data[0];
    let translated = "";
    for (let i = 0; i < chunks.length; i++) {
        const chunk = chunks[i];
        if (Array.isArray(chunk) && typeof chunk[0] === "string") {
            translated += chunk[0];
        }
    }

    const detected = (typeof data[2] === "string") ? data[2] : "";

    return {
        success: true,
        translatedText: translated,
        detectedSource: detected
    };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        SUPPORTED_LANGUAGES,
        buildTranslateUrl,
        parseTranslationResponse
    };
}
