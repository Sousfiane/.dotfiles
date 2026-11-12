import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

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

        Text {
            visible: root.header !== ""
            Layout.topMargin: root.header !== "" ? 6 : 0
            text: root.header
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 3
            font.bold: true
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

                    Text {
                        Layout.fillWidth: true
                        text: root.dev.name || root.dev.address
                        elide: Text.ElideRight
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 1
                        font.bold: root.dev.connected
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.status
                        elide: Text.ElideRight
                        color: root.dev.connected ? Theme.accent : Theme.dim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                    }
                }

                // battery
                Text {
                    visible: root.dev.connected && root.level >= 0
                    text: Math.round(root.level * 100) + "%"
                    color: root.level < 0.2 ? Theme.urgent : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }

                // main action
                Rectangle {
                    implicitWidth: 86
                    implicitHeight: 24
                    radius: 12
                    opacity: root.busy ? 0.5 : 1
                    color: root.dev.connected ? Theme.surface : Theme.accent
                    border.width: root.dev.connected ? 1 : 0
                    border.color: Theme.border

                    Text {
                        anchors.centerIn: parent
                        text: root.busy ? "…" : root.dev.connected ? "Disconnect" : root.dev.paired ? "Connect" : "Pair"
                        color: root.dev.connected ? Theme.fg : Theme.bg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 3
                        font.bold: true
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !root.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectRequested();
                            root.activated();
                        }
                    }
                }

                // forget (saved devices only)
                Text {
                    visible: root.dev.paired
                    text: "×"
                    color: Theme.dim
                    font.family: Theme.font
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
