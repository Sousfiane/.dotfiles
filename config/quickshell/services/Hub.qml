pragma Singleton
import Quickshell
import QtQuick

// The hub's open state (its tab is Panels.hubTab).
Singleton {
    id: root

    readonly property bool open: Panels.isOpen("hub")

    function toggle() {
        Panels.toggle("hub");
    }
}
