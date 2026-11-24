import QtQuick
import qs.config

// a keyboard shortcut letter in a small framed square
Rectangle {
    property alias text: label.text

    implicitWidth: 22
    implicitHeight: 22
    radius: 6
    color: Theme.surface
    border.width: 1
    border.color: Theme.border

    Txt {
        id: label
        anchors.centerIn: parent
        variant: "small"
    }
}
