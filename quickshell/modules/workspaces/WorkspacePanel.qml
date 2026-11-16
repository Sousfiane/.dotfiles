import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

Variants {
    model: Quickshell.screens

    DropdownPanel {
        required property var modelData

        name: "workspaces"
        ipc: false
        compact: true
        targetScreen: modelData
        edge: "left"
        cardWidth: 340

        open: WsPanel.open && WsPanel.screenName === modelData.name

        onCardHoverChanged: hovered => WsPanel.hoverCard = hovered

        ColumnLayout {
            id: ws
            spacing: 8

            readonly property var windows: Hyprland.toplevels.values.filter(w => w.workspace?.id === WsPanel.wsId)
            readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === WsPanel.wsId) ?? null

            // "Workspace 3" for numbered ones, the real name for named ones
            readonly property string title: workspace && String(workspace.name) !== String(workspace.id) ? workspace.name : "Workspace " + WsPanel.wsId

            // header: name on the left, window count on the right
            RowLayout {
                Layout.fillWidth: true

                Txt {
                    Layout.fillWidth: true
                    variant: "heading"
                    text: ws.title
                    elide: Text.ElideRight
                }

                Txt {
                    variant: "dim"
                    text: ws.windows.length === 0 ? "empty" : ws.windows.length + (ws.windows.length === 1 ? " window" : " windows")
                }
            }

            Divider {
                visible: ws.windows.length > 0
            }

            // one row per window (first eight)
            Repeater {
                model: ws.windows.slice(0, 8)

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

                        Txt {
                            Layout.fillWidth: true
                            variant: "row"
                            font.bold: true
                            text: line.cls || "Unknown"
                            elide: Text.ElideRight
                        }

                        Txt {
                            Layout.fillWidth: true
                            variant: "small"
                            text: line.modelData.title || ""
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Txt {
                visible: ws.windows.length > 8
                variant: "small"
                text: "+ " + (ws.windows.length - 8) + " more"
            }
        }
    }
}
