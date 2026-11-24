pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root

    // Every notification is a Notif (see Notif.qml), shared by the toasts and the center. The views take
    // these lists as models: a ScriptModel diffs them by object, so a change touches one card only.
    property var history: []      // Notif objects, newest first, what the center shows
    readonly property var popups: history.filter(n => n.popup)

    readonly property int maxHistory: 50
    property int nextId: 0

    property bool dnd: false
    // everything up to this id has been seen (the center was open when it came, or opened since).
    // Derived from the history, so a notification removed from a toast or the center leaves the count too
    property int seenUpTo: -1
    readonly property int unread: history.filter(n => n.id > seenUpTo).length

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

    // drops it everywhere and lets the app know it was dismissed
    function remove(n: Notif) {
        if (!history.includes(n))
            return;
        history = history.filter(x => x !== n);
        n.notification?.dismiss();
        dropImage(n.savedImage);
        // a toast or card may still be sliding out with it
        n.destroy(1000);
    }

    function clearHistory() {
        for (const n of history.slice())
            remove(n);
    }

    // its toast's time is up: the app may have asked not to be kept around
    function expire(n: Notif) {
        if (n.fleeting)
            remove(n);
        else
            n.popup = false;
    }

    // ---------- going to the app ----------

    // the notification's own "default" action: the app opens the right tab or conversation itself
    function invokeDefault(live) {
        const action = live?.actions.find(a => a.identifier === "default");
        action?.invoke();
        return !!action;
    }

    function desktopEntryFor(n) {
        const id = n.desktopEntry.replace(/\.desktop$/, "");
        return (id !== "" ? DesktopEntries.byId(id) : null) ?? (n.appName !== "" ? DesktopEntries.heuristicLookup(n.appName) : null);
    }

    // every name the app's windows could go by, lowercased
    function namesFor(n, desktop) {
        const names = [n.desktopEntry.replace(/\.desktop$/, ""), n.appName, desktop?.id ?? "", desktop?.startupClass ?? ""];
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
    function activate(n: Notif) {
        const invoked = invokeDefault(n.notification);
        const desktop = desktopEntryFor(n);
        const win = windowFor(namesFor(n, desktop));

        Panels.hide("notifs");

        if (win)
            focusWindow(win);              // also when the action ran: Wayland apps can't always raise themselves
        else if (!invoked && desktop)
            Launcher.run(desktop);         // not running: start it

        remove(n);
    }

    // ---------- saved images ----------

    // raw images copied to files (see Notif.setImage), named by time and id so they never clash
    readonly property string imageDir: Quickshell.cachePath("notif-images")

    function dropImage(path: string) {
        if (path.startsWith(imageDir + "/"))
            Quickshell.execDetached(["rm", "-f", path]);
    }

    // ---------- the history on disk ----------

    // so a restart or a config reload doesn't lose it. Live notifications aren't carried over
    // (keepOnReload is off): what comes back is the copy, still readable and clickable to go to the app.
    FileView {
        id: store
        path: Quickshell.statePath("notifs.json")
        blockLoading: true
        printErrors: false
    }

    readonly property var savedFields: ["id", "appName", "appIcon", "desktopEntry", "summary", "body", "image", "savedImage", "urgency", "time"]

    function save() {
        const entries = history.filter(n => !n.fleeting).map(n => {
            const e = {};
            for (const f of savedFields)
                e[f] = n[f];
            // a raw image that isn't saved yet won't exist after a restart
            if (e.image.startsWith("image://qsimage/"))
                e.image = "";
            return e;
        });
        store.setText(JSON.stringify({
            nextId,
            seenUpTo,
            history: entries
        }));
    }

    // written once per event loop turn, whatever changed in it
    property bool saveQueued: false
    function queueSave() {
        if (saveQueued)
            return;
        saveQueued = true;
        Qt.callLater(() => {
            saveQueued = false;
            save();
        });
    }

    onHistoryChanged: queueSave()
    onSeenUpToChanged: queueSave()

    Component {
        id: notifComp
        Notif {
            id: made
            // edits made after it came (a player's next track, an image saved to a file) are kept too
            onSummaryChanged: root.queueSave()
            onBodyChanged: root.queueSave()
            onImageChanged: root.queueSave()
            onExpired: root.expire(made)
        }
    }

    Component.onCompleted: {
        Quickshell.execDetached(["mkdir", "-p", imageDir]);
        try {
            const data = JSON.parse(store.text() || "{}");
            const restored = (data.history ?? []).map(e => notifComp.createObject(root, e));
            history = restored.slice(0, maxHistory);
            nextId = Math.max(data.nextId ?? 0, ...restored.map(n => n.id + 1));
            seenUpTo = data.seenUpTo ?? nextId - 1;
        } catch (e) {
            console.warn("Could not load the notification history:", e);
        }
    }

    // ---------- the server ----------

    NotificationServer {
        id: server
        keepOnReload: false
        persistenceSupported: true
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: live => {
            // kept alive while it is in the history, so it stays clickable
            live.tracked = true;

            const n = notifComp.createObject(root, {
                id: root.nextId++
            });
            n.follow(live);
            // the app closed it, or it was dismissed: the copy stays, its toast goes
            live.closed.connect(() => {
                n.notification = null;
                n.popup = false;
            });

            const next = [n].concat(root.history);
            for (const old of next.splice(root.maxHistory))
                root.remove(old);
            root.history = next;

            if (root.open)
                root.seenUpTo = n.id;

            // Do Not Disturb: still recorded in history, but only critical ones pop up
            n.popup = !root.dnd || n.critical;
        }
    }
}
