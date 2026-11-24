pragma Singleton
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick

// The system tray: apps living in the background (Vesktop, EasyEffects...). The bar keeps them in a
// drawer that opens on hover (modules/bar/TrayIcon); their menus open as a dropdown (modules/tray).
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
    onItemsChanged: if (open && !items.includes(menuItem))
        Panels.hide("tray")

    function name(item) {
        return item?.tooltipTitle || item?.title || item?.id || "";
    }

    // ---------- the icons ----------

    // left: the app's own action (most bring their window back); apps that only have a menu show it
    function click(item, button) {
        if (button === Qt.RightButton)
            openMenu(item);
        else if (button === Qt.MiddleButton)
            item.secondaryActivate();
        else if (item.onlyMenu)
            openMenu(item);
        else
            item.activate();
    }

    // DBusMenu labels mark their access key with "_" ("_Quit"); "__" is a real underscore
    function label(text) {
        return (text ?? "").replace(/__/g, "\u0000").replace(/_/g, "").replace(/\u0000/g, "_");
    }
}
