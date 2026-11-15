import qs.config
import qs.services
import qs.components

BarButton {
    icon: Net.icon
    iconColor: !Net.online ? Theme.dim : Net.degraded ? Theme.urgent : Theme.fg

    onClicked: Net.toggle()
    onRightClicked: Net.toggleWifi()
}
