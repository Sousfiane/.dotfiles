pragma Singleton
import Quickshell
import QtQuick
import qs.config

Singleton {
    id: root

    property string query: ""

    readonly property bool open: Panels.isOpen("launcher")

    function toggle() {
        Panels.toggle("launcher");
    }

    // start fresh on every open
    onOpenChanged: if (open)
        query = ""

    readonly property var results: {
        const q = query.toLowerCase();

        return DesktopEntries.applications.values.filter(a => !a.noDisplay && a.name.toLowerCase().includes(q)).sort((a, b) => {
            const qa = a.name.toLowerCase();
            const qb = b.name.toLowerCase();

            // names starting with the query first
            const pa = qa.startsWith(q) ? 0 : 1;
            const pb = qb.startsWith(q) ? 0 : 1;
            if (pa !== pb)
                return pa - pb;

            // then the most launched
            const ua = LauncherHistory.count(a.id);
            const ub = LauncherHistory.count(b.id);
            if (ua !== ub)
                return ub - ua;

            return qa.localeCompare(qb);
        });
    }

    // starts a desktop entry (also used by the notification center)
    function run(entry) {
        const cmd = entry.runInTerminal ? [Config.terminal, "-e", ...entry.command] : entry.command;

        Quickshell.execDetached({
            command: ["uwsm", "app", "--", ...cmd],
            workingDirectory: entry.workingDirectory
        });
    }

    // picked from the launcher: counts towards the ranking, then closes it
    function launch(entry) {
        if (entry) {
            LauncherHistory.record(entry.id);
            run(entry);
        }
        Panels.hide("launcher");
    }
}
