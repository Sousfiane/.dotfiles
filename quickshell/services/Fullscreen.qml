pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

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
