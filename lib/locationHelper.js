// Pure helper for IP geolocation parsing and location formatting
// Compatible with QML (no bare ES6 export) and Node.js testing

function getDefaultLocation() {
    return {
        success: false,
        city: "Jakarta",
        region: "DKI Jakarta",
        country: "Indonesia",
        lat: -6.2088,
        lon: 106.8456,
        timezone: "Asia/Jakarta"
    };
}

function parseIpApiResponse(rawJson) {
    if (!rawJson) return getDefaultLocation();

    try {
        var data = typeof rawJson === "string" ? JSON.parse(rawJson) : rawJson;
        if (!data || typeof data !== "object") {
            return getDefaultLocation();
        }

        if (data.status === "success" && typeof data.lat === "number" && typeof data.lon === "number") {
            return {
                success: true,
                city: data.city ? String(data.city).trim() : "Jakarta",
                region: data.regionName ? String(data.regionName).trim() : "",
                country: data.country ? String(data.country).trim() : "Indonesia",
                lat: data.lat,
                lon: data.lon,
                timezone: data.timezone ? String(data.timezone).trim() : "Asia/Jakarta"
            };
        }
    } catch (e) {
        // Fall back to default
    }

    return getDefaultLocation();
}

function formatLocationLabel(city, region) {
    var c = city ? String(city).trim() : "";
    var r = region ? String(region).trim() : "";

    if (c.length > 0 && r.length > 0) {
        return c + ", " + r;
    }
    if (c.length > 0) {
        return c;
    }
    return "Lokasi Otomatis";
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        getDefaultLocation: getDefaultLocation,
        parseIpApiResponse: parseIpApiResponse,
        formatLocationLabel: formatLocationLabel
    };
}
