pragma Singleton

import Quickshell
import Quickshell.Io

import QtQuick

Singleton {
    id: root

    property var usageCounts: ({})

    FileView {
        id: usageFile

        path: Quickshell.cachePath("launcher-usage.json")
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: {
        try {
            const data = usageFile.text();
            usageCounts = data.length > 0 ? JSON.parse(data) : {};
        } catch (e) {
            console.warn("Could not load launcher history:", e);
            usageCounts = {};
        }
    }

    function count(id: string): int {
        return usageCounts[id] || 0;
    }

    function record(id: string): void {
        const updated = Object.assign({}, usageCounts);

        updated[id] = (updated[id] || 0) + 1;

        usageCounts = updated;
        usageFile.setText(JSON.stringify(updated, null, 2));
    }
}
