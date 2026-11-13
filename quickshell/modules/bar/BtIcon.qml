import Quickshell
import QtQuick
import qs.config
import qs.services
import qs.modules.bluetooth

Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon

        // nf-md: bluetooth_off, bluetooth_connect, bluetooth
        text: !Bt.powered ? String.fromCodePoint(0xF00B2) : Bt.connected ? String.fromCodePoint(0xF00B1) : String.fromCodePoint(0xF00AF)

        color: Bt.panelOpen ? Theme.accent : !Bt.powered ? Theme.dim : Theme.fg

        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 3
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Bt.togglePower();
            else
                Bt.toggle();
        }
    }
}
