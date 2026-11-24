pragma Singleton
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    // Each notification becomes one entry, shared by the toasts and the history:
    //   { id, notif, appName, summary, body, image, appIcon, urgency, desktopEntry, time, timeout }
    // (`timeout`: how long its toast stays, in ms; critical ones stay until clicked)
    // `notif` is the live Notification while the app still has it open (null once it's gone);
    // the copied text keeps the entry readable after that.
    property var history: []      // newest first, what the center shows
    property var popups: []       // the subset currently shown as toasts

    // What the views use as models: ids, small stable keys for the ScriptModel diff. Delegates look their
    // entry up with entry(id), which re-runs whenever the history changes, so a card notices when the app
    // has withdrawn its notification (entry.notif becomes null) instead of holding on to the old object.
    readonly property var historyIds: history.map(e => e.id)
    readonly property var popupIds: popups.map(e => e.id)

    property int nextId: 0

    function entry(id) {
        return history.find(e => e.id === id) ?? null;
    }

    // what a toast or a history card shows: the live notification's text while the app still has it
    // open (it may update it), the copy kept in the entry after that
    function view(id) {
        const e = entry(id);
        const n = e?.notif ?? null;
        return {
            live: n,
            appName: n?.appName ?? e?.appName ?? "",
            summary: n?.summary ?? e?.summary ?? "",
            body: n?.body ?? e?.body ?? "",
            // sent with it: cover art, screenshot, avatar... A saved copy wins over the live one (see saveImage)
            image: e?.image.startsWith("file://") ? e.image : n?.image ?? e?.image ?? "",
            icon: iconSource(n?.appIcon ?? e?.appIcon ?? ""),
            urgency: n?.urgency ?? e?.urgency ?? 0,
            time: e?.time ?? "",
            timeout: e?.timeout ?? 5000
        };
    }

    // app icon: either an icon name or an absolute path
    function iconSource(icon) {
        if (icon === "")
            return "";
        return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, true);
    }

    readonly property int maxHistory: 50

    property bool dnd: false
    // everything up to this id has been seen (the center was open when it came, or opened since).
    // Derived from the history, so a notification removed from a toast or the center leaves the count too
    property int seenUpTo: -1
    readonly property int unread: history.filter(e => e.id > seenUpTo).length

    readonly property bool open: Panels.isOpen("notifs")

    function toggle() {
        Panels.toggle("notifs");
    }

    onOpenChanged: {
        if (open) {
            seenUpTo = nextId - 1;
            Hyprland.refreshToplevels();       // fresh focus order for the window lookup
        }
    }

    // ---------- list bookkeeping ----------

    function without(list, id) {
        return list.filter(e => e.id !== id);
    }

    function hidePopup(id) {
        popups = without(popups, id);
    }

    // drops the entry everywhere and lets the app know it was dismissed
    function remove(id) {
        const e = entry(id);
        history = without(history, id);
        popups = without(popups, id);
        const n = e?.notif;
        if (e)
            e.notif = null;
        if (n)
            n.dismiss();
    }

    function clearHistory() {
        for (const e of history.slice())
            remove(e.id);
    }

    // the app closed it, or it was dismissed: keep the text, forget the object
    function released(n) {
        const e = history.find(x => x.notif === n);
        if (!e)
            return;
        e.notif = null;
        popups = without(popups, e.id);
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
            const cls = Ws.windowClass(w).toLowerCase();
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
    function activate(id) {
        const entry = root.entry(id);
        if (!entry)
            return;

        const invoked = invokeDefault(entry.notif);
        const desktop = desktopEntryFor(entry);
        const win = windowFor(namesFor(entry, desktop));

        Panels.hide("notifs");

        if (win)
            focusWindow(win);              // also when the action ran: Wayland apps can't always raise themselves
        else if (!invoked && desktop)
            Launcher.run(desktop);         // not running: start it

        remove(id);
    }

    // ---------- images ----------

    // An image sent as raw data (image://qsimage/...: chat avatars and the like) only exists while the app
    // keeps its notification open, and cards are rebuilt (on scrolling, on reopening the center). So the
    // first card that shows one saves what it drew to a file, and the entry points to that from then on.
    // Files are named by entry id: a later run overwrites them, so there are never more than maxHistory.
    readonly property string imageDir: Quickshell.cachePath("notif-images")

    Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", imageDir])

    // `item`: the card's loaded picture, drawn at 128px (the size AppIcon decodes at)
    function saveImage(id, item) {
        const e = entry(id);
        if (!e || !e.image.startsWith("image://qsimage/") || e.saving)
            return;
        e.saving = true;
        item.grabToImage(result => {
            const path = `${imageDir}/${id}.png`;
            if (!result.saveToFile(path) || !entry(id))
                return;
            // ids restart after a reload while Qt's image cache may not, so the URL gets a unique stamp:
            // a reused file name never shows the previous sender's avatar
            e.image = `file://${path}?${Date.now()}`;
            history = history.slice();      // let the views pick up the new source
        }, Qt.size(128, 128));
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
                id: root.nextId++,
                notif: n,
                appName: n.appName,
                summary: n.summary,
                body: n.body,
                image: n.image,
                appIcon: n.appIcon,
                urgency: n.urgency,
                desktopEntry: n.desktopEntry,
                time: Qt.formatDateTime(new Date(), "HH:mm"),
                timeout: n.expireTimeout > 0 ? n.expireTimeout : 5000      // already in ms
            };

            const next = [entry].concat(root.history);
            for (const old of next.splice(root.maxHistory))
                root.remove(old.id);
            root.history = next;

            if (root.open)
                root.seenUpTo = entry.id;

            // Do Not Disturb: still recorded in history, but only critical ones pop up
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [entry].concat(root.popups);
        }
    }
}
