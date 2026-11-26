import Quickshell
import QtQuick
import qs.services
import qs.components.ui

// The clock in the middle of the bar: opens the hub.
BarButton {
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    label: Qt.formatDateTime(clock.date, "ddd d MMM  HH:mm")
    open: Panels.activeEdge === "center"     // the hub, and every other panel under the clock

    onClicked: Hub.toggle()
}
