import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root
    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    readonly property var mine: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === monitor).sort((a, b) => a.id - b.id)

    spacing: 6

    Repeater {
        model: root.mine

        delegate: Item {
            id: workspace

            required property var modelData

            readonly property var windows: Hyprland.toplevels.values.filter(w => w.workspace?.id === modelData.id)

            // "Workspace 3" for numbered ones, the real name for named ones
            readonly property string title: String(modelData.name) === String(modelData.id) ? "Workspace " + modelData.id : modelData.name

            implicitWidth: 16
            implicitHeight: 22

            Text {
                anchors.centerIn: parent

                text: workspace.modelData.focused ? "󱓻" : ""

                color: Theme.fg

                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: workspace.modelData.activate()
            }

            PopupWindow {
                visible: mouse.containsMouse

                // make sure window data (including the class) is fresh
                onVisibleChanged: if (visible)
                    Hyprland.refreshToplevels()

                anchor.item: workspace
                anchor.edges: Edges.Bottom
                anchor.gravity: Edges.Bottom

                implicitWidth: card.implicitWidth
                implicitHeight: card.implicitHeight
                color: "transparent"

                Rectangle {
                    id: card

                    implicitWidth: 320
                    implicitHeight: col.implicitHeight + 24

                    radius: Theme.radius
                    color: Theme.bg
                    border.color: Theme.border

                    ColumnLayout {
                        id: col
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 12
                        }
                        spacing: 8

                        // Header: name on the left, window count on the right
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                Layout.fillWidth: true
                                text: workspace.title
                                elide: Text.ElideRight
                                color: Theme.fg
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize + 1
                                font.bold: true
                            }

                            Text {
                                text: workspace.windows.length === 0 ? "empty" : workspace.windows.length + (workspace.windows.length === 1 ? " window" : " windows")
                                color: Theme.dim
                                font.family: Theme.font
                                font.pixelSize: Theme.fontSize - 2
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 1
                            color: Theme.border
                            visible: workspace.windows.length > 0
                        }

                        // One row per window (first eight)
                        Repeater {
                            model: workspace.windows.slice(0, 8)

                            delegate: RowLayout {
                                id: line

                                required property var modelData

                                // Wayland app id first, Hyprland's class as fallback
                                readonly property string cls: modelData.wayland?.appId || modelData.lastIpcObject?.class || ""

                                // only used for the icon
                                readonly property var entry: cls !== "" ? DesktopEntries.heuristicLookup(cls) : null

                                Layout.fillWidth: true
                                spacing: 10

                                IconImage {
                                    implicitSize: 22
                                    source: Quickshell.iconPath(line.entry?.icon ?? line.cls.toLowerCase(), "application-x-executable")
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: line.cls || "Unknown"
                                        elide: Text.ElideRight
                                        color: Theme.fg
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 1
                                        font.bold: true
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: line.modelData.title || ""
                                        elide: Text.ElideRight
                                        color: Theme.dim
                                        font.family: Theme.font
                                        font.pixelSize: Theme.fontSize - 2
                                    }
                                }
                            }
                        }

                        Text {
                            visible: workspace.windows.length > 8
                            text: "+ " + (workspace.windows.length - 8) + " more"
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                    }
                }
            }
        }
    }
}
