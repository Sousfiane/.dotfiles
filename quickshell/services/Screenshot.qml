pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config

Singleton {
    id: root

    readonly property bool open: Panels.isOpen("screenshot")

    function toggle() {
        Panels.toggle("screenshot");
    }

    // ---------- what can be captured ----------

    readonly property var modes: [
        {
            key: "R",
            label: "Region",
            icon: Icons.shotRegion,
            args: ["-m", "region"]
        },
        {
            key: "W",
            label: "Window",
            icon: Icons.shotWindow,
            args: ["-m", "window"]
        },
        {
            key: "O",
            label: "Monitor",
            icon: Icons.shotMonitor,
            args: ["-m", "output"]
        },
        {
            key: "A",
            label: "Active window",
            icon: Icons.shotActiveWindow,
            args: ["-m", "window", "-m", "active"]
        },
        {
            key: "M",
            label: "Active monitor",
            icon: Icons.shotActiveMonitor,
            args: ["-m", "output", "-m", "active"]
        }
    ]

    // one entry per monitor, by name, on the number keys
    readonly property var monitors: Hyprland.monitors.values.map((m, i) => ({
                key: String(i + 1),
                label: m.name,
                icon: Icons.shotMonitor,
                args: ["-m", "output", "-m", m.name]
            }))

    readonly property var all: modes.concat(monitors)

    // always straight to the clipboard: no file, no notification
    function command(mode) {
        return ["hyprshot", ...mode.args, "--clipboard-only", "--silent"];
    }

    // close the panel first and wait for it to slide away, so it is not in the shot
    // (it keeps the longer 400 ms wait it always had)
    function take(mode) {
        const cmd = command(mode);
        Panels.closeThen(() => Quickshell.execDetached(cmd), 400);
    }
}
