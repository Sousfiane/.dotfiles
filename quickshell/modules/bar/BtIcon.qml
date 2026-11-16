import qs.config
import qs.services
import qs.components.ui

BarButton {
    iconSize: Theme.fontSize + 1
    icon: !Bt.powered ? Icons.bluetoothOff : Bt.connected ? Icons.bluetoothConnected : Icons.bluetooth
    open: Bt.open
    off: !Bt.powered

    onClicked: Bt.toggle()
    onRightClicked: Bt.togglePower()
}
