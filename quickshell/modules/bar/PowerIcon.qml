import qs.config
import qs.services
import qs.components.ui

BarButton {
    icon: Icons.power
    open: Power.open

    onClicked: Power.toggle()
}
