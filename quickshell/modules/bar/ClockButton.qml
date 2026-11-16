import Quickshell
import QtQuick
import qs.services
import qs.components.ui

BarButton {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    label: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
    open: Hub.open

    onClicked: Hub.toggle()
}
