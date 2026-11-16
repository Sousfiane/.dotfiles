pragma Singleton
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // monitor name -> true when its active workspace has a fullscreen window
    property var states: ({})

    function on(name) {
        return states[name] === true;
    }

    // events come in bursts and some fire just before Hyprland has applied the change
    // (closewindow comes before the fullscreen window is restored), so read the state a moment later
    function refresh() {
        settle.restart();
    }

    Timer {
        id: settle
        interval: 60
        onTriggered: {
            proc.running = false;
            proc.running = true;
        }
    }

    Component.onCompleted: refresh()

    Process {
        id: proc
        command: ["sh", "-c", "hyprctl -j monitors; printf '\\n@@@@\\n'; hyprctl -j workspaces"]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("@@@@");
                if (parts.length < 2)
                    return;

                try {
                    const monitors = JSON.parse(parts[0]);
                    const workspaces = JSON.parse(parts[1]);
                    const fullscreenIds = workspaces.filter(w => w.hasfullscreen).map(w => w.id);

                    const out = ({});
                    for (const m of monitors)
                        out[m.name] = fullscreenIds.indexOf(m.activeWorkspace.id) !== -1;
                    root.states = out;
                } catch (e) {
                    console.log("fullscreen: could not parse hyprctl output", e);
                }
            }
        }
    }

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
            case "monitoradded":
            case "monitorremoved":
                root.refresh();
            }
        }
    }
}
