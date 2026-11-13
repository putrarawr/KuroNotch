#!/usr/bin/env bash
set -euo pipefail

# KuroNotch Uninstaller
# Uninstalls KuroNotch and restores Caelestia / Hyprland configuration.

cat << "EOF"
  /\_/\   
 ( x.x )  KURO NOTCH UNINSTALLER
  > ^ <   https://github.com/putrarawr/KuroNotch
EOF
echo ""

echo "==> Stopping running KuroNotch processes..."
pkill -f "quickshell.*island-notch" 2>/dev/null || true
pkill -f "island-notch" 2>/dev/null || true
pkill -f "restore-wallpaper" 2>/dev/null || true

echo "==> Removing wrapper binaries from ~/.local/bin..."
rm -f "$HOME/.local/bin/island-notch"
rm -f "$HOME/.local/bin/kuronotch"
rm -f "$HOME/.local/bin/kuro-island"
rm -f "$HOME/.local/bin/restore-wallpaper"

echo "==> Removing Quickshell configuration symlinks..."
rm -f "$HOME/.config/quickshell/island-notch"
rm -f "$HOME/.config/quickshell/KuroNotch"
rm -f "$HOME/.config/quickshell/kuro-island"

# Restore Hyprland configuration if autostart lines exist
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
if [ -f "$HYPR_CONF" ]; then
    echo "==> Cleaning KuroNotch entries from hyprland.conf..."
    python3 - << 'EOF'
import os

path = os.path.expanduser("~/.config/hypr/hyprland.conf")
if not os.path.exists(path):
    exit(0)

with open(path, "r", encoding="utf-8") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    stripped = line.strip()
    if "exec-once = ~/.local/bin/restore-wallpaper" in stripped:
        new_lines.append("exec-once = hyprpaper\n")
        continue
    if "ISLAND NOTCH & CLIPBOARD AUTOSTART" in stripped:
        continue
    if any(k in stripped for k in [
        "exec-once = ~/.local/bin/island-notch",
        "exec-once = $HOME/.local/bin/island-notch",
        "exec-once = wl-paste --type text --watch cliphist store",
        "exec-once = wl-paste --type image --watch cliphist store",
        "bind = $mainMod, I, exec, ~/.local/bin/island-notch",
        "bind = $mainMod SHIFT, V, exec, ~/.local/bin/island-notch",
        "bind = $mainMod, N, exec, ~/.local/bin/island-notch",
    ]):
        continue
    new_lines.append(line)

with open(path, "w", encoding="utf-8") as f:
    f.writelines(new_lines)
print("  -> hyprland.conf cleaned.")
EOF
fi

# Restore Caelestia Notifs.qml if disabled
NOTIFS_QML="$HOME/.config/quickshell/caelestia/services/Notifs.qml"
if [ -f "$NOTIFS_QML" ]; then
    echo "==> Restoring Caelestia NotificationServer in Notifs.qml..."
    python3 - << 'EOF'
import os

path = os.path.expanduser("~/.config/quickshell/caelestia/services/Notifs.qml")
if not os.path.exists(path):
    exit(0)

with open(path, "r", encoding="utf-8") as f:
    content = f.read()

marker = "// [island-notch] NotificationServer disabled so island-notch exclusively owns org.freedesktop.Notifications"
if marker in content:
    content = content.replace(marker + "\n    /*\n", "")
    content = content.replace(marker + "\n    /*", "")
    content = content.replace("    */", "")
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print("  -> Caelestia Notifs.qml restored.")
EOF
fi

# Restore Caelestia shell.json if modified
CAELESTIA_JSON="$HOME/.config/caelestia/shell.json"
if [ -f "$CAELESTIA_JSON" ]; then
    echo "==> Restoring Caelestia shell.json..."
    python3 - << 'EOF'
import json, os

path = os.path.expanduser("~/.config/caelestia/shell.json")
if not os.path.exists(path):
    exit(0)

with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

if "osd" in data and "enabled" in data["osd"]:
    data["osd"]["enabled"] = True
if "dashboard" in data and "showOnHover" in data["dashboard"]:
    data["dashboard"]["showOnHover"] = True
if "utilities" in data and "toasts" in data["utilities"]:
    toasts = data["utilities"]["toasts"]
    toasts["chargingChanged"] = True
    toasts["audioOutputChanged"] = True
    toasts["audioInputChanged"] = True

with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=4)
print("  -> Caelestia shell.json restored.")
EOF
fi

echo ""
echo "✨ KuroNotch uninstalled cleanly!"
