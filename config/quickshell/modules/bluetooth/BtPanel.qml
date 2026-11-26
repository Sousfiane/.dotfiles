import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The Bluetooth panel: connected, saved and newly found devices, to connect, pair or forget, with j/k
// and Enter as well as the mouse.
DropdownPanel {
    id: panel
    name: "bluetooth"
    edge: "right"
    cardWidth: 460

    ColumnLayout {
        id: menu
        spacing: 12

        Selection {
            id: nav
            count: Bt.list.length
            view: list
        }
        readonly property var selDev: Bt.list[nav.index] ?? null

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
                Bt.activate(selDev);
                break;
            case Qt.Key_S:
                Bt.toggleScan();
                break;
            case Qt.Key_P:
                Bt.togglePower();
                break;
            case Qt.Key_F:
                Bt.forget(selDev);
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
        PanelHeader {
            icon: Icons.bluetooth
            iconColor: Bt.powered ? Theme.accent : Theme.dim
            title: "Bluetooth"
            subtitle: Bt.adapter?.name ?? ""

            Pill {
                visible: Bt.powered
                text: Bt.scanning ? "Scanning…" : "Scan"
                active: Bt.scanning
                onClicked: Bt.toggleScan()
            }

            Toggle {
                visible: !!Bt.adapter
                checked: Bt.powered
                onToggled: Bt.togglePower()
            }
        }

        Divider {}

        // ---------- devices ----------
        ScrollList {
            id: list
            visible: Bt.list.length > 0
            model: ScriptModel {
                values: Bt.list
            }

            delegate: BtRow {
                required property var modelData
                required property int index

                width: ListView.view.rowWidth
                dev: modelData
                selected: nav.index === index

                header: (index === 0 || Bt.groupOf(Bt.list[index - 1]) !== Bt.groupOf(modelData)) ? ["Connected", "My devices", "Available"][Bt.groupOf(modelData)] : ""

                onSelectRequested: nav.select(index)
                onActivated: Bt.activate(modelData)
                onForgetRequested: Bt.forget(modelData)
            }
        }

        EmptyState {
            visible: Bt.list.length === 0
            text: !Bt.adapter ? "No Bluetooth adapter found" : !Bt.powered ? "Bluetooth is off  (p to turn it on)" : Bt.scanning ? "Searching for devices…" : "No devices  (s to scan)"
        }

        Hint {
            text: "j k select • Enter connect / pair • f forget • s scan • p power • Esc close"
        }
    }
}
