import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// The launcher's file search ("/"): fd over the home folder, run again as `query` settles; with no
// query it costs nothing. Hidden files and what .gitignore files leave out aren't searched.
Scope {
    id: root

    property string query: ""

    readonly property string home: Quickshell.env("HOME")
    property var paths: []                  // what fd found for `foundFor`
    property string foundFor: ""
    property bool searching: false

    onQueryChanged: debounce.restart()

    Timer {
        id: debounce
        interval: 150
        onTriggered: root.search()
    }

    function search() {
        const words = query.split(/\s+/).filter(w => w !== "");
        if (words.length === 0) {
            paths = [];
            foundFor = "";
            return;
        }
        // fd matches the first word on names; the others narrow its results down in find(), on the whole path
        fd.running = false;
        fd.wanted = query;
        fd.command = ["fd", "--fixed-strings", "--ignore-case", "--max-results", "400", "--exclude", "node_modules", "--", words[0], home];
        searching = true;
        fd.running = true;
    }

    Process {
        id: fd
        property string wanted: ""
        stdout: StdioCollector {
            onStreamFinished: {
                root.paths = text.split("\n").filter(l => l !== "");
                root.foundFor = fd.wanted;
                root.searching = false;
            }
        }
    }

    // the paths found that hold every word, best first: the name itself, then names that start with the
    // first word, then shallow paths. Each { path, name, folder (from the home, "~/…/"), dir (its folder) }
    function find(text, limit) {
        const words = text.toLowerCase().split(/\s+/).filter(w => w !== "");
        const found = [];
        for (const path of paths) {
            const rel = path.startsWith(home + "/") ? path.slice(home.length + 1) : path;
            if (!words.every(w => rel.toLowerCase().includes(w)))
                continue;
            const trimmed = rel.endsWith("/") ? rel.slice(0, -1) : rel;
            const name = trimmed.slice(trimmed.lastIndexOf("/") + 1);
            const lowName = name.toLowerCase();
            found.push({
                rank: (lowName === words[0] ? 0 : lowName.startsWith(words[0]) ? 1 : 2) * 1000 + trimmed.split("/").length * 10 + Math.min(9, name.length / 8),
                path,
                name,
                folder: "~/" + trimmed.slice(0, trimmed.length - name.length),
                dir: path.slice(0, path.length - (rel.endsWith("/") ? 1 : 0) - name.length),
                glyph: glyph(rel)
            });
        }
        found.sort((a, b) => a.rank - b.rank || a.name.localeCompare(b.name));
        return found.slice(0, limit);
    }

    // a glyph for what a path holds, from its extension
    function glyph(path) {
        if (path.endsWith("/"))
            return Icons.folder;
        const ext = path.slice(path.lastIndexOf(".") + 1).toLowerCase();
        if (["png", "jpg", "jpeg", "gif", "webp", "svg", "bmp", "avif", "heic"].includes(ext))
            return Icons.fileImage;
        if (["mp4", "mkv", "webm", "mov", "avi"].includes(ext))
            return Icons.fileVideo;
        if (["mp3", "flac", "ogg", "opus", "wav", "m4a"].includes(ext))
            return Icons.fileMusic;
        if (ext === "pdf")
            return Icons.filePdf;
        if (["txt", "md", "odt", "doc", "docx", "rtf", "ods", "xls", "xlsx", "odp", "ppt", "pptx", "csv"].includes(ext))
            return Icons.fileDocument;
        return Icons.file;
    }
}
