import Quickshell
import QtQuick
import qs.config
import qs.services

Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 6

        Text {
            // nf-md-update
            text: String.fromCodePoint(0xF06B0)
            color: Updates.failed ? Theme.urgent : Updates.panelOpen ? Theme.accent : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 3
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: Updates.count > 0
            text: Updates.count
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Updates.toggle()
    }
}
