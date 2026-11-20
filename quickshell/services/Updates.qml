pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

Singleton {
    id: root

    property int count: 0
    property var packages: []                       // everything, parsed
    property bool failed: false
    readonly property bool checking: proc.running

    // ---------- panel ----------

    readonly property bool open: Panels.isOpen("updates")

    function toggle() {
        Panels.toggle("updates");
    }

    // change this if you use an AUR helper (e.g. "yay -Syu")
    function runUpdate() {
        Quickshell.execDetached(["uwsm", "app", "--", ...Config.floatingTerm(["bash", "-c", "yay -Syu; echo; read -rp 'Press Enter to close...'"])]);
        Panels.hide("updates");
    }

    // ---------- checking ----------

    function refresh() {
        proc.refresh();
    }

    PolledProcess {
        id: proc
        command: ["checkupdates"]
        running: true                               // check once at startup
        interval: 30 * 60 * 1000                    // then every 30 minutes

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
}
