import Quickshell
import Quickshell.Io        // <-- add this
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Scope {
    id: root
    property bool open: false

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.open = !root.open;
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            id: win
            implicitWidth: 520
            implicitHeight: 400
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

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
                    Quickshell.execDetached({
                        command: ["uwsm", "app", "--", ...entry.command],
                        workingDirectory: entry.workingDirectory
                    });
                }
                root.open = false;
            }

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.bg
                border.color: Theme.border
                border {
                    color: Theme.border
                    width: 2
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8

                    TextInput {
                        id: input
                        Layout.fillWidth: true
                        color: Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize + 3
                        focus: true
                        Component.onCompleted: forceActiveFocus()

                        onTextChanged: list.currentIndex = 0
                        Keys.onEscapePressed: root.open = false
                        Keys.onDownPressed: list.incrementCurrentIndex()
                        Keys.onUpPressed: list.decrementCurrentIndex()
                        Keys.onReturnPressed: win.launch()
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
