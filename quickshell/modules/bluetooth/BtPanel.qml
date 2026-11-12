import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Scope {
    id: root

    // `qs ipc call bluetooth toggle|close`
    IpcHandler {
        target: "bluetooth"
        function toggle(): void {
            Bt.toggle();
        }
        function close(): void {
            Bt.panelOpen = false;
        }
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor?.name;
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        return Quickshell.screens[0];
    }

    LazyLoader {
        active: Bt.panelOpen

        PanelWindow {
            screen: root.focusedScreen()
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: "bluetooth-panel"

            Item {
                id: content
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                property int sel: 0
                readonly property int selIndex: Math.max(0, Math.min(sel, Bt.list.length - 1))
                readonly property var selDev: Bt.list[selIndex] ?? null

                onSelIndexChanged: list.positionViewAtIndex(selIndex, ListView.Contain)

                function move(d) {
                    sel = Math.max(0, Math.min(Bt.list.length - 1, selIndex + d));
                }

                Keys.onEscapePressed: Bt.panelOpen = false
                Keys.onUpPressed: move(-1)
                Keys.onDownPressed: move(1)
                Keys.onReturnPressed: Bt.activate(selDev)
                Keys.onEnterPressed: Bt.activate(selDev)

                Keys.onPressed: event => {
                    let handled = true;
                    switch (event.text) {
                    case "j":
                        move(1);
                        break;
                    case "k":
                        move(-1);
                        break;
                    case " ":
                        Bt.activate(selDev);
                        break;
                    case "s":
                        Bt.toggleScan();
                        break;
                    case "p":
                        Bt.togglePower();
                        break;
                    case "f":
                        Bt.forget(selDev);
                        break;
                    case "q":
                        Bt.panelOpen = false;
                        break;
                    default:
                        handled = false;
                    }
                    if (handled)
                        event.accepted = true;
                }

                // click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: Bt.panelOpen = false
                }

                Rectangle {
                    id: card
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: Theme.barHeight + 8
                        rightMargin: 8
                    }
                    width: 460
                    height: Math.min(col.implicitHeight + 32, parent.height - Theme.barHeight - 24)
                    radius: Theme.radius + 4
                    color: Theme.bg
                    border.color: Theme.border
                    border.width: 2

                    // swallow clicks on the card
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: col
                        anchors {
                            fill: parent
                            margins: 16
                        }
                        spacing: 12

                        // ---------- header ----------
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                // nf-md-bluetooth
                                text: String.fromCodePoint(0xF00AF)
                                color: Bt.powered ? Theme.accent : Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 6
                            }

                            ColumnLayout {
                                spacing: 0

                                Text {
                                    text: "Bluetooth"
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 4
                                    font.bold: true
                                }

                                Text {
                                    visible: Bt.adapter !== null && Bt.adapter !== undefined
                                    text: Bt.adapter?.name ?? ""
                                    color: Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 3
                                }
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            // scan button
                            Rectangle {
                                visible: Bt.powered
                                implicitWidth: scanLabel.implicitWidth + 18
                                implicitHeight: 24
                                radius: 12
                                color: Bt.scanning ? Theme.accent : Theme.surface

                                Text {
                                    id: scanLabel
                                    anchors.centerIn: parent
                                    text: Bt.scanning ? "Scanning…" : "Scan"
                                    color: Bt.scanning ? Theme.bg : Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 3
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Bt.toggleScan()
                                }
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
                                    color: Bt.powered ? Theme.bg : Theme.dim

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

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Theme.border
                        }

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
                                selected: content.selIndex === index

                                header: (index === 0 || Bt.groupOf(Bt.list[index - 1]) !== Bt.groupOf(modelData)) ? ["Connected", "My devices", "Available"][Bt.groupOf(modelData)] : ""

                                onSelectRequested: content.sel = index
                                onActivated: Bt.activate(modelData)
                                onForgetRequested: Bt.forget(modelData)
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            Layout.bottomMargin: 8
                            visible: Bt.list.length === 0
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: !Bt.adapter ? "No Bluetooth adapter found" : !Bt.powered ? "Bluetooth is off  (p to turn it on)" : Bt.scanning ? "Searching for devices…" : "No devices  (s to scan)"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }

                        Text {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            wrapMode: Text.Wrap
                            text: "j k select • Enter connect / pair • f forget • s scan • p power • Esc close"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 3
                        }
                    }
                }
            }
        }
    }
}
