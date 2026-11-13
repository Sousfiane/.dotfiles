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

    // `qs ipc call updates toggle|close`
    IpcHandler {
        target: "updates"
        function toggle(): void {
            Updates.toggle();
        }
        function close(): void {
            Updates.panelOpen = false;
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
        open: Updates.panelOpen

        PanelWindow {
            screen: root.focusedScreen()
            margins.top: Theme.barHeight
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
            WlrLayershell.namespace: "updates-panel"

            Item {
                id: content
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                function scrollBy(d) {
                    const max = Math.max(0, list.contentHeight - list.height);
                    list.contentY = Math.max(0, Math.min(max, list.contentY + d));
                }

                Keys.onEscapePressed: Updates.panelOpen = false
                Keys.onUpPressed: scrollBy(-60)
                Keys.onDownPressed: scrollBy(60)

                Keys.onPressed: event => {
                    let handled = true;
                    switch (event.text) {
                    case "j":
                        scrollBy(60);
                        break;
                    case "k":
                        scrollBy(-60);
                        break;
                    case "r":
                        Updates.refresh();
                        break;
                    case "u":
                        Updates.runUpdate();
                        break;
                    case "q":
                        Updates.panelOpen = false;
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
                    onClicked: Updates.panelOpen = false
                }

                SlideArea {
                    open: Updates.panelOpen

                    DropCard {
                        id: card
                        edge: "right"
                        anchors {
                            top: parent.top
                            right: parent.right
                        }
                        width: 460
                        height: Math.min(col.implicitHeight + 32, parent.height - 16)

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
                                    // nf-md-update
                                    text: String.fromCodePoint(0xF06B0)
                                    color: Updates.failed ? Theme.urgent : Updates.count > 0 ? Theme.accent : Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 6
                                }

                                ColumnLayout {
                                    spacing: 0

                                    Text {
                                        text: "Updates"
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize + 4
                                        font.bold: true
                                    }

                                    Text {
                                        text: Updates.failed ? "Could not check for updates" : (Updates.checking && Updates.count === 0) ? "Checking…" : Updates.count === 0 ? "System is up to date" : Updates.count + (Updates.count === 1 ? " update available" : " updates available")
                                        color: Updates.failed ? Theme.urgent : Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 3
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                // refresh
                                Rectangle {
                                    implicitWidth: refreshLabel.implicitWidth + 18
                                    implicitHeight: 24
                                    radius: 12
                                    color: Updates.checking ? Theme.accent : Theme.surface

                                    Text {
                                        id: refreshLabel
                                        anchors.centerIn: parent
                                        text: Updates.checking ? "Checking…" : "Refresh"
                                        color: Updates.checking ? Theme.bg : Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 3
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Updates.refresh()
                                    }
                                }

                                // update
                                Rectangle {
                                    visible: Updates.count > 0
                                    implicitWidth: updateLabel.implicitWidth + 18
                                    implicitHeight: 24
                                    radius: 12
                                    color: Theme.accent

                                    Text {
                                        id: updateLabel
                                        anchors.centerIn: parent
                                        text: "Update"
                                        color: Theme.bg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 3
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Updates.runUpdate()
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Theme.border
                            }

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
                                    color: rowHover.containsMouse ? Theme.surface : "transparent"

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

                                        Text {
                                            Layout.fillWidth: true
                                            text: row.modelData.name
                                            elide: Text.ElideRight
                                            color: Theme.fg
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 1
                                        }

                                        Text {
                                            text: row.modelData.from + " → " + row.modelData.to
                                            color: Theme.dim
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 3
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: 8
                                Layout.bottomMargin: 8
                                visible: Updates.count === 0
                                horizontalAlignment: Text.AlignHCenter
                                text: Updates.failed ? "Check your network, then press r to retry" : Updates.checking ? "Checking for updates…" : "Nothing to update"
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                            }

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                text: "j k scroll • u update system • r refresh • Esc close"
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
