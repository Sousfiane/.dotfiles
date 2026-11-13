import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

Variants {
    model: Quickshell.screens

    Scope {
        id: scope
        required property var modelData

        SlideLoader {
            open: WsPanel.open && WsPanel.screenName === scope.modelData.name

            PanelWindow {
                id: win

                screen: scope.modelData
                anchors {
                    top: true
                    left: true
                }
                margins.top: Theme.barHeight

                // just big enough for the card and its flare, so the rest of the screen stays clickable
                implicitWidth: card.width + card.flare + 2
                implicitHeight: card.height + 2

                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "workspace-panel"

                readonly property var windows: Hyprland.toplevels.values.filter(w => w.workspace?.id === WsPanel.wsId)
                readonly property var ws: Hyprland.workspaces.values.find(w => w.id === WsPanel.wsId) ?? null

                // "Workspace 3" for numbered ones, the real name for named ones
                readonly property string title: ws && String(ws.name) !== String(ws.id) ? ws.name : "Workspace " + WsPanel.wsId

                SlideArea {
                    open: WsPanel.open && WsPanel.screenName === scope.modelData.name

                    DropCard {
                        id: card
                        edge: "left"
                        anchors {
                            top: parent.top
                            left: parent.left
                        }
                        width: 340
                        height: col.implicitHeight + 28

                        HoverHandler {
                            onHoveredChanged: WsPanel.hoverCard = hovered
                        }

                        ColumnLayout {
                            id: col
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                leftMargin: 16
                                rightMargin: 16
                                topMargin: 12
                            }
                            spacing: 8

                            // header: name on the left, window count on the right
                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    Layout.fillWidth: true
                                    text: win.title
                                    elide: Text.ElideRight
                                    color: Theme.fg
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize + 2
                                    font.bold: true
                                }

                                Text {
                                    text: win.windows.length === 0 ? "empty" : win.windows.length + (win.windows.length === 1 ? " window" : " windows")
                                    color: Theme.dim
                                    font.family: Theme.font
                                    font.pixelSize: Theme.fontSize - 2
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: 1
                                color: Theme.border
                                visible: win.windows.length > 0
                            }

                            // one row per window (first eight)
                            Repeater {
                                model: win.windows.slice(0, 8)

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
                                visible: win.windows.length > 8
                                text: "+ " + (win.windows.length - 8) + " more"
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
}
