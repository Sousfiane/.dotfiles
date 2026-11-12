import Quickshell
import QtQuick
import qs.config
import qs.services

Item {
    id: root

    property bool open: false
    readonly property bool hovered: iconHover.hovered || popupHover.hovered

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // small delay so moving the mouse from the icon to the popup doesn't close it
    onHoveredChanged: {
        if (hovered) {
            closeTimer.stop();
            open = true;
        } else
            closeTimer.restart();
    }

    Timer {
        id: closeTimer
        interval: 200
        onTriggered: root.open = false
    }

    HoverHandler {
        id: iconHover
    }

    Row {
        id: row
        spacing: 6

        Text {
            // nf-md-update
            text: String.fromCodePoint(0xf03d4)
            color: Updates.failed ? Theme.urgent : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 3
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: Updates.count > 0
            text: Updates.count
            color: Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    PopupWindow {
        visible: root.open
        anchor.item: root
        anchor.edges: Edges.Bottom
        anchor.gravity: Edges.Bottom
        implicitWidth: card.implicitWidth
        implicitHeight: card.implicitHeight
        color: "transparent"

        Rectangle {
            id: card
            implicitWidth: list.implicitWidth + 24
            implicitHeight: list.implicitHeight + 24
            radius: Theme.radius
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.80)
            border.color: Theme.border

            HoverHandler {
                id: popupHover
            }

            Column {
                id: list
                anchors {
                    left: parent.left
                    top: parent.top
                    margins: 12
                }
                spacing: 4

                Text {
                    text: Updates.failed ? "Could not check for updates" : Updates.count === 0 ? "System is up to date" : Updates.count + (Updates.count === 1 ? " update" : " updates")
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                Repeater {
                    model: Updates.firstTen

                    delegate: Row {
                        id: line
                        required property var modelData
                        spacing: 12

                        Text {
                            width: 190
                            text: line.modelData.name
                            elide: Text.ElideRight
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                        Text {
                            text: line.modelData.from + " → " + line.modelData.to
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }
                }

                Text {
                    visible: Updates.count > 10
                    text: "+ " + (Updates.count - 10) + " more"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }
}
