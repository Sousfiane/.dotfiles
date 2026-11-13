import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

Scope {
    id: root

    // `qs ipc call power toggle|close`
    IpcHandler {
        target: "power"
        function toggle(): void {
            Power.toggle();
        }
        function close(): void {
            Power.open = false;
        }
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor?.name;
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        return Quickshell.screens[0];
    }

    SlideLoader {
        open: Power.open

        PanelWindow {
            screen: root.focusedScreen()
            margins.top: Theme.barHeight       // <-- add this
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
            WlrLayershell.namespace: "power-menu"

            Item {
                id: content
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                property int sel: 0

                function move(d) {
                    sel = Math.max(0, Math.min(Power.actions.length - 1, sel + d));
                }

                Keys.onEscapePressed: Power.open = false
                Keys.onUpPressed: move(-1)
                Keys.onDownPressed: move(1)
                Keys.onReturnPressed: Power.run(Power.actions[sel])
                Keys.onEnterPressed: Power.run(Power.actions[sel])

                // j / k to select, or a single letter to run an action directly
                Keys.onPressed: event => {
                    if (event.text === "j") {
                        move(1);
                        event.accepted = true;
                        return;
                    }
                    if (event.text === "k") {
                        move(-1);
                        event.accepted = true;
                        return;
                    }
                    const a = Power.actions.find(x => x.key === event.text.toUpperCase());
                    if (a) {
                        Power.run(a);
                        event.accepted = true;
                    }
                }

                // click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: Power.open = false
                }

                SlideArea {
                    open: Power.open

                    DropCard {
                        id: card
                        edge: "right"
                        anchors {
                            top: parent.top
                            right: parent.right
                        }
                        width: 300
                        height: col.implicitHeight + 32
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

                            Text {
                                text: "Power"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 4
                                font.bold: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Theme.border
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Repeater {
                                    model: Power.actions

                                    delegate: Rectangle {
                                        id: btn
                                        required property var modelData
                                        required property int index

                                        readonly property bool current: content.sel === index

                                        Layout.fillWidth: true
                                        implicitHeight: 44
                                        radius: Theme.radius
                                        color: current ? Theme.surface : "transparent"
                                        border.width: current ? 1 : 0
                                        border.color: Theme.accent

                                        RowLayout {
                                            anchors {
                                                fill: parent
                                                leftMargin: 12
                                                rightMargin: 12
                                            }
                                            spacing: 12

                                            Text {
                                                Layout.preferredWidth: 26
                                                horizontalAlignment: Text.AlignHCenter
                                                text: String.fromCodePoint(btn.modelData.icon)
                                                color: btn.current ? Theme.accent : Theme.fg
                                                font.family: Theme.font
                                                font.pixelSize: Theme.fontSize + 6
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: btn.modelData.label
                                                color: Theme.fg
                                                font.family: Theme.font
                                                font.pixelSize: Theme.fontSize
                                                font.bold: btn.current
                                            }

                                            // shortcut key
                                            Rectangle {
                                                implicitWidth: 22
                                                implicitHeight: 22
                                                radius: 6
                                                color: Theme.surface
                                                border.width: 1
                                                border.color: Theme.border

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: btn.modelData.key
                                                    color: Theme.dim
                                                    font.family: Theme.font
                                                    font.pixelSize: Theme.fontSize - 3
                                                }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onEntered: content.sel = btn.index
                                            onClicked: Power.run(btn.modelData)
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                text: "j k select • Enter run • letter shortcut • Esc close"
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
}
