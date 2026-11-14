#!/usr/bin/env bash
# ==============================================================================
# KuroNotch (Kuro Island) System Doctor & Diagnostics CLI
# ==============================================================================
set -u

COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"
COLOR_GREEN="\033[38;5;48m"
COLOR_YELLOW="\033[38;5;220m"
COLOR_RED="\033[38;5;196m"
COLOR_CYAN="\033[38;5;45m"
COLOR_GRAY="\033[38;5;244m"

print_header() {
    echo -e "${COLOR_CYAN}${COLOR_BOLD}"
    echo "  /\_/\   KURO NOTCH SYSTEM DOCTOR"
    echo " ( o.o )  System Compatibility & Diagnostics"
    echo "  > ^ <   https://github.com/putrarawr/KuroNotch"
    echo -e "${COLOR_RESET}"
}

OK="${COLOR_GREEN}[OK]${COLOR_RESET}"
WARN="${COLOR_YELLOW}[WARN]${COLOR_RESET}"
FAIL="${COLOR_RED}[FAIL]${COLOR_RESET}"
INFO="${COLOR_CYAN}[INFO]${COLOR_RESET}"

HAS_WARNINGS=0

check_distro() {
    local distro="Linux"
    if [ -f /etc/os-release ]; then
        distro=$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2 | tr -d '"')
    fi
    local kernel=$(uname -r)
    echo -e "$OK OS / Kernel: ${COLOR_BOLD}$distro${COLOR_RESET} ($kernel)"
}

check_display_session() {
    local session_type="${XDG_SESSION_TYPE:-unknown}"
    local desktop="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"

    if [ "$session_type" = "unknown" ]; then
        if [ -n "${WAYLAND_DISPLAY:-}" ]; then
            session_type="wayland"
        elif [ -n "${DISPLAY:-}" ]; then
            session_type="x11"
        fi
    fi

    echo -e "$OK Display Server: ${COLOR_BOLD}$session_type${COLOR_RESET}"
    echo -e "$OK Desktop Environment: ${COLOR_BOLD}$desktop${COLOR_RESET}"

    # Check GNOME Wayland layer-shell limitation
    if [ "$session_type" = "wayland" ] && [[ "${desktop,,}" == *"gnome"* ]]; then
        echo -e "$WARN GNOME Wayland detected: Mutter does not support wlr-layer-shell upstream."
        echo -e "       ${COLOR_GRAY}-> Tip: For KuroNotch overlay support on GNOME, use GNOME on Xorg (X11).${COLOR_RESET}"
        HAS_WARNINGS=1
    fi
}

