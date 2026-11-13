import Quickshell
import QtQuick
import qs.config
import qs.services

Item {
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: label
        text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
        color: Hub.open ? Theme.accent : Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Hub.toggle()
    }
}
