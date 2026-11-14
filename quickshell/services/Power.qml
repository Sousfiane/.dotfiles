pragma Singleton
import Quickshell
import QtQuick
import qs.config

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
            icon: Icons.lock,
            command: ["hyprlock"]
        },
        {
            key: "S",
            label: "Suspend",
            icon: Icons.suspend,
            command: ["systemctl", "suspend"]
        },
        {
            key: "O",
            label: "Log out",
            icon: Icons.logout,
            command: ["uwsm", "stop"]
        },
        {
            key: "R",
            label: "Reboot",
            icon: Icons.reboot,
            command: ["systemctl", "reboot"]
        },
        {
            key: "P",
            label: "Shutdown",
            icon: Icons.shutdown,
            command: ["systemctl", "poweroff"]
        }
    ]

    function run(action) {
        open = false;
        Quickshell.execDetached(action.command);
    }
}
