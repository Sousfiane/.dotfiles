pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int count: 0
    property var packages: []                       // everything, parsed
    readonly property var firstTen: packages.slice(0, 10)
    property bool failed: false

    function refresh() {
        if (!proc.running)
            proc.running = true;
    }

    Process {
        id: proc
        command: ["checkupdates"]
        running: true                               // check once at startup

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(l => l.length > 0);
                root.packages = lines.map(l => {
                    const p = l.split(" ");         // name old -> new
                    return {
                        name: p[0],
                        from: p[1],
                        to: p[3]
                    };
                });
                root.count = lines.length;
            }
        }

        // checkupdates exits 2 when there are no updates, which is not an error
        onExited: (code, status) => {
            root.failed = code !== 0 && code !== 2;
        }
    }

    Timer {
        interval: 30 * 60 * 1000                    // every 30 minutes
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
