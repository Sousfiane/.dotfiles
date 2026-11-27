import Quickshell.Io
import QtQuick

// A JSON file the shell keeps state in (the dock's pins and settings, launcher usage, the notification
// history). Read synchronously, so load() works from Component.onCompleted; a file that is missing,
// empty or unreadable gives the fallback.
FileView {
    id: root

    property bool pretty: true          // indented; off for a large file nobody reads

    blockLoading: true
    printErrors: false

    function load(fallback) {
        const data = text();
        if (data.trim() === "")
            return fallback;
        try {
            return JSON.parse(data);
        } catch (e) {
            console.warn("Could not read " + path + ":", e);
            return fallback;
        }
    }

    function save(value) {
        setText(pretty ? JSON.stringify(value, null, 2) : JSON.stringify(value));
    }
}
