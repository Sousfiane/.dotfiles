pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false

    // [{ name, address, battery }]  battery is 0..1, or -1 if unknown
    readonly property var connectedDevices: powered ? Bluetooth.devices.values.filter(d => d.connected).map(d => ({
                name: d.name,
                address: d.address,
                battery: batteryOf(d)
            })) : []

    readonly property bool connected: connectedDevices.length > 0

    // BlueZ first (headphones etc.), UPower as a fallback (DS4 and similar)
    function batteryOf(dev) {
        if (dev.batteryAvailable)
            return dev.battery;

        const addr = dev.address.toLowerCase();
        const up = UPower.devices.values.find(d => d.nativePath.toLowerCase().includes(addr));
        return up ? up.percentage : -1;
    }
}
