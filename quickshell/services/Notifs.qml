pragma Singleton
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    // Each notification becomes one entry, shared by the toasts and the history:
    //   { notif, appName, summary, body, urgency, desktopEntry, time, popupUntil }
    // (`popupUntil`: when its toast hides, in ms since epoch; 0 = stays until clicked)
    // `notif` is the live Notification while the app still has it open (null once it's gone);
    // the copied text keeps the entry readable after that.
    property var history: []      // newest first, what the center shows
    property var popups: []       // the subset currently shown as toasts

    readonly property int maxHistory: 50

    property bool dnd: false
    property int unread: 0

    readonly property bool open: Panels.isOpen("notifs")

    function toggle() {
        Panels.toggle("notifs");
    }

    onOpenChanged: {
        if (open) {
            unread = 0;
            Hyprland.refreshToplevels();       // fresh focus order for the window lookup
        }
    }

    // ---------- list bookkeeping ----------

    function without(list, entry) {
        return list.filter(e => e !== entry);
    }

    function hidePopup(entry) {
        popups = without(popups, entry);
    }

    // drops the entry everywhere and lets the app know it was dismissed
    function remove(entry) {
        history = without(history, entry);
        popups = without(popups, entry);
        const n = entry.notif;
        entry.notif = null;
        if (n)
            n.dismiss();
    }

    function removeAt(i) {
        if (history[i])
            remove(history[i]);
    }

    function clearHistory() {
        for (const e of history.slice())
            remove(e);
        unread = 0;
    }

    // the app closed it, or it was dismissed: keep the text, forget the object
    function released(n) {
        const entry = history.find(e => e.notif === n);
        if (!entry)
            return;
        entry.notif = null;
        popups = without(popups, entry);
        history = history.slice();             // re-evaluate bindings on `notif`
    }

    // ---------- going to the app ----------

    // the notification's own "default" action: the app opens the right tab or conversation itself
    function invokeDefault(n) {
        if (!n)
            return false;
        for (let i = 0; i < n.actions.length; i++) {
            if (n.actions[i].identifier === "default") {
                n.actions[i].invoke();
                return true;
            }
        }
        return false;
    }

    function desktopEntryFor(entry) {
        const id = (entry.desktopEntry || "").replace(/\.desktop$/, "");
        return (id !== "" ? DesktopEntries.byId(id) : null) ?? (entry.appName !== "" ? DesktopEntries.heuristicLookup(entry.appName) : null);
    }

    // every name the app's windows could go by, lowercased
    function namesFor(entry, desktop) {
        const names = [entry.desktopEntry.replace(/\.desktop$/, ""), entry.appName, desktop?.id ?? "", desktop?.startupClass ?? ""];
        return names.map(s => s.toLowerCase()).filter(s => s !== "");
    }

    // the app's most recently focused window, or null
    function windowFor(names) {
        const matches = Hyprland.toplevels.values.filter(w => {
            const cls = (w.wayland?.appId || w.lastIpcObject?.class || "").toLowerCase();
            return cls !== "" && names.some(n => cls === n || cls.endsWith("." + n) || n.endsWith("." + cls));
        });
        matches.sort((a, b) => (a.lastIpcObject?.focusHistoryID ?? 1e9) - (b.lastIpcObject?.focusHistoryID ?? 1e9));
        return matches[0] ?? null;
    }

    function focusWindow(w) {
        const addr = "0x" + String(w.address).replace(/^0x/, "");
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr}" })`);
    }

    // a click on a toast or a history entry
    function activate(entry) {
        const invoked = invokeDefault(entry.notif);
        const desktop = desktopEntryFor(entry);
        const win = windowFor(namesFor(entry, desktop));

        Panels.hide("notifs");

        if (win)
            focusWindow(win);              // also when the action ran: Wayland apps can't always raise themselves
        else if (!invoked && desktop)
            Launcher.run(desktop);         // not running: start it

        remove(entry);
    }

    // ---------- the server ----------

    NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: n => {
            // kept alive for as long as it is in the history, so it stays clickable
            n.tracked = true;
            n.closed.connect(() => root.released(n));

            const entry = {
                notif: n,
                appName: n.appName,
                summary: n.summary,
                body: n.body,
                urgency: n.urgency,
                desktopEntry: n.desktopEntry,
                time: Qt.formatDateTime(new Date(), "HH:mm")
            };

            const next = [entry].concat(root.history);
            for (const old of next.splice(root.maxHistory))
                root.remove(old);
            root.history = next;

            if (!root.open)
                root.unread++;

            // Do Not Disturb: still recorded in history, but only critical ones pop up.
            // The deadline lives on the entry, so rebuilding the toast list doesn't restart it.
            const critical = n.urgency === NotificationUrgency.Critical;
            if (!root.dnd || critical) {
                entry.popupUntil = critical ? 0 : Date.now() + (n.expireTimeout > 0 ? n.expireTimeout * 1000 : 5000);
                root.popups = [entry].concat(root.popups);
            }
        }
    }
}
