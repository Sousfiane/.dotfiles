import QtQuick
import qs.config

Item {
    id: root

    property bool open: false         // bind to the panel's open state
    property int duration: 220

    default property alias content: holder.data

    // wait until the window has a real size before animating in
    property bool started: false
    Component.onCompleted: Qt.callLater(() => root.started = true)

    readonly property bool shown: open && started && height > 0
    property real progress: shown ? 1 : 0

    Behavior on progress {
        NumberAnimation {
            duration: root.duration
            easing.type: root.shown ? Easing.OutCubic : Easing.InCubic
        }
    }

    // the area below the bar, clipped so content "emerges" from under it
    anchors {
        top: parent.top
        topMargin: 0
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }
    clip: true

    Item {
        id: holder
        width: root.width
        height: root.height
        y: -(1 - root.progress) * height
    }
}
