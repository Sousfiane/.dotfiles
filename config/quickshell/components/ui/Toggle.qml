import QtQuick
import qs.config

// An on/off switch, accent when on.
Rectangle {
    id: root

    property bool checked: false

    signal toggled

    implicitWidth: 40
    implicitHeight: 22
    radius: height / 2
    color: checked ? Theme.accent : Theme.surface
    Behavior on color {
        CAnim {}
    }

    Rectangle {
        y: 3
        x: root.checked ? parent.width - width - 3 : 3
        width: 16
        height: 16
        radius: width / 2
        color: root.checked ? Theme.bgSolid : Theme.dim
        Behavior on color {
            CAnim {}
        }

        Behavior on x {
            Anim {
                duration: Motion.fast
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
