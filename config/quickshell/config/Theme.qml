pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The system theme, from the merged theme ~/.local/state/theme/current.json: theme.json in config/theme
// (fonts, radii, opacities), the fonts picked in the theme picker over its own, and the current palette's
// colours on top, put together by config/theme/merge.sh. Hyprland, kitty, Neovim, tmux and zsh read the same
// file. It's kept up to date outside the shell (theme.path watches the theme's files and theme.service
// runs config/theme/apply.sh, install/units): this file only follows it, and says what each colour is used
// for.
Singleton {
    id: root

    readonly property string themeDir: Quickshell.env("HOME") + "/.config/theme"
    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/theme"

    // ---------- the merged theme ----------

    FileView {
        id: currentFile

        path: root.stateDir + "/current.json"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }

    // the last version that parsed (it's written in one step, so only a missing file fails). A plain object
    // changed in place, so keeping it doesn't make the binding below run again
    readonly property var cache: ({
            theme: null
        })
    function parse(text) {
        try {
            cache.theme = JSON.parse(text);
        } catch (e) {}
        return cache.theme;
    }
    readonly property var theme: parse(currentFile.text()) ?? {
        font: {},
        radius: {},
        opacity: {},
        colors: {}
    }
    readonly property var colors: theme.colors
    readonly property bool dark: theme.dark ?? true
    readonly property string paletteName: theme.palette ?? ""
    // the palette's own fields (its name, dark, gtk...), as the theme picker shows them
    readonly property var palette: theme
    // the fonts in use: theme.json's with the picked ones on top { ui, uiPixelSize, mono, monoPointSize, app, appPointSize }
    readonly property var fonts: theme.font

    // theme.json as it is, for its own defaults (the theme picker marks the default font)
    FileView {
        id: settingsFile

        path: root.themeDir + "/theme.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property var settings: {
        try {
            return JSON.parse(settingsFile.text());
        } catch (e) {
            return {
                font: {}
            };
        }
    }

    // a new machine: no current.json yet, merge.sh writes it (and the state files), then it's read
    Process {
        id: merger

        command: [root.themeDir + "/merge.sh"]
        onExited: currentFile.reload()
    }
    Component.onCompleted: if (!currentFile.text())
        merger.running = true

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
    // corners, by what they round (theme.json): a surface floating over the desktop (a dropdown, the dock,
    // a toast, the OSD; Hyprland's windows too), what sits on one (rows, buttons, inputs), small marks
    // (swatches, boxes). Circles and pills are height / 2, whatever their size
    readonly property int radiusLarge: theme.radius.large
    readonly property int radius: theme.radius.medium
    readonly property int radiusSmall: theme.radius.small
    readonly property int barHeight: 32
}
