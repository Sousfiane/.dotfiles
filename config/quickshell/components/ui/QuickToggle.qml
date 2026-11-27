import QtQuick
import QtQuick.Layouts
import qs.config

// A quick toggle in the hub: its icon over its name, filled with the accent while it is on.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property bool active: false
    property bool available: true     // false: dimmed and does nothing (no Wi-Fi card, no Bluetooth adapter)

    signal clicked

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 58
    radius: Theme.radius
    opacity: available ? 1 : 0.4
    color: active ? Theme.accent : mouse.containsMouse && available ? Theme.surface : Theme.surfaceClear
    border.width: 1
    border.color: active ? Theme.accent : mouse.containsMouse && available ? Theme.accent : Theme.border
    Behavior on color {
        CAnim {}
    }
    Behavior on border.color {
        CAnim {}
    }

    Column {
        anchors.centerIn: parent
        spacing: 3

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.icon
            color: root.active ? Theme.bgSolid : Theme.fg
            font.pixelSize: Theme.fontSize + 4
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            variant: "small"
            text: root.label
            color: root.active ? Theme.bgSolid : Theme.dim
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.available)
            root.clicked()
    }
}
