pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The hub's quick toggles that aren't another service's: keep awake. A process that runs only while the
// toggle is on, so off costs nothing. It doesn't survive a restart of the shell.
Singleton {
    id: root

    // ---------- keep awake ----------

    // an idle inhibitor lock, which hypridle respects: the screens stay on and nothing locks
    property bool keepAwake: false

    Process {
        running: root.keepAwake
        command: ["systemd-inhibit", "--what=idle", "--who=Quickshell", "--why=Keep awake (the hub)", "sleep", "infinity"]
        // it stopped or never started: show the toggle off again
        onRunningChanged: if (!running)
            root.keepAwake = false
    }
}
