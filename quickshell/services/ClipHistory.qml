pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool open: false
    property string query: ""
    property var items: []                       // everything parsed from clipvault

    readonly property ListModel entries: ListModel {}   // what the grid shows
    readonly property string cacheDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/clipvault/thumbs"

    onQueryChanged: applyFilter()

    function toggle() {
        open = !open;
        if (open) {
            query = "";
            refresh();
        }
    }

    function refresh() {
        historyProcess.running = false;
        historyProcess.running = true;
    }

    function applyFilter() {
        entries.clear();
        const needle = query.toLowerCase().trim();
        for (const item of items)
            if (needle.length === 0 || item.searchText.indexOf(needle) !== -1)
                entries.append(item);
    }

    function copy(id) {
        if (!/^[0-9]+$/.test(id))
            return;
        Quickshell.execDetached(["bash", "-c", "set -o pipefail; clipvault get \"$1\" | wl-copy", "clipboard-copy", id]);
        open = false;
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
        applyFilter();
    }

    Process {
        id: historyProcess
        command: ["clipvault", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }
}
