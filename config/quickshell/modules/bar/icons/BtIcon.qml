import qs.config
import qs.services
import qs.components.ui

// Bluetooth in the bar: click for the panel, right click to power it on or off.
BarButton {
    iconSize: Theme.fontSize + 1
    icon: !Bt.powered ? Icons.bluetoothOff : Bt.connected ? Icons.bluetoothConnected : Icons.bluetooth
    glyphs: [Icons.bluetooth, Icons.bluetoothConnected, Icons.bluetoothOff]
    open: Bt.open
    off: !Bt.powered

    onClicked: Bt.toggle()
    onRightClicked: Bt.togglePower()
}
