pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

Singleton {
    id: root

    readonly property string repoPath: Config.dotfilesRepo

    property int count: 0
    property var changes: []
    property bool failed: false
    readonly property bool checking: proc.running

    // ---------- panel ----------

    property bool panelOpen: false

    function toggle() {
        panelOpen = !panelOpen;
    }

    function openLazygit() {
        Quickshell.execDetached(["uwsm", "app", "--", Config.terminal, "-e", "lazygit", "-p", repoPath]);
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
                const output = text.replace(/\s+$/, "");
                root.changes = output.length > 0 ? output.split("\n") : [];
                root.count = root.changes.length;
            }
        }

        onExited: (code, status) => {
            root.failed = code !== 0;
        }
    }

    Timer {
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
