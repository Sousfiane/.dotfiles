import qs.config
import qs.services
import qs.components.ui

// The updates in the bar: number of pending packages, click for the panel.
BarButton {
    icon: Icons.update
    label: Updates.count > 0 ? String(Updates.count) : ""
    alert: Updates.failed
    open: Updates.open

    onClicked: Updates.toggle()
}
