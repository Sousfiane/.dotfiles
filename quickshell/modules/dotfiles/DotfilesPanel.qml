import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

DropdownPanel {
    id: panel
    name: "dotfiles"
    edge: "right"
    cardWidth: 460

    ColumnLayout {
        spacing: 12

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_J:
            case Qt.Key_Down:
                list.scrollBy(60);
                break;
            case Qt.Key_K:
            case Qt.Key_Up:
                list.scrollBy(-60);
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
                panel.close();
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        PanelHeader {
            icon: Icons.git
            iconColor: Dotfiles.failed ? Theme.urgent : Dotfiles.count > 0 ? Theme.accent : Theme.dim
            title: "Dotfiles"
            subtitle: Dotfiles.failed ? "Could not read the repository" : Dotfiles.count === 0 ? "Working tree clean" : Dotfiles.count + (Dotfiles.count === 1 ? " change" : " changes")
            subtitleColor: Dotfiles.failed ? Theme.urgent : Theme.dim

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

        ScrollList {
            id: list
            visible: Dotfiles.count > 0
            model: Dotfiles.changes

            delegate: ListRow {
                id: row
                required property string modelData

                // status letters, then whitespace, then the path (tolerates a stripped leading space)
                readonly property var parts: modelData.match(/^\s*(\S{1,2})\s+(.*)$/) ?? ["", "", modelData]
                readonly property string code: parts[1]
                readonly property string path: parts[2]

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
