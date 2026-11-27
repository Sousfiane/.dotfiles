import QtQuick
import Quickshell.Io

// A Process for a periodic check (updates, weather, calendar, git status). It runs every
// `interval` ms; refresh() while it is running makes it run once more right after, so no request
// is lost. The owner sets `fetchedAt` when a run gave a good result, for refreshIfStale().
Process {
    id: root

    property int interval: 0                // ms between runs, 0 = only when asked
    property real fetchedAt: 0              // ms since epoch of the last good result

    property bool again: false

    function refresh() {
        if (running)
            again = true;
        else
            running = true;
    }

    // refresh when the last good result is older than `maxAgeMin` minutes
    function refreshIfStale(maxAgeMin) {
        if (Date.now() - fetchedAt > maxAgeMin * 60 * 1000)
            refresh();
    }

    onExited: if (again) {
        again = false;
        running = true;
    }

    property Timer timer: Timer {
        interval: root.interval
        running: root.interval > 0
        repeat: true
        onTriggered: root.refresh()
    }
}
