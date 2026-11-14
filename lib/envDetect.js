/**
 * KuroNotch - Linux Environment & Display Server Detection
 * Pure helper module to classify runtime desktop and compositor environment.
 */

export function detectEnvironment(env = (typeof process !== "undefined" ? process.env : {})) {
    const rawSessionType = (env.XDG_SESSION_TYPE || "").toLowerCase().trim();
    let sessionType = rawSessionType;

    if (!sessionType) {
        if (Boolean(env.WAYLAND_DISPLAY)) {
            sessionType = "wayland";
        } else if (Boolean(env.DISPLAY)) {
            sessionType = "x11";
        } else {
            sessionType = "unknown";
        }
    }

    const currentDesktop = (env.XDG_CURRENT_DESKTOP || "").toLowerCase();
    const desktopSession = (env.DESKTOP_SESSION || "").toLowerCase();
    const combinedDesktop = `${currentDesktop}:${desktopSession}`;

    const isHyprland = Boolean(env.HYPRLAND_INSTANCE_SIGNATURE) || combinedDesktop.includes("hyprland");
    const isXfce = combinedDesktop.includes("xfce");
    const isGnome = combinedDesktop.includes("gnome");
    const isKde = combinedDesktop.includes("kde") || combinedDesktop.includes("plasma");
    const isCinnamon = combinedDesktop.includes("cinnamon");
    const isGnomeWayland = sessionType === "wayland" && isGnome;

    return {
        sessionType,
        desktop: env.XDG_CURRENT_DESKTOP || env.DESKTOP_SESSION || "unknown",
        isHyprland,
        isXfce,
        isGnome,
        isKde,
        isCinnamon,
        isGnomeWayland,
        needsCompositorCheck: sessionType === "x11",
        recommendedRhi: "opengl"
    };
}
