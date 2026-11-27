pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// The clipboard history from clipvault: listed, filtered and thumbnailed for the panel, an entry copied
// again on Enter.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("clipboard")
    property string query: ""
    property var items: []                       // everything parsed from clipvault

    // what the grid shows: the same objects, filtered, so its ScriptModel keeps the tiles still listed
    readonly property var entries: {
        const needle = query.toLowerCase().trim();
        return needle === "" ? items : items.filter(item => item.searchText.indexOf(needle) !== -1);
    }
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Config.home + "/.cache")) + "/clipvault/thumbs"

    function toggle() {
        Panels.toggle("clipboard");
    }

    // start fresh and reload the history on every open
    function reset() {
        query = "";
        refresh();
    }

    onOpenChanged: if (open)
        reset()

    // the service is created lazily, so it can be created after the panel is already open
    Component.onCompleted: if (open)
        reset()

    function refresh() {
        historyProcess.running = false;
        historyProcess.running = true;
    }

    function copy(id) {
        if (!/^[0-9]+$/.test(id))
            return;
        Quickshell.execDetached(["bash", "-c", "set -o pipefail; clipvault get \"$1\" | wl-copy", "clipboard-copy", id]);
        Panels.hide("clipboard");
    }

    function parse(output) {
        const parsed = [];
        for (const line of output.split(/\r?\n/)) {
            const match = line.match(/^([0-9]+)\s+(.*)$/);
            if (!match)
                continue;
            const clipId = match[1];
            const content = match[2];

            if (content.startsWith("<meta http-equiv="))
                continue;

            if (/^\[\[\s*binary/i.test(content)) {
                const extMatch = content.match(/\b(jpeg|jpg|png|bmp|webp|tiff|tif|gif)\b/i);
                if (!extMatch)
                    continue;
                const ext = extMatch[1].toLowerCase();
                parsed.push({
                    clipId: clipId,
                    kind: "image",
                    imageExt: ext,
                    preview: "Image • " + ext.toUpperCase(),
                    searchText: "image " + ext + " " + clipId
                });
                continue;
            }

            parsed.push({
                clipId: clipId,
                kind: "text",
                imageExt: "",
                preview: content.length > 240 ? content.substring(0, 240) + "…" : content,
                searchText: content.toLowerCase()
            });
        }
        items = parsed;
    }

    Process {
        id: historyProcess
        command: ["clipvault", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    // ---------- image thumbnails ----------

    // clipId -> "ready" | "failed". Reassigned on every change so tiles re-evaluate.
    property var thumbs: ({})

    // internal bookkeeping, mutated in place (nothing binds to these)
    property var requested: ({})
    property var queue: []
    readonly property int maxParallel: 3

    function thumbPath(clipId, ext) {
        return cacheDir + "/" + clipId + ".thumb." + ext;
    }

    // tiles call this when they appear; each thumbnail is generated once
    function requestThumb(clipId, ext) {
        if (requested[clipId])
            return;
        requested[clipId] = true;
        queue.push({
            clipId: clipId,
            imageExt: ext
        });
        pump();
    }

    function finishThumb(job, ok) {
        thumbs = Object.assign({}, thumbs, {
            [job.clipId]: ok ? "ready" : "failed"
        });
    }

    // hand queued jobs to idle workers
    function pump() {
        for (let i = 0; i < workers.count && queue.length > 0; i++) {
            const w = workers.objectAt(i);
            if (w && w.job === null) {
                w.job = queue.shift();
                w.running = true;
            }
        }
    }

    readonly property string thumbScript: ['set -e', 'cache="$1"', 'id="$2"', 'ext="$3"', 'mkdir -p "$cache"', 'original="$cache/$id.$ext"', 'thumb="$cache/$id.thumb.$ext"', 'if [ ! -s "$original" ]; then', '  clipvault get "$id" > "$original.tmp"', '  mv "$original.tmp" "$original"', 'fi', 'if [ ! -s "$thumb" ]; then', '  if command -v magick >/dev/null 2>&1; then', '    magick "$original" -thumbnail "256x256>" "$thumb" 2>/dev/null || cp -f "$original" "$thumb"', '  else', '    cp -f "$original" "$thumb"', '  fi', 'fi'].join("\n")

    Instantiator {
        id: workers
        model: root.maxParallel

        delegate: Process {
            id: worker

            property var job: null

            command: job ? ["bash", "-c", root.thumbScript, "clipboard-thumbnail", root.cacheDir, job.clipId, job.imageExt] : ["true"]

            onExited: (exitCode, exitStatus) => {
                if (job)
                    root.finishThumb(job, exitCode === 0);
                job = null;
                root.pump();
            }
        }
    }
}
