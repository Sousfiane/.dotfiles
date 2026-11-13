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
            // nf-md: bell_off (DND), bell_ring (unread), bell_outline
            text: Notifs.dnd ? String.fromCodePoint(0xF009B) : Notifs.unread > 0 ? String.fromCodePoint(0xF009D) : String.fromCodePoint(0xF009C)
            color: Notifs.centerOpen ? Theme.accent : Notifs.dnd ? Theme.dim : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 3
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: Notifs.unread > 0 && !Notifs.dnd
            text: Notifs.unread
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Notifs.dnd = !Notifs.dnd;
            else
                Notifs.centerOpen = !Notifs.centerOpen;
        }
    }
}
