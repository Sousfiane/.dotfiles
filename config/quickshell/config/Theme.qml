pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // The system theme: fonts, radii and opacities are read from ~/.config/theme/theme.json, the colours from
    // the current palette, ~/.config/theme/palettes/<palette>.json (config/theme in the dotfiles). The current
    // palette is named in ~/.local/state/theme/palette, out of the repo so switching never changes it;
    // theme.json's "palette" is only the default; the fonts picked in the theme picker are in fonts.json next
    // to it, over theme.json's. Hyprland, kitty, Neovim, tmux and zsh read them too. A change
    // to any of them updates the shell at once, and runs theme/apply.sh so the others follow. This file only
    // says what each colour is used for.
    readonly property string themeDir: Quickshell.env("HOME") + "/.config/theme"
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/theme"

    // the current palette's name: the state file, or theme.json's default
    readonly property string paletteName: stateFile.text().trim() || (settings.palette ?? "rose-pine")

    FileView {
        id: stateFile

        path: root.stateDir + "/palette"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: applyTimer.restart()
    }

    // the fonts picked in the theme picker (written by `theme font`): only those, over theme.json's
    FileView {
        id: fontsFile

        path: root.stateDir + "/fonts.json"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: applyTimer.restart()
    }

    // a file that doesn't exist can't be watched: the state files are created first (the default palette,
    // no fonts picked)
    Process {
        id: stateCreator

        command: ["sh", "-c", 'mkdir -p "$1" && { [ -s "$1/palette" ] || printf "%s\\n" "$2" > "$1/palette"; } && { [ -s "$1/fonts.json" ] || echo "{}" > "$1/fonts.json"; }', "sh", root.stateDir, root.settings.palette ?? "rose-pine"]
        onExited: {
            stateFile.reload();
            fontsFile.reload();
        }
    }

    FileView {
        id: settingsFile

        path: root.themeDir + "/theme.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            paletteFile.reload(); // also picks up a palette file that didn't exist yet
            applyTimer.restart();
        }
    }

    FileView {
        id: paletteFile

        path: root.themeDir + "/palettes/" + root.paletteName + ".json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: applyTimer.restart()
    }

    // the last version of each file that parsed, so a typo while editing keeps the shell as it was
    readonly property var cache: ({ settings: null, palette: null, fonts: {} })
    function parse(key, text) {
        try {
            cache[key] = JSON.parse(text);
        } catch (e) {
            console.warn("theme:", key, e);
        }
        return cache[key];
    }
    readonly property var settings: parse("settings", settingsFile.text())
    readonly property var palette: parse("palette", paletteFile.text())
    // theme.json's fonts with the picked ones on top: { ui, uiPixelSize, mono, monoPointSize, app, appPointSize }
    readonly property var fonts: Object.assign({}, settings.font, fontsFile.text().trim() ? parse("fonts", fontsFile.text()) : {})
    readonly property var theme: settings
    readonly property var colors: palette.colors
    readonly property bool dark: palette.dark

    // ---------- the other apps follow ----------

    // what the other apps were last brought up to date with
    property string appliedText: ""
    Component.onCompleted: {
        appliedText = settingsFile.text() + stateFile.text() + paletteFile.text() + fontsFile.text();
        stateCreator.running = true;
    }

    // switching palettes changes both files in turn: wait for them to settle, then apply once
    Timer {
        id: applyTimer

        interval: 300
        onTriggered: root.applyEverywhere()
    }

    // after a real change that parses (a typo mid-edit doesn't reload everything)
    function applyEverywhere() {
        const text = settingsFile.text() + stateFile.text() + paletteFile.text() + fontsFile.text();
        if (text === appliedText)
            return;
        try {
            JSON.parse(settingsFile.text());
            JSON.parse(paletteFile.text());
        } catch (e) {
            return;
        }
        appliedText = text;
        Quickshell.execDetached([root.themeDir + "/apply.sh"]);
    }

    // the palette, by name
    readonly property color base: colors.base
    readonly property color surfaceRp: colors.surface
    readonly property color overlay: colors.overlay
    readonly property color muted: colors.muted
    readonly property color subtle: colors.subtle
    readonly property color text: colors.text
    readonly property color love: colors.love
    readonly property color gold: colors.gold
    readonly property color rose: colors.rose
    readonly property color pine: colors.pine
    readonly property color foam: colors.foam
    readonly property color iris: colors.iris
    readonly property color highlightMed: colors.highlightMed

    // ---------- transparency ----------
    readonly property real alpha: theme.opacity.panel             // bar, dropdowns, toasts, OSD
    readonly property real surfaceAlpha: theme.opacity.control    // rows, buttons and inputs drawn on top of those

    // `c` with opacity `a` (0..1)
    function withAlpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    // fully opaque versions, for anything that must never show through
    readonly property color bgSolid: base
    readonly property color surfaceSolid: overlay

    // Semantic names used by the modules
    readonly property color bg: withAlpha(base, alpha)
    readonly property color surface: withAlpha(overlay, surfaceAlpha)
    readonly property color border: iris
    readonly property color fg: text
    readonly property color dim: subtle
    readonly property color accent: iris
    readonly property color urgent: love
    readonly property color line: muted   // also Hyprland's window border

    // the same colours fully see-through: fade to these instead of "transparent", which is
    // transparent *black* and would dip through a dark tint on the way
    readonly property color surfaceClear: withAlpha(overlay, 0)
    readonly property color accentClear: withAlpha(iris, 0)

    readonly property string font: fonts.ui
    readonly property int fontSize: fonts.uiPixelSize
    readonly property int radiusSmall: theme.radius.small
    readonly property int radius: theme.radius.medium
    readonly property int radiusLarge: theme.radius.large
    readonly property int barHeight: 32
}
