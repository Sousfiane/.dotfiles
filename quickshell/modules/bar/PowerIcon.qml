import qs.config
import qs.services
import qs.components.ui

BarButton {
    iconSize: Theme.fontSize + 4
    icon: Icons.power
    open: Power.open

    onClicked: Power.toggle()
}
