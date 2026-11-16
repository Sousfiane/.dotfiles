import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

Item {
    id: root

    required property var dev
    property bool selected: false
    property string header: ""         // section label, empty when not the first of its group

    signal selectRequested
    signal activated
    signal forgetRequested

    readonly property string status: Bt.statusOf(dev)
    readonly property bool busy: status.endsWith("…")
    readonly property real level: Bt.batteryOf(dev)

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

                // freedesktop icon BlueZ reports for the device (headset, gamepad, keyboard...)
                IconImage {
                    Layout.preferredWidth: 26
                    Layout.preferredHeight: 26
                    source: Quickshell.iconPath(root.dev.icon || "bluetooth", "bluetooth")
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Txt {
                        Layout.fillWidth: true
                        variant: "row"
                        font.bold: root.dev.connected
                        text: root.dev.name || root.dev.address
                        elide: Text.ElideRight
                    }

                    Txt {
                        Layout.fillWidth: true
                        variant: "small"
                        color: root.dev.connected ? Theme.accent : Theme.dim
                        text: root.status
                        elide: Text.ElideRight
                    }
                }

                // battery
                Txt {
                    visible: root.dev.connected && root.level >= 0
                    variant: "dim"
                    color: root.level < 0.2 ? Theme.urgent : Theme.dim
                    text: Math.round(root.level * 100) + "%"
                }

                // main action
                Pill {
                    minWidth: 86
                    primary: !root.dev.connected
                    enabled: !root.busy
                    opacity: root.busy ? 0.5 : 1
                    text: root.busy ? "…" : root.dev.connected ? "Disconnect" : root.dev.paired ? "Connect" : "Pair"
                    onClicked: {
                        root.selectRequested();
                        root.activated();
                    }
                }

                // forget (saved devices only)
                Txt {
                    visible: root.dev.paired
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
    }
}
