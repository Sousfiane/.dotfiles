pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

// Which monitors show a fullscreen window, for the bar that hides over it, and the actions its stand-in
// title bar runs on that window.
Singleton {
    id: root

    // monitor name -> true when its active workspace has a fullscreen window
    readonly property var states: {
        const out = {};
        for (const m of Hyprland.monitors.values)
            out[m.name] = m.activeWorkspace?.hasFullscreen ?? false;
        return out;
    }

    function on(name) {
        return states[name] === true;
    }

    // workspace id -> true once it has shown a fullscreen window: only there can a focus change drop or
    // bring back the fullscreen without an event, so only there does one need a refresh (focus follows
    // the mouse: elsewhere that would be two requests to Hyprland every time the pointer crosses a window)
    property var hadFullscreen: ({})
    onStatesChanged: {
        for (const m of Hyprland.monitors.values)
            if (m.activeWorkspace?.hasFullscreen)
                hadFullscreen[m.activeWorkspace.id] = true;
    }

    // the fullscreen window on monitor `name` (a HyprlandToplevel), null when there is none
    function window(name) {
        const ws = Hyprland.monitors.values.find(m => m.name === name)?.activeWorkspace;
        if (!(ws?.hasFullscreen ?? false))
            return null;
        return ws.toplevels.values.find(t => t.wayland?.fullscreen) ?? null;
    }

    // Run Lua against the fullscreen window of monitor `name` (bound to `w`): that window, not the
    // focused one, since a click on the bar doesn't move focus and focus may be on another monitor.
    function act(name, lua) {
        Quickshell.execDetached(["hyprctl", "eval", `local ws = hl.get_active_workspace("${name}")
            local w = ws ~= nil and ws.fullscreen_window or nil
            if w ~= nil then ${lua} end`]);
    }

    function exit(name) {
        act(name, "hl.dispatch(hl.dsp.window.fullscreen({ window = w }))");
    }

    function close(name) {
        act(name, "hl.dispatch(hl.dsp.window.close({ window = w }))");
    }

    // out of fullscreen into a floating window, sized and centered like SUPER+SHIFT+F
    function float(name) {
        act(name, `hl.dispatch(hl.dsp.window.fullscreen({ window = w }))
            hl.dispatch(hl.dsp.window.float({ window = w, action = "enable" }))
            hl.dispatch(hl.dsp.window.resize({ x = 875, y = 600, window = w }))
            hl.dispatch(hl.dsp.window.center({ window = w }))`);
    }

    // Quickshell keeps hasFullscreen and each monitor's activeWorkspace up to date from events, but
    // Hyprland doesn't send the right ones in every case (see below), so re-read both over the socket.
    // Events come in bursts and some fire just before Hyprland has applied the change (closewindow comes
    // before the fullscreen window is restored), so read a moment later.
    function refresh() {
        settle.restart();
    }

    Timer {
        id: settle
        interval: 60
        onTriggered: {
            Hyprland.refreshMonitors();
            Hyprland.refreshWorkspaces();
        }
    }

    Component.onCompleted: refresh()

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            switch (event.name) {
            // with misc:on_focus_under_fullscreen, focusing another window drops the fullscreen and
            // refocusing restores it, and neither sends a "fullscreen" event: only the focus change shows it
            case "activewindowv2":
                if (root.hadFullscreen[Hyprland.focusedWorkspace?.id])
                    root.refresh();
                break;
            case "fullscreen":
            case "workspace":
            case "workspacev2":
            case "focusedmon":
            case "openwindow":
            case "closewindow":
            case "movewindow":
            // moving a workspace to another monitor sends no "workspace" event, and the "focusedmon"
            // before it still names the old one: monitors keep a stale activeWorkspace until refreshed
            case "moveworkspacev2":
            case "monitoradded":
            case "monitorremoved":
                root.refresh();
            }
        }
    }
}
