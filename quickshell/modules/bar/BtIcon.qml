import qs.config
import qs.services
import qs.components.ui

BarButton {
    icon: !Bt.powered ? Icons.bluetoothOff : Bt.connected ? Icons.bluetoothConnected : Icons.bluetooth
    iconColor: !Bt.powered ? Theme.dim : Bt.connected ? Theme.accent : Theme.fg

    onClicked: Bt.toggle()
    onRightClicked: Bt.togglePower()
}
