/**
 * shalatHelper.js - Accurate, offline astronomical prayer time calculator for KuroNotch.
 * Implements Kemenag (Kementerian Agama RI) calculation standards for Indonesian cities.
 */

const DEG2RAD = Math.PI / 180.0;
const RAD2DEG = 180.0 / Math.PI;

function dsin(d) { return Math.sin(d * DEG2RAD); }
function dcos(d) { return Math.cos(d * DEG2RAD); }
function dtan(d) { return Math.tan(d * DEG2RAD); }
function darcsin(x) { return Math.asin(x) * RAD2DEG; }
function darccos(x) { return Math.acos(x) * RAD2DEG; }
function darctan2(y, x) { return Math.atan2(y, x) * RAD2DEG; }
function fixAngle(a) { return a - 360.0 * Math.floor(a / 360.0); }
function fixHour(h) { return h - 24.0 * Math.floor(h / 24.0); }

/**
 * Calculates solar position (declination & equation of time).
 * @param {number} jd - Julian Date
 * @returns {{ declination: number, equation: number }}
 */
function sunPosition(jd) {
    const D = jd - 2451545.0;
    const g = fixAngle(357.529 + 0.98560028 * D);
    const q = fixAngle(280.459 + 0.98564736 * D);
    const L = fixAngle(q + 1.915 * dsin(g) + 0.020 * dsin(2 * g));

    const e = 23.439 - 0.00000036 * D;
    const d = darcsin(dsin(e) * dsin(L));
    let ra = darctan2(dcos(e) * dsin(L), dcos(L)) / 15.0;
    ra = fixHour(ra);

    const eq = (q / 15.0) - ra;
    return { declination: d, equation: eq * 60.0 };
}

/**
 * Computes Julian Date from JavaScript Date object.
 */
function toJulianDate(date) {
    let year = date.getFullYear();
    let month = date.getMonth() + 1;
    const day = date.getDate();

    if (month <= 2) {
        year -= 1;
        month += 12;
    }

    const A = Math.floor(year / 100);
    const B = 2 - A + Math.floor(A / 4);
    return Math.floor(365.25 * (year + 4716)) + Math.floor(30.6001 * (month + 1)) + day + B - 1524.5;
}

/**
 * Calculates Sun hour angle for given altitude angle.
 */
function sunAngleTime(angle, decl, lat) {
    const top = -dsin(angle) - dsin(lat) * dsin(decl);
    const bottom = dcos(lat) * dcos(decl);
    const cosAngle = top / bottom;

    if (cosAngle > 1.0) return null; // Sun never reaches angle
    if (cosAngle < -1.0) return null;

    return darccos(cosAngle) / 15.0;
}

/**
 * Formats fractional hours to "hh:mm"
 */
function floatToTime(hours) {
    if (hours === null || isNaN(hours)) return "--:--";
    let h = fixHour(hours);
    const totalMinutes = Math.round(h * 60);
    const hh = Math.floor(totalMinutes / 60) % 24;
    const mm = totalMinutes % 60;
    const pad = n => (n < 10 ? "0" : "") + n;
    return `${pad(hh)}:${pad(mm)}`;
}

/**
 * Indonesian major cities coordinates & timezone presets
 */
const INDONESIAN_CITIES = [
    { name: "Jakarta", latitude: -6.2088, longitude: 106.8456, timezone: 7 },
    { name: "Surabaya", latitude: -7.2575, longitude: 112.7521, timezone: 7 },
    { name: "Bandung", latitude: -6.9175, longitude: 107.6191, timezone: 7 },
    { name: "Medan", latitude: 3.5952, longitude: 98.6722, timezone: 7 },
    { name: "Semarang", latitude: -6.9667, longitude: 110.4167, timezone: 7 },
    { name: "Yogyakarta", latitude: -7.7956, longitude: 110.3695, timezone: 7 },
    { name: "Makassar", latitude: -5.1477, longitude: 119.4327, timezone: 8 },
    { name: "Denpasar", latitude: -8.6705, longitude: 115.2126, timezone: 8 },
    { name: "Balikpapan", latitude: -1.2654, longitude: 116.8312, timezone: 8 },
    { name: "Jayapura", latitude: -2.5337, longitude: 140.7181, timezone: 9 }
];

function getCityCoordinates(cityName) {
    const match = INDONESIAN_CITIES.find(c => c.name.toLowerCase() === (cityName || "").toLowerCase().trim());
    return match || INDONESIAN_CITIES[0]; // fallback to Jakarta
}

/**
 * Calculates prayer times for a given date and location.
 *
 * @param {Date} date
 * @param {number} latitude
 * @param {number} longitude
 * @param {number} timezone (e.g. 7 for WIB, 8 for WITA, 9 for WIT)
 * @returns {{ subuh: string, terbit: string, dzuhur: string, ashar: string, maghrib: string, isya: string }}
 */
