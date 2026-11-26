import Quickshell
import QtQuick
import qs.services

// Loads a dropdown's window when it opens and keeps it until its slide out is over (Panels.closeMs), so
// closing never cuts the animation short.
LazyLoader {
    id: root

    property bool open: false
    property int closeDelay: Panels.closeMs

    property bool alive: false
    active: alive

    onOpenChanged: {
        if (open) {
            unloadTimer.stop();
            alive = true;
        } else {
            unloadTimer.restart();
        }
    }

    Component.onCompleted: if (open)
        alive = true

    property Timer unloadTimer: Timer {
        interval: root.closeDelay
        onTriggered: root.alive = false
    }
}
