import Quickshell
import QtQuick
import qs.config
import qs.services

Item {
    id: root

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Text {
        id: icon

        // nf-md: bluetooth_off, bluetooth_connect, bluetooth
        text: !Bt.powered ? String.fromCodePoint(0xF00B2) : Bt.connected ? String.fromCodePoint(0xF00B1) : String.fromCodePoint(0xF00AF)

        color: !Bt.powered ? Theme.dim : Theme.fg

        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 3
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton
        onClicked: Quickshell.execDetached(["uwsm", "app", "--", "blueberry"])
    }

    PopupWindow {
        visible: hover.containsMouse

        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom

        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        color: "transparent"

        Rectangle {
            id: card
            implicitWidth: Math.max(220, list.implicitWidth + 24)
            implicitHeight: list.implicitHeight + 24
            radius: Theme.radius
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.80)
            border.color: Theme.border

            Column {
                id: list
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 6

                Text {
                    text: !Bt.powered ? "Bluetooth is off" : !Bt.connected ? "No device connected" : "Connected devices"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                Repeater {
                    model: Bt.connectedDevices

                    delegate: Row {
                        id: line
                        required property var modelData
                        spacing: 16

                        Text {
                            width: 150
                            color: Theme.fg
                            text: line.modelData.name + ":"
                            elide: Text.ElideRight
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }

                        Text {
                            readonly property real level: line.modelData.battery

                            text: level >= 0 ? Math.round(level * 100) + "%" : "–"
                            color: level >= 0 && level < 0.2 ? Theme.urgent : Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }
                }
            }
        }
    }
}
