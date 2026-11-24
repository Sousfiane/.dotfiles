import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

DropdownPanel {
    id: panel
    name: "updates"
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
            case Qt.Key_R:
                Updates.refresh();
                break;
            case Qt.Key_U:
                Updates.runUpdate();
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
            icon: Icons.update
            iconColor: Updates.failed ? Theme.urgent : Updates.count > 0 ? Theme.accent : Theme.dim
            title: "Updates"
            subtitle: Updates.updating ? "Updating in the terminal…" : Updates.failed ? "Could not check for updates" : (Updates.checking && Updates.count === 0) ? "Checking…" : Updates.count === 0 ? "System is up to date" : Fmt.plural(Updates.count, "update") + " available" + (Updates.aurCount > 0 ? `  •  ${Updates.aurCount} from the AUR` : "")
            subtitleColor: Updates.failed ? Theme.urgent : Theme.dim

            Pill {
                text: Updates.checking ? "Checking…" : "Refresh"
                active: Updates.checking
                onClicked: Updates.refresh()
            }

            Pill {
                visible: Updates.count > 0 && !Updates.updating
                text: "Update"
                primary: true
                onClicked: Updates.runUpdate()
            }
        }

        Divider {}

        ScrollList {
            id: list
            visible: Updates.count > 0
            model: Updates.packages

            delegate: ListRow {
                id: row
                required property var modelData

                Txt {
                    Layout.fillWidth: true
                    variant: "row"
                    text: row.modelData.name
                    elide: Text.ElideRight
                }

                Txt {
                    visible: row.modelData.aur
                    variant: "small"
                    color: Theme.gold
                    text: "AUR"
                }

                Txt {
                    variant: "small"
                    text: row.modelData.from + " → " + row.modelData.to
                }
            }
        }

        EmptyState {
            visible: Updates.count === 0
            text: Updates.failed ? "Check your network, then press r to retry" : Updates.checking ? "Checking for updates…" : "Nothing to update"
        }

        Hint {
            text: "j k scroll • u update system • r refresh • Esc close"
        }
    }
}
