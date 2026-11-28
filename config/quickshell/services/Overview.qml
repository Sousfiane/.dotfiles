pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Mission Control for the scrolling layout (SUPER + Up, or `qs ipc call overview toggle`): every monitor
// shows its workspaces as rows, each row its strip of windows as live previews, laid out as the layout
// has them (columns side by side, what's scrolled out of view on either side of a frame round the screen).
//
//   click a window          go to it (its workspace, scrolled into view)
//   drag it to another row  move it there; to the last row, a new workspace
//   middle-click            close it
//   click a row             go to that workspace
//   h j k l / arrows        choose a window, Enter goes to it; Esc closes
//
// This is its state and its IPC; modules/overview/OverviewPanel.qml puts a window on every monitor.
Singleton {
    id: root

    property bool open: false
    property string screenName: ""        // the monitor it opened on: it takes the keyboard

    function show() {
        Panels.closeAll();
        Hyprland.refreshToplevels();
        screenName = Hyprland.focusedMonitor?.name ?? "";
        open = true;
    }

    function close() {
        open = false;
    }

    function toggle() {
        if (open)
            close();
        else
            show();
    }

    IpcHandler {
        target: "overview"

        function toggle(): void {
            root.toggle();
        }
        function open(): void {
            root.show();
        }
        function close(): void {
            root.close();
        }
    }
}
