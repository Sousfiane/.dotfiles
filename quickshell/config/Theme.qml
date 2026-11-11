pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // Rosé Pine (main)
    readonly property color base: "#191724"
    readonly property color surfaceRp: "#1f1d2e"
    readonly property color overlay: "#26233a"
    readonly property color muted: "#6e6a86"
    readonly property color subtle: "#908caa"
    readonly property color text: "#e0def4"
    readonly property color love: "#eb6f92"
    readonly property color gold: "#f6c177"
    readonly property color rose: "#ebbcba"
    readonly property color pine: "#31748f"
    readonly property color foam: "#9ccfd8"
    readonly property color iris: "#c4a7e7"
    readonly property color highlightMed: "#403d52"

    // Semantic names used by the modules
    readonly property color bg: base
    readonly property color surface: overlay
    readonly property color border: iris
    readonly property color fg: text
    readonly property color dim: subtle
    readonly property color accent: iris
    readonly property color urgent: love

    readonly property string font: "JetBrainsMono Nerd Font"
    readonly property int fontSize: 13
    readonly property int radius: 6
    readonly property int barHeight: 32
}
