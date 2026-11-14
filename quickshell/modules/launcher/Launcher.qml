import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

Scope {
    id: root
    property bool open: false

    // change to foot, alacritty, ghostty...
    readonly property string terminal: "kitty"
    onOpenChanged: Panels.launcherOpen = open
    Connections {
        target: Panels
        function onLauncherOpenChanged() {
            if (!Panels.launcherOpen)
                root.open = false;
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.open = !root.open;
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
        open: root.open

        PanelWindow {
            id: win

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
            WlrLayershell.namespace: "launcher"

            readonly property var results: {
                const q = input.text.toLowerCase();

                return DesktopEntries.applications.values.filter(a => !a.noDisplay && a.name.toLowerCase().includes(q)).sort((a, b) => {
                    const qa = a.name.toLowerCase();
                    const qb = b.name.toLowerCase();

                    // Matching names first
                    const pa = qa.startsWith(q) ? 0 : 1;
                    const pb = qb.startsWith(q) ? 0 : 1;

                    if (pa !== pb)
                        return pa - pb;

                    // Most frequently launched first
                    const ua = LauncherHistory.count(a.id);
                    const ub = LauncherHistory.count(b.id);
                    if (ua !== ub)
                        return ub - ua;

                    // Alphabetical fallback
                    return qa.localeCompare(qb);
                });
            }

            function launch() {
                const entry = results[list.currentIndex];
                if (entry) {
                    LauncherHistory.record(entry.id);

                    const cmd = entry.runInTerminal ? [root.terminal, "-e", ...entry.command] : entry.command;

                    Quickshell.execDetached({
                        command: ["uwsm", "app", "--", ...cmd],
                        workingDirectory: entry.workingDirectory
                    });
                }
                root.open = false;
            }

            Item {
                anchors.fill: parent

                // click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.open = false
                }

                SlideArea {
                    open: root.open

                    DropCard {
                        edge: "center"
                        anchors {
                            top: parent.top
                            horizontalCenter: parent.horizontalCenter
                        }
                        width: 560
                        height: 440

                        // swallow clicks on the card
                        MouseArea {
                            anchors.fill: parent
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40

                                radius: Theme.radius
                                color: Theme.surface

                                TextInput {
                                    id: input

                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12

                                    focus: true
                                    Component.onCompleted: forceActiveFocus()

                                    verticalAlignment: TextInput.AlignVCenter

                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 3

                                    clip: true
                                    selectByMouse: true

                                    onTextChanged: list.currentIndex = 0

                                    Keys.onEscapePressed: root.open = false
                                    Keys.onDownPressed: list.incrementCurrentIndex()
                                    Keys.onUpPressed: list.decrementCurrentIndex()
                                    Keys.onReturnPressed: win.launch()
                                    Keys.onEnterPressed: win.launch()

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "Apps..."
                                        color: Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize
                                        visible: input.text.length === 0
                                        enabled: false
                                    }
                                }
                            }

                            ListView {
                                id: list
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                clip: true
                                model: win.results
                                currentIndex: 0

                                delegate: Rectangle {
                                    id: row

                                    required property var modelData
                                    required property int index

                                    width: ListView.view.width
                                    height: 36
                                    radius: 6

                                    color: (mouseArea.containsMouse || ListView.isCurrentItem) ? Theme.surface : "transparent"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 120
                                        }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        spacing: 10

                                        IconImage {
                                            implicitSize: 24
                                            source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: row.modelData.name
                                            color: Theme.fg
                                            font.family: Theme.font
                                            font.pixelSize: Theme.fontSize
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: mouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor

                                        onEntered: list.currentIndex = row.index

                                        onClicked: {
                                            list.currentIndex = row.index;
                                            input.forceActiveFocus();
                                            win.launch();
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
}
