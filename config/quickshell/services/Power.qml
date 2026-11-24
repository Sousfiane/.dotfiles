pragma Singleton
import Quickshell
import QtQuick
import qs.config

Singleton {
    id: root

    readonly property bool open: Panels.isOpen("power")

    function toggle() {
        Panels.toggle("power");
    }

    readonly property var actions: [
        {
            key: "L",
            label: "Lock",
            icon: Icons.lock,
            command: ["qs", "ipc", "call", "lock", "lock"]     // the Quickshell lockscreen (modules/lock)
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
        Panels.hide("power");
        Quickshell.execDetached(action.command);
    }
}
