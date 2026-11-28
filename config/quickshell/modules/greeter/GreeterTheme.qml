import Quickshell
import Quickshell.Io
import QtQuick

// The greeter's theme, as config/Theme.qml reads it but from `home` (the user's, the greeter runs as another
// user) and once: nothing is watched, created or applied. The merged theme (~/.local/state/theme/current.json:
// theme.json, the fonts picked and the current palette, written by merge.sh), and the shell's current
// wallpaper.
Scope {
    id: root

    required property string home

    function parse(file) {
        try {
            return JSON.parse(file.text());
        } catch (e) {
            return {};
        }
    }

    FileView {
        id: currentFile
        path: root.home + "/.local/state/theme/current.json"
        blockLoading: true
        printErrors: false
    }

    readonly property var settings: parse(currentFile)
    readonly property var fonts: settings.font ?? {}

    // Rosé Pine Moon, for a missing or broken palette
    readonly property var colors: Object.assign({
        base: "#232136",
        surface: "#2a273f",
        overlay: "#393552",
        muted: "#6e6a86",
        subtle: "#908caa",
        text: "#e0def4",
        love: "#eb6f92",
        gold: "#f6c177",
        rose: "#ea9a97",
        pine: "#3e8fb0",
        foam: "#9ccfd8",
        iris: "#c4a7e7",
        highlightLow: "#2a283e",
        highlightMed: "#44415a",
        highlightHigh: "#56526e"
    }, settings.colors ?? {})
    readonly property string font: fonts.ui ?? "JetBrainsMono Nerd Font"
    readonly property int fontSize: fonts.uiPixelSize ?? 13
    readonly property int radius: settings.radius?.large ?? 6
    readonly property real panelAlpha: settings.opacity?.panel ?? 0.95
    readonly property real controlAlpha: settings.opacity?.control ?? 0.75

    // the shell's current wallpaper: its state file (services/Wallpapers.qml), the newest if there are several
    property string wallpaper: ""
    Process {
        running: true
        command: ["sh", "-c", 'f=$(ls -t "$1"/.local/state/quickshell/by-shell/*/wallpaper 2>/dev/null | head -n 1) && head -n 1 "$f"', "sh", root.home]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = text.trim();
                if (path !== "")
                    root.wallpaper = "file://" + path;
            }
        }
    }

    // the palette's colours are hex strings: made a colour first (a string has no r, g, b: black)
    function alpha(c, a) {
        const k = Qt.tint(c, "transparent");
        return Qt.rgba(k.r, k.g, k.b, a);
    }
}
