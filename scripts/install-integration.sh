#!/usr/bin/env bash
set -euo pipefail

# scripts/install-integration.sh
# Idempotently installs island-notch integration into Caelestia, Hyprland, and system autostart.
# Creates timestamped .bak.<timestamp> backups before modifying any external file.

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
QUICKSHELL_DIR="$HOME/.config/quickshell"
CAELESTIA_NOTIFS="$HOME/.config/quickshell/caelestia/services/Notifs.qml"
CAELESTIA_SHELL_JSON="$HOME/.config/caelestia/shell.json"
HYPRLAND_CONF="$HOME/.config/hypr/hyprland.conf"
BIN_DIR="$HOME/.local/bin"

# Pre-create all required runtime directories upfront to avoid clean-install races
mkdir -p "$HOME/.config/island-notch" "$HOME/.local/state/island-notch" "$HOME/.cache/island-notch/lyrics"

echo "=== Island Notch Integration Installer ==="
echo "Timestamp: $TIMESTAMP"

# 1. Symlink ~/.config/quickshell/island-notch -> repo
echo "[1/5] Setting up Quickshell configuration symlink..."
mkdir -p "$QUICKSHELL_DIR"
ln -sfn "$REPO_DIR" "$QUICKSHELL_DIR/island-notch"
echo "  -> Symlinked $QUICKSHELL_DIR/island-notch to $REPO_DIR"

# 2. Install wrapper executable ~/.local/bin/island-notch
echo "[2/5] Installing wrapper binary ~/.local/bin/island-notch..."
mkdir -p "$BIN_DIR"
cp "$REPO_DIR/scripts/island-notch" "$BIN_DIR/island-notch"
chmod +x "$BIN_DIR/island-notch"
echo "  -> Installed and made executable $BIN_DIR/island-notch"

# 3. Update ~/.config/caelestia/shell.json cleanly (merge, preserve other settings)
echo "[3/5] Updating Caelestia shell.json..."
if [ -f "$CAELESTIA_SHELL_JSON" ]; then
    cp "$CAELESTIA_SHELL_JSON" "${CAELESTIA_SHELL_JSON}.bak.${TIMESTAMP}"
    echo "  -> Backup created: ${CAELESTIA_SHELL_JSON}.bak.${TIMESTAMP}"
fi

mkdir -p "$(dirname "$CAELESTIA_SHELL_JSON")"
python3 - <<EOF
import json, os

path = os.path.expanduser("$CAELESTIA_SHELL_JSON")
if os.path.exists(path):
    with open(path, "r", encoding="utf-8") as f:
        try:
            data = json.load(f)
        except Exception:
            data = {}
else:
    data = {}

# Merge required values without overwriting existing unrelated configuration
data.setdefault("osd", {})["enabled"] = False
data.setdefault("dashboard", {})["showOnHover"] = False

toasts = data.setdefault("utilities", {}).setdefault("toasts", {})
toasts["chargingChanged"] = False
toasts["audioOutputChanged"] = False
toasts["audioInputChanged"] = False

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4)
EOF
echo "  -> Updated $CAELESTIA_SHELL_JSON"

# 4. Patch Caelestia Notifs.qml to disable NotificationServer instantiation
echo "[4/5] Patching Caelestia Notifs.qml (disabling NotificationServer)..."
if [ -f "$CAELESTIA_NOTIFS" ]; then
    if grep -q "\[island-notch\] NotificationServer disabled" "$CAELESTIA_NOTIFS"; then
        echo "  -> NotificationServer in $CAELESTIA_NOTIFS is already disabled (skipping)."
    else
        cp "$CAELESTIA_NOTIFS" "${CAELESTIA_NOTIFS}.bak.${TIMESTAMP}"
        echo "  -> Backup created: ${CAELESTIA_NOTIFS}.bak.${TIMESTAMP}"

        python3 - <<EOF
import os

path = os.path.expanduser("$CAELESTIA_NOTIFS")
with open(path, "r", encoding="utf-8") as f:
    content = f.read()

target = """    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            root.list = [comp, ...root.list];
        }
    }"""

