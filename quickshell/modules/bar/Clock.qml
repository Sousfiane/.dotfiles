import Quickshell
import QtQuick
import qs.config

Text {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
    color: Theme.fg
    font.family: Theme.font
    font.pixelSize: Theme.fontSize
    font.bold: true
}
