pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // The system theme: fonts, radii, opacities and which palette are read from ~/.config/theme/theme.json,
    // the colours from the palette it names, ~/.config/theme/palettes/<palette>.json (config/theme in the
    // dotfiles). Hyprland, kitty, Neovim and tmux read them too. Saving either updates the shell at once, and
    // runs theme/apply.sh so the others follow. This file only says what each colour is used for.
    readonly property string themeDir: Quickshell.env("HOME") + "/.config/theme"

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

        path: root.themeDir + "/palettes/" + (root.settings.palette ?? "rose-pine") + ".json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: applyTimer.restart()
    }

    // the last version of each file that parsed, so a typo while editing keeps the shell as it was
    readonly property var cache: ({ settings: null, palette: null })
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
    readonly property var theme: settings
    readonly property var colors: palette.colors
    readonly property bool dark: palette.dark

    // ---------- the other apps follow ----------

    // what the other apps were last brought up to date with
    property string appliedText: ""
    Component.onCompleted: appliedText = settingsFile.text() + paletteFile.text()

    // switching palettes changes both files in turn: wait for them to settle, then apply once
    Timer {
        id: applyTimer

        interval: 300
        onTriggered: root.applyEverywhere()
    }

    // after a real change that parses (a typo mid-edit doesn't reload everything)
    function applyEverywhere() {
        const text = settingsFile.text() + paletteFile.text();
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

    readonly property string font: theme.font.ui
    readonly property int fontSize: theme.font.uiPixelSize
    readonly property int radiusSmall: theme.radius.small
    readonly property int radius: theme.radius.medium
    readonly property int radiusLarge: theme.radius.large
    readonly property int barHeight: 32
}