check_compositor() {
    local session_type="${XDG_SESSION_TYPE:-}"
    if [ "$session_type" = "wayland" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; then
        if [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
            echo -e "$OK Compositor: ${COLOR_BOLD}Hyprland${COLOR_RESET} (Native Wayland layer-shell active)"
        else
            echo -e "$OK Compositor: ${COLOR_BOLD}Wayland Compositor${COLOR_RESET} (wlr-layer-shell compatible)"
        fi
    else
        # X11 Session checks
        local compositor_found=0
        if command -v xfconf-query >/dev/null 2>&1; then
            local xfwm_comp
            xfwm_comp=$(xfconf-query -c xfwm4 -p /general/use_compositing 2>/dev/null || echo "false")
            if [ "$xfwm_comp" = "true" ]; then
                echo -e "$OK Compositor: ${COLOR_BOLD}XFCE xfwm4${COLOR_RESET} (Display compositing ENABLED)"
                compositor_found=1
            else
                echo -e "$WARN Compositor: ${COLOR_BOLD}XFCE xfwm4${COLOR_RESET} (Display compositing is DISABLED)"
                echo -e "       ${COLOR_GRAY}-> Fix: Run 'xfconf-query -c xfwm4 -p /general/use_compositing -s true' or kuronotch auto-fixes this.${COLOR_RESET}"
                HAS_WARNINGS=1
            fi
        fi

        if [ "$compositor_found" -eq 0 ]; then
            if pgrep -x "picom" >/dev/null 2>&1; then
                echo -e "$OK Compositor: ${COLOR_BOLD}picom${COLOR_RESET} (Active X11 compositor)"
                compositor_found=1
            elif pgrep -x "compton" >/dev/null 2>&1; then
                echo -e "$OK Compositor: ${COLOR_BOLD}compton${COLOR_RESET} (Active X11 compositor)"
                compositor_found=1
            elif command -v xprop >/dev/null 2>&1 && xprop -root _NET_WM_CM_S0 2>/dev/null | grep -q "window id"; then
                echo -e "$OK Compositor: ${COLOR_BOLD}Active X11 Compositor detected${COLOR_RESET} (_NET_WM_CM_S0)"
                compositor_found=1
            else
                echo -e "$WARN Compositor: ${COLOR_BOLD}No active X11 compositor detected!${COLOR_RESET}"
                echo -e "       ${COLOR_GRAY}-> Transparency and spring animations require an X11 compositor (xfwm4 or picom).${COLOR_RESET}"
                HAS_WARNINGS=1
            fi
        fi
    fi
}

check_gpu() {
    if command -v glxinfo >/dev/null 2>&1; then
        local direct
        direct=$(glxinfo 2>/dev/null | grep -i "direct rendering:" | awk '{print $3}')
        local renderer
        renderer=$(glxinfo 2>/dev/null | grep -i "OpenGL renderer string:" | cut -d: -f2 | xargs)

        if [ "$direct" = "Yes" ]; then
            echo -e "$OK 3D Acceleration: ${COLOR_BOLD}Direct Hardware Rendering (Yes)${COLOR_RESET}"
            echo -e "$OK GPU Renderer: ${COLOR_GRAY}$renderer${COLOR_RESET}"
        else
            echo -e "$WARN 3D Acceleration: ${COLOR_BOLD}Software / Indirect Rendering ($direct)${COLOR_RESET}"
            echo -e "       ${COLOR_GRAY}-> Warning: Software rendering (llvmpipe) may cause dropped animation frames.${COLOR_RESET}"
            HAS_WARNINGS=1
        fi
    else
        echo -e "$INFO 3D Acceleration: glxinfo not found (skipped direct rendering check)"
    fi
}

check_quickshell() {
    local qs_path
    qs_path=$(command -v quickshell || echo "/usr/local/bin/quickshell")

    if [ -x "$qs_path" ]; then
        local qs_ver
        qs_ver=$("$qs_path" --version 2>/dev/null | head -n1 || echo "0.3.1")
        echo -e "$OK Quickshell Engine: ${COLOR_BOLD}$qs_path${COLOR_RESET} ($qs_ver)"
    else
        echo -e "$FAIL Quickshell Engine: Not found at $qs_path!"
        echo -e "       ${COLOR_GRAY}-> Please install Quickshell 0.3.1 to run KuroNotch.${COLOR_RESET}"
        HAS_WARNINGS=1
    fi
}

check_audio_mpris() {
    if command -v pw-cli >/dev/null 2>&1 || pgrep -x "pipewire" >/dev/null 2>&1; then
        echo -e "$OK Audio Subsystem: ${COLOR_BOLD}PipeWire${COLOR_RESET}"
    elif command -v pactl >/dev/null 2>&1 || pgrep -x "pulseaudio" >/dev/null 2>&1; then
        echo -e "$OK Audio Subsystem: ${COLOR_BOLD}PulseAudio${COLOR_RESET}"
    else
        echo -e "$INFO Audio Subsystem: Standard ALSA / Audio"
    fi

    local players=""
    if command -v playerctl >/dev/null 2>&1; then
        players=$(playerctl -l 2>/dev/null | tr '\n' ' ' | xargs || true)
    fi
    if [ -n "$players" ]; then
        echo -e "$OK Active MPRIS Media Players: ${COLOR_BOLD}$players${COLOR_RESET}"
    else
        echo -e "$INFO Active MPRIS Media Players: None running currently"
    fi
}

main() {
    print_header
    echo -e "${COLOR_BOLD}--- System Diagnostics Check ---${COLOR_RESET}"
    check_distro
    check_display_session
    check_compositor
    check_gpu
    check_quickshell
    check_audio_mpris
    echo ""

    if [ "$HAS_WARNINGS" -eq 0 ]; then
        echo -e "${COLOR_GREEN}${COLOR_BOLD}✓ Everything looks great! Your system is fully ready for KuroNotch.${COLOR_RESET}"
        exit 0
    else
        echo -e "${COLOR_YELLOW}${COLOR_BOLD}! Some recommendations above will ensure maximum animation smoothness.${COLOR_RESET}"
        exit 0
    fi
}

main "$@"
