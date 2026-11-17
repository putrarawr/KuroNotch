import { describe, it } from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { loadQmlJs } from "./helpers/loadQmlJs.mjs";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const {
    parseIpApiResponse,
    formatLocationLabel,
    getDefaultLocation
} = loadQmlJs(path.resolve(__dirname, "../lib/locationHelper.js"));

describe("locationHelper.js - Auto Geolocation Parser & Formatter", () => {
    it("parses valid ip-api.com response into standardized location object", () => {
        const rawJson = JSON.stringify({
            status: "success",
            country: "Indonesia",
            regionName: "East Java",
            city: "Banyuwangi",
            lat: -8.2183,
            lon: 114.3602,
            timezone: "Asia/Jakarta"
        });

        const res = parseIpApiResponse(rawJson);
        assert.equal(res.success, true);
        assert.equal(res.city, "Banyuwangi");
        assert.equal(res.region, "East Java");
        assert.equal(res.country, "Indonesia");
        assert.equal(res.lat, -8.2183);
        assert.equal(res.lon, 114.3602);
        assert.equal(res.timezone, "Asia/Jakarta");
    });

    it("falls back gracefully on empty, failed, or malformed JSON", () => {
        const failJson = JSON.stringify({ status: "fail", message: "invalid query" });
        const res1 = parseIpApiResponse(failJson);
        assert.equal(res1.success, false);
        assert.ok(res1.city.length > 0);
        assert.equal(typeof res1.lat, "number");

        const res2 = parseIpApiResponse("invalid-json");
        assert.equal(res2.success, false);
        assert.ok(res2.city.length > 0);

        const res3 = parseIpApiResponse(null);
        assert.equal(res3.success, false);
    });

    it("formats clean human-readable location label", () => {
        assert.equal(formatLocationLabel("Banyuwangi", "East Java"), "Banyuwangi, East Java");
        assert.equal(formatLocationLabel("Jakarta", ""), "Jakarta");
        assert.equal(formatLocationLabel("", ""), "Lokasi Otomatis");
    });

    it("provides safe default fallback location", () => {
        const def = getDefaultLocation();
        assert.equal(def.city, "Jakarta");
        assert.equal(def.lat, -6.2088);
        assert.equal(def.lon, 106.8456);
    });
});
