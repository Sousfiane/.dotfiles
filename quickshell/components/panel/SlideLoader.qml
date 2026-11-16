import Quickshell
import QtQuick

LazyLoader {
    id: root

    property bool open: false
    property int closeDelay: 260      // keep this a bit longer than SlideArea.duration

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
