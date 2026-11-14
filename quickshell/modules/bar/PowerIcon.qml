import qs.config
import qs.services
import qs.components

BarButton {
    icon: Icons.power
    iconColor: Power.open ? Theme.accent : Theme.fg
    onClicked: Power.toggle()
}
