import Quickshell
import QtQuick
import qs.config
import qs.services
import qs.components

BarButton {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    label: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
    labelColor: Hub.open ? Theme.accent : Theme.fg

    onClicked: Hub.toggle()
}
