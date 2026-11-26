import qs.config
import qs.services
import qs.components.ui

// The power button at the right end of the bar: opens the power menu.
BarButton {
    iconSize: Theme.fontSize + 4
    icon: Icons.power
    open: Power.open

    onClicked: Power.toggle()
}
