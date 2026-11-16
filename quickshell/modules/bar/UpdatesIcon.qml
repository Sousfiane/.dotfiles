import qs.config
import qs.services
import qs.components.ui

BarButton {
    icon: Icons.update
    label: Updates.count > 0 ? String(Updates.count) : ""
    alert: Updates.failed
    open: Updates.open

    onClicked: Updates.toggle()
}
