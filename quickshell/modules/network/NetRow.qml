import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.config
import qs.services
import qs.components.ui

Item {
    id: root

    required property var row
    property bool selected: false
    property string header: ""         // section label, empty when not the first of its group

    signal selectRequested
    signal activated
    signal forgetRequested

    readonly property bool isWired: row.type === "wired"
    readonly property var obj: isWired ? row.dev : row.net
    readonly property bool connected: obj.state === ConnectionState.Connected
    readonly property bool busy: obj.state === ConnectionState.Connecting || obj.state === ConnectionState.Disconnecting
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

    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors {
            left: parent.left
            right: parent.right
        }
        spacing: 4

        Txt {
            visible: root.header !== ""
            Layout.topMargin: root.header !== "" ? 6 : 0
            variant: "small"
            font.bold: true
            text: root.header
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 52
            radius: Theme.radius
            color: root.selected ? Theme.surface : "transparent"
            border.width: root.selected ? 1 : 0
            border.color: Theme.accent

            MouseArea {
                anchors.fill: parent
                onClicked: root.selectRequested()
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 10
                    rightMargin: 10
                }
                spacing: 10

                // device kind: cable, or signal strength
                Txt {
                    Layout.preferredWidth: 26
                    horizontalAlignment: Text.AlignHCenter
                    text: root.isWired ? Icons.ethernet : Net.wifiIcon(root.obj.signalStrength)
                    color: root.connected ? Theme.accent : Theme.fg
                    font.pixelSize: Theme.fontSize + 6
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    RowLayout {
                        spacing: 6

                        Txt {
                            Layout.fillWidth: true
                            variant: "row"
                            font.bold: root.connected
                            text: root.isWired ? "Ethernet  (" + root.obj.name + ")" : root.obj.name
                            elide: Text.ElideRight
                        }

                        Txt {
                            visible: root.secured
                            variant: "small"
                            text: Icons.lock
                        }
                    }

                    Txt {
                        Layout.fillWidth: true
                        variant: "small"
                        color: root.connected ? Theme.accent : Theme.dim
                        text: root.busy || root.isWired || root.connected ? Net.stateText(root.obj.state) : root.known ? "Saved" : root.secured ? "Secured" : "Open"
                        elide: Text.ElideRight
                    }
                }

                // signal strength
                Txt {
                    visible: !root.isWired
                    variant: "dim"
                    text: Math.round(root.obj.signalStrength * 100) + "%"
                }

                Pill {
                    minWidth: 86
                    primary: !root.connected
                    enabled: !root.busy
                    opacity: root.busy ? 0.5 : 1
                    text: root.busy ? "…" : root.connected ? "Disconnect" : "Connect"
                    onClicked: {
                        root.selectRequested();
                        root.activated();
                    }
                }

                // forget (saved Wi-Fi networks only)
                Txt {
                    visible: root.known
                    text: "×"
                    color: Theme.dim
                    font.pixelSize: Theme.fontSize + 4

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -4
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.forgetRequested()
                    }
                }
            }
        }

        // password prompt for networks that need one
        RowLayout {
            visible: root.prompting
            Layout.fillWidth: true
            Layout.leftMargin: 10
            Layout.rightMargin: 10
            Layout.bottomMargin: 8
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 30
                radius: 6
                color: Theme.bgSolid
                border.width: 1
                border.color: Theme.border

                TextInput {
                    id: pass
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    clip: true
                    selectByMouse: true

                    Keys.onReturnPressed: root.submit()
                    Keys.onEnterPressed: root.submit()
                    Keys.onEscapePressed: event => {
                        Net.promptNet = null;
                        event.accepted = true;
                    }

                    Txt {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: pass.text.length === 0
                        enabled: false
                        variant: "dim"
                        text: "Password"
                    }
                }
            }

            Pill {
                text: "Join"
                primary: true
                onClicked: root.submit()
            }
        }
    }
}
