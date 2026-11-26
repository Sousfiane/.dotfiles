import QtQuick
import QtQuick.Layouts
import qs.config

// A shortcut tile in a grid (the hub's): its icon and name, the key that opens it in the top right corner.
// The model gives { label, key, icon, target, soon }; one marked `soon` is shown dimmed and does nothing yet.
Rectangle {
    id: tile

    required property var modelData
    readonly property bool soon: modelData.soon ?? false

    signal activated(string target)

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 70
    radius: Theme.radius
    opacity: soon ? 0.5 : 1
    color: mouse.containsMouse && !soon ? Theme.surface : Theme.surfaceClear
    border.width: 1
    border.color: mouse.containsMouse && !soon ? Theme.accent : Theme.border
    Behavior on color {
        CAnim {}
    }
    Behavior on border.color {
        CAnim {}
    }

    Column {
        anchors.centerIn: parent
        spacing: 4

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.modelData.icon
            color: mouse.containsMouse && !tile.soon ? Theme.accent : Theme.fg
            Behavior on color {
                CAnim {}
            }
            font.pixelSize: Theme.fontSize + 8
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            variant: "dim"
            color: Theme.fg
            text: tile.modelData.label
        }
    }

    // the key that opens it, or "soon"
    Txt {
        anchors {
            top: parent.top
            right: parent.right
            margins: 6
        }
        variant: "small"
        text: tile.soon ? "soon" : tile.modelData.key
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: tile.soon ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: if (!tile.soon)
            tile.activated(tile.modelData.target)
    }
}
