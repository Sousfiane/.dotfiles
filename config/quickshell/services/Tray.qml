pragma Singleton
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Io
import QtQuick

// The system tray: apps living in the background (Vesktop, EasyEffects...). The bar keeps them in a
// drawer that opens on hover (modules/bar/icons/TrayIcon); their menus open as a dropdown (modules/tray).
Singleton {
    id: root

    // passive items ask not to be shown
    readonly property var items: SystemTray.items.values.filter(i => i.status !== Status.Passive)
    readonly property bool attention: items.some(i => i.status === Status.NeedsAttention)

    // ---------- the menu dropdown ----------

    property SystemTrayItem menuItem: null      // whose menu the dropdown shows
    readonly property bool open: Panels.isOpen("tray")

    function openMenu(item) {
        if (!item?.hasMenu)
            return;
        if (open && menuItem === item) {
            Panels.hide("tray");
            return;
        }
        menuItem = item;
        Panels.show("tray");
    }

    // the app went away while its menu was showing
    function checkMenuItem() {
        if (open && !items.includes(menuItem))
            Panels.hide("tray");
    }

    function name(item) {
        return item?.tooltipTitle || item?.title || item?.id || "";
    }

    // ---------- the icons ----------

    // left: the app's own action (most bring their window back). Apps that can't do that get launched again
    // from their desktop entry, which for single-instance apps (Steam, Vesktop...) brings the running window
    // up; with no entry to launch, the menu. Right: the menu.
    function click(item, button) {
        if (button === Qt.RightButton)
            openMenu(item);
        else if (button === Qt.MiddleButton)
            item.secondaryActivate();
        else if (!item.onlyMenu && !menuOnly.includes(item.id))
            item.activate();
        else if (entry(item))
            entry(item).execute();
        else
            openMenu(item);
    }

    // the desktop entry behind a tray item: its id is usually the app's ("steam"), sometimes with a suffix
    // ("vesktop_status_icon_1")
    function entry(item) {
        const id = item.id ?? "";
        const base = id.replace(/[_-]status[_-]?icon.*$/i, "").replace(/[_-]client$/i, "");
        return DesktopEntries.byId(id) ?? DesktopEntries.byId(base)
            ?? (base !== "" ? DesktopEntries.heuristicLookup(base) : null)
            ?? (item.title ? DesktopEntries.heuristicLookup(item.title) : null);
    }

    // ---------- apps with nothing to activate ----------

    // AppIndicator apps (nm-applet, Electron apps like Vesktop...) don't implement Activate at all, and don't
    // say they're menu-only either, so a left click would do nothing. Quickshell can't tell, so ask D-Bus:
    // the ids of the registered items whose interface has no Activate method.
    property var menuOnly: []

    onItemsChanged: {
        checkMenuItem();
        probe.restart();
    }
    Component.onCompleted: probe.restart()

    Timer {
        id: probe
        interval: 500                        // let a burst of (un)registrations settle
        onTriggered: {
            prober.running = false;
            prober.running = true;
        }
    }

    Process {
        id: prober
        command: ["sh", "-c", `busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems | tr ' ' '\\n' | sed -n 's/^"\\(.*\\)"$/\\1/p' |
while read -r e; do
    svc=\${e%%/*}; obj=/\${e#*/}; [ "$svc" = "$e" ] && obj=/StatusNotifierItem
    busctl --user introspect "$svc" "$obj" org.kde.StatusNotifierItem 2>/dev/null | grep -q '^\\.Activate ' ||
        busctl --user get-property "$svc" "$obj" org.kde.StatusNotifierItem Id | cut -d'"' -f2
done`]
        stdout: StdioCollector {
            onStreamFinished: root.menuOnly = text.split("\n").filter(l => l !== "")
        }
    }

    // DBusMenu labels mark their access key with "_" ("_Quit"); "__" is a real underscore
    function label(text) {
        return (text ?? "").replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_");
    }
}
