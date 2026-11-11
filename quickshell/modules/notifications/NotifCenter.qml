import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Scope {
    id: root

    // `qs ipc call notifs toggle|dnd|clear`
    IpcHandler {
        target: "notifs"
        function toggle(): void {
            Notifs.centerOpen = !Notifs.centerOpen;
        }
        function dnd(): void {
            Notifs.dnd = !Notifs.dnd;
        }
        function clear(): void {
            Notifs.clearHistory();
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
        active: Notifs.centerOpen

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

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: Notifs.centerOpen = false

                // click outside the card to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: Notifs.centerOpen = false
                }

                Rectangle {
                    id: card
                    anchors {
                        top: parent.top
                        right: parent.right
                        topMargin: Theme.barHeight + 8
                        rightMargin: 8
                    }
                    width: 380
                    height: Math.min(col.implicitHeight + 24, 600)
                    radius: Theme.radius
                    color: Theme.bg
                    border {
                        color: Theme.border
                        width: 2
                    }

                    // swallow clicks on empty areas of the card
                    MouseArea {
                        anchors.fill: parent
                    }

                    ColumnLayout {
                        id: col
                        anchors {
                            fill: parent
                            margins: 12
                        }
                        spacing: 10

                        // header
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: "Notifications"
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 1
                                font.bold: true
                            }

                            Rectangle {
                                implicitWidth: dndLabel.implicitWidth + 16
                                implicitHeight: 24
                                radius: 12
                                color: Notifs.dnd ? Theme.accent : Theme.surface

                                Text {
                                    id: dndLabel
                                    anchors.centerIn: parent
                                    text: "Do not disturb"
                                    color: Notifs.dnd ? Theme.bg : Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 2
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifs.dnd = !Notifs.dnd
                                }
                            }

                            Rectangle {
                                implicitWidth: clearLabel.implicitWidth + 16
                                implicitHeight: 24
                                radius: 12
                                color: Theme.surface

                                Text {
                                    id: clearLabel
                                    anchors.centerIn: parent
                                    text: "Clear"
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 2
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Notifs.clearHistory()
                                }
                            }
                        }

                        Text {
                            visible: Notifs.history.count === 0
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            Layout.bottomMargin: 8
                            horizontalAlignment: Text.AlignHCenter
                            text: "No notifications"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                        }

                        ListView {
                            id: list
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, 480)
                            visible: Notifs.history.count > 0
                            clip: true
                            spacing: 8
                            model: Notifs.history

                            delegate: Rectangle {
                                id: item
                                required property int index
                                required property string appName
                                required property string summary
                                required property string body
                                required property int urgency
                                required property string time

                                width: ListView.view.width
                                height: itemCol.implicitHeight + 20
                                radius: 6
                                color: Theme.surface
                                border.width: urgency === NotificationUrgency.Critical ? 1 : 0
                                border.color: Theme.urgent

                                ColumnLayout {
                                    id: itemCol
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        margins: 10
                                    }
                                    spacing: 2

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            Layout.fillWidth: true
                                            text: item.appName
                                            elide: Text.ElideRight
                                            color: Theme.dim
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 2
                                        }
                                        Text {
                                            text: item.time
                                            color: Theme.dim
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 2
                                        }
                                        Text {
                                            text: "×"
                                            color: Theme.dim
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize + 2

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -4
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: Notifs.removeAt(item.index)
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: item.summary
                                        wrapMode: Text.Wrap
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize
                                        font.bold: true
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: item.body !== ""
                                        text: item.body
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 4
                                        elide: Text.ElideRight
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 1
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
