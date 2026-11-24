pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// lockscreen state. Lock from anywhere with Lock.lock() or `qs ipc call lock lock`;
// only a correct password (modules/lock) unlocks it.
// Each screen is captured first, so the lockscreen can fade in over the desktop and back out to it.
Singleton {
    id: root

    property bool locked: false
    property bool capturing: false

    function lock() {
        if (locked || capturing)
            return;
        capturing = true;
        // an open dropdown slides away first, so it is not in the screenshot
        Panels.closeThen(capture);
    }

    function shotPath(screenName) {
        return Quickshell.env("XDG_RUNTIME_DIR") + "/qs-lock-" + screenName + ".png";
    }

    function capture() {
        shot.command = ["sh", "-c", 'for o; do grim -l 0 -o "$o" "$XDG_RUNTIME_DIR/qs-lock-$o.png" & done; wait', "sh", ...Quickshell.screens.map(s => s.name)];
        shot.running = true;
        guard.restart();
    }

    function finishCapture() {
        if (!capturing)
            return;
        capturing = false;
        guard.stop();
        locked = true;
    }

    // the screenshots are only needed while locked
    onLockedChanged: if (!locked)
        Quickshell.execDetached(["sh", "-c", 'rm -f "$XDG_RUNTIME_DIR"/qs-lock-*.png']);

    Process {
        id: shot
        onExited: root.finishCapture()
    }

    // never let a stuck screenshot delay the lock
    Timer {
        id: guard
        interval: 1500
        onTriggered: root.finishCapture()
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            root.lock();
        }
        function isLocked(): bool {
            return root.locked;
        }
    }
}