replacement = """    // [island-notch] NotificationServer disabled so island-notch exclusively owns org.freedesktop.Notifications
    /*
    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            notif.tracked = true;

            const comp = notifComp.createObject(root, {
                popup: root.shouldShowPopup(),
                notification: notif
            });
            root.list = [comp, ...root.list];
        }
    }
    */"""

if target in content:
    new_content = content.replace(target, replacement, 1)
    with open(path, "w", encoding="utf-8") as f:
        f.write(new_content)
    print("  -> Successfully disabled NotificationServer block in Notifs.qml")
else:
    # Fallback line-by-line regex or comment if whitespace differs
    import re
    pattern = r'(?m)^(\s*NotificationServer\s*\{[\s\S]*?^\s*\})'
    match = re.search(pattern, content)
    if match:
        block = match.group(1)
        commented = "    // [island-notch] NotificationServer disabled so island-notch exclusively owns org.freedesktop.Notifications\n    /*\n" + block + "\n    */"
        new_content = content[:match.start()] + commented + content[match.end():]
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
        print("  -> Successfully disabled NotificationServer block in Notifs.qml (pattern match)")
    else:
        print("  -> WARNING: Could not find NotificationServer block in Notifs.qml")
EOF
    fi
else
    echo "  -> Note: $CAELESTIA_NOTIFS does not exist, skipping."
fi

# Mask swaync.service so it never intercepts D-Bus notifications on startup
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user stop swaync.service 2>/dev/null || true
    systemctl --user mask swaync.service 2>/dev/null || true
fi

# 5. Update hyprland.conf autostart and ensure wl-paste cliphist watchers are active
echo "[5/5] Configuring Hyprland autostart in hyprland.conf..."
if [ -f "$HYPRLAND_CONF" ]; then
    cp "$HYPRLAND_CONF" "${HYPRLAND_CONF}.bak.${TIMESTAMP}"
    echo "  -> Backup created: ${HYPRLAND_CONF}.bak.${TIMESTAMP}"

    python3 - <<EOF
import os

path = os.path.expanduser("$HYPRLAND_CONF")
with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_entries = []
text_content = "".join(lines)

if "exec-once = ~/.local/bin/island-notch" not in text_content and "exec-once = $HOME/.local/bin/island-notch" not in text_content:
    new_entries.append("exec-once = ~/.local/bin/island-notch\n")

if "wl-paste --type text --watch cliphist store" not in text_content:
    new_entries.append("exec-once = wl-paste --type text --watch cliphist store\n")

if "wl-paste --type image --watch cliphist store" not in text_content:
    new_entries.append("exec-once = wl-paste --type image --watch cliphist store\n")

if "island-notch ipc call notch toggleExpand" not in text_content:
    new_entries.append("bind = \$mainMod, I, exec, ~/.local/bin/island-notch ipc call notch toggleExpand\n")

if "island-notch ipc call notch setPage 3" not in text_content:
    new_entries.append("bind = \$mainMod SHIFT, V, exec, ~/.local/bin/island-notch ipc call notch setPage 3\n")

if "island-notch ipc call notch setPage 4" not in text_content:
    new_entries.append("bind = \$mainMod, N, exec, ~/.local/bin/island-notch ipc call notch setPage 4\n")

if new_entries:
    with open(path, "a", encoding="utf-8") as f:
        f.write("\n# --- ISLAND NOTCH & CLIPBOARD AUTOSTART ---\n")
        for entry in new_entries:
            f.write(entry)
    print(f"  -> Added {len(new_entries)} entries to hyprland.conf")
else:
    print("  -> Autostart & keybind entries already present in hyprland.conf (skipping)")
EOF
else
    echo "  -> Note: $HYPRLAND_CONF does not exist, skipping."
fi

# Ensure background cliphist watchers are running immediately
if ! pgrep -f "wl-paste --type text --watch cliphist store" >/dev/null 2>&1; then
    echo "  -> Starting text cliphist watcher..."
    setsid wl-paste --type text --watch cliphist store </dev/null >/dev/null 2>&1 &
fi
if ! pgrep -f "wl-paste --type image --watch cliphist store" >/dev/null 2>&1; then
    echo "  -> Starting image cliphist watcher..."
    setsid wl-paste --type image --watch cliphist store </dev/null >/dev/null 2>&1 &
fi

echo "=== Island Notch Installation Completed Successfully ==="
