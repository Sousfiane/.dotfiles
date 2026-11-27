import Quickshell
import Quickshell.Io
import QtQuick

// The launcher's emoji (":"): Unicode's list, from the unicode-emoji package, read once `wanted` is set
// (the first time ":" is typed), then searched by name.
Scope {
    id: root

    property bool wanted: false
    property bool missing: false            // the package isn't installed
    property var all: []                    // [{ char, name, words }]

    FileView {
        path: root.wanted ? "/usr/share/unicode/emoji/emoji-test.txt" : ""
        printErrors: false
        onLoaded: root.all = root.parse(text())
        onLoadFailed: root.missing = true
    }

    // "1F600 ; fully-qualified # 😀 E1.0 grinning face", under "# subgroup: face-smiling". The skin tone
    // variants are left out: the list would be five times as long
    function parse(text) {
        const out = [];
        let subgroup = "";
        for (const line of text.split("\n")) {
            if (line.startsWith("# subgroup:")) {
                subgroup = line.slice(11).trim().replace(/-/g, " ");
                continue;
            }
            const m = line.match(/; fully-qualified\s+#\s+(\S+)\s+E[\d.]+\s+(.+)$/);
            if (m && !m[2].includes("skin tone"))
                out.push({
                    char: m[1],
                    name: m[2],
                    words: (m[2] + " " + subgroup).toLowerCase()
                });
        }
        return out;
    }

    // every word in the name or its subgroup; names that start with the first word first
    function find(text, limit) {
        const words = text.toLowerCase().split(/\s+/).filter(w => w !== "");
        if (words.length === 0)
            return all.slice(0, limit);
        return all.filter(e => words.every(w => e.words.includes(w))).map((e, i) => ({
                    e,
                    i,
                    rank: e.name.startsWith(words[0]) ? 0 : e.name.includes(" " + words[0]) ? 1 : 2
                })).sort((a, b) => a.rank - b.rank || a.i - b.i).slice(0, limit).map(x => x.e);
    }
}
