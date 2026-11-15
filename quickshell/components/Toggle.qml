import QtQuick
import qs.config

Rectangle {
    id: root

    property bool checked: false

    signal toggled

    implicitWidth: 40
    implicitHeight: 22
    radius: 11
    color: checked ? Theme.accent : Theme.surface

    Rectangle {
        y: 3
        x: root.checked ? parent.width - width - 3 : 3
        width: 16
        height: 16
        radius: 8
        color: root.checked ? Theme.bgSolid : Theme.dim

        Behavior on x {
            NumberAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
