import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

DropdownPanel {
    name: "dotfiles"
    open: Dotfiles.panelOpen
    edge: "right"
    cardWidth: 460

    onToggleRequested: Dotfiles.toggle()
    onCloseRequested: Dotfiles.panelOpen = false

    ColumnLayout {
        spacing: 12

        function scrollBy(d) {
            const max = Math.max(0, list.contentHeight - list.height);
            list.contentY = Math.max(0, Math.min(max, list.contentY + d));
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_J:
            case Qt.Key_Down:
                scrollBy(60);
                break;
            case Qt.Key_K:
            case Qt.Key_Up:
                scrollBy(-60);
                break;
            case Qt.Key_G:
            case Qt.Key_Return:
            case Qt.Key_Enter:
                Dotfiles.openLazygit();
                break;
            case Qt.Key_R:
                Dotfiles.refresh();
                break;
            case Qt.Key_Q:
                Dotfiles.panelOpen = false;
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        // ---------- header ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Txt {
                text: Icons.git
                color: Dotfiles.failed ? Theme.urgent : Dotfiles.count > 0 ? Theme.accent : Theme.dim
                font.pixelSize: Theme.fontSize + 6
            }

            ColumnLayout {
                spacing: 0

                Txt {
                    text: "Dotfiles"
                    variant: "title"
                }

                Txt {
                    variant: "small"
                    color: Dotfiles.failed ? Theme.urgent : Theme.dim
                    text: Dotfiles.failed ? "Could not read the repository" : Dotfiles.count === 0 ? "Working tree clean" : Dotfiles.count + (Dotfiles.count === 1 ? " change" : " changes")
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Pill {
                text: Dotfiles.checking ? "Checking…" : "Refresh"
                active: Dotfiles.checking
                onClicked: Dotfiles.refresh()
            }

            Pill {
                text: "Lazygit"
                primary: true
                onClicked: Dotfiles.openLazygit()
            }
        }

        Divider {}

        // ---------- changed files ----------
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 420)
            visible: Dotfiles.count > 0
            clip: true
            spacing: 2
            model: Dotfiles.changes

            delegate: Rectangle {
                id: row
                required property string modelData

                // status letters, then whitespace, then the path (tolerates a stripped leading space)
                readonly property var parts: modelData.match(/^\s*(\S{1,2})\s+(.*)$/) ?? ["", "", modelData]
                readonly property string code: parts[1]
                readonly property string path: parts[2]

                width: ListView.view.width
                implicitHeight: 30
                radius: 6
                color: rowHover.hovered ? Theme.surface : "transparent"

                HoverHandler {
                    id: rowHover
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    spacing: 12

                    Txt {
                        Layout.preferredWidth: 22
                        text: row.code
                        color: row.code.indexOf("D") !== -1 ? Theme.urgent : row.code.indexOf("?") !== -1 ? Theme.dim : Theme.accent
                        font.pixelSize: Theme.fontSize - 2
                        font.bold: true
                    }

                    Txt {
                        Layout.fillWidth: true
                        variant: "row"
                        text: row.path
                        elide: Text.ElideMiddle
                    }
                }
            }
        }

        Txt {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            visible: Dotfiles.count === 0
            horizontalAlignment: Text.AlignHCenter
            text: Dotfiles.failed ? "Check the repository path in Config.qml" : "Nothing to commit"
        }

        Hint {
            text: "j k scroll • Enter / g lazygit • r refresh • Esc close"
        }
    }
}
