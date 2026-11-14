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
            switch (root.pending) {
            case "launcher":
                Launcher.open = true;
                break;
            case "wallpaper":
                Wallpapers.open = true;
                break;
            case "clipboard":
                ClipHistory.toggle();      // also refreshes the history and clears the query
                break;
            }
            root.pending = "";
        }
    }
}
