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
    function openPicker(target) {       // "launcher" | "wallpaper" | "theme" | "clipboard" | "screenshot"
        Panels.closeThen(() => Panels.show(target));
    }
}
