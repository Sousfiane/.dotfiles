import QtQuick
import qs.config

// A row box that shows the keyboard selection: filled, with an accent outline, while selected.
// Clicking anywhere on it asks to be selected.
Rectangle {
    id: root

    property bool selected: false

    signal selectRequested

    radius: Theme.radius
    color: selected ? Theme.surface : "transparent"
    border.width: selected ? 1 : 0
    border.color: Theme.accent

    MouseArea {
        anchors.fill: parent
        onClicked: root.selectRequested()
    }
}
