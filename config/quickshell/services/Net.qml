pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import qs.config

// The network for the bar and the panel (NetworkManager): devices, Wi-Fi networks, connectivity, the
// active connection's details, and connecting or forgetting.
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("network")

    function toggle() {
        Panels.toggle("network");
    }

    // ---------- devices ----------

    readonly property var devices: Networking.devices.values
    readonly property var wiredDevices: devices.filter(d => d.type === DeviceType.Wired)
    readonly property var wifiDevice: devices.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool scanning: wifiDevice ? wifiDevice.scannerEnabled : false

    readonly property var wiredUp: wiredDevices.find(d => d.connected) ?? null
    readonly property var wifiNetwork: wifiDevice ? (wifiDevice.networks.values.find(n => n.state === ConnectionState.Connected) ?? null) : null

    // what the machine is online through: "wired" | "wifi" | "none"
    readonly property string kind: wiredUp ? "wired" : (wifiDevice && wifiDevice.connected) ? "wifi" : "none"
    readonly property var activeDevice: kind === "wired" ? wiredUp : kind === "wifi" ? wifiDevice : null
    readonly property bool online: kind !== "none"
    readonly property real strength: wifiNetwork ? wifiNetwork.signalStrength : 0

    // "full" | "limited" | "portal" | "none" | "unknown"
    readonly property string internet: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full:
            return "full";
        case NetworkConnectivity.Limited:
            return "limited";
        case NetworkConnectivity.Portal:
            return "portal";
        case NetworkConnectivity.None:
            return "none";
        default:
            return "unknown";
        }
    }
    readonly property bool degraded: online && (internet === "limited" || internet === "portal")

    // ---------- presentation ----------

    function wifiIcon(s) {
        return s < 0.25 ? Icons.wifi1 : s < 0.5 ? Icons.wifi2 : s < 0.75 ? Icons.wifi3 : Icons.wifi4;
    }

    readonly property string icon: kind === "wired" ? Icons.ethernet : kind === "wifi" ? wifiIcon(strength) : (!wifiDevice && wiredDevices.length > 0) ? Icons.ethernetOff : Icons.wifiOff

    readonly property string title: kind === "wired" ? "Ethernet" : kind === "wifi" ? (wifiNetwork ? wifiNetwork.name : "Wi-Fi") : "Not connected"

    readonly property string subtitle: {
        if (kind === "none")
            return wifiDevice ? (wifiOn ? "Choose a network below" : "Wi-Fi is off") : wiredDevices.length > 0 ? "Cable unplugged" : "No network devices found";

        const parts = [];
        if (kind === "wired")
            parts.push(activeDevice.name);
        else
            parts.push("Wi-Fi", Math.round(strength * 100) + "%");
        if (ip !== "")
            parts.push(ip);
        return parts.join("  •  ");
    }

    function stateText(s) {
        switch (s) {
        case ConnectionState.Connected:
            return "Connected";
        case ConnectionState.Connecting:
            return "Connecting…";
        case ConnectionState.Disconnecting:
            return "Disconnecting…";
        case ConnectionState.Disconnected:
            return "Disconnected";
        default:
            return "";
        }
    }

    // ---------- the active connection's details (nmcli) ----------

    property string ip: ""                // in the header
    property var details: []              // [{ label, value }], the panel's details section
    property bool detailsShown: false

    function refreshDetails() {
        infoProc.running = false;
        if (activeDevice) {
            infoProc.running = true;
        } else {
            ip = "";
            details = [];
        }
    }

    onActiveDeviceChanged: refreshDetails()

    // `nmcli -t` lines are "KEY:value" (or "KEY[n]:value" for lists); values can contain ":" themselves
    function parseInfo(text) {
        const kv = {};
        for (const line of text.split("\n")) {
            const i = line.indexOf(":");
            if (i < 0)
                continue;
            const key = line.slice(0, i).replace(/\[\d+\]$/, "");
            const value = line.slice(i + 1).trim();
            if (value !== "" && value !== "--")
                (kv[key] = kv[key] ?? []).push(value);
        }
        const one = k => kv[k]?.[0] ?? "";
        const all = k => kv[k] ?? [];

        ip = one("IP4.ADDRESS");

        const method = {
            auto: "DHCP",
            manual: "static",
            "link-local": "link-local"
        }[one("ipv4.method")];
        const speed = one("CAPABILITIES.SPEED");

        details = [
            {
                label: "Connection",
                value: one("GENERAL.CONNECTION")
            },
            {
                label: "Address",
                value: method ?? ""
            },
            {
                label: "IPv4",
                value: all("IP4.ADDRESS").join(", ")
            },
            {
                label: "Gateway",
                value: one("IP4.GATEWAY")
            },
            {
                label: "DNS",
                value: all("IP4.DNS").concat(all("IP6.DNS")).join(", ")
            },
            {
                label: "IPv6",
                // the link-local one (fe80::) is always there and says nothing
                value: all("IP6.ADDRESS").filter(a => !a.startsWith("fe80:")).join(", ")
            },
            {
                label: "Speed",
                value: /^\d/.test(speed) && !speed.startsWith("0 ") ? speed : ""
            },
            {
                label: "MAC",
                value: one("GENERAL.HWADDR")
            },
            {
                label: "MTU",
                value: one("GENERAL.MTU")
            }
        ].filter(d => d.value !== "");
    }

    Process {
        id: infoProc
        // the device's state, then how its connection gets an address (DHCP or static)
        command: ["sh", "-c", 'nmcli -t -f GENERAL.HWADDR,GENERAL.MTU,GENERAL.CONNECTION,CAPABILITIES.SPEED,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS,IP6.ADDRESS,IP6.DNS device show "$1"; ' + 'con=$(nmcli -g GENERAL.CONNECTION device show "$1"); [ -n "$con" ] && nmcli -t -f ipv4.method connection show "$con"', "sh", root.activeDevice ? root.activeDevice.name : ""]

        stdout: StdioCollector {
            onStreamFinished: root.parseInfo(text)
        }
    }

    // NetworkManager's own editor, for what the panel doesn't do (static IP, DNS, MTU, VPN...)
    function editConnections() {
        Panels.hide("network");
        Quickshell.execDetached(["uwsm-app", "--", "nm-connection-editor"]);
    }

    // a click on a detail copies it
    function copy(value) {
        Quickshell.clipboardText = value;
    }

    // ---------- the list the panel shows ----------

    // when wired, the Wi-Fi list stays collapsed until asked for
    property bool wifiExpanded: false
    readonly property bool showWifi: wifiOn && wifiDevice !== null && (kind !== "wired" || wifiExpanded)

    property var rows: []
    property string rowsSig: ""

    // the network whose password prompt is open
    property var promptNet: null

    function compareNets(a, b) {
        const ca = a.state === ConnectionState.Connected ? 0 : 1;
        const cb = b.state === ConnectionState.Connected ? 0 : 1;
        if (ca !== cb)
            return ca - cb;
        if (a.known !== b.known)
            return a.known ? -1 : 1;
        const sa = Math.round(a.signalStrength * 4);
        const sb = Math.round(b.signalStrength * 4);
        if (sa !== sb)
            return sb - sa;
        return a.name.localeCompare(b.name);
    }

    // rebuilt on a timer and replaced only when the structure changes, so a changing signal
    // strength never rebuilds the list under the user (or under a password field)
    function rebuild() {
        if (promptNet)
            return;

        const wired = wiredDevices.map(d => ({
                    type: "wired",
                    dev: d,
                    group: "Wired"
                }));

        let wifi = [];
        if (showWifi) {
            wifi = wifiDevice.networks.values.filter(n => n.name !== "").sort(compareNets).map(n => ({
                        type: "wifi",
                        net: n,
                        group: n.state === ConnectionState.Connected ? "Connected" : n.known ? "Saved networks" : "Available"
                    }));
        }

        const out = kind === "wired" ? wired.concat(wifi) : wifi.concat(wired);
        const sig = out.map(r => r.type + ":" + (r.dev ? r.dev.name : r.net.name) + ":" + r.group).join("|");
        if (sig === rowsSig)
            return;

        rowsSig = sig;
        rows = out;
    }

    onKindChanged: rebuild()
    onWifiOnChanged: rebuild()
    onWifiExpandedChanged: rebuild()
    onWifiDeviceChanged: rebuild()
    Component.onCompleted: rebuild()

    Timer {
        interval: 1000
        running: root.open
        repeat: true
        onTriggered: root.rebuild()
    }

    // scan while the panel is open
    onOpenChanged: {
        promptNet = null;
        if (wifiDevice)
            wifiDevice.scannerEnabled = open;
        if (open) {
            wifiExpanded = false;
            detailsShown = false;
            refreshDetails();
        }
        rebuild();
    }

    // ---------- actions ----------

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function toggleScan() {
        if (wifiDevice && wifiOn)
            wifiDevice.scannerEnabled = !wifiDevice.scannerEnabled;
    }

    function isSecured(net) {
        return net.security !== WifiSecurityType.Open;
    }

    function needsPassword(net) {
        return !net.known && isSecured(net);
    }

    // a click or Enter on a row: asks for a password first when the network needs one
    function request(row) {
        if (row.type === "wifi" && row.net.state !== ConnectionState.Connected && needsPassword(row.net)) {
            promptNet = row.net;
            return;
        }
        promptNet = null;
        activate(row);
    }

    function activate(row) {
        if (row.type === "wired") {
            Quickshell.execDetached(["nmcli", "device", row.dev.connected ? "disconnect" : "connect", row.dev.name]);
            return;
        }

        const n = row.net;
        if (n.stateChanging)
            return;
        if (n.state === ConnectionState.Connected)
            n.disconnect();
        else
            n.connect();
    }

    // through NetworkManager's D-Bus API, so the password never shows on a command line
    function connectWithPassword(net, psk) {
        net.connectWithPsk(psk);
    }

    function forget(net) {
        if (net && net.known)
            net.forget();
    }

    // captive portals
    function signIn() {
        Quickshell.execDetached(["uwsm-app", "--", "xdg-open", "http://neverssl.com"]);
    }

    function recheck() {
        Networking.checkConnectivity();
    }
}
