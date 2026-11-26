pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// The palettes in ~/.config/theme/palettes and the installed fonts, for the theme picker. Switching runs the
// `theme` command, which writes the palette's name to ~/.local/state/theme/palette (a font to fonts.json next
// to it); Theme follows those files and brings every app up to date.
Singleton {
    id: root

    // [{ id, name, dark, colors }]
    property var palettes: []
    readonly property string current: Theme.paletteName

    // the fonts that can be picked, and where each is used
    // `sizeKey` is the size's name in theme.json/fonts.json
    readonly property var fontRoles: [
        { key: "ui", label: "Shell", what: "bar and panels", sizeKey: "uiPixelSize", unit: "px" },
        { key: "mono", label: "Terminal", what: "kitty and window titles", sizeKey: "monoPointSize", unit: "pt" },
        { key: "app", label: "Apps", what: "GTK and Qt apps", sizeKey: "appPointSize", unit: "pt" }
    ]
    // installed families that can write Latin text (not each script's Noto), and the monospace ones among them
    property var fonts: []
    property var monoFonts: []

    function refresh() {
        lister.running = true;
        fontLister.running = true;
    }

    function set(id) {
        if (id !== current)
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme", id]);
    }

    // sizes asked for but not in fonts.json yet, so quick presses add up instead of all starting from the
    // same old size
    property var pendingSizes: ({})
    Connections {
        target: Theme
        function onFontsChanged() {
            root.pendingSizes = {};
        }
    }

    function fontSize(role) {
        return pendingSizes[role.key] ?? Theme.fonts[role.sizeKey];
    }

    function changeFontSize(role, delta) {
        const size = Math.max(6, Math.min(40, fontSize(role) + delta));
        if (size === fontSize(role))
            return;
        pendingSizes = Object.assign({}, pendingSizes, { [role.key]: size });
        Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme", "font", role.key, "size", String(size)]);
    }

    function setFont(key, family) {
        if (family !== Theme.fonts[key])
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme", "font", key, family]);
    }

    Process {
        id: fontLister

        // "m<TAB>family" for monospace, "p<TAB>family" for the rest, a family's first name only
        command: ["sh", "-c", `
            fc-list :lang=fr:spacing=100 family | cut -d, -f1 | sed 's/^/m\t/'
            fc-list :lang=fr family | cut -d, -f1 | sed 's/^/p\t/'`]
        stdout: StdioCollector {
            onStreamFinished: {
                const mono = new Set(), all = new Set();
                for (const line of text.split("\n")) {
                    const [kind, family] = line.split("\t");
                    if (!family)
                        continue;
                    all.add(family);
                    // some monospace fonts don't say so (Noto Sans Mono): their name does
                    if (kind === "m" || /Mono/.test(family))
                        mono.add(family);
                }
                root.fonts = [...all].sort((a, b) => a.localeCompare(b));
                root.monoFonts = [...mono].sort((a, b) => a.localeCompare(b));
            }
        }
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
