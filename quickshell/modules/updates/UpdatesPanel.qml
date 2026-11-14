import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

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
            subtitle: Updates.failed ? "Could not check for updates" : (Updates.checking && Updates.count === 0) ? "Checking…" : Updates.count === 0 ? "System is up to date" : Updates.count + (Updates.count === 1 ? " update available" : " updates available")
            subtitleColor: Updates.failed ? Theme.urgent : Theme.dim

            Pill {
                text: Updates.checking ? "Checking…" : "Refresh"
                active: Updates.checking
                onClicked: Updates.refresh()
            }

            Pill {
                visible: Updates.count > 0
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
                    variant: "small"
                    text: row.modelData.from + " → " + row.modelData.to
                }
            }
        }

        Txt {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            visible: Updates.count === 0
            horizontalAlignment: Text.AlignHCenter
            text: Updates.failed ? "Check your network, then press r to retry" : Updates.checking ? "Checking for updates…" : "Nothing to update"
        }

        Hint {
            text: "j k scroll • u update system • r refresh • Esc close"
        }
    }
}
