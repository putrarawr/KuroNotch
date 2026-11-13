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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

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
ln -sfn "$REPO_DIR" "$HOME/.config/quickshell/island-notch"
ln -sfn "$REPO_DIR" "$HOME/.config/quickshell/KuroNotch"
ln -sfn "$REPO_DIR" "$HOME/.config/quickshell/kuro-island"

# Install binary wrappers
echo "==> Installing wrapper binaries into ~/.local/bin..."
for cmd in island-notch kuronotch kuro-island; do
    cat > "$HOME/.local/bin/$cmd" << 'WRAPPER'
#!/usr/bin/env bash
unset LD_LIBRARY_PATH
exec /usr/local/bin/quickshell -c island-notch "$@"
WRAPPER
    chmod +x "$HOME/.local/bin/$cmd"
done

# Run integration installer
if [ -f "$REPO_DIR/scripts/install-integration.sh" ]; then
    echo "==> Running desktop integration installer..."
    bash "$REPO_DIR/scripts/install-integration.sh"
fi

echo ""
echo "✨ KuroNotch (Kuro Island) installed successfully!"
echo "To start now, run: ~/.local/bin/island-notch (or kuronotch)"
echo "Or reload Hyprland to launch via autostart (exec-once)."
echo "Kuro says: nya~ (Enjoy your new dynamic desktop!)"
