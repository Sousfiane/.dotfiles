pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    // CHANGE THIS to your real repo path
    property string repoPath: Quickshell.env("HOME") + "/.dotfiles"

    property int count: 0
    property var changes: []
    property bool failed: false

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
        interval: 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
