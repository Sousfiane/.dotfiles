pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property bool open: Panels.isOpen("hub")

    function toggle() {
        Panels.toggle("hub");
    }

    // close the hub first, then open the picker once the hub has let go of the keyboard
    property string pending: ""

    function openPicker(target) {       // "launcher" | "wallpaper" | "clipboard"
        pending = target;
        Panels.hide("hub");
        pickerTimer.restart();
    }

    Timer {
        id: pickerTimer
        interval: 220
        onTriggered: {
            if (root.pending !== "")
                Panels.show(root.pending);
            root.pending = "";
        }
    }
}
