import Quickshell
import QtQuick
import qs.config
import qs.services

Item {
    id: root
    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon
        // nf-md-power
        text: String.fromCodePoint(0xF0425)
        color: Power.open ? Theme.accent : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 4
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Power.toggle()
    }
}
