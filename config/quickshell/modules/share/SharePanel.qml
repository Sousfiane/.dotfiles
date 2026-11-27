import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The screen sharing picker (services/Share.qml), opened when an app asks to share the screen. Tabs as in
// Hyprland's own picker: the monitors, the windows, the workspaces, and a region to draw, each shown with a
// live preview where there is one. Picking one shares it; Esc cancels.
DropdownPanel {
    name: "share"
    ipc: false                  // opened by an app's request, through Share's own IPC target
    edge: "center"
    cardWidth: 4 * 200 + 32

    ColumnLayout {
        id: share
        spacing: 12

        // ---------- what each tab holds ----------

        readonly property var screens: Hyprland.monitors.values.map(m => ({
                    kind: "screen",
                    name: m.name,
                    label: m.name,
                    detail: `${m.width}×${m.height}`,
                    screen: Quickshell.screens.find(s => s.name === m.name) ?? null
                }))

        readonly property var windows: Share.windows.map(w => ({
                    kind: "window",
                    window: w
                }))

        readonly property var workspaces: Share.workspaces.map(w => {
            const hypr = Hyprland.workspaces.values.find(x => String(x.name) === w.name) ?? null;
            // shown on a monitor right now: that monitor is its preview
            const monitor = Hyprland.monitors.values.find(m => m.activeWorkspace && String(m.activeWorkspace.name) === w.name) ?? null;
            return {
                kind: "workspace",
                id: w.id,
                label: /^\d+$/.test(w.name) ? "Workspace " + w.name : w.name,
                detail: w.outputs.length > 0 ? "on " + w.outputs.join(", ") : "",
                screen: monitor ? (Quickshell.screens.find(s => s.name === monitor.name) ?? null) : null,
                toplevels: hypr ? Hyprland.toplevels.values.filter(t => t.workspace === hypr) : []
            };
        })

        readonly property var region: [
            {
                kind: "region",
                label: "Region",
                detail: "Draw it on the screen"
            }
        ]

        readonly property var lists: [screens, windows, workspaces, region]
        readonly property var items: lists[Share.tab]

        // the card keeps one height whichever tab is shown: the fullest tab's, up to three rows
        readonly property int rows: Math.min(3, Math.max(1, ...lists.map(l => Math.ceil(l.length / 4))))

        function activate(item) {
            if (!item)
                return;
            switch (item.kind) {
            case "screen":
                Share.shareScreen(item.name);
                break;
            case "window":
                Share.shareWindow(item.window.handle);
                break;
            case "workspace":
                Share.shareWorkspace(item.id);
                break;
            case "region":
                Share.shareRegion();
                break;
            }
        }

        Keys.onPressed: event => {
            const moves = {
                [Qt.Key_Left]: "Left",
                [Qt.Key_H]: "Left",
                [Qt.Key_Right]: "Right",
                [Qt.Key_L]: "Right",
                [Qt.Key_Up]: "Up",
                [Qt.Key_K]: "Up",
                [Qt.Key_Down]: "Down",
                [Qt.Key_J]: "Down"
            };
            if (event.key === Qt.Key_Tab)
                Share.tab = (Share.tab + 1) % Share.tabs.length;
            else if (event.key === Qt.Key_Backtab)
                Share.tab = (Share.tab + Share.tabs.length - 1) % Share.tabs.length;
            else if (moves[event.key])
                grid["moveCurrentIndex" + moves[event.key]]();
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                activate(items[grid.currentIndex]);
            else if (event.key === Qt.Key_Space)
                Share.remember = !Share.remember;
            else if (event.key === Qt.Key_R)
                Share.shareRegion();
            else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                // the tab's first nine, by number
                const item = items[event.key - Qt.Key_1];
                if (!item)
                    return;
                activate(item);
            } else
                return;
            event.accepted = true;
        }

        PanelHeader {
            icon: Icons.share
            title: "Share your screen"
            subtitle: "Pick what the app will see"

            Txt {
                variant: "dim"
                text: "Remember"
            }

            Toggle {
                checked: Share.remember
                onToggled: Share.remember = !Share.remember
            }
        }

        // ---------- tabs ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: Share.tabs

                delegate: Pill {
                    required property string modelData
                    required property int index

                    // the region is always one: no count on it
                    readonly property int count: index < 3 ? share.lists[index].length : 0

                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    fontSize: Theme.fontSize - 2
                    active: Share.tab === index
                    bold: active
                    text: modelData + (count > 0 ? "  " + count : "")
                    onClicked: Share.tab = index
                }
            }
        }

        GridView {
            id: grid

            Layout.fillWidth: true
            Layout.preferredHeight: share.rows * cellHeight
            visible: count > 0
            clip: true
            cellWidth: 200
            cellHeight: 160
            model: share.items
            boundsBehavior: Flickable.StopAtBounds
            onModelChanged: currentIndex = 0

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: GridTile {
                id: tile

                required property var modelData

                readonly property string kind: modelData.kind
                readonly property var win: modelData.window ?? null
                readonly property var toplevel: win?.toplevel ?? null
                // the same entry the dock and the workspace cards pick: the icon and readable name
                readonly property var entry: toplevel ? Apps.entryForWindow(toplevel) : (win ? Apps.entryFor(win.cls) : null)

                // what the live preview shows: a monitor, a window, or the monitor a workspace is on
                readonly property var source: kind === "window" ? (toplevel?.wayland ?? null) : (modelData.screen ?? null)

                onClicked: share.activate(modelData)

                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    spacing: 6

                    // ---------- the preview ----------
                    Item {
                        id: previewArea
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ScreencopyView {
                            id: preview

                            visible: tile.source !== null && hasContent
                            captureSource: tile.source
                            live: Share.open

                            // fitted in the area, keeping the source's shape
                            readonly property real ratio: sourceSize.height > 0 ? sourceSize.width / sourceSize.height : 16 / 9
                            width: Math.min(previewArea.width, previewArea.height * ratio)
                            height: width / ratio
                            anchors.centerIn: parent
                        }

                        // a workspace that isn't on screen: its windows' icons
                        Row {
                            anchors.centerIn: parent
                            visible: !preview.visible && tile.kind === "workspace" && tile.modelData.toplevels.length > 0
                            spacing: 6

                            Repeater {
                                model: tile.kind === "workspace" ? tile.modelData.toplevels.slice(0, 6) : []

                                delegate: AppIcon {
                                    required property var modelData
                                    implicitSize: 28
                                    source: Icons.source(Apps.entryForWindow(modelData)?.icon ?? Windows.appClass(modelData).toLowerCase(), "application-x-executable")
                                }
                            }
                        }

                        // nothing to show: a glyph for what it is
                        Txt {
                            anchors.centerIn: parent
                            visible: !preview.visible && !(tile.kind === "workspace" && tile.modelData.toplevels.length > 0)
                            text: ({
                                    screen: Icons.shotMonitor,
                                    window: Icons.shotWindow,
                                    workspace: Icons.apps,
                                    region: Icons.shotRegion
                                })[tile.kind]
                            color: tile.highlighted ? Theme.accent : Theme.dim
                            font.pixelSize: 40
                        }
                    }

                    // ---------- what it is ----------
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        AppIcon {
                            visible: tile.win !== null
                            implicitSize: 18
                            source: tile.win ? Icons.source(tile.entry?.icon ?? tile.win.cls.toLowerCase(), "application-x-executable") : ""
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Txt {
                                Layout.fillWidth: true
                                variant: "row"
                                font.bold: true
                                text: tile.win ? (tile.entry?.name || tile.win.cls || "Window") : tile.modelData.label
                                elide: Text.ElideRight
                            }

                            Txt {
                                Layout.fillWidth: true
                                variant: "small"
                                text: tile.win ? tile.win.title : tile.modelData.detail
                                elide: Text.ElideRight
                            }
                        }

                        KeyBadge {
                            visible: tile.kind === "region" || tile.index < 9
                            text: tile.kind === "region" ? "R" : String(tile.index + 1)
                        }
                    }
                }
            }
        }

        EmptyState {
            visible: grid.count === 0
            Layout.preferredHeight: share.rows * grid.cellHeight
            text: ["No monitors to share", "No windows to share", "No workspaces to share", ""][Share.tab]
        }

        Hint {
            text: "Tab switch tabs • arrows or h j k l select • Enter or 1–9 share • R region • Space remember • Esc cancel"
        }
    }
}
