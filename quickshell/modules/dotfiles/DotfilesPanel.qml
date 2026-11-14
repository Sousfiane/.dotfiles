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

                                Txt {
                                    text: Icons.git
                                    color: Dotfiles.failed ? Theme.urgent : Dotfiles.count > 0 ? Theme.accent : Theme.dim
                                    font.pixelSize: Theme.fontSize + 6
                                }

                                ColumnLayout {
                                    spacing: 0

                                    Txt {
                                        text: "Dotfiles"
                                        variant: "title"
                                    }

                                    Txt {
                                        variant: "small"
                                        color: Dotfiles.failed ? Theme.urgent : Theme.dim
                                        text: Dotfiles.failed ? "Could not read the repository" : Dotfiles.count === 0 ? "Working tree clean" : Dotfiles.count + (Dotfiles.count === 1 ? " change" : " changes")
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Pill {
                                    text: Dotfiles.checking ? "Checking…" : "Refresh"
                                    active: Dotfiles.checking
                                    onClicked: Dotfiles.refresh()
                                }

                                Pill {
                                    text: "Lazygit"
                                    primary: true
                                    onClicked: Dotfiles.openLazygit()
                                }
                            }

                            Divider {}

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

                                    // status letters, then whitespace, then the path (tolerates a stripped leading space)
                                    readonly property var parts: modelData.match(/^\s*(\S{1,2})\s+(.*)$/) ?? ["", "", modelData]
                                    readonly property string code: parts[1]
                                    readonly property string path: parts[2]

                                    width: ListView.view.width
                                    implicitHeight: 30
                                    radius: 6
                                    color: rowHover.hovered ? Theme.surface : "transparent"

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

                                        Txt {
                                            Layout.preferredWidth: 22
                                            text: row.code
                                            color: row.code.indexOf("D") !== -1 ? Theme.urgent : row.code.indexOf("?") !== -1 ? Theme.dim : Theme.accent
                                            font.pixelSize: Theme.fontSize - 2
                                            font.bold: true
                                        }

                                        Txt {
                                            Layout.fillWidth: true
                                            variant: "row"
                                            text: row.path
                                            elide: Text.ElideMiddle
                                        }
                                    }
                                }
                            }

                            Txt {
                                Layout.fillWidth: true
                                Layout.topMargin: 8
                                Layout.bottomMargin: 8
                                visible: Dotfiles.count === 0
                                horizontalAlignment: Text.AlignHCenter
                                text: Dotfiles.failed ? "Check the repository path in Config.qml" : "Nothing to commit"
                            }

                            Hint {
                                text: "j k scroll • Enter / g lazygit • r refresh • Esc close"
                            }
                        }
                    }
                }
            }
        }
    }
}
