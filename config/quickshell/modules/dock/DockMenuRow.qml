import QtQuick
import qs.config
import qs.components.ui

// one line of the dock's right-click menu
Rectangle {
    id: root

    property string text: ""
    property bool active: false       // the focused window: shown in the accent
    property bool danger: false       // closes something: turns red on hover

    signal clicked

    height: 28
    radius: Theme.radius
    color: mouse.containsMouse ? Theme.surface : Theme.surfaceClear

    Behavior on color {
        CAnim {}
    }

    Txt {
        anchors {
            left: parent.left
            right: parent.right
            leftMargin: 8
            rightMargin: 8
            verticalCenter: parent.verticalCenter
        }
        variant: "row"
        text: root.text
        elide: Text.ElideRight
        color: root.danger && mouse.containsMouse ? Theme.urgent : root.active ? Theme.accent : Theme.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
