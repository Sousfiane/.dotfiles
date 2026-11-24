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

        open: Ws.open && Ws.screenName === modelData.name

        onCardHoverChanged: hovered => Ws.hoverCard = hovered

        ColumnLayout {
            id: ws
            spacing: 8

            readonly property var windows: Hyprland.toplevels.values.filter(w => w.workspace?.id === Ws.wsId)
            readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === Ws.wsId) ?? null

            // "Workspace 3" for numbered ones, the real name for named ones
            readonly property string title: workspace && String(workspace.name) !== String(workspace.id) ? workspace.name : "Workspace " + Ws.wsId

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
                    text: ws.windows.length === 0 ? "empty" : Fmt.plural(ws.windows.length, "window")
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
                    readonly property string rawCls: Ws.windowClass(modelData)
                    // floating terminals carry a custom class so Hyprland floats them: show them as the terminal
                    readonly property string cls: rawCls === Config.floatingClass ? Config.terminal : rawCls

                    // gives the icon and the readable name ("Files" rather than org.gnome.Nautilus)
                    readonly property var entry: cls !== "" ? DesktopEntries.heuristicLookup(cls) : null

                    Layout.fillWidth: true
                    spacing: 10

                    AppIcon {
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
                            text: line.entry?.name || line.cls || "Unknown"
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
