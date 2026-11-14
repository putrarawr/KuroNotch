#!/usr/bin/env bash
set -euo pipefail

# KuroNotch (Kuro Island) Installer
# Installs KuroNotch (Dynamic Island & Companion for Linux Wayland / Hyprland) cleanly.

cat << "EOF"
  /\_/\   
 ( o.o )  KURO NOTCH (Dynamic Island for Linux & Hyprland)
  > ^ <   https://github.com/putrarawr/KuroNotch
EOF
echo ""

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

TARGET_DIR="$HOME/.config/quickshell/island-notch"

# Check if running from inside an existing cloned repo
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../shell.qml" ]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
else
    echo "==> Cloning KuroNotch repository into $TARGET_DIR..."
    mkdir -p "$HOME/.config/quickshell"
    if [ -d "$TARGET_DIR/.git" ]; then
        echo "  -> Existing git repo found in $TARGET_DIR, pulling latest changes..."
        git -C "$TARGET_DIR" pull --rebase origin main || true
    else
        rm -rf "$TARGET_DIR"
        git clone https://github.com/putrarawr/KuroNotch.git "$TARGET_DIR"
    fi
    REPO_DIR="$TARGET_DIR"
fi

echo "==> Preparing installation directories..."
mkdir -p "$HOME/.config/island-notch"
mkdir -p "$HOME/.config/kuro-island"
mkdir -p "$HOME/.local/state/island-notch/wallpaper"
mkdir -p "$HOME/.local/state/kuro-island/wallpaper"
mkdir -p "$HOME/.cache/island-notch/lyrics"
mkdir -p "$HOME/.cache/kuro-island/lyrics"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/quickshell"

# Symlink config so Quickshell can locate it by any alias
echo "==> Linking Quickshell configuration..."
if [ "$REPO_DIR" != "$TARGET_DIR" ]; then
    ln -sfn "$REPO_DIR" "$TARGET_DIR"
fi
ln -sfn "$REPO_DIR" "$HOME/.config/quickshell/KuroNotch"
ln -sfn "$REPO_DIR" "$HOME/.config/quickshell/kuro-island"

# Install binary wrappers
echo "==> Installing wrapper binaries into ~/.local/bin..."
for cmd in island-notch kuronotch kuro-island; do
    cat > "$HOME/.local/bin/$cmd" << 'WRAPPER'
#!/usr/bin/env bash
LAUNCHER="$HOME/.config/quickshell/island-notch/scripts/island-notch"
if [ -x "$LAUNCHER" ]; then
    exec "$LAUNCHER" "$@"
fi
unset LD_LIBRARY_PATH
exec /usr/local/bin/quickshell -n -c island-notch "$@"
WRAPPER
    chmod +x "$HOME/.local/bin/$cmd"
done

# Run integration installer
if [ -f "$REPO_DIR/scripts/install-integration.sh" ]; then
    echo "==> Running desktop integration installer..."
    bash "$REPO_DIR/scripts/install-integration.sh"
fi

# Automatically start KuroNotch immediately in the background
echo "==> Starting KuroNotch..."
pkill -f "quickshell.*island-notch" 2>/dev/null || true
sleep 0.5
nohup "$HOME/.local/bin/island-notch" >/dev/null 2>&1 &

echo ""
echo "✨ KuroNotch (Kuro Island) installed & launched successfully!"
echo "Notch sekarang sudah aktif di bagian atas layar kamu!"
echo "Pintasan cepat: Tekan Super+I untuk membuka/menutup Notch."
echo "Untuk mengontrol via terminal: ~/.local/bin/island-notch (atau kuronotch)"
echo "Kuro says: nya~ (Enjoy your new dynamic desktop!)"
