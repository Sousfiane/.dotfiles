import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

DropdownPanel {
    id: panel
    name: "bluetooth"
    edge: "right"
    cardWidth: 460

    ColumnLayout {
        id: menu
        spacing: 12

        property int sel: 0
        readonly property int selIndex: Math.max(0, Math.min(sel, Bt.list.length - 1))
        readonly property var selDev: Bt.list[selIndex] ?? null

        onSelIndexChanged: list.positionViewAtIndex(selIndex, ListView.Contain)

        function move(d) {
            sel = Math.max(0, Math.min(Bt.list.length - 1, selIndex + d));
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_J:
            case Qt.Key_Down:
                move(1);
                break;
            case Qt.Key_K:
            case Qt.Key_Up:
                move(-1);
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

                width: ListView.view.width
                dev: modelData
                selected: menu.selIndex === index

                header: (index === 0 || Bt.groupOf(Bt.list[index - 1]) !== Bt.groupOf(modelData)) ? ["Connected", "My devices", "Available"][Bt.groupOf(modelData)] : ""

                onSelectRequested: menu.sel = index
                onActivated: Bt.activate(modelData)
                onForgetRequested: Bt.forget(modelData)
            }
        }

        Txt {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            visible: Bt.list.length === 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            variant: "dim"
            text: !Bt.adapter ? "No Bluetooth adapter found" : !Bt.powered ? "Bluetooth is off  (p to turn it on)" : Bt.scanning ? "Searching for devices…" : "No devices  (s to scan)"
        }

        Hint {
            text: "j k select • Enter connect / pair • f forget • s scan • p power • Esc close"
        }
    }
}
