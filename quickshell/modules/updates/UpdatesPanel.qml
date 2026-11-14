import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

DropdownPanel {
    name: "updates"
    edge: "right"
    cardWidth: 460

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

        // ---------- header ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Txt {
                text: Icons.update
                color: Updates.failed ? Theme.urgent : Updates.count > 0 ? Theme.accent : Theme.dim
                font.pixelSize: Theme.fontSize + 6
            }

            ColumnLayout {
                spacing: 0

                Txt {
                    text: "Updates"
                    variant: "title"
                }

                Txt {
                    variant: "small"
                    color: Updates.failed ? Theme.urgent : Theme.dim
                    text: Updates.failed ? "Could not check for updates" : (Updates.checking && Updates.count === 0) ? "Checking…" : Updates.count === 0 ? "System is up to date" : Updates.count + (Updates.count === 1 ? " update available" : " updates available")
                }
            }

            Item {
                Layout.fillWidth: true
            }

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

        // ---------- package list ----------
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 420)
            visible: Updates.count > 0
            clip: true
            spacing: 2
            model: Updates.packages

            delegate: Rectangle {
                id: row
                required property var modelData

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
