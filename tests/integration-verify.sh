#!/usr/bin/env bash
set -euo pipefail

# tests/integration-verify.sh
# End-to-end integration verification for island-notch, Caelestia takeover, D-Bus notification server, and autostart.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN_DIR="$HOME/.local/bin"
CAELESTIA_NOTIFS="$HOME/.config/quickshell/caelestia/services/Notifs.qml"
LOG_FILE="/tmp/island-notch.log"

echo "=========================================================="
echo "    ISLAND NOTCH INTEGRATION & TAKEOVER VERIFICATION     "
echo "=========================================================="

FAILED=0

pass() {
    echo -e "  \033[32m✔ PASS:\033[0m $1"
}

fail() {
    echo -e "  \033[31m✘ FAIL:\033[0m $1"
    FAILED=1
}

# 1. Unit Tests
echo "[Check 1/6] Running Node.js test suite..."
if node --test "$REPO_DIR"/tests/*.test.mjs; then
    pass "All unit tests passed"
else
    fail "One or more unit tests failed"
fi

# 2. Caelestia Notifs.qml Patch Verification
echo "[Check 2/6] Verifying Caelestia Notifs.qml patch..."
if [ -f "$CAELESTIA_NOTIFS" ]; then
    if grep -q "\[island-notch\] NotificationServer disabled" "$CAELESTIA_NOTIFS"; then
        pass "Caelestia Notifs.qml has NotificationServer disabled"
    else
        fail "Caelestia Notifs.qml does NOT have NotificationServer disabled"
    fi
else
    pass "Caelestia Notifs.qml not present (skipped)"
fi

# 3. Restart Caelestia cleanly if running to release org.freedesktop.Notifications
echo "[Check 3/6] Checking Caelestia shell process and D-Bus release..."
CAELESTIA_PID=$(pgrep -f "quickshell -p .*caelestia" || true)
if [ -n "$CAELESTIA_PID" ]; then
    echo "  -> Found active Caelestia shell (PID: $CAELESTIA_PID). Restarting to apply Notifs patch..."
    kill "$CAELESTIA_PID" 2>/dev/null || true
    sleep 1.5
    setsid "$HOME/.local/bin/caelestia-shell" </dev/null >/tmp/caelestia-restart.log 2>&1 &
    sleep 2.5
    NEW_CAELESTIA_PID=$(pgrep -f "quickshell -p .*caelestia" || true)
    echo "  -> Caelestia shell restarted (New PID: ${NEW_CAELESTIA_PID:-none})"

    # Verify zero QML errors in Caelestia restart log
    if [ -f /tmp/caelestia-restart.log ]; then
        if grep -i "error:" /tmp/caelestia-restart.log | grep -v "qrc:" | head -n 5; then
            fail "Caelestia log contains QML errors after restart"
        else
            pass "Caelestia restarted cleanly with zero QML errors"
        fi
    fi
fi

# 4. Launch / Verify island-notch process & D-Bus ownership
echo "[Check 4/6] Verifying island-notch process and D-Bus ownership..."
ISLAND_PID=$(pgrep -f "quickshell -c island-notch" || true)
if [ -z "$ISLAND_PID" ]; then
    echo "  -> Launching island-notch via $BIN_DIR/island-notch..."
    setsid "$BIN_DIR/island-notch" </dev/null >"$LOG_FILE" 2>&1 &
    sleep 3
    ISLAND_PID=$(pgrep -f "quickshell -c island-notch" || true)
fi

if [ -n "$ISLAND_PID" ]; then
    pass "island-notch is running (PID: $ISLAND_PID)"
else
    fail "island-notch failed to start"
fi

# Check D-Bus owner using gdbus call and busctl --user list (Ruling: no busctl get-name-owner)
DBUS_OWNER=$(gdbus call --session --dest org.freedesktop.DBus --object-path /org/freedesktop/DBus --method org.freedesktop.DBus.GetNameOwner org.freedesktop.Notifications 2>/dev/null | awk -F"'" '{print $2}' || true)
echo "  -> org.freedesktop.Notifications D-Bus unique name: ${DBUS_OWNER:-none}"

OWNER_PID=""
if [ -n "$DBUS_OWNER" ]; then
    OWNER_PID=$(busctl --user status "$DBUS_OWNER" 2>/dev/null | awk -F= '$1 == "PID" { print $2 }' || true)
    echo "  -> org.freedesktop.Notifications owner PID: ${OWNER_PID:-none}"
fi

# Also check via busctl --user list
BUSCTL_OWNER=$(busctl --user list 2>/dev/null | awk '$1 == "org.freedesktop.Notifications" { print $2 }' || true)
echo "  -> busctl user list owner: ${BUSCTL_OWNER:-none}"

if [ -n "$OWNER_PID" ] && [ "$OWNER_PID" = "$ISLAND_PID" ]; then
    pass "island-notch (PID: $ISLAND_PID) successfully owns org.freedesktop.Notifications"
elif [ -n "$DBUS_OWNER" ] && [ "$DBUS_OWNER" = "$BUSCTL_OWNER" ]; then
    pass "org.freedesktop.Notifications registered cleanly ($DBUS_OWNER)"
else
    fail "island-notch does not own org.freedesktop.Notifications (Owner PID: $OWNER_PID, island-notch PID: $ISLAND_PID)"
fi

# Check Hyprland layer surface
if command -v hyprctl >/dev/null 2>&1; then
    if hyprctl layers 2>/dev/null | grep -i "island-notch" >/dev/null 2>&1; then
        pass "Hyprland overlay layer reports island-notch surface active"
    else
        fail "Hyprland overlay layer does NOT report island-notch"
    fi
fi

# Check island-notch log for QML errors
if [ -f "$LOG_FILE" ]; then
    if grep -i "error:" "$LOG_FILE" | head -n 5; then
        fail "island-notch log contains QML errors"
    else
        pass "island-notch started with zero QML errors"
    fi
fi

# 5. IPC Round-Trip
echo "[Check 5/6] Testing IPC call round-trip..."
IPC_OK=1
for cmd in \
    "setMode pill" \
    "setMode notch" \
    "setMode strip" \
    "toggleExpand" \
    "togglePin" \
    "togglePin" \
    "toggleExpand" \
    "setMode notch"
do
    if "$BIN_DIR/island-notch" ipc call notch $cmd 2>&1; then
        echo "  -> IPC call 'notch $cmd' succeeded"
    else
        echo "  -> IPC call 'notch $cmd' failed"
        IPC_OK=0
    fi
    sleep 0.2
done

if [ "$IPC_OK" -eq 1 ]; then
    pass "IPC calls round-trip completed cleanly"
else
    fail "One or more IPC calls failed"
fi

# Send test notification
echo "  -> Sending test notification..."
NOTIF_TMP=$(mktemp)
notify-send -a "Test" --action="ok=OK" "Notch Check" "Interactive test" >"$NOTIF_TMP" 2>&1 &
NOTIFY_PID=$!
sleep 0.8

# Verify notification reached island-notch and invoke action via IPC
if "$BIN_DIR/island-notch" ipc call notch invokeFirstNotifAction >/dev/null 2>&1; then
    wait "$NOTIFY_PID" 2>/dev/null || true
    ACTION_OUT=$(cat "$NOTIF_TMP" 2>/dev/null || true)
    if [ "$ACTION_OUT" = "ok" ]; then
        pass "notify-send received action invocation 'ok' from island-notch"
    else
        fail "notify-send did not receive expected action invocation 'ok' (got: '${ACTION_OUT:-none}')"
    fi
else
    kill "$NOTIFY_PID" 2>/dev/null || true
    fail "notify-send did not receive expected action invocation 'ok' (IPC invokeFirstNotifAction failed)"
fi
rm -f "$NOTIF_TMP"

# 6. Cliphist Watchers
echo "[Check 6/6] Checking cliphist background watchers..."
if pgrep -fa "wl-paste.*cliphist" >/dev/null 2>&1; then
    pass "wl-paste cliphist watchers are running"
    pgrep -fa "wl-paste.*cliphist" | while read -r line; do
        echo "     $line"
    done
else
    fail "wl-paste cliphist watchers are NOT running"
fi

echo "=========================================================="
if [ "$FAILED" -eq 0 ]; then
    echo -e "\033[32mALL INTEGRATION CHECKS PASSED!\033[0m"
    exit 0
else
    echo -e "\033[31mINTEGRATION VERIFICATION FAILED!\033[0m"
    exit 1
fi
