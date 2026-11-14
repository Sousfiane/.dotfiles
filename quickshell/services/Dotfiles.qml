pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // Change this if your repository is somewhere else
    property string repoPath: Quickshell.env("HOME") + "/.dotfiles"

    property int count: 0
    property var changes: []
    property bool failed: false
    readonly property bool checking: proc.running

    readonly property bool hasChanges: count > 0

    // ---------- panel ----------

    property bool panelOpen: false
    property string terminal: "kitty"               // change to your terminal

    function toggle() {
        panelOpen = !panelOpen;
    }

    function openLazygit() {
        Quickshell.execDetached(["uwsm", "app", "--", terminal, "-e", "lazygit", "-p", repoPath]);
        panelOpen = false;
    }

    // ---------- git status ----------

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    Process {
        id: proc

        command: ["git", "-C", root.repoPath, "status", "--porcelain=v1", "--untracked-files=all"]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const output = text.trim();

                root.changes = output.length > 0 ? output.split("\n") : [];

                root.count = root.changes.length;
                console.log("dotfiles: count =", root.count);
            }
        }

        stderr: StdioCollector {
            onStreamFinished: if (text.length > 0)
                console.log("dotfiles stderr:", text)
        }

        onExited: (code, status) => {
            root.failed = code !== 0;
            console.log("dotfiles: exit code", code, "path", root.repoPath);
        }
    }

    Timer {
        interval: 60 * 1000 // Every minute
        running: true
        repeat: true

        onTriggered: root.refresh()
    }
}
