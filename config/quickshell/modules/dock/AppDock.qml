import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// A macOS-style dock at the bottom of every monitor: pinned apps, then the other running ones.
// Auto-hide (the default): hidden while windows are open, touching the bottom edge brings it up,
// stays up on an empty workspace. Always (Dock.alwaysShow, set in the theme panel): stays up and
// windows keep clear of it. Over a fullscreen window it only comes up from the edge, after a slightly longer push.
//   left click   start the app, or focus its window (again: the next one)
//   middle click a new window
//   right click  pin / unpin, its windows, close
//   drag a pin   reorder
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData
        screen: modelData

        WlrLayershell.layer: WlrLayer.Overlay     // Top sits under fullscreen windows
        WlrLayershell.namespace: "qs-dock"
        // always shown: windows tile above the plate, like macOS's dock; else no space is kept. The mode
        // stays Normal and only the zone changes: setting exclusiveZone also sets exclusionMode to Normal,
        // so a mode that varied (Ignore when hidden) lost to it depending on load order and the space
        // stayed after a reload; left at its default the mode is Auto, which keeps the window's height
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: Dock.alwaysShow && items.length > 0 ? margin + dotRow + iconSize + pad * 2 : 0
        color: "transparent"

        anchors {
            bottom: true
            left: true
            right: true
        }
        // room above the plate for magnified icons, the name tooltip and the right-click menu
        implicitHeight: 360

        // ---------- sizes ----------

        readonly property int iconSize: 42
        readonly property real maxScale: 1.5        // the icon under the pointer
        readonly property real reach: 2.6           // how many icons either side grow with it
        readonly property int pad: 9                // pill padding around the icons
        readonly property int dotRow: 10            // under the pill: the running dots
        readonly property int spacing: 6
        readonly property int margin: 8             // from the screen edge: Hyprland's gaps_out
        readonly property int sepWidth: 1 + spacing * 2

        // ---------- what it shows ----------

        readonly property var items: {
            const out = Dock.pinnedItems.slice();
            if (Dock.pinnedItems.length > 0 && Dock.runningItems.length > 0)
                out.push({
                    separator: true,
                    key: "--sep--"
                });
            return out.concat(Dock.runningItems);
        }

        // where each icon's center would be with nothing magnified, in window coordinates.
        // Magnification reads the pointer against this resting layout, so icons growing under
        // the pointer never move what is under it.
        readonly property var restCenters: {
            // same widths as the cells: an icon is followed by a gap, unless it is last or before
            // the separator (whose width carries a gap on each side)
            const out = [];
            let x = 0;
            for (let i = 0; i < items.length; i++) {
                const sep = items[i].separator === true;
                const w = sep ? sepWidth : iconSize;
                out.push(x + w / 2);
                x += w + (sep || i === items.length - 1 || items[i + 1].separator ? 0 : spacing);
            }
            const start = (width - x) / 2;
            return out.map(c => c + start);
        }

        // ---------- shown / hidden ----------

        // looked up in the live list, not with monitorFor(): when the screens wake, the outputs go
        // away and come back, and the object monitorFor() handed out can be dropped while the dock
        // still holds it. This follows the monitor that is tracked now.
        readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.name === screen?.name) ?? null
        readonly property bool fullscreen: Fullscreen.on(screen?.name ?? "")
        // not known yet (monitor or workspace still missing after a reconnect) counts as not empty:
        // the dock stays hidden rather than stuck up
        readonly property var workspace: monitor?.activeWorkspace ?? null
        readonly property bool emptyWorkspace: workspace !== null && workspace.toplevels.values.length === 0

        property bool revealed: false

        // ---------- dragging a pin ----------

        property string dragKey: ""             // the pin being dragged, "" when none
        property int dragFrom: -1               // its slot when the drag started
        property real dragX: 0                  // the pointer, in window coordinates
        property bool dropping: false           // the frame the new order lands: offsets reset without animating

        readonly property real slot: iconSize + spacing
        // pins come first and are all the same width, so their slots don't depend on the order
        readonly property real pinsStart: restCenters.length > 0 ? restCenters[0] : 0
        readonly property int dragTarget: dragKey === "" ? -1 : Math.max(0, Math.min(Dock.pinnedItems.length - 1, Math.round((dragX - pinsStart) / slot)))

        // how far the icon in `index` is pushed aside to open the dragged pin's new slot
        function shiftAt(index) {
            if (dragKey === "" || index === dragFrom || index >= Dock.pinnedItems.length)
                return 0;
            if (dragFrom < dragTarget && index > dragFrom && index <= dragTarget)
                return -slot;
            if (dragTarget < dragFrom && index >= dragTarget && index < dragFrom)
                return slot;
            return 0;
        }

        function drop() {
            const key = dragKey, to = dragTarget;
            dropping = true;
            Dock.movePin(key, to);
            dragKey = "";
            dragFrom = -1;
            Qt.callLater(() => dropping = false);
        }
        property var menuItem: null            // the icon whose right-click menu is open
        property real menuCenter: 0

        readonly property bool shown: items.length > 0 && (revealed || menuItem !== null || (!fullscreen && (emptyWorkspace || Dock.alwaysShow)) || Dock.forced || dragKey !== "")

        onFullscreenChanged: if (fullscreen) {
            revealed = false;
            menuItem = null;
        }

        Timer {
            id: showTimer
            interval: win.fullscreen ? 250 : 100  // brushing the edge on the way to something else doesn't count
            onTriggered: win.revealed = true
        }
        Timer {
            id: hideTimer
            interval: 450
            onTriggered: {
                win.revealed = false;
                win.menuItem = null;
            }
        }

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    hideTimer.stop();
                    showTimer.restart();
                } else {
                    showTimer.stop();
                    hideTimer.restart();
                }
            }
        }

        // only the plate (and the menu) takes input; hidden, a 2 px strip under where it sits
        mask: Region {
            item: hit

            Region {
                x: menu.x
                y: menu.y
                width: win.menuItem ? menu.width : 0
                height: win.menuItem ? menu.height : 0
            }
        }

        Item {
            id: hit
            x: plate.x
            width: plate.width
            height: win.shown ? win.iconSize * win.maxScale + win.pad * 2 + win.dotRow + win.margin : 2
            y: win.height - height
        }

        // ---------- magnification ----------

        HoverHandler {
            id: pointer
            enabled: win.shown
        }

        // 0..1: eases in as the pointer arrives and out as it leaves, so icons don't snap
        property real magnify: pointer.hovered && win.menuItem === null && win.dragKey === "" && plate.y === plateRestY ? 1 : 0
        Behavior on magnify {
            Anim {
                duration: Motion.normal
                curve: Motion.enter
            }
        }

        function scaleAt(index) {
            if (magnify === 0)
                return 1;
            const d = Math.abs(pointer.point.position.x - restCenters[index]) / (iconSize + spacing);
            const f = d >= reach ? 0 : (Math.cos(Math.PI * d / reach) + 1) / 2;
            return 1 + (maxScale - 1) * f * magnify;
        }

        // ---------- the plate ----------

        readonly property real plateRestY: height - margin - dotRow - plate.height

        Rectangle {
            id: plate

            readonly property int pad: win.pad

            // grows with the magnified icons, like the real thing
            width: row.width + pad * 2
            height: win.iconSize + pad * 2
            x: (win.width - width) / 2
            y: win.shown ? win.plateRestY : win.height + 1

            // the bar's look: its background, and the 1 px line the bar and the dropdowns are drawn with
            radius: Theme.radiusLarge            // same as the dropdowns
            color: Theme.bg
            border.width: 1
            border.color: Theme.line

            Behavior on y {
                Anim {
                    duration: win.shown ? Motion.normal : Motion.out
                    curve: win.shown ? Motion.enter : Motion.exit
                }
            }

            Row {
                id: row
                anchors {
                    bottom: parent.bottom
                    bottomMargin: plate.pad
                    horizontalCenter: parent.horizontalCenter
                }
                spacing: 0

                Repeater {
                    model: ScriptModel {
                        values: win.items
                        objectProp: "key"
                    }

                    delegate: Item {
                        id: cell

                        required property var modelData
                        required property int index

                        readonly property bool isSep: modelData.separator === true
                        readonly property real scale_: isSep ? 1 : win.scaleAt(index)
                        readonly property var windows: isSep ? [] : (Dock.windowsByApp[modelData.key] ?? [])
                        readonly property bool running: windows.length > 0
                        readonly property bool focused: !isSep && Dock.activeKey === modelData.key
                        readonly property bool urgent: windows.some(w => w.urgent)
                        readonly property bool last: index === win.items.length - 1
                        readonly property bool beforeSep: win.items[index + 1]?.separator === true

                        width: isSep ? win.sepWidth : win.iconSize * scale_ + (last || beforeSep ? 0 : win.spacing)
                        height: win.iconSize * (isSep ? 1 : scale_)

                        // dragged: follows the pointer. Its neighbours slide over to make room
                        readonly property bool dragged: !isSep && win.dragKey === modelData.key
                        property real shift: dragged ? win.dragX - win.restCenters[index] : win.shiftAt(index)
                        Behavior on shift {
                            enabled: !cell.dragged && !win.dropping
                            Anim {}
                        }
                        transform: Translate {
                            x: cell.shift
                        }
                        z: dragged ? 1 : 0

                        // ---- separator ----
                        Rectangle {
                            visible: cell.isSep
                            anchors.centerIn: parent
                            width: 1
                            height: win.iconSize * 0.6
                            color: Theme.line
                        }

                        // ---- icon ----
                        Item {
                            id: tile
                            visible: !cell.isSep
                            width: win.iconSize * cell.scale_
                            height: width
                            anchors.bottom: parent.bottom

                            property real hop: 0       // the launch bounce

                            AppIcon {
                                anchors.fill: parent
                                anchors.bottomMargin: -tile.hop
                                anchors.topMargin: tile.hop
                                implicitSize: win.iconSize
                                source: cell.isSep ? "" : Icons.source(cell.modelData.icon, "application-x-executable")
                                opacity: area.pressed ? 0.7 : 1
                            }

                            SequentialAnimation {
                                id: bounce
                                loops: 2
                                Anim {
                                    target: tile
                                    property: "hop"
                                    to: -16
                                    duration: 220
                                    curve: Motion.enter
                                }
                                Anim {
                                    target: tile
                                    property: "hop"
                                    to: 0
                                    duration: 260
                                    curve: [0.5, 0, 0.75, 0, 1, 1]
                                }
                            }
                            // stops once the window shows up
                            Connections {
                                target: cell
                                function onRunningChanged() {
                                    if (cell.running && bounce.running) {
                                        bounce.stop();
                                        tile.hop = 0;
                                    }
                                }
                            }

                            MouseArea {
                                id: area
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                                preventStealing: true

                                // a pin pressed and moved a few px becomes a drag (and is no click)
                                property real pressX: 0
                                property bool wasDrag: false

                                function windowX(mouse) {
                                    return mapToItem(null, mouse.x, mouse.y).x;
                                }

                                onPressed: mouse => {
                                    pressX = windowX(mouse);
                                    wasDrag = false;
                                }
                                onPositionChanged: mouse => {
                                    if (!(pressed && pressedButtons & Qt.LeftButton) || !cell.modelData.pinned)
                                        return;
                                    const x = windowX(mouse);
                                    if (win.dragKey === "" && Math.abs(x - pressX) > 6) {
                                        win.menuItem = null;
                                        win.dragX = x;
                                        win.dragFrom = cell.index;
                                        win.dragKey = cell.modelData.key;
                                        wasDrag = true;
                                    }
                                    if (win.dragKey === cell.modelData.key)
                                        win.dragX = x;
                                }
                                onReleased: if (win.dragKey === cell.modelData.key)
                                    win.drop()
                                onCanceled: if (win.dragKey === cell.modelData.key) {
                                    win.dragKey = "";
                                    win.dragFrom = -1;
                                }

                                onClicked: mouse => {
                                    if (wasDrag)
                                        return;
                                    if (mouse.button === Qt.RightButton) {
                                        const open = win.menuItem?.key === cell.modelData.key;
                                        win.menuCenter = win.restCenters[cell.index];
                                        win.menuItem = open ? null : cell.modelData;
                                        return;
                                    }
                                    win.menuItem = null;
                                    if (mouse.button === Qt.MiddleButton || !cell.running) {
                                        if (cell.modelData.entry) {
                                            bounce.restart();
                                            Dock.launch(cell.modelData);
                                        }
                                    } else {
                                        Dock.activate(cell.modelData);
                                    }
                                }
                            }
                        }

                        // ---- running indicator: a dot, a short pill on the focused app ----
                        Rectangle {
                            visible: !cell.isSep
                            anchors.horizontalCenter: tile.horizontalCenter
                            y: cell.height + plate.pad + (win.dotRow - height) / 2 + 1
                            height: 4
                            width: cell.focused ? 12 : 4
                            radius: 2
                            opacity: cell.running ? 1 : 0
                            color: cell.urgent ? Theme.urgent : cell.focused ? Theme.accent : Theme.dim

                            Behavior on width {
                                Anim {}
                            }
                            Behavior on opacity {
                                Anim {
                                    duration: Motion.fast
                                }
                            }
                            Behavior on color {
                                CAnim {}
                            }
                        }

                        // ---- name, above the icon ----
                        Rectangle {
                            visible: opacity > 0
                            opacity: area.containsMouse && win.menuItem === null && win.dragKey === "" ? 1 : 0
                            anchors.horizontalCenter: tile.horizontalCenter
                            y: tile.y - height - 10
                            width: label.implicitWidth + 16
                            height: label.implicitHeight + 8
                            radius: Theme.radius
                            color: Theme.bg
                            border.width: 1
                            border.color: Theme.line

                            Behavior on opacity {
                                Anim {
                                    duration: Motion.fast
                                }
                            }

                            Txt {
                                id: label
                                anchors.centerIn: parent
                                // a window title can be long
                                width: Math.min(implicitWidth, 320)
                                elide: Text.ElideRight
                                variant: "row"
                                text: Dock.nameFor(cell.modelData)
                            }
                        }
                    }
                }
            }
        }

        // ---------- right-click menu ----------

        Rectangle {
            id: menu

            readonly property var item: win.menuItem
            readonly property var windows: item ? (Dock.windowsByApp[item.key] ?? []) : []

            visible: opacity > 0
            opacity: item ? 1 : 0
            width: 220
            height: col.implicitHeight + 12
            x: Math.max(8, Math.min(win.width - width - 8, win.menuCenter - width / 2))
            y: plate.y - height - 10
            radius: Theme.radiusLarge
            color: Theme.bg
            border.width: 1
            border.color: Theme.line

            Behavior on opacity {
                Anim {
                    duration: Motion.fast
                }
            }

            // keeps showing the last app while fading out
            property var shownItem: null
            onItemChanged: if (item)
                shownItem = item

            Column {
                id: col
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 6
                }
                spacing: 2

                Txt {
                    x: 8
                    width: parent.width - 16
                    height: 26
                    verticalAlignment: Text.AlignVCenter
                    variant: "dim"
                    text: Dock.nameFor(menu.shownItem)
                    elide: Text.ElideRight
                }

                // its windows: click one to go to it
                Repeater {
                    model: menu.windows.slice(0, 8)

                    delegate: DockMenuRow {
                        required property var modelData
                        width: col.width
                        text: modelData.title || modelData.lastIpcObject?.title || "Window"
                        active: modelData === Hyprland.activeToplevel
                        onClicked: {
                            Windows.focus(modelData);
                            win.menuItem = null;
                        }
                    }
                }

                Rectangle {
                    visible: menu.windows.length > 0
                    width: parent.width
                    height: 1
                    color: Theme.line
                }

                DockMenuRow {
                    width: col.width
                    visible: menu.shownItem?.entry != null
                    text: menu.shownItem && Dock.isPinned(menu.shownItem.key) ? "Unpin from dock" : "Pin to dock"
                    onClicked: {
                        Dock.togglePin(menu.shownItem.key);
                        win.menuItem = null;
                    }
                }

                DockMenuRow {
                    width: col.width
                    visible: menu.shownItem?.entry != null
                    text: "New window"
                    onClicked: {
                        Dock.launch(menu.shownItem);
                        win.menuItem = null;
                    }
                }

                DockMenuRow {
                    width: col.width
                    visible: menu.windows.length > 0
                    text: menu.windows.length > 1 ? "Close " + menu.windows.length + " windows" : "Close"
                    danger: true
                    onClicked: {
                        Dock.closeAll(menu.shownItem);
                        win.menuItem = null;
                    }
                }
            }
        }
    }
}
