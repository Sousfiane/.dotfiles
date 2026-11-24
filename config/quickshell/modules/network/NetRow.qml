import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.config
import qs.services
import qs.components.ui

DeviceRow {
    id: root

    required property var row

    readonly property bool isWired: row.type === "wired"
    readonly property var obj: isWired ? row.dev : row.net
    readonly property bool connected: obj.state === ConnectionState.Connected
    readonly property bool secured: !isWired && Net.isSecured(obj)
    readonly property bool known: !isWired && obj.known
    readonly property bool prompting: !isWired && Net.promptNet === obj

    function submit() {
        if (pass.text.length === 0)
            return;
        Net.connectWithPassword(obj, pass.text);
        pass.text = "";
        Net.promptNet = null;
    }

    // give the password field the keyboard as soon as it appears
    onPromptingChanged: if (prompting)
        Qt.callLater(() => pass.forceActiveFocus())

    // device kind: cable, or signal strength
    icon: Txt {
        anchors.centerIn: parent
        text: root.isWired ? Icons.ethernet : Net.wifiIcon(root.obj.signalStrength)
        color: root.connected ? Theme.accent : Theme.fg
        font.pixelSize: Theme.fontSize + 6
    }

    title: isWired ? "Ethernet  (" + obj.name + ")" : obj.name
    titleBold: connected
    titleExtras: Txt {
        visible: root.secured
        variant: "small"
        text: Icons.lock
    }

    busy: obj.state === ConnectionState.Connecting || obj.state === ConnectionState.Disconnecting
    status: busy || isWired || connected ? Net.stateText(obj.state) : known ? "Saved" : secured ? "Secured" : "Open"
    statusColor: connected ? Theme.accent : Theme.dim
    detail: isWired ? "" : Math.round(obj.signalStrength * 100) + "%"

    actionText: connected ? "Disconnect" : "Connect"
    primary: !connected
    canForget: known           // saved Wi-Fi networks only

    // password prompt for networks that need one
    RowLayout {
        visible: root.prompting
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        Layout.bottomMargin: 8
        spacing: 8

        InputField {
            id: pass
            color: Theme.bgSolid
            password: true
            placeholder: "Password"

            onAccepted: root.submit()
            onCancelled: Net.promptNet = null
        }

        Pill {
            text: "Join"
            primary: true
            onClicked: root.submit()
        }
    }
}
