import QtQuick
import qs.config

// A thin bar filled to `fraction` (0..1): the accent, the urgent colour past `warnAt`.
Rectangle {
    id: root

    property real fraction: 0
    property real warnAt: 0.85
    property color fill: Theme.accent

    implicitHeight: 4
    radius: height / 2
    color: Theme.surface

    Rectangle {
        height: parent.height
        radius: parent.radius
        width: parent.width * Math.max(0, Math.min(1, root.fraction))
        color: root.fraction > root.warnAt ? Theme.urgent : root.fill
        Behavior on width {
            Anim {}
        }
    }
}
