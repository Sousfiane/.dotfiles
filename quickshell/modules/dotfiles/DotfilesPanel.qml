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

    // `qs ipc call dotfiles toggle|close`
    IpcHandler {
        target: "dotfiles"
        function toggle(): void {
            Dotfiles.toggle();
        }
        function close(): void {
            Dotfiles.panelOpen = false;
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
        open: Dotfiles.panelOpen

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
            WlrLayershell.namespace: "dotfiles-panel"

            Item {
                id: content
                anchors.fill: parent
                focus: true
                Component.onCompleted: forceActiveFocus()

                function scrollBy(d) {
                    const max = Math.max(0, list.contentHeight - list.height);
                    list.contentY = Math.max(0, Math.min(max, list.contentY + d));
                }

                Keys.onEscapePressed: Dotfiles.panelOpen = false
                Keys.onUpPressed: scrollBy(-60)
                Keys.onDownPressed: scrollBy(60)
                Keys.onReturnPressed: Dotfiles.openLazygit()
                Keys.onEnterPressed: Dotfiles.openLazygit()

                Keys.onPressed: event => {
                    let handled = true;
                    switch (event.text) {
                    case "j":
                        scrollBy(60);
                        break;
                    case "k":
                        scrollBy(-60);
                        break;
                    case "g":
                        Dotfiles.openLazygit();
                        break;
                    case "r":
                        Dotfiles.refresh();
                        break;
                    case "q":
                        Dotfiles.panelOpen = false;
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
                    onClicked: Dotfiles.panelOpen = false
                }

                SlideArea {
                    open: Dotfiles.panelOpen

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
                                    // nf-md-git
                                    text: String.fromCodePoint(0xF02A2)
                                    color: Dotfiles.failed ? Theme.urgent : Dotfiles.count > 0 ? Theme.accent : Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 6
                                }

                                ColumnLayout {
                                    spacing: 0

                                    Text {
                                        text: "Dotfiles"
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize + 4
                                        font.bold: true
                                    }

                                    Text {
                                        text: Dotfiles.failed ? "Could not read the repository" : Dotfiles.count === 0 ? "Working tree clean" : Dotfiles.count + (Dotfiles.count === 1 ? " change" : " changes")
                                        color: Dotfiles.failed ? Theme.urgent : Theme.dim
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
                                    color: Dotfiles.checking ? Theme.accent : Theme.surface

                                    Text {
                                        id: refreshLabel
                                        anchors.centerIn: parent
                                        text: Dotfiles.checking ? "Checking…" : "Refresh"
                                        color: Dotfiles.checking ? Theme.bg : Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 3
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Dotfiles.refresh()
                                    }
                                }

                                // lazygit
                                Rectangle {
                                    implicitWidth: gitLabel.implicitWidth + 18
                                    implicitHeight: 24
                                    radius: 12
                                    color: Theme.accent

                                    Text {
                                        id: gitLabel
                                        anchors.centerIn: parent
                                        text: "Lazygit"
                                        color: Theme.bg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 3
                                        font.bold: true
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Dotfiles.openLazygit()
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Theme.border
                            }

                            // ---------- changed files ----------
                            ListView {
                                id: list
                                Layout.fillWidth: true
                                Layout.preferredHeight: Math.min(contentHeight, 420)
                                visible: Dotfiles.count > 0
                                clip: true
                                spacing: 2
                                model: Dotfiles.changes

                                delegate: Rectangle {
                                    id: row
                                    required property string modelData

                                    // porcelain format: two status letters, a space, then the path
                                    readonly property string code: modelData.substring(0, 2).trim()
                                    readonly property string path: modelData.substring(3)

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
                                            Layout.preferredWidth: 22
                                            text: row.code
                                            color: row.code.indexOf("D") !== -1 ? Theme.urgent : row.code.indexOf("?") !== -1 ? Theme.dim : Theme.accent
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 2
                                            font.bold: true
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: row.path
                                            elide: Text.ElideMiddle
                                            color: Theme.fg
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize - 1
                                        }
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: 8
                                Layout.bottomMargin: 8
                                visible: Dotfiles.count === 0
                                horizontalAlignment: Text.AlignHCenter
                                text: Dotfiles.failed ? "Check the repository path in Dotfiles.qml" : "Nothing to commit"
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize
                            }

                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                wrapMode: Text.Wrap
                                text: "j k scroll • Enter / g lazygit • r refresh • Esc close"
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
