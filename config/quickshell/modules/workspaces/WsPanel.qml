import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The card that drops under a workspace dot while the pointer is on it: the workspace's name and its
// windows, each with its app icon and title.
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

                    // gives the icon and the readable name ("Files" rather than org.gnome.Nautilus): the same
                    // entry the dock picks, so a game from Heroic is found by its title
                    readonly property var entry: Dock.entryForWindow(modelData)
                    // no entry: a game of Steam or Heroic gives its cover and its name
                    readonly property var game: entry ? null : Games.gameFor(cls, modelData.title ?? "")

                    Layout.fillWidth: true
                    spacing: 10

                    AppIcon {
                        implicitSize: 22
                        source: Games.iconSource(line.entry?.icon ?? line.game?.art ?? line.cls.toLowerCase(), "application-x-executable")
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Txt {
                            Layout.fillWidth: true
                            variant: "row"
                            font.bold: true
                            // no entry or game (a cracked exe): the window's title, which is its name
                            text: line.entry?.name || line.game?.name || line.modelData.title || line.cls || "Unknown"
                            elide: Text.ElideRight
                        }

                        // the title under the name, unless it already is the name
                        Txt {
                            Layout.fillWidth: true
                            visible: line.entry !== null
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
