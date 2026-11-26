pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// pending updates: the official repos (checkupdates) and the AUR (yay), which `yay -Syu` both installs
Singleton {
    id: root

    property var packages: []                       // [{ name, from, to, aur }], repos first
    readonly property int count: packages.length
    readonly property int aurCount: packages.filter(p => p.aur).length
    property bool failed: false
    readonly property bool checking: proc.running
    readonly property bool updating: updater.running

    // ---------- panel ----------

    readonly property bool open: Panels.isOpen("updates")

    function toggle() {
        Panels.toggle("updates");
    }

    // in a floating terminal; `uwsm-app` returns when the terminal closes, and the list is checked again then
    function runUpdate() {
        Panels.hide("updates");
        if (!updater.running)
            updater.running = true;
    }

    Process {
        id: updater
        command: ["uwsm-app", "--", ...Config.floatingTerm(["bash", "-c", "yay -Syu; echo; read -rp 'Press Enter to close...'"])]
        onExited: root.refresh()
    }

    // ---------- checking ----------

    function refresh() {
        proc.refresh();
    }

    // "name old -> new" (yay adds the package's age after it)
    function parse(lines, aur) {
        return lines.filter(l => l.trim() !== "").map(l => {
            const p = l.trim().split(/\s+/);
            return {
                name: p[0],
                from: p[1],
                to: p[3],
                aur: aur
            };
        });
    }

    PolledProcess {
        id: proc
        // checkupdates' status is the one that counts (2 = nothing to update, which is fine); the AUR part
        // comes after a marker line, and an AUR query that fails just leaves it empty
        command: ["sh", "-c", 'checkupdates; status=$?; echo "@@aur"; yay -Qua 2>/dev/null; exit $status']
        running: true                               // check once at startup
        interval: 30 * 60 * 1000                    // then every 30 minutes

        stdout: StdioCollector {
            onStreamFinished: {
                const [repo, aur] = text.split("@@aur\n");
                root.packages = root.parse((repo ?? "").split("\n"), false).concat(root.parse((aur ?? "").split("\n"), true));
            }
        }

        onExited: (code, status) => {
            root.failed = code !== 0 && code !== 2;
        }
    }
}
