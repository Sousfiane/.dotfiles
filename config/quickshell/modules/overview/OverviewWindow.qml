import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// Mission Control on one monitor (Overview.qml): its workspaces, each a cell with its number and its strip
// as the layout has it, at one scale for every cell so the windows compare. The cells fill a grid of 1, 2 or
// 3 columns, whichever shows the windows largest (a few short strips side by side, long ones a row each),
// in reading order. A frame marks the part of each strip the monitor shows; what's scrolled out of view is
// fainter. The row under the grid takes a window dropped on it to a new workspace.
PanelWindow {
    id: win

    required property var overview

    // looked up in the live list, as the bar does (the object monitorFor() hands out can go away)
    readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.name === screen?.name) ?? null
    readonly property bool hasKeys: overview.open && overview.screenName === (screen?.name ?? "")

    // 0 closed .. 1 open: everything fades and settles on it
    property real shown: overview.open ? 1 : 0
    Behavior on shown {
        Anim {
            curve: win.overview.open ? Motion.enter : Motion.exit
            duration: win.overview.open ? Motion.normal : Motion.out
        }
    }
    visible: shown > 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-overview"           // blurred behind, as every qs-* layer (rules.lua)
    WlrLayershell.keyboardFocus: hasKeys ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"

    // ---------- what's shown: this monitor's workspaces and their windows ----------

    readonly property var view: Strip.viewport(monitor)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1
    readonly property var rows: !visible ? [] : Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor?.name === screen?.name).sort((a, b) => a.id - b.id).map(w => {
        const windows = Strip.windows(w.id);
        return {
            id: w.id,
            windows: windows,
            min: Math.min(view.x, ...windows.map(x => x.x)),
            max: Math.max(view.x + view.w, ...windows.map(x => x.x + x.w))
        };
    })

    // ---------- layout: a grid of cells, one scale for every cell ----------

    readonly property int marginX: 72
    readonly property int marginTop: Theme.barHeight + 36
    readonly property int marginBottom: 96             // clear of the dock
    readonly property int labelWidth: 56
    readonly property int rowGap: 28
    readonly property int colGap: 40
    readonly property int newRowHeight: 48
    readonly property real maxScale: 0.42              // a single workspace isn't blown up to the whole screen

    readonly property real widest: Math.max(1, ...rows.map(r => r.max - r.min))
    readonly property real gridHeight: height - marginTop - marginBottom - newRowHeight - rowGap

    // the grid for `cols` columns: { cols, perCol (rows of cells), cellW, cellH, scale }
    function gridFor(cols) {
        const lines = Math.ceil(rows.length / cols);
        const cellW = (width - 2 * marginX - (cols - 1) * colGap) / cols;
        const cellH = gridHeight / lines - rowGap;
        const scale = Math.min(maxScale, cellH / view.h, (cellW - labelWidth) / widest);
        return {
            cols: cols,
            lines: lines,
            cellW: cellW,
            cellH: cellH,
            scale: scale
        };
    }

    // the columns that show the windows largest (fewer columns when it's a tie)
    readonly property var grid: {
        if (!rows.length || view.h <= 0)
            return gridFor(1);
        let best = gridFor(1);
        for (let c = 2; c <= Math.min(3, rows.length); c++) {
            const g = gridFor(c);
            if (g.scale > best.scale * 1.05)
                best = g;
        }
        return best;
    }
    readonly property real scale: Math.max(0, grid.scale)
    // the cells only as tall as the windows need, the grid centred in the room
    readonly property real cellHeight: view.h * scale
    readonly property real gridTop: marginTop + Math.max(0, (gridHeight - grid.lines * (cellHeight + rowGap)) / 2)

    function cellX(i) {
        return marginX + (i % grid.cols) * (grid.cellW + colGap);
    }
    function cellY(i) {
        return gridTop + Math.floor(i / grid.cols) * (cellHeight + rowGap);
    }
    readonly property real newRowY: gridTop + grid.lines * (cellHeight + rowGap)

    // ---------- going somewhere ----------

    function goToWindow(address) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${address}" })`);
        overview.close();
    }

    function goToWorkspace(id) {
        Hyprland.dispatch(`hl.dsp.focus({ workspace = ${id} })`);
        overview.close();
    }

    // ---------- the keyboard: a window chosen, row by row ----------

    property string selected: ""
    onHasKeysChanged: if (hasKeys) {
        selected = Hyprland.activeToplevel ? "0x" + String(Hyprland.activeToplevel.address).replace(/^0x/, "") : "";
        keys.forceActiveFocus();
    }

    function locate(address) {
        for (let r = 0; r < rows.length; r++) {
            const i = rows[r].windows.findIndex(w => w.address === address);
            if (i >= 0)
                return [r, i];
        }
        return null;
    }

    function step(dx, dy) {
        const at = locate(selected);
        if (!at) {
            const first = rows.find(r => r.windows.length);
            selected = first ? first.windows[0].address : "";
            return;
        }
        let [r, i] = at;
        if (dx !== 0) {
            const wins = rows[r].windows;
            if (i + dx >= 0 && i + dx < wins.length) {
                selected = wins[i + dx].address;
                return;
            }
            // past the strip's end: the next workspace with windows that way, from its near end
            for (let n = r + dx; n >= 0 && n < rows.length; n += dx) {
                const next = rows[n].windows;
                if (next.length) {
                    selected = (dx > 0 ? next[0] : next[next.length - 1]).address;
                    return;
                }
            }
            return;
        }
        // the cell above or below (a grid line away) with windows, and in it the window nearest across
        const from = rows[r].windows[i];
        const mid = from.x + from.w / 2 - rows[r].min;
        for (let n = r + dy * grid.cols; n >= 0 && n < rows.length; n += dy * grid.cols) {
            const wins = rows[n].windows;
            if (!wins.length)
                continue;
            const best = wins.reduce((a, w) => Math.abs(w.x + w.w / 2 - rows[n].min - mid) < Math.abs(a.x + a.w / 2 - rows[n].min - mid) ? w : a);
            selected = best.address;
            return;
        }
    }

    Item {
        id: keys
        focus: true
        Keys.onPressed: event => {
            const k = event.key;
            if (k === Qt.Key_Escape)
                win.overview.close();
            else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
                if (win.selected)
                    win.goToWindow(win.selected);
            } else if (k === Qt.Key_H || k === Qt.Key_Left)
                win.step(-1, 0);
            else if (k === Qt.Key_L || k === Qt.Key_Right)
                win.step(1, 0);
            else if (k === Qt.Key_K || k === Qt.Key_Up)
                win.step(0, -1);
            else if (k === Qt.Key_J || k === Qt.Key_Down)
                win.step(0, 1);
            else
                return;
            event.accepted = true;
        }
    }

    // ---------- dragging a window to another row ----------

    property var dragged: null            // the window being dragged (one of rows[].windows)
    property real dragX: 0                // the pointer, in this window
    property real dragY: 0
    property real grabX: 0                // where the window was grabbed, in it
    property real grabY: 0
    property real dragScale: 1

    // the cell under the pointer: an index into rows, rows.length for the new-workspace row, -1 for none
    readonly property int dropRow: {
        if (!dragged)
            return -1;
        for (let i = 0; i < rows.length; i++) {
            const x = cellX(i), y = cellY(i);
            if (dragX >= x - colGap / 2 && dragX < x + grid.cellW + colGap / 2 && dragY >= y - rowGap / 2 && dragY < y + cellHeight + rowGap / 2)
                return i;
        }
        if (dragY >= newRowY - rowGap / 2 && dragY < newRowY + newRowHeight + rowGap)
            return rows.length;
        return -1;
    }

    function drop() {
        const w = dragged, target = dropRow;
        dragged = null;
        if (!w || target < 0)
            return;
        const ws = target === rows.length ? '"emptym"' : rows[target].id;
        if (target < rows.length && rows[target].windows.some(x => x.address === w.address))
            return;                          // its own row
        Hyprland.dispatch(`hl.dsp.window.move({ workspace = ${ws}, window = "address:${w.address}", follow = false })`);
    }

    // ---------- drawing ----------

    // the backdrop: the desktop blurred and darkened; a click on it closes
    Rectangle {
        anchors.fill: parent
        color: Theme.withAlpha(Theme.base, 0.78)
        opacity: win.shown

        MouseArea {
            anchors.fill: parent
            onClicked: win.overview.close()
        }
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: win.shown
        scale: 0.97 + 0.03 * win.shown

        Repeater {
            model: ScriptModel {
                values: win.rows
                objectProp: "id"
            }

            delegate: Item {
                id: row

                required property var modelData
                required property int index

                readonly property bool active: modelData.id === win.activeId
                readonly property real stripW: (modelData.max - modelData.min) * win.scale
                // the strip centred in the room for it, right of the number
                readonly property real stripX: win.labelWidth + (win.grid.cellW - win.labelWidth - stripW) / 2

                function mapX(x) {
                    return stripX + (x - modelData.min) * win.scale;
                }

                x: win.cellX(index)
                y: win.cellY(index)
                width: win.grid.cellW
                height: win.cellHeight

                Behavior on x {
                    Anim {}
                }
                Behavior on y {
                    Anim {}
                }

                // the cell lights up under a dragged window
                Rectangle {
                    x: -14
                    width: parent.width + 28
                    height: parent.height + 16
                    y: -8
                    radius: Theme.radiusLarge
                    color: Theme.withAlpha(Theme.accent, 0.08)
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.accent, 0.5)
                    opacity: win.dropRow === row.index && !row.modelData.windows.some(w => w.address === win.dragged?.address) ? 1 : 0
                    Behavior on opacity {
                        Anim {
                            duration: Motion.fast
                        }
                    }
                }

                // the workspace's number; a click there or on the cell's empty space goes to it
                Txt {
                    x: 0
                    width: win.labelWidth - 16
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignRight
                    variant: "title"
                    font.pixelSize: Theme.fontSize + 10
                    text: row.modelData.id
                    color: row.active ? Theme.accent : Theme.dim
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.goToWorkspace(row.modelData.id)
                }

                // what the monitor shows of this workspace
                Rectangle {
                    x: row.mapX(win.view.x) - 3
                    y: -3
                    width: win.view.w * win.scale + 6
                    height: win.view.h * win.scale + 6
                    radius: Theme.radiusLarge
                    color: Theme.withAlpha(Theme.fg, 0.04)
                    border.width: 1
                    border.color: row.active ? Theme.withAlpha(Theme.accent, 0.6) : Theme.withAlpha(Theme.fg, 0.14)
                }

                Txt {
                    visible: row.modelData.windows.length === 0
                    x: row.mapX(win.view.x)
                    width: win.view.w * win.scale
                    anchors.verticalCenter: parent.verticalCenter
                    horizontalAlignment: Text.AlignHCenter
                    variant: "dim"
                    text: "Empty"
                }

                Repeater {
                    model: ScriptModel {
                        values: row.modelData.windows
                        objectProp: "address"
                    }

                    delegate: Item {
                        id: tile

                        required property var modelData

                        readonly property bool onScreen: modelData.x + modelData.w > win.view.x + 1 && modelData.x < win.view.x + win.view.w - 1
                        readonly property bool lit: mouse.containsMouse || win.selected === modelData.address
                        readonly property bool lifted: win.dragged?.address === modelData.address

                        x: row.mapX(modelData.x)
                        y: (modelData.y - win.view.y) * win.scale
                        width: modelData.w * win.scale
                        height: modelData.h * win.scale
                        z: modelData.floating ? 2 : 1
                        opacity: lifted ? 0.3 : onScreen ? 1 : 0.55

                        Behavior on x {
                            Anim {}
                        }
                        Behavior on opacity {
                            Anim {
                                duration: Motion.fast
                            }
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: 8
                            color: Theme.surface

                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: win.visible ? (tile.modelData.toplevel?.wayland ?? null) : null
                                live: win.overview.open
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 8
                            color: "transparent"
                            border.width: tile.lit ? 2 : 1
                            border.color: tile.lit ? Theme.accent : Theme.withAlpha(Theme.fg, 0.12)
                        }

                        // the app, at the bottom edge as macOS does
                        AppIcon {
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                verticalCenter: parent.bottom
                            }
                            implicitSize: 32
                            source: Icons.source(Apps.entryForWindow(tile.modelData.toplevel)?.icon ?? Windows.appClass(tile.modelData.toplevel).toLowerCase(), "application-x-executable")
                        }

                        // its title, under the pointer or the keyboard
                        Rectangle {
                            visible: tile.lit && tile.modelData.title !== ""
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                bottom: parent.bottom
                                bottomMargin: 22
                            }
                            width: Math.min(title.implicitWidth + 16, tile.width + 40)
                            height: title.implicitHeight + 8
                            radius: height / 2
                            color: Theme.withAlpha(Theme.base, 0.9)

                            Txt {
                                id: title
                                anchors.centerIn: parent
                                width: parent.width - 16
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                variant: "row"
                                text: tile.modelData.title
                            }
                        }

                        MouseArea {
                            id: mouse

                            property real pressX: 0
                            property real pressY: 0
                            property bool moved: false

                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                            cursorShape: win.dragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                            preventStealing: true

                            onPressed: m => {
                                pressX = m.x;
                                pressY = m.y;
                                moved = false;
                            }
                            onPositionChanged: m => {
                                if (!pressed || !(pressedButtons & Qt.LeftButton))
                                    return;
                                const p = mapToItem(content, m.x, m.y);
                                if (!moved && Math.hypot(m.x - pressX, m.y - pressY) > 8) {
                                    moved = true;
                                    win.grabX = pressX;
                                    win.grabY = pressY;
                                    win.dragged = tile.modelData;
                                }
                                if (moved) {
                                    win.dragX = p.x;
                                    win.dragY = p.y;
                                }
                            }
                            onReleased: m => {
                                if (moved)
                                    win.drop();
                                else if (m.button === Qt.MiddleButton)
                                    Windows.close(tile.modelData.toplevel);
                                else
                                    win.goToWindow(tile.modelData.address);
                                moved = false;
                            }
                        }
                    }
                }
            }
        }

        // the last row: a new workspace, for a window dropped on it
        Rectangle {
            readonly property bool target: win.dropRow === win.rows.length

            x: win.marginX
            y: win.newRowY
            width: win.width - 2 * win.marginX
            height: win.newRowHeight
            radius: Theme.radiusLarge
            color: target ? Theme.withAlpha(Theme.accent, 0.1) : Theme.withAlpha(Theme.fg, 0.03)
            border.width: 1
            border.color: target ? Theme.accent : Theme.withAlpha(Theme.fg, 0.12)
            opacity: win.dragged ? 1 : 0.6

            Txt {
                anchors.centerIn: parent
                variant: "dim"
                text: "+  New workspace"
                color: parent.target ? Theme.accent : Theme.dim
            }
        }

        // the window being dragged, under the pointer
        Item {
            visible: win.dragged !== null
            z: 10
            x: win.dragX - win.grabX
            y: win.dragY - win.grabY
            width: (win.dragged?.w ?? 0) * win.scale
            height: (win.dragged?.h ?? 0) * win.scale

            ClippingRectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.surface
                opacity: 0.9

                ScreencopyView {
                    anchors.fill: parent
                    captureSource: win.dragged?.toplevel?.wayland ?? null
                    live: true
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "transparent"
                border.width: 2
                border.color: Theme.accent
            }
        }
    }

    // the keyboard's hints, at the bottom
    Hint {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: win.marginBottom - 40
        }
        visible: win.hasKeys
        opacity: win.shown
        text: "h j k l choose • Enter go • click go • drag to move • middle-click close • Esc"
    }
}
