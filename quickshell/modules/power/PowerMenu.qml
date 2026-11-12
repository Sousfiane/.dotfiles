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

    // `qs ipc call power toggle`
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

    LazyLoader {
        active: Power.open

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
            WlrLayershell.namespace: "power-menu"

            Item {
                id: content
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                property int index: 0

                Keys.onEscapePressed: Power.open = false
                Keys.onLeftPressed: index = Math.max(0, index - 1)
                Keys.onRightPressed: index = Math.min(Power.actions.length - 1, index + 1)
                Keys.onReturnPressed: Power.run(Power.actions[index])
                Keys.onEnterPressed: Power.run(Power.actions[index])

                // single-key shortcuts: L, S, O, R, P
                Keys.onPressed: event => {
                    const k = event.text.toUpperCase();
                    const a = Power.actions.find(x => x.key === k);
                    if (a) {
                        Power.run(a);
                        event.accepted = true;
                    }
                }

                // dimmed backdrop, click to close
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.45)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Power.open = false
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    implicitWidth: row.implicitWidth + 40
                    implicitHeight: row.implicitHeight + 40
                    radius: Theme.radius + 4
                    color: Theme.bg
                    border.color: Theme.border
                    border.width: 2

                    // swallow clicks on the card
                    MouseArea {
                        anchors.fill: parent
                    }

                    Row {
                        id: row
                        anchors.centerIn: parent
                        spacing: 12

                        Repeater {
                            model: Power.actions

                            delegate: Rectangle {
                                id: btn
                                required property var modelData
                                required property int index

                                readonly property bool current: content.index === index

                                width: 96
                                height: 104
                                radius: Theme.radius
                                color: current ? Theme.surface : "transparent"
                                border.width: current ? 2 : 0
                                border.color: Theme.accent

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: String.fromCodePoint(btn.modelData.icon)
                                        color: btn.current ? Theme.accent : Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: 32
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: btn.modelData.label
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: btn.modelData.key
                                        color: Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 3
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: content.index = btn.index
                                    onClicked: Power.run(btn.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
