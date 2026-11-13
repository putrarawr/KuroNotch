#!/usr/bin/env bash
set -euo pipefail

# Kuro Island Installer
# Installs Kuro Island (Dynamic Notch & Companion for Hyprland) cleanly.

cat << "EOF"
  /\_/\   
 ( o.o )  KURO ISLAND (Dynamic Island for Linux & Hyprland)
  > ^ <   https://github.com/putrapad/kuro-island
EOF
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "==> Preparing installation directories..."
mkdir -p "$HOME/.config/kuro-island"
mkdir -p "$HOME/.local/state/kuro-island/wallpaper"
mkdir -p "$HOME/.cache/kuro-island/lyrics"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config/quickshell"

# Symlink config
echo "==> Linking Quickshell configuration..."
ln -sfn "$REPO_DIR" "$HOME/.config/quickshell/island-notch"
ln -sfn "$REPO_DIR" "$HOME/.config/quickshell/kuro-island"

# Install binary wrappers
echo "==> Installing wrapper binaries..."
cat > "$HOME/.local/bin/kuro-island" << 'WRAPPER'
#!/usr/bin/env bash
unset LD_LIBRARY_PATH
exec /usr/local/bin/quickshell -c island-notch "$@"
WRAPPER
chmod +x "$HOME/.local/bin/kuro-island"

cat > "$HOME/.local/bin/island-notch" << 'WRAPPER'
#!/usr/bin/env bash
unset LD_LIBRARY_PATH
exec /usr/local/bin/quickshell -c island-notch "$@"
WRAPPER
chmod +x "$HOME/.local/bin/island-notch"

# Run integration installer
if [ -f "$REPO_DIR/scripts/install-integration.sh" ]; then
    echo "==> Running desktop integration installer..."
    bash "$REPO_DIR/scripts/install-integration.sh"
fi

echo ""
echo "✨ Kuro Island installed successfully!"
echo "To start now, run: ~/.local/bin/kuro-island"
echo "Or reload Hyprland to launch via autostart (exec-once)."
echo "Kuro says: nya~ (Enjoy your new dynamic desktop!)"
