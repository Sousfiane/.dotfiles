pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// how often and how recently each app was launched, for the launcher's ranking.
// Saved as { id: { count, last } }; older files hold plain counts, read as launched long ago.
Singleton {
    id: root

    property var usage: ({})

    FileView {
        id: usageFile

        path: Quickshell.cachePath("launcher-usage.json")
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: {
        try {
            const data = usageFile.text();
            usage = data.length > 0 ? JSON.parse(data) : {};
        } catch (e) {
            console.warn("Could not load launcher history:", e);
            usage = {};
        }
    }

    function count(id: string): int {
        const u = usage[id];
        return typeof u === "number" ? u : u?.count ?? 0;
    }

    // launches weighed by how long ago the last one was, so a phase of heavy use fades out
    function frecency(id: string): real {
        const u = usage[id];
        if (!u)
            return 0;
        if (typeof u === "number")
            return u * 0.3;                     // from before dates were kept
        const days = (Date.now() - u.last) / 86400000;
        const weight = days < 4 ? 1 : days < 14 ? 0.7 : days < 31 ? 0.5 : days < 90 ? 0.3 : 0.1;
        return u.count * weight;
    }

    function record(id: string): void {
        const updated = Object.assign({}, usage);

        updated[id] = {
            count: count(id) + 1,
            last: Date.now()
        };

        usage = updated;
        usageFile.setText(JSON.stringify(updated, null, 2));
    }
}
