pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    property bool open: false

    function toggle() {
        open = !open;
    }

    // `icon` is an nf-md codepoint. Change the lock command to your locker.
    readonly property var actions: [
        {
            key: "L",
            label: "Lock",
            icon: 0xF033E,
            command: ["hyprlock"]
        },
        {
            key: "S",
            label: "Suspend",
            icon: 0xF0904,
            command: ["systemctl", "suspend"]
        },
        {
            key: "O",
            label: "Log out",
            icon: 0xF0343,
            command: ["uwsm", "stop"]
        },
        {
            key: "R",
            label: "Reboot",
            icon: 0xF0709,
            command: ["systemctl", "reboot"]
        },
        {
            key: "P",
            label: "Shutdown",
            icon: 0xF0425,
            command: ["systemctl", "poweroff"]
        }
    ]

    function run(action) {
        open = false;
        Quickshell.execDetached(action.command);
    }
}