function calculatePrayerTimes(date, latitude, longitude, timezone) {
    const jd = toJulianDate(date);
    const sun = sunPosition(jd);

    // Midday (Dzuhur) in local time
    // Base solar noon = 12 + timezone - (longitude / 15) - (equation / 60)
    const noon = 12.0 + timezone - (longitude / 15.0) - (sun.equation / 60.0);
    // Kemenag adds ~2 minutes ihtiyat (safety buffer)
    const dzuhurHour = noon + (2.0 / 60.0);

    // Subuh (Kemenag standard angle: 20°)
    const subuhAngle = sunAngleTime(20.0, sun.declination, latitude);
    const subuhHour = subuhAngle ? (noon - subuhAngle + (2.0 / 60.0)) : null;

    // Terbit (Sunrise, angle: 0.833° refraction & radius)
    const terbitAngle = sunAngleTime(0.833, sun.declination, latitude);
    const terbitHour = terbitAngle ? (noon - terbitAngle) : null;

    // Ashar (Shafi'i: shadow length = object + noon shadow)
    // alt = arccot(1 + tan|lat - decl|)
    const asharAlt = darccos(dsin(Math.abs(latitude - sun.declination))) ? (RAD2DEG * Math.atan(1.0 / (1.0 + dtan(Math.abs(latitude - sun.declination))))) : 45.0;
    const asharAngle = sunAngleTime(90.0 - asharAlt, sun.declination, latitude);
    const asharHour = asharAngle ? (noon + asharAngle + (2.0 / 60.0)) : null;

    // Maghrib (Sunset, angle: 0.833°) + 2 mins ihtiyat
    const maghribHour = terbitAngle ? (noon + terbitAngle + (2.0 / 60.0)) : null;

    // Isya (Kemenag standard angle: 18°) + 2 mins ihtiyat
    const isyaAngle = sunAngleTime(18.0, sun.declination, latitude);
    const isyaHour = isyaAngle ? (noon + isyaAngle + (2.0 / 60.0)) : null;

    return {
        subuh: floatToTime(subuhHour),
        terbit: floatToTime(terbitHour),
        dzuhur: floatToTime(dzuhurHour),
        ashar: floatToTime(asharHour),
        maghrib: floatToTime(maghribHour),
        isya: floatToTime(isyaHour)
    };
}

/**
 * Finds next upcoming prayer and calculates minutes diff and countdown format.
 *
 * @param {Object} times - object with subuh, dzuhur, ashar, maghrib, isya (hh:mm)
 * @param {string|Date} [currentTime] - "hh:mm" or Date object
 * @returns {{ name: string, time: string, diffMinutes: number, countdownFormatted: string }}
 */
function getNextPrayer(times, currentTime) {
    if (!times) {
        return { name: "Shalat", time: "--:--", diffMinutes: 0, countdownFormatted: "" };
    }

    let curHour = 0;
    let curMin = 0;

    if (currentTime instanceof Date) {
        curHour = currentTime.getHours();
        curMin = currentTime.getMinutes();
    } else if (typeof currentTime === "string" && currentTime.indexOf(":") !== -1) {
        const parts = currentTime.split(":");
        curHour = parseInt(parts[0], 10) || 0;
        curMin = parseInt(parts[1], 10) || 0;
    } else {
        const now = new Date();
        curHour = now.getHours();
        curMin = now.getMinutes();
    }

    const currentTotalMin = curHour * 60 + curMin;

    const prayerOrder = [
        { name: "Subuh", time: times.subuh },
        { name: "Dzuhur", time: times.dzuhur },
        { name: "Ashar", time: times.ashar },
        { name: "Maghrib", time: times.maghrib },
        { name: "Isya", time: times.isya }
    ];

    for (let i = 0; i < prayerOrder.length; i++) {
        const p = prayerOrder[i];
        if (!p.time || p.time.indexOf(":") === -1) continue;
        const [h, m] = p.time.split(":").map(Number);
        const pTotal = h * 60 + m;

        if (pTotal > currentTotalMin) {
            const diff = pTotal - currentTotalMin;
            const hours = Math.floor(diff / 60);
            const mins = diff % 60;
            const fmt = hours > 0 ? `${hours}j ${mins}m` : `${mins}m`;
            return {
                name: p.name,
                time: p.time,
                diffMinutes: diff,
                countdownFormatted: fmt
            };
        }
    }

    // After Isya -> next is Subuh tomorrow
    const subuhParts = (times.subuh || "04:30").split(":").map(Number);
    const subuhMin = subuhParts[0] * 60 + subuhParts[1];
    const diffTomorrow = (24 * 60 - currentTotalMin) + subuhMin;
    const hours = Math.floor(diffTomorrow / 60);
    const mins = diffTomorrow % 60;
    const fmt = hours > 0 ? `${hours}j ${mins}m` : `${mins}m`;

    return {
        name: "Subuh",
        time: times.subuh || "04:30",
        diffMinutes: diffTomorrow,
        countdownFormatted: fmt
    };
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = {
        calculatePrayerTimes,
        getNextPrayer,
        INDONESIAN_CITIES,
        getCityCoordinates
    };
}
