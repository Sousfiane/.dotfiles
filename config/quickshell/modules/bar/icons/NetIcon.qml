import qs.config
import qs.services
import qs.components.ui

BarButton {
    icon: Net.icon
    glyphs: [Icons.wifi1, Icons.wifi2, Icons.wifi3, Icons.wifi4, Icons.wifiOff, Icons.ethernet, Icons.ethernetOff]
    alert: Net.degraded
    open: Net.open
    off: !Net.online

    onClicked: Net.toggle()
    onRightClicked: Net.toggleWifi()
}
