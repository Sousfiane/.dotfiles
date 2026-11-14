import qs.config
import qs.services
import qs.components

BarButton {
    icon: Icons.update
    iconColor: Updates.failed ? Theme.urgent : (Updates.panelOpen || Updates.count > 0) ? Theme.accent : Theme.dim
    label: Updates.count > 0 ? String(Updates.count) : ""

    onClicked: Updates.toggle()
}
