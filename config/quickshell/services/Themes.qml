pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// The palettes in ~/.config/theme/palettes, for the theme picker. Switching runs the `theme` command, which
// writes the palette's name to ~/.local/state/theme/palette; Theme follows that file and brings every app up
// to date.
Singleton {
    id: root

    // [{ id, name, dark, colors }]
    property var palettes: []
    readonly property string current: Theme.paletteName

    function refresh() {
        lister.running = true;
    }

    function set(id) {
        if (id !== current)
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme", id]);
    }

    Process {
        id: lister

        // one JSON object per line, with the file name as its id
        command: ["sh", "-c", `
            for f in "$HOME"/.config/theme/palettes/*.json; do
                jq -c --arg id "$(basename "$f" .json)" '{id: $id, name, dark, colors}' "$f"
            done`]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                for (const line of text.split("\n")) {
                    try {
                        if (line.trim())
                            out.push(JSON.parse(line));
                    } catch (e) {
                        console.warn("Themes:", e);
                    }
                }
                // dark ones first, then by name: Rosé Pine, Moon, Dawn
                root.palettes = out.sort((a, b) => (b.dark - a.dark) || a.id.localeCompare(b.id));
            }
        }
    }

    Component.onCompleted: refresh()
}
