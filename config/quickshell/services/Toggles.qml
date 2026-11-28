pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// The hub's quick toggles that aren't another service's: keep awake, the TV.
Singleton {
    id: root

    // ---------- the TV ----------

    // Hyprland's (config/hypr/config/monitors.lua): toggle_tv() turns it on or off and keeps which in
    // ~/.local/state/hypr/tv, which this follows; SUPER + T does the same
    readonly property bool tv: tvState.text().trim() === "on"

    function toggleTv() {
        tvToggle.running = true;
    }

    FileView {
        id: tvState
        path: Quickshell.env("HOME") + "/.local/state/hypr/tv"
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
    }

    // a file that doesn't exist can't be watched: it's created first, as "off" (what Hyprland does without it)
    Process {
        running: true
        command: ["sh", "-c", 'mkdir -p "$(dirname "$1")" && { [ -s "$1" ] || echo off > "$1"; }', "sh", tvState.path]
        onExited: tvState.reload()
    }

    Process {
        id: tvToggle
        command: ["hyprctl", "eval", 'require("config.monitors").toggle_tv()']
    }

    // ---------- keep awake ----------

    // A process that runs only while the toggle is on, so off costs nothing. It doesn't survive a restart of
    // the shell.

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
