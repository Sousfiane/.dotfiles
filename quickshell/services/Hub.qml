pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property bool open: false

    function toggle() {
        open = !open;
    }

    // close the hub first, then open the picker once the hub has let go of the keyboard
    property string pending: ""

    function openPicker(target) {
        pending = target;
        open = false;
        pickerTimer.restart();
    }

    Timer {
        id: pickerTimer
        interval: 220
        onTriggered: {
            if (root.pending !== "")
                Quickshell.execDetached(["qs", "ipc", "call", root.pending, "toggle"]);
            root.pending = "";
        }
    }
}
