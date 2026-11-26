pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // The system theme: colours, fonts, radii and opacities are read from ~/.config/theme/theme.json
    // (config/theme/theme.json in the dotfiles), which Hyprland, kitty, Neovim and tmux read too. Saving it
    // updates the shell at once, and runs theme/apply.sh so the others follow. This file only says what each
    // colour is used for.
    FileView {
        id: themeFile

        path: Quickshell.env("HOME") + "/.config/theme/theme.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.applyEverywhere(text())
    }

    // the text the other apps were last brought up to date with
    property string appliedText: ""
    Component.onCompleted: appliedText = themeFile.text()

    // after a real change that parses (a typo mid-edit doesn't reload everything), the other apps follow
    function applyEverywhere(text) {
        if (text === appliedText)
            return;
        try {
            JSON.parse(text);
        } catch (e) {
            return;
        }
        appliedText = text;
        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/theme/apply.sh"]);
    }

    // the last version that parsed, so a typo while editing keeps the shell as it was
    readonly property var cache: ({ theme: null })
    readonly property var theme: {
        const text = themeFile.text();
        try {
            cache.theme = JSON.parse(text);
        } catch (e) {
            console.warn("theme.json:", e);
        }
        return cache.theme;
    }
    readonly property var colors: theme.colors

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
