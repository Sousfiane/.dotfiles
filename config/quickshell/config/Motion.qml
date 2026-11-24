pragma Singleton
import Quickshell
import QtQuick

// The one motion vocabulary, shared with Hyprland (hypr/config/looknfeel.lua uses the same
// curves and durations: Hyprland's `speed` is in tenths of a second, so 2 = 200 ms).
//
//   move   something going from A to B, both on screen   (windows, workspaces, the ws pill)
//   enter  something arriving: fast start, soft landing  (panels, bar, popups)
//   exit   something leaving: soft start, gone fast      (always a bit shorter than enter)
Singleton {
    // ---------- curves (cubic bezier, for Easing.BezierSpline) ----------
    readonly property var move: [0.77, 0, 0.175, 1, 1, 1]      // easeInOutQuart
    readonly property var enter: [0.16, 1, 0.3, 1, 1, 1]       // easeOutExpo-ish
    readonly property var exit: [0.7, 0, 0.84, 0, 1, 1]        // easeInQuart

    // ---------- durations (ms) ----------
    readonly property int fast: 120      // hover, colour, toggles, small state changes
    readonly property int normal: 200    // moves and entrances
    readonly property int out: 150       // exits
    readonly property int slow: 350      // full-screen fades (lock screen, wallpaper)
}
