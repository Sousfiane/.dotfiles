import QtQuick
import Quickshell
import qs.services
import qs.config

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 6

        Text {
            // nf-md-git
            text: String.fromCodePoint(0xF02A2)
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 3
            color: Dotfiles.failed ? Theme.urgent : Dotfiles.panelOpen ? Theme.accent : Theme.fg
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: Dotfiles.count > 0
            text: Dotfiles.count
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: Theme.fg
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Dotfiles.toggle()
    }
}
