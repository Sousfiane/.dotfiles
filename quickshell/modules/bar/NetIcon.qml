import qs.config
import qs.services
import qs.components.ui

BarButton {
    icon: Net.icon
    alert: Net.degraded
    open: Net.open
    off: !Net.online

    onClicked: Net.toggle()
    onRightClicked: Net.toggleWifi()
}
