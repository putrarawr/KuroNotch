pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../config"
import "../lib/cliphistParser.js" as CliphistParser

Singleton {
    id: root

    property var entries: []
    property var filteredEntries: []
    property string searchQuery: ""
    property var previewCache: ({})
    property bool pingRunning: false
    property string pingResult: ""

    property bool _deleting: false
    property var _pendingDeletes: []

    property bool _decoding: false
    property var _pendingDecodes: []
    property string _currentDecodeId: ""
    property string _currentDecodePath: ""

    readonly property var safeImageExtensions: ({
        "png": "png",
        "jpg": "jpg",
        "jpeg": "jpeg",
        "webp": "webp",
        "gif": "gif",
        "bmp": "bmp",
        "svg": "svg",
        "avif": "avif",
        "ico": "ico"
    })

    function refresh(): void {
        if (!listProc.running)
            listProc.running = true;
    }

    function copyEntry(id: string): void {
        const cleanId = String(id || "").trim();
        if (!/^[0-9]+$/.test(cleanId))
            return;

        Quickshell.execDetached([
            "sh", "-c",
            'if command -v wl-copy >/dev/null 2>&1; then cliphist decode "$1" | wl-copy; elif command -v xclip >/dev/null 2>&1; then cliphist decode "$1" | xclip -selection clipboard; fi',
            "sh",
            cleanId
        ]);

        NotchController.triggerPeek("osd", 1, {
            title: "Copied to Clipboard",
            subtitle: `Entry #${cleanId}`,
            icon: "content_copy",
            progress: 1
        });
    }

    function sendToMobile(item): void {
        if (!item || !item.id)
            return;

        const cleanId = String(item.id || "").trim();
        if (!/^[0-9]+$/.test(cleanId))
            return;

        const ip = (Config.connect?.mobileIp || "192.168.1.10").trim();
        const port = Config.connect?.port || 8088;
        const targetUrl = `http://${ip}:${port}/api/clipboard`;
        const isImage = Boolean(item.isImage);
        const format = (item.imageFormat || "png").toLowerCase();

        NotchController.triggerPeek("osd", 1, {
            title: "Mengirim ke HP...",
            subtitle: isImage ? "Mengirim foto ke itel P55" : "Mengirim teks ke itel P55",
            icon: "phonelink_ring",
            progress: 0.5
        });

        sendMobileProc.command = [
            "python3", "-c",
            "import sys, json, urllib.request, subprocess\n" +
            "clean_id = sys.argv[1]\n" +
            "is_img = sys.argv[2] == '1'\n" +
            "img_fmt = sys.argv[3]\n" +
            "target_url = sys.argv[4]\n" +
            "try:\n" +
            "    decode_proc = subprocess.run(['cliphist', 'decode', clean_id], stdout=subprocess.PIPE, check=True)\n" +
            "    if is_img:\n" +
            "        import base64\n" +
            "        b64 = base64.b64encode(decode_proc.stdout).decode('ascii')\n" +
            "        payload = json.dumps({'type': 'image', 'data': b64, 'format': img_fmt}).encode('utf-8')\n" +
            "    else:\n" +
            "        text_content = decode_proc.stdout.decode('utf-8', errors='replace')\n" +
            "        payload = json.dumps({'type': 'text', 'text': text_content}).encode('utf-8')\n" +
            "    req = urllib.request.Request(target_url, data=payload, headers={'Content-Type': 'application/json'})\n" +
            "    with urllib.request.urlopen(req, timeout=4) as response:\n" +
            "        sys.exit(0 if response.status == 200 else 1)\n" +
            "except Exception as e:\n" +
            "    sys.stderr.write(str(e))\n" +
            "    sys.exit(2)\n",
            cleanId,
            isImage ? "1" : "0",
            format,
            targetUrl
        ];
        sendMobileProc.running = true;
    }

    function pingMobile(): void {
        if (root.pingRunning) return;
        const ip = (Config.connect?.mobileIp || "192.168.1.10").trim();
        const port = Config.connect?.port || 8088;
        root.pingRunning = true;
        root.pingResult = "";
        pingProc.command = [
            "python3", "-c",
            "import sys, urllib.request\n" +
            "url = sys.argv[1]\n" +
            "try:\n" +
            "    with urllib.request.urlopen(url, timeout=2.5) as res:\n" +
            "        sys.exit(0 if res.status == 200 else 1)\n" +
            "except Exception:\n" +
            "    sys.exit(2)\n",
            `http://${ip}:${port}/ping`
        ];
        pingProc.running = true;
    }

    function deleteEntry(id: string): void {
        const cleanId = String(id || "").trim();
        if (!/^[0-9]+$/.test(cleanId))
            return;

        if (root._deleting) {
            const queue = root._pendingDeletes ? root._pendingDeletes.slice() : [];
            queue.push(cleanId);
            root._pendingDeletes = queue;
            return;
        }

        root._runDelete(cleanId);
    }

    function _runDelete(cleanId: string): void {
        root._deleting = true;
        deleteProc.command = [
            "sh", "-c",
            "printf '%s\\t\\n' \"$1\" | cliphist delete",
            "sh",
            cleanId
        ];
        deleteProc.running = true;
    }

    function decodePreview(id: string, format: string): string {
        const cleanId = String(id || "").trim();
        if (!/^[0-9]+$/.test(cleanId))
            return "";

        if (root.previewCache && root.previewCache[cleanId])
            return root.previewCache[cleanId];

        const ext = root.safeImageExtensions[(format || "png").toLowerCase()] || "png";
        const targetPath = `/tmp/island-notch-clip-${cleanId}.${ext}`;

        if (root._currentDecodeId !== cleanId) {
            let alreadyPending = false;
            const queue = root._pendingDecodes ? root._pendingDecodes.slice() : [];
            for (let i = 0; i < queue.length; i++) {
                if (queue[i].id === cleanId) {
                    alreadyPending = true;
                    break;
                }
            }
            if (!alreadyPending) {
                queue.push({
                    id: cleanId,
                    path: targetPath,
                    tmpPath: `${targetPath}.tmp`
                });
                root._pendingDecodes = queue;
                Qt.callLater(root._processDecodeQueue);
            }
        }

        return "";
    }

    function _processDecodeQueue(): void {
        if (root._decoding || !root._pendingDecodes || root._pendingDecodes.length === 0)
            return;

        const queue = root._pendingDecodes.slice();
        const next = queue.shift();
        root._pendingDecodes = queue;
        if (!next)
            return;

        root._decoding = true;
        root._currentDecodeId = next.id;
        root._currentDecodePath = next.path;

        decodeProc.command = [
            "sh", "-c",
            'if [ ! -f "$2" ]; then cliphist decode "$1" > "$3" && mv -f "$3" "$2"; fi',
            "sh",
            next.id,
            next.path,
            next.tmpPath
        ];
        decodeProc.running = true;
    }

    onSearchQueryChanged: {
        root.filteredEntries = CliphistParser.filterClipEntries(root.entries, root.searchQuery);
    }

    Process {
        id: deleteProc

        running: false

        onExited: (code, status) => {
            if (root._pendingDeletes && root._pendingDeletes.length > 0) {
                const queue = root._pendingDeletes.slice();
                const nextId = queue.shift();
                root._pendingDeletes = queue;
                root._runDelete(nextId);
            } else {
                root._deleting = false;
                root.refresh();
            }
        }
    }

    Process {
        id: decodeProc

        running: false

        onExited: (code, status) => {
            if (code === 0 && root._currentDecodeId.length > 0 && root._currentDecodePath.length > 0) {
                const updated = Object.assign({}, root.previewCache);
                updated[root._currentDecodeId] = root._currentDecodePath;
                root.previewCache = updated;
            }
            root._currentDecodeId = "";
            root._currentDecodePath = "";
            root._decoding = false;
            root._processDecodeQueue();
        }
    }

    Process {
        id: listProc

        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = CliphistParser.parseCliphistOutput(text);
                root.entries = parsed;
                root.filteredEntries = CliphistParser.filterClipEntries(parsed, root.searchQuery);
            }
        }
    }

    Process {
        id: sendMobileProc

        running: false

        onExited: (code, status) => {
            if (code === 0) {
                NotchController.triggerPeek("osd", 1, {
                    title: "Terkirim ke Mobile",
                    subtitle: "Disalin ke Kuro Island (itel P55)",
                    icon: "phonelink",
                    progress: 1
                });
            } else {
                NotchController.triggerPeek("osd", 1, {
                    title: "Gagal Kirim ke HP",
                    subtitle: "Periksa IP (" + (Config.connect?.mobileIp || "192.168.1.10") + ") & Wi-Fi",
                    icon: "phonelink_erase",
                    progress: 1
                });
            }
        }
    }

    Process {
        id: pingProc

        running: false

        onExited: (code, status) => {
            root.pingRunning = false;
            root.pingResult = (code === 0) ? "ok" : "failed";
            if (code === 0) {
                NotchController.triggerPeek("osd", 1, {
                    title: "Koneksi Berhasil",
                    subtitle: "itel P55 terhubung di port " + (Config.connect?.port || 8088),
                    icon: "check_circle",
                    progress: 1
                });
            } else {
                NotchController.triggerPeek("osd", 1, {
                    title: "HP Tidak Merespon",
                    subtitle: "Pastikan Kuro Island aktif di HP & Wi-Fi sama",
                    icon: "error",
                    progress: 1
                });
            }
        }
    }

    Component.onCompleted: {
        root.refresh();
    }
}
