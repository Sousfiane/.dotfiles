import Quickshell
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// A Bluetooth device in the panel: its icon, name, state and battery, and the action it takes next.
DeviceRow {
    id: root

    required property var dev

    readonly property real level: Bt.batteryOf(dev)

    // freedesktop icon BlueZ reports for the device (headset, gamepad, keyboard...)
    icon: AppIcon {
        anchors.fill: parent
        source: Quickshell.iconPath(root.dev.icon || "bluetooth", "bluetooth")
    }

    title: dev.name || dev.address
    titleBold: dev.connected
    status: Bt.statusOf(dev)
    statusColor: dev.connected ? Theme.accent : Theme.dim
    busy: status.endsWith("…")

    // battery
    detail: dev.connected && level >= 0 ? Math.round(level * 100) + "%" : ""
    detailColor: level < 0.2 ? Theme.urgent : Theme.dim

    actionText: dev.connected ? "Disconnect" : dev.paired ? "Connect" : "Pair"
    primary: !dev.connected
    canForget: dev.paired      // saved devices only
}
