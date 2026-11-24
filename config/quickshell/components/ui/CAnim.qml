import QtQuick
import qs.config

// A ColorAnimation on the shared timing: `Behavior on color { CAnim {} }`.
ColorAnimation {
    duration: Motion.fast
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Motion.enter
}
