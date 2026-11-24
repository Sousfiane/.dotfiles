import QtQuick
import qs.config

// A row box that shows the keyboard selection: filled, with an accent outline, while selected.
// Clicking anywhere on it asks to be selected.
Rectangle {
    id: root

    property bool selected: false

    signal selectRequested

    radius: Theme.radius
    color: selected ? Theme.surface : Theme.surfaceClear
    border.width: 1
    border.color: selected ? Theme.accent : Theme.accentClear
    Behavior on color {
        CAnim {}
    }
    Behavior on border.color {
        CAnim {}
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.selectRequested()
    }
}
