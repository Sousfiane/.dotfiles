import QtQuick
import qs.config

// A NumberAnimation on the shared motion curves: `Behavior on x { Anim {} }`.
// Defaults to a move; set `curve: Motion.enter` / `Motion.exit` and a duration for the rest.
NumberAnimation {
    property var curve: Motion.move

    duration: Motion.normal
    easing.type: Easing.BezierSpline
    easing.bezierCurve: curve
}
