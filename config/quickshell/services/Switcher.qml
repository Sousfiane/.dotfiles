pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.config

// The app switcher, as macOS's Cmd + Tab, with ALT (SUPER + Tab switches workspaces):
//
//   ALT + Tab        the apps, most recently used first, the previous one chosen; Tab again goes on,
//                    SHIFT + Tab back. Letting go of ALT goes to the app's last window (the strip
//                    scrolls to it); a quick ALT + Tab goes straight back to the previous app
//   ALT + ²          the same for the windows of the app in front, shown as live previews (macOS's Cmd + `)
//   while it shows   h l / arrows choose, Enter goes, Esc cancels, Q quits the chosen app; a click goes
//
// Hyprland binds the keys (bindings.lua) and calls this through IPC: `qs ipc call switcher next apps`,
// `prev`, and `commit` when ALT is let go. It shows on the focused monitor, after a short moment so a quick
// tap doesn't flash it.
//
// This is its state, what it lists and what it does; modules/switcher/SwitcherPanel.qml draws it.
Singleton {
    id: root


    property bool open: false
    property string mode: "apps"          // "apps" or "windows"
    property int index: 0
    property string screenName: ""
    property bool uiShown: false          // drawn: a moment after opening

    // ---------- what it lists ----------

    // the windows, most recently focused first
    readonly property var recent: {
        if (!open)
            return [];
        return Hyprland.toplevels.values.filter(t => {
            const o = t.lastIpcObject;
            return o && o.mapped && !o.hidden && o.workspace?.id > 0;
        }).sort((a, b) => (a.lastIpcObject.focusHistoryID ?? 99) - (b.lastIpcObject.focusHistoryID ?? 99));
    }

    // the apps, in the order their last window was used: { cls, name, icon, windows }
    readonly property var apps: {
        const byClass = {}, out = [];
        for (const t of recent) {
            const cls = Windows.appClass(t);
            if (!byClass[cls]) {
                const entry = Apps.entryForWindow(t);
                byClass[cls] = {
                    cls: cls,
                    name: entry?.name ?? cls,
                    icon: Icons.source(entry?.icon ?? cls.toLowerCase(), "application-x-executable"),
                    windows: []
                };
                out.push(byClass[cls]);
            }
            byClass[cls].windows.push(t);
        }
        return out;
    }

    // the windows of the app in front
    readonly property var appWindows: {
        const front = recent[0];
        return front ? recent.filter(t => Windows.appClass(t) === Windows.appClass(front)) : [];
    }

    readonly property int count: mode === "apps" ? apps.length : appWindows.length

    // ---------- moving through it ----------

    function start(m, dir) {
        if (open && mode === m) {
            if (count > 0)
                index = (index + dir + count) % count;
            return;
        }
        Panels.closeAll();
        Hyprland.refreshToplevels();
        mode = m;
        screenName = Hyprland.focusedMonitor?.name ?? "";
        index = -1;                       // set once the list is read (below)
        pendingDir = dir;
        open = true;
        showTimer.restart();
    }

    // the first choice waits for the fresh list: the previous one going forward, the last one going back
    property int pendingDir: 1
    onCountChanged: if (open && index < 0 && count > 0)
        index = count === 1 ? 0 : (pendingDir > 0 ? 1 : count - 1)
    onOpenChanged: if (open && count > 0 && index < 0)
        index = count === 1 ? 0 : (pendingDir > 0 ? 1 : count - 1)

    function commit() {
        if (!open)
            return;
        const i = index < 0 ? (count > 1 ? 1 : 0) : index;
        const target = mode === "apps" ? apps[i]?.windows[0] : appWindows[i];
        close();
        if (target)
            Windows.focus(target);
    }

    function close() {
        open = false;
        uiShown = false;
        showTimer.stop();
    }

    // quits the chosen app: every window of it closed, the list stays open
    function quitChosen() {
        if (mode !== "apps" || !apps[index])
            return;
        for (const t of apps[index].windows)
            Windows.close(t);
        Qt.callLater(Hyprland.refreshToplevels);
    }

    Timer {
        id: showTimer
        interval: 110
        onTriggered: root.uiShown = root.open
    }

    IpcHandler {
        target: "switcher"

        function next(mode: string): void {
            root.start(mode === "windows" ? "windows" : "apps", 1);
        }
        function prev(mode: string): void {
            root.start(mode === "windows" ? "windows" : "apps", -1);
        }
        function commit(): void {
            root.commit();
        }
        function cancel(): void {
            root.close();
        }
    }

    // the choice moved by `d` (1 next, -1 back), round the list
    function step(d) {
        if (count > 0)
            index = (index + d + count) % count;
    }
}
