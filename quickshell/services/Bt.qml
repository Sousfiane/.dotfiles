pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter?.enabled ?? false
    readonly property bool scanning: adapter?.discovering ?? false

    property bool panelOpen: false

    // ---------- used by the bar tooltip ----------

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

    // ---------- panel ----------

    // 0 connected, 1 saved, 2 newly discovered
    function groupOf(d) {
        return d.connected ? 0 : d.paired ? 1 : 2;
    }

    // unknown devices are named after their address, which isn't useful to show
    function realName(d) {
        const n = d.name || "";
        return n !== "" && n.replace(/-/g, ":").toUpperCase() !== d.address.toUpperCase();
    }

    readonly property var list: powered ? Bluetooth.devices.values.filter(d => groupOf(d) < 2 || realName(d)).sort((a, b) => groupOf(a) - groupOf(b) || (a.name || "").localeCompare(b.name || "")) : []

    function statusOf(d) {
        if (d.pairing)
            return "Pairing…";
        if (d.state === BluetoothDeviceState.Connecting)
            return "Connecting…";
        if (d.state === BluetoothDeviceState.Disconnecting)
            return "Disconnecting…";
        if (d.connected)
            return "Connected";
        if (d.paired)
            return "Paired";
        return "Not paired";
    }

    function toggle() {
        panelOpen = !panelOpen;
    }

    function togglePower() {
        if (adapter)
            adapter.enabled = !adapter.enabled;
    }

    function toggleScan() {
        if (adapter && adapter.enabled)
            adapter.discovering = !adapter.discovering;
    }

    // scan while the panel is open, stop when it closes
    onPanelOpenChanged: {
        if (adapter && adapter.enabled)
            adapter.discovering = panelOpen;
    }

    function activate(d) {
        if (!d || statusOf(d).endsWith("…"))
            return;

        if (d.connected)
            d.disconnect();
        else if (d.paired)
            d.connect();
        else
            pairAndConnect(d);
    }

    function forget(d) {
        if (d && d.paired)
            d.forget();
    }

    // pair, then trust and connect as soon as the pairing has gone through
    property var pendingDev: null
    property int pendingTicks: 0

    function pairAndConnect(d) {
        pendingDev = d;
        pendingTicks = 0;
        d.pair();
        pairTimer.restart();
    }

    Timer {
        id: pairTimer
        interval: 500
        repeat: true
        onTriggered: {
            root.pendingTicks++;
            const d = root.pendingDev;

            if (!d) {
                stop();
            } else if (d.paired) {
                d.trusted = true;
                d.connect();
                root.pendingDev = null;
                stop();
            } else if (root.pendingTicks > 60) {      // give up after 30 s
                root.pendingDev = null;
                stop();
            }
        }
    }
}
