import qs.config
import qs.services
import qs.components.ui

// The network in the bar: cable or Wi-Fi strength, click for the panel, right click to toggle Wi-Fi.
BarButton {
    icon: Net.icon
    glyphs: [Icons.wifi1, Icons.wifi2, Icons.wifi3, Icons.wifi4, Icons.wifiOff, Icons.ethernet, Icons.ethernetOff]
    alert: Net.degraded
    open: Net.open
    off: !Net.online

    onClicked: Net.toggle()
    onRightClicked: Net.toggleWifi()
}
