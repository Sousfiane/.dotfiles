pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

// The strip of the scrolling layout, for the bar's minimap: the columns of the workspace a monitor shows,
// left to right, and what's on screen. Hyprland doesn't report columns, so they're worked out from its
// windows: the tiled ones sharing a left edge are one column, as wide as they are, stacked top to bottom.
// Positions are Hyprland's layout coordinates (logical pixels, the monitors side by side), the windows
// scrolled out of view lying outside their monitor.
//
// The positions come from Hyprland's window list, refreshed on the events that move windows (focus, a
// window opening, closing or moving, a workspace switching). Resizing a column (SUPER + R, dragging an
// edge) sends no event, so while a monitor shows two windows or more the list is also read twice a second.
Singleton {
    id: root

    // the columns of the workspace `monitor` (a HyprlandMonitor) shows:
    //   { key, x, w, focused, windows: [{ address, title, y, h, focused }] }
    // `key` stays with a column while it moves or resizes (its top window's address)
    function columns(monitor) {
        const ws = monitor?.activeWorkspace?.id;
        if (ws === undefined)
            return [];
        const active = Hyprland.activeToplevel?.address ?? "";
        const byX = {};
        for (const t of Hyprland.toplevels.values) {
            const o = t.lastIpcObject;
            if (!o || o.workspace?.id !== ws || o.floating || o.hidden || !o.mapped || !o.at || !o.size)
                continue;
            const address = "0x" + String(t.address).replace(/^0x/, "");
            const win = {
                address: address,
                title: o.title ?? "",
                y: o.at[1],
                h: o.size[1],
                focused: String(t.address).replace(/^0x/, "") === String(active).replace(/^0x/, "")
            };
            const col = byX[o.at[0]] ?? (byX[o.at[0]] = {
                    x: o.at[0],
                    w: 0,
                    windows: []
                });
            col.w = Math.max(col.w, o.size[0]);
            col.windows.push(win);
        }
        return Object.values(byX).sort((a, b) => a.x - b.x).map(c => {
            c.windows.sort((a, b) => a.y - b.y);
            c.key = c.windows[0].address;
            c.focused = c.windows.some(w => w.focused);
            return c;
        });
    }

    // the monitor's own area in the same coordinates (its size divided by its scale)
    function viewport(monitor) {
        const s = monitor?.scale || 1;
        return {
            x: monitor?.x ?? 0,
            y: monitor?.y ?? 0,
            w: (monitor?.width ?? 0) / s,
            h: (monitor?.height ?? 0) / s
        };
    }

    // focus a column (its focused window, else its top one): the layout scrolls it into view
    function focusColumn(col) {
        const w = col.windows.find(w => w.focused) ?? col.windows[0];
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${w.address}" })`);
    }

    // along the strip of the focused monitor, as SUPER + wheel does
    function step(right) {
        Hyprland.dispatch(`hl.dsp.layout("focus ${right ? "r" : "l"}")`);
    }

    // ---------- keeping the positions fresh ----------

    // a monitor shows two windows or more: only then can a column change size or scroll out of view
    readonly property bool busy: Hyprland.monitors.values.some(m => {
        const ws = m.activeWorkspace?.id;
        let n = 0;
        for (const t of Hyprland.toplevels.values)
            if (t.workspace?.id === ws && ++n > 1)
                return true;
        return false;
    })

    Timer {
        id: soon
        interval: 50                 // a burst of events (a switch sends several) is read once
        onTriggered: Hyprland.refreshToplevels()
    }

    Timer {
        running: root.busy
        interval: 500
        repeat: true
        onTriggered: Hyprland.refreshToplevels()
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            switch (event.name) {
            case "activewindowv2":
            case "openwindow":
            case "closewindow":
            case "movewindowv2":
            case "changefloatingmode":
            case "fullscreen":
            case "workspacev2":
            case "moveworkspacev2":
                soon.restart();
            }
        }
    }
}
