pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string wallDir: `${Quickshell.env("HOME")}/wallpapers`
    readonly property string thumbDir: `${Quickshell.env("HOME")}/.cache/wall_gtk_thumbs`
    readonly property string stateDir: `${Quickshell.env("HOME")}/.local/state/caelestia/wallpaper`
    readonly property string stateFile: `${stateDir}/path.txt`
    readonly property string schemeFile: `${Quickshell.env("HOME")}/.local/state/caelestia/scheme.json`

    property var wallpapers: [] // Array<{ path, name, thumbUrl }>
    property string currentPath: ""
    property bool scanning: false
    property bool applying: false
    property bool _dirReady: false

    function refresh(): void {
        if (root.scanning || scanProc.running)
            return;
        root.scanning = true;
        scanProc.running = true;
    }

    function applyWallpaper(imgPath: string): void {
        const clean = String(imgPath || "").trim();
        if (clean.length === 0)
            return;
        root.currentPath = clean;
        root.applying = true;

        const baseName = clean.split("/").pop().replace(/\.[^.]+$/, "");
        NotchController.triggerPeek("osd", 1, {
            title: "Wallpaper Diganti",
            subtitle: baseName,
            icon: "wallpaper",
            progress: 1,
            durationMs: 2200
        });

        Quickshell.execDetached([
            "python3", "-c",
            `import json, os, random, subprocess, time
img = os.path.expanduser(os.sys.argv[1])
state_file = os.path.expanduser(os.sys.argv[2])
scheme_file = os.path.expanduser(os.sys.argv[3])
wal_colors = os.path.expanduser("~/.cache/wal/colors.json")

if not os.path.isfile(img):
    raise SystemExit(0)

subprocess.run(["pkill", "-x", "hyprpaper"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
q = subprocess.run(["swww", "query"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
if q.returncode != 0:
    subprocess.Popen(["swww-daemon"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(25):
        time.sleep(0.1)
        if subprocess.run(["swww", "query"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
            break

t_type = random.choice(["wipe", "wave", "grow", "outer", "center"])
t_angle = str(random.choice([0, 30, 45, 90, 135, 210, 315]))
subprocess.run([
    "swww", "img", img,
    "--transition-type", t_type,
    "--transition-angle", t_angle,
    "--transition-step", "90",
    "--transition-fps", "120",
    "--transition-bezier", "0.13,0.99,0.29,1.1"
], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

os.makedirs(os.path.dirname(state_file), exist_ok=True)
with open(state_file, "w", encoding="utf-8") as f:
    f.write(img + "\\n")

try:
    subprocess.run(["wal", "-i", img, "--backend", "haishoku", "-n", "-q"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
except Exception:
    subprocess.run(["wal", "-i", img, "-n", "-q"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

if os.path.exists(wal_colors):
    try:
        with open(wal_colors, "r", encoding="utf-8") as f:
            wal_data = json.load(f)
        c = {k: v.lstrip("#") for k, v in wal_data["colors"].items()}
        s = {k: v.lstrip("#") for k, v in wal_data["special"].items()}
        scheme = {
            "name": "dynamic", "flavour": "default", "mode": "dark",
            "colours": {
                "primary": c["color4"], "onPrimary": s["background"],
                "primaryContainer": c["color1"], "onPrimaryContainer": s["foreground"],
                "secondary": c["color5"], "onSecondary": s["background"],
                "secondaryContainer": c["color2"], "onSecondaryContainer": s["foreground"],
                "tertiary": c["color6"], "onTertiary": s["background"],
                "tertiaryContainer": c["color3"], "onTertiaryContainer": s["foreground"],
                "surface": s["background"], "onSurface": s["foreground"],
                "surfaceVariant": c["color8"], "onSurfaceVariant": c["color7"],
                "background": s["background"], "onBackground": s["foreground"],
                "outline": c["color8"], "outlineVariant": c["color0"],
                "error": "ffb4ab", "onError": "690005",
                "errorContainer": "93000a", "onErrorContainer": "ffdad6",
                **{f"term{i}": c[f"color{i}"] for i in range(16)}
            }
        }
        os.makedirs(os.path.dirname(scheme_file), exist_ok=True)
        with open(scheme_file, "w", encoding="utf-8") as f:
            json.dump(scheme, f, indent=2)
    except Exception:
        pass
`,
            clean,
            root.stateFile,
            root.schemeFile
        ]);
        applyClearTimer.restart();
    }

    function stepWallpaper(delta: int): void {
        const list = root.wallpapers;
        if (!list || list.length === 0)
            return;
        let idx = -1;
        for (let i = 0; i < list.length; i++) {
            if (list[i].path === root.currentPath) {
                idx = i;
                break;
            }
        }
        const nextIdx = idx < 0
            ? 0
            : (((idx + delta) % list.length) + list.length) % list.length;
        root.applyWallpaper(list[nextIdx].path);
    }

    function randomWallpaper(): void {
        const list = root.wallpapers;
        if (!list || list.length === 0)
            return;
        if (list.length === 1) {
            root.applyWallpaper(list[0].path);
            return;
        }
        let chosen = list[Math.floor(Math.random() * list.length)];
        if (chosen.path === root.currentPath) {
            chosen = list[(list.indexOf(chosen) + 1) % list.length];
        }
        root.applyWallpaper(chosen.path);
    }

    Timer {
        id: applyClearTimer

        interval: 600
        repeat: false
        onTriggered: root.applying = false
    }

    Process {
        id: ensureDirProc

        running: false
        command: [
            "sh", "-c",
            'mkdir -p "$1" "$2" && touch "$3"',
            "sh",
            root.stateDir,
            root.thumbDir,
            root.stateFile
        ]
        onExited: {
            root._dirReady = true;
            stateFileView.reload();
            root.refresh();
        }
    }

    FileView {
        id: stateFileView

        path: root._dirReady ? root.stateFile : ""
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const p = text().trim();
            if (p.length > 0)
                root.currentPath = p;
        }
    }

    Process {
        id: scanProc

        running: false
        command: [
            "python3", "-c",
            `import glob, json, os, shutil, subprocess
wall_dir = os.path.expanduser(os.sys.argv[1])
thumb_dir = os.path.expanduser(os.sys.argv[2])
os.makedirs(thumb_dir, exist_ok=True)
exts = (".jpg", ".jpeg", ".png", ".webp")
files = []
if os.path.isdir(wall_dir):
    for name in sorted(os.listdir(wall_dir), key=str.lower):
        if name.lower().endswith(exts):
            files.append(os.path.join(wall_dir, name))

has_magick = shutil.which("magick") is not None
out = []
generated = 0
for p in files:
    base = os.path.basename(p)
    stem = os.path.splitext(base)[0]
    thumb = os.path.join(thumb_dir, stem + ".png")
    if not os.path.isfile(thumb) and has_magick and generated < 8:
        subprocess.run([
            "magick", p, "-thumbnail", "360x220^",
            "-gravity", "center", "-extent", "360x220",
            "-strip", "-quality", "82", thumb
        ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        generated += 1
    thumb_url = "file://" + (thumb if os.path.isfile(thumb) else p)
    clean_name = stem.replace("-", " ").replace("_", " ")
    if len(clean_name) > 26:
        clean_name = clean_name[:23] + "..."
    out.append({"path": p, "name": clean_name, "thumbUrl": thumb_url})

cur = ""
try:
    q = subprocess.check_output(["swww", "query"], text=True, stderr=subprocess.DEVNULL)
    for ln in q.splitlines():
        if "currently displaying: image:" in ln:
            cur = ln.split("currently displaying: image:", 1)[1].strip()
            break
except Exception:
    pass
print(json.dumps({"items": out, "current": cur}))`,
            root.wallDir,
            root.thumbDir
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                root.scanning = false;
                const raw = text.trim();
                if (!raw.startsWith("{"))
                    return;
                try {
                    const data = JSON.parse(raw);
                    if (Array.isArray(data.items))
                        root.wallpapers = data.items;
                    if (typeof data.current === "string" && data.current.length > 0 && root.currentPath.length === 0)
                        root.currentPath = data.current;
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: {
        ensureDirProc.running = true;
    }
}
