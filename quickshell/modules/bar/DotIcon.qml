import QtQuick
import Quickshell
import qs.services
import qs.config

Item {
    id: root

    property string terminal: "kitty"      // change to foot, alacritty, ghostty...

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 6

        Text {
            // nf-md-git
            text: String.fromCodePoint(0xF02A2)
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 3
            color: Dotfiles.failed ? Theme.urgent : Theme.fg
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: Dotfiles.count > 0
            text: Dotfiles.count
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
            color: Theme.fg
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        anchors.margins: -4
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["uwsm", "app", "--", root.terminal, "--app-id=FloatingTerm", "-e", "lazygit", "-p", Dotfiles.repoPath])
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
            implicitWidth: 360
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
                spacing: 4

                Text {
                    text: Dotfiles.failed ? "Could not read the repository" : Dotfiles.count === 0 ? "Dotfiles are clean" : "Dotfiles changes (" + Dotfiles.count + ")"
                    font.family: Theme.font
                    color: Theme.fg
                    font.pixelSize: Theme.fontSize
                    font.bold: true
                }

                Repeater {
                    // first ten only
                    model: Dotfiles.changes.slice(0, 10)

                    delegate: Row {
                        id: line
                        required property string modelData
                        spacing: 10

                        Text {
                            width: 24
                            text: line.modelData.substring(0, 2).trim()
                            color: Theme.accent
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                        Text {
                            width: 300
                            text: line.modelData.substring(2).trim()
                            elide: Text.ElideMiddle
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                        }
                    }
                }

                Text {
                    visible: Dotfiles.count > 10
                    text: "+ " + (Dotfiles.count - 10) + " more"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                }
            }
        }
    }
}
