#!/usr/bin/env bash
set -euo pipefail

# KuroNotch Instant Updater
# Updates KuroNotch from GitHub and reloads the desktop notch cleanly.

cat << "EOF"
  /\_/\   
 ( ^.^ )  KURO NOTCH UPDATER
  > ^ <   https://github.com/putrarawr/KuroNotch
EOF
echo ""

TARGET_DIR="$HOME/.config/quickshell/island-notch"

SCRIPT_DIR=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Detect repository directory
if [ -n "$SCRIPT_DIR" ] && [ -f "$SCRIPT_DIR/../shell.qml" ]; then
    REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
elif [ -d "$TARGET_DIR/.git" ]; then
    REPO_DIR="$TARGET_DIR"
else
    echo "==> KuroNotch installation not found in $TARGET_DIR. Cloning latest..."
    mkdir -p "$HOME/.config/quickshell"
    git clone https://github.com/putrarawr/KuroNotch.git "$TARGET_DIR"
    REPO_DIR="$TARGET_DIR"
fi

echo "==> Fetching latest KuroNotch updates from GitHub ($REPO_DIR)..."
git -C "$REPO_DIR" fetch origin main
LOCAL_HASH=$(git -C "$REPO_DIR" rev-parse HEAD)
REMOTE_HASH=$(git -C "$REPO_DIR" rev-parse origin/main)

if [ "$LOCAL_HASH" = "$REMOTE_HASH" ]; then
    echo "  -> Already up to date! (commit: ${LOCAL_HASH:0:7})"
else
    git -C "$REPO_DIR" pull --rebase origin main
    NEW_HASH=$(git -C "$REPO_DIR" rev-parse HEAD)
    echo "  -> Successfully updated from ${LOCAL_HASH:0:7} to ${NEW_HASH:0:7}!"
fi

# Refresh wrapper binaries
echo "==> Updating wrapper commands in ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
for cmd in island-notch kuronotch kuro-island; do
    cat > "$HOME/.local/bin/$cmd" << 'WRAPPER'
#!/usr/bin/env bash
if [ "${1:-}" = "update" ] || [ "${1:-}" = "--update" ]; then
    UPDATE_SCRIPT="$HOME/.config/quickshell/island-notch/scripts/update.sh"
    if [ -x "$UPDATE_SCRIPT" ]; then
        exec "$UPDATE_SCRIPT" "${@:2}"
    else
        curl -sSL https://raw.githubusercontent.com/putrarawr/KuroNotch/main/scripts/update.sh | bash -s -- "${@:2}"
        exit $?
    fi
elif [ "${1:-}" = "uninstall" ] || [ "${1:-}" = "--uninstall" ]; then
    UNINSTALL_SCRIPT="$HOME/.config/quickshell/island-notch/scripts/uninstall.sh"
    if [ -x "$UNINSTALL_SCRIPT" ]; then
        exec "$UNINSTALL_SCRIPT" "${@:2}"
    else
        curl -sSL https://raw.githubusercontent.com/putrarawr/KuroNotch/main/scripts/uninstall.sh | bash -s -- "${@:2}"
        exit $?
    fi
fi
unset LD_LIBRARY_PATH
exec /usr/local/bin/quickshell -c island-notch "$@"
WRAPPER
    chmod +x "$HOME/.local/bin/$cmd"
done

# Reload KuroNotch process seamlessly
echo "==> Reloading KuroNotch..."
pkill -f "quickshell.*island-notch" 2>/dev/null || true
sleep 0.5
nohup "$HOME/.local/bin/island-notch" >/dev/null 2>&1 &

echo ""
echo "✨ KuroNotch updated and reloaded successfully!"
echo "Notch versi terbaru sekarang sudah aktif di layar kamu."
echo "Kuro says: nya~ (Updated and running smoothly!)"
