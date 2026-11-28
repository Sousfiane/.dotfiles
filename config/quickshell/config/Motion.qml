pragma Singleton
import Quickshell
import QtQuick

// The one motion vocabulary, shared with Hyprland (hypr/config/looknfeel.lua uses the same
// curves and durations: Hyprland's `speed` is in tenths of a second, so 2 = 200 ms).
//
//   move   something going from A to B, both on screen   (windows, workspaces, the ws pill)
//   enter  something arriving: fast start, soft landing  (panels, bar, popups)
//   exit   something leaving: soft start, gone fast      (always a bit shorter than enter)
//   spring something settling: past the mark by a few percent and back, as macOS's windows do
//          (Hyprland's windows arriving and moving along the strip; `springDuration`)
Singleton {
    // ---------- curves (cubic bezier, for Easing.BezierSpline) ----------
    readonly property var move: [0.77, 0, 0.175, 1, 1, 1]      // easeInOutQuart
    readonly property var enter: [0.16, 1, 0.3, 1, 1, 1]       // easeOutExpo-ish
    readonly property var exit: [0.7, 0, 0.84, 0, 1, 1]        // easeInQuart
    readonly property var spring: [0.32, 1.2, 0.5, 1, 1, 1]    // easeOutBack, soft

    // ---------- durations (ms) ----------
    readonly property int fast: 120      // hover, colour, toggles, small state changes
    readonly property int normal: 200    // moves and entrances
    readonly property int out: 150       // exits
    readonly property int slow: 350      // full-screen fades (lock screen, wallpaper)
    readonly property int springDuration: 300   // a spring needs a little longer to settle
    readonly property int barIn: 140     // the bar sliding in: snappier than a panel
    readonly property int barOut: 100    // the bar sliding out
}
