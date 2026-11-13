#!/usr/bin/env python3
"""
record_live_showcase.py
Automates mouse movement and Quickshell IPC calls to record the actual, live
Kuro Island notch running on the Linux/Hyprland desktop.
"""

import os
import signal
import subprocess
import time

def move_to(x, y):
    """ydotool uses x/2, y/2 scaling on this compositor."""
    subprocess.run(
        ["ydotool", "mousemove", "-a", "-x", str(int(x / 2)), "-y", str(int(y / 2))],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )

def smooth_move(x1, y1, x2, y2, steps=24, delay=0.015):
    """Smooth ease-in-out cursor movement simulating human motion."""
    for i in range(steps + 1):
        t = i / steps
        t = t * t * (3 - 2 * t)
        cx = x1 + (x2 - x1) * t
        cy = y1 + (y2 - y1) * t
        move_to(cx, cy)
        time.sleep(delay)

def click():
    subprocess.run(["ydotool", "click", "0xC0"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def ipc_call(*args):
    cmd = ["/usr/local/bin/quickshell", "ipc", "-c", "island-notch", "call", "notch"] + list(args)
    subprocess.run(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

def main():
    out_dir = os.path.join(os.path.dirname(__file__), "..", "public", "recordings")
    os.makedirs(out_dir, exist_ok=True)
    out_file = os.path.join(out_dir, "real_notch.mp4")

    print("==> Initializing Kuro Island state...")
    ipc_call("closeSettings")
    move_to(200, 500)  # Move cursor far away to ensure collapsed state
    time.sleep(1.0)

    # Geometry for recording: centered around notch (350, 0, width 666, height 330)
    geom = "350,0 666x330"
    print(f"==> Launching wf-recorder on region [{geom}] -> {out_file}...")
    rec_proc = subprocess.Popen([
        "wf-recorder",
        "-g", geom,
        "-r", "60",
        "-c", "libx264",
        "-p", "crf=18",
        "-p", "preset=ultrafast",
        "-y",
        "-f", out_file
    ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    # Allow recorder to start capturing frames
    time.sleep(1.2)

    try:
        print("==> [1/6] Kuro greeting & waving paws...")
        ipc_call("wave")
        time.sleep(2.8)

        print("==> [2/6] Moving cursor to hover notch (Trigger Expand)...")
        smooth_move(200, 500, 683, 16, steps=25, delay=0.016)
        time.sleep(1.8)

        print("==> [3/6] Navigating to Media page with live Cava visualizer...")
        ipc_call("setPage", "0")
        time.sleep(2.0)

        # Bottom indicator dock coordinates (around center 683, y ~ 222)
        print("==> [4/6] Smoothly hovering across bottom dock dots...")
        dots = [
            (620, 222, "Shelf"),
            (652, 222, "Pomodoro"),
            (683, 222, "Center"),
            (715, 222, "Clipboard"),
            (746, 222, "Notifications")
        ]
        
        cur_x, cur_y = 683, 80
        for dx, dy, name in dots:
            smooth_move(cur_x, cur_y, dx, dy, steps=18, delay=0.015)
            cur_x, cur_y = dx, dy
            time.sleep(1.2)
            # Click middle ones to show real page transitions
            if name in ["Pomodoro", "Clipboard"]:
                click()
                time.sleep(1.4)

        print("==> [5/6] Moving cursor away (Trigger Auto-Collapse)...")
        smooth_move(cur_x, cur_y, 200, 500, steps=25, delay=0.016)
        time.sleep(2.2)

        print("==> [6/6] Final wave & wrap up...")
        ipc_call("wave")
        time.sleep(2.0)

    finally:
        print("==> Stopping recorder cleanly...")
        rec_proc.send_signal(signal.SIGINT)
        try:
            rec_proc.wait(timeout=4)
        except subprocess.TimeoutExpired:
            rec_proc.kill()
        
        move_to(200, 500)
        time.sleep(0.5)

    if os.path.isfile(out_file):
        size_kb = os.path.getsize(out_file) / 1024
        print(f"✨ Successfully recorded live Kuro Island: {out_file} ({size_kb:.1f} KB)")
    else:
        print("⚠️ Recording file not found!")

if __name__ == "__main__":
    main()
