import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The network panel: cable and Wi-Fi networks to connect, with the details of the active connection and
// what to do about a captive portal.
DropdownPanel {
    id: panel
    name: "network"
    edge: "right"
    cardWidth: 440

    ColumnLayout {
        id: menu
        spacing: 12
        focus: true

        Selection {
            id: nav
            count: Net.rows.length
            view: list
        }
        readonly property var selRow: Net.rows[nav.index] ?? null

        // when the password prompt closes, the keys come back to the panel
        Connections {
            target: Net

            function onPromptNetChanged() {
                if (Net.promptNet === null)
                    menu.forceActiveFocus();
            }
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_J:
            case Qt.Key_Down:
                nav.move(1);
                break;
            case Qt.Key_K:
            case Qt.Key_Up:
                nav.move(-1);
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
                if (selRow)
                    Net.request(selRow);
                break;
            case Qt.Key_S:
                Net.toggleScan();
                break;
            case Qt.Key_W:
                Net.toggleWifi();
                break;
            case Qt.Key_E:
                Net.wifiExpanded = !Net.wifiExpanded;
                break;
            case Qt.Key_I:
                if (Net.activeDevice)
                    Net.detailsShown = !Net.detailsShown;
                break;
            case Qt.Key_C:
                Net.editConnections();
                break;
            case Qt.Key_F:
                if (selRow && selRow.type === "wifi")
                    Net.forget(selRow.net);
                break;
            case Qt.Key_Q:
                panel.close();
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        // ---------- header: adapts to wired / Wi-Fi / offline ----------
        PanelHeader {
            icon: Net.icon
            iconColor: !Net.online ? Theme.dim : Net.degraded ? Theme.urgent : Theme.accent
            title: Net.title
            subtitle: Net.subtitle

            Pill {
                visible: Net.showWifi
                text: Net.scanning ? "Scanning…" : "Scan"
                active: Net.scanning
                onClicked: Net.toggleScan()
            }

            Toggle {
                visible: Net.wifiDevice !== null
                checked: Net.wifiOn
                onToggled: Net.toggleWifi()
            }
        }

        // connected, but no internet / captive portal
        RowLayout {
            visible: Net.degraded
            Layout.fillWidth: true
            spacing: 8

            Txt {
                Layout.fillWidth: true
                variant: "dim"
                color: Theme.urgent
                wrapMode: Text.Wrap
                text: Net.internet === "portal" ? "This network needs you to sign in" : "Connected, but the internet looks unreachable"
            }

            Pill {
                visible: Net.internet === "portal"
                text: "Sign in"
                primary: true
                onClicked: Net.signIn()
            }

            Pill {
                text: "Recheck"
                onClicked: Net.recheck()
            }
        }

        // ---------- the active connection: details, and NetworkManager's editor for the rest ----------
        RowLayout {
            visible: Net.devices.length > 0
            Layout.fillWidth: true
            spacing: 8

            Txt {
                Layout.fillWidth: true
                variant: "dim"
                text: Net.activeDevice ? "Connection details" : "Connections"
            }

            Pill {
                text: "Edit"
                onClicked: Net.editConnections()
            }

            Pill {
                visible: Net.activeDevice !== null && Net.details.length > 0
                text: Net.detailsShown ? "Hide" : "Show"
                active: Net.detailsShown
                onClicked: Net.detailsShown = !Net.detailsShown
            }
        }

        // label / value rows; a click on a value copies it
        ColumnLayout {
            visible: Net.detailsShown && Net.activeDevice !== null
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 4

            Repeater {
                model: Net.details

                delegate: RowLayout {
                    id: detail
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 12

                    Txt {
                        Layout.preferredWidth: 80
                        Layout.alignment: Qt.AlignTop
                        variant: "dim"
                        text: detail.modelData.label
                    }

                    Txt {
                        Layout.fillWidth: true
                        text: detail.modelData.value
                        wrapMode: Text.WrapAnywhere
                        color: copyArea.containsMouse ? Theme.accent : Theme.fg
                        Behavior on color {
                            CAnim {}
                        }

                        MouseArea {
                            id: copyArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Net.copy(detail.modelData.value)
                        }
                    }
                }
            }
        }

        Divider {}

        // when wired, the Wi-Fi list stays out of the way until asked for
        RowLayout {
            visible: Net.kind === "wired" && Net.wifiDevice !== null && Net.wifiOn
            Layout.fillWidth: true

            Txt {
                Layout.fillWidth: true
                variant: "dim"
                text: "Wi-Fi networks"
            }

            Pill {
                text: Net.wifiExpanded ? "Hide" : "Show"
                onClicked: Net.wifiExpanded = !Net.wifiExpanded
            }
        }

        // ---------- devices and networks ----------
        ScrollList {
            id: list
            visible: Net.rows.length > 0
            model: Net.rows

            delegate: NetRow {
                required property var modelData
                required property int index

                width: ListView.view.rowWidth
                row: modelData
                selected: nav.index === index
                header: (index === 0 || Net.rows[index - 1].group !== modelData.group) ? modelData.group : ""

                onSelectRequested: nav.select(index)
                onActivated: Net.request(modelData)
                onForgetRequested: Net.forget(modelData.net)
            }
        }

        EmptyState {
            visible: Net.rows.length === 0
            text: Net.devices.length === 0 ? "No network devices found (is NetworkManager running?)" : !Net.wifiOn && Net.wifiDevice ? "Wi-Fi is off  (w to turn it on)" : Net.scanning ? "Searching for networks…" : "Nothing to show"
        }

        Hint {
            text: Net.kind === "wired" ? "j k select • Enter connect • i details • c edit • e Wi-Fi list • w Wi-Fi on/off • Esc close" : "j k select • Enter connect • i details • c edit • f forget • s scan • w Wi-Fi on/off • Esc close"
        }
    }
}
