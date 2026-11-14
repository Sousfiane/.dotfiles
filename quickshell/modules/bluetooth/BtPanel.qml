import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

DropdownPanel {
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
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Txt {
                text: Icons.bluetooth
                color: Bt.powered ? Theme.accent : Theme.dim
                font.pixelSize: Theme.fontSize + 6
            }

            ColumnLayout {
                spacing: 0

                Txt {
                    text: "Bluetooth"
                    variant: "title"
                }

                Txt {
                    visible: Bt.adapter !== null && Bt.adapter !== undefined
                    variant: "small"
                    text: Bt.adapter?.name ?? ""
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Pill {
                visible: Bt.powered
                text: Bt.scanning ? "Scanning…" : "Scan"
                active: Bt.scanning
                onClicked: Bt.toggleScan()
            }

            // power switch
            Rectangle {
                visible: Bt.adapter !== null && Bt.adapter !== undefined
                implicitWidth: 40
                implicitHeight: 22
                radius: 11
                color: Bt.powered ? Theme.accent : Theme.surface

                Rectangle {
                    y: 3
                    x: Bt.powered ? parent.width - width - 3 : 3
                    width: 16
                    height: 16
                    radius: 8
                    color: Bt.powered ? Theme.bgSolid : Theme.dim

                    Behavior on x {
                        NumberAnimation {
                            duration: 120
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Bt.togglePower()
                }
            }
        }

        Divider {}

        // ---------- devices ----------
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 420)
            visible: Bt.list.length > 0
            clip: true
            spacing: 2
            model: Bt.list

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
            text: !Bt.adapter ? "No Bluetooth adapter found" : !Bt.powered ? "Bluetooth is off  (p to turn it on)" : Bt.scanning ? "Searching for devices…" : "No devices  (s to scan)"
        }

        Hint {
            text: "j k select • Enter connect / pair • f forget • s scan • p power • Esc close"
        }
    }
}
