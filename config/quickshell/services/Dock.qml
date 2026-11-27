pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick
import qs.config

// The dock's apps: the pinned ones in their order, then whatever else has a window open.
// Pins are desktop entry ids, saved in the state dir; Config.dockPins is the list before the first change.
Singleton {
    id: root

    property var pins: []

    FileView {
        id: pinsFile

        path: Quickshell.statePath("dock-pins.json")
        blockLoading: true
        printErrors: false
    }

    Component.onCompleted: {
        try {
            const data = pinsFile.text();
            pins = data.length > 0 ? JSON.parse(data) : Config.dockPins.slice();
        } catch (e) {
            console.warn("Could not load dock pins:", e);
            pins = Config.dockPins.slice();
        }
    }

    function save(next) {
        pins = next;
        pinsFile.setText(JSON.stringify(next, null, 2));
    }

    function isPinned(id: string): bool {
        return pins.includes(id);
    }

    function pin(id: string): void {
        if (id !== "" && !isPinned(id))
            save(pins.concat([id]));
    }

    function unpin(id: string): void {
        save(pins.filter(p => p !== id));
    }

    function togglePin(id: string): void {
        isPinned(id) ? unpin(id) : pin(id);
    }

    // moves a pin to position `to` (an index in the pinned list)
    function movePin(id: string, to: int): void {
        const rest = pins.filter(p => p !== id);
        rest.splice(Math.max(0, Math.min(to, rest.length)), 0, id);
        if (rest.join("\n") !== pins.join("\n"))
            save(rest);
    }

    // ---------- windows -> apps ----------

    // the class a window is matched on: floating terminals carry a custom class, they are the terminal
    function windowClass(w) {
        const c = Ws.windowClass(w);
        return c === Config.floatingClass ? Config.terminal : c;
    }

    // the desktop entry a window class belongs to, cached (heuristicLookup walks every entry)
    property var entryCache: ({})
    readonly property var allApps: DesktopEntries.applications.values
    onAllAppsChanged: {
        entryCache = ({});
        itemCache = ({});           // entries are new objects after an app is installed or removed
    }

    function entryFor(cls) {
        const key = cls.toLowerCase();
        if (key in entryCache)
            return entryCache[key];
        const exact = allApps.find(a => a.id.toLowerCase() === key || (a.startupClass ?? "").toLowerCase() === key);
        return entryCache[key] = exact ?? DesktopEntries.heuristicLookup(cls) ?? null;
    }

    // a letter (accented ones too) or a digit: "" past the end of a string is not
    function isWordChar(c) {
        return c !== "" && (c.toLowerCase() !== c.toUpperCase() || (c >= "0" && c <= "9"));
    }

    // the desktop entry whose name starts a window's title: a game from Heroic runs with a shared class
    // (steam_app_default) that no entry claims, but its title begins with the game's name
    // ("Cyberpunk 2077 (C) 2020 by CD Projekt RED"), which is the name of the entry Heroic writes for it.
    // The name must end at a word boundary, and the longest one wins
    function entryForTitle(title) {
        if (title === "")
            return null;
        const t = title.toLowerCase();
        const key = "title:" + t;
        if (key in entryCache)
            return entryCache[key];
        let best = null;
        for (const a of allApps) {
            const n = (a.name ?? "").toLowerCase();
            if (a.noDisplay || n === "" || !t.startsWith(n) || isWordChar(t.charAt(n.length)))
                continue;
            if (!best || n.length > best.name.length)
                best = a;
        }
        return entryCache[key] = best;
    }

    // the desktop entry of a window: by its class, else by its title
    function entryForWindow(w) {
        const cls = windowClass(w);
        if (cls === "")
            return null;
        return entryFor(cls) ?? entryForTitle(w.title ?? "");
    }

    // window classes that have no desktop entry still get an icon: keyed by "class:<name>"
    function keyFor(w) {
        const cls = windowClass(w);
        if (cls === "")
            return "";
        const e = entryForWindow(w);
        return e ? e.id : "class:" + cls;
    }

    // app key -> its windows, oldest first
    readonly property var windowsByApp: {
        const out = {};
        for (const w of Hyprland.toplevels.values) {
            const k = keyFor(w);
            if (k === "")
                continue;
            (out[k] = out[k] ?? []).push(w);
        }
        return out;
    }

    readonly property string activeKey: Hyprland.activeToplevel ? keyFor(Hyprland.activeToplevel) : ""

    // One object per dock icon, reused across updates so the dock's model diffs by identity:
    //   { key, entry (null for a bare class), pinned }
    property var itemCache: ({})

    function itemFor(key, pinned) {
        const id = key + (pinned ? "#p" : "");
        if (itemCache[id])
            return itemCache[id];
        const entry = key.startsWith("class:") ? null : DesktopEntries.byId(key);
        return itemCache[id] = {
            key,
            entry,
            pinned,
            name: entry?.name ?? key.slice(6),
            icon: entry?.icon ?? key.slice(6).toLowerCase()
        };
    }

    // re-read once the desktop entries are scanned: right after startup byId() still finds nothing
    readonly property var pinnedItems: allApps.length >= 0 ? pins.filter(id => DesktopEntries.byId(id) !== null).map(id => itemFor(id, true)) : []
    readonly property var runningItems: Object.keys(windowsByApp).filter(k => !pins.includes(k)).sort().map(k => itemFor(k, false))

    // what an icon is called: its desktop entry's name, else its first window's title (a game started
    // from Heroic or a cracked exe has no entry and a class like steam_app_default; its title is the
    // game's name), else the class
    function nameFor(item) {
        if (!item)
            return "";
        if (item.entry)
            return item.name ?? "";
        return (windowsByApp[item.key] ?? [])[0]?.title || item.name || "";
    }

    // ---------- actions ----------

    function addr(w) {
        return "0x" + String(w.address).replace(/^0x/, "");
    }

    function focusWindow(w) {
        Hyprland.dispatch(`hl.dsp.focus({ window = "address:${addr(w)}" })`);
    }

    function closeWindow(w) {
        Hyprland.dispatch(`hl.dsp.window.close({ window = "address:${addr(w)}" })`);
    }

    // not running: start it. Running: focus its window, and on the next click the one after it
    function activate(item) {
        const wins = windowsByApp[item.key] ?? [];
        if (wins.length === 0) {
            launch(item);
            return;
        }
        const cur = wins.indexOf(Hyprland.activeToplevel);
        focusWindow(wins[(cur + 1) % wins.length]);
    }

    function launch(item) {
        if (!item.entry)
            return;
        LauncherHistory.record(item.entry.id);
        Launcher.run(item.entry, null);
    }

    function closeAll(item) {
        for (const w of windowsByApp[item.key] ?? [])
            closeWindow(w);
    }

    // always up like macOS's dock (windows keep clear of it), or hidden until the bottom edge is touched.
    // Picked in the theme panel, saved next to the pins.
    property bool alwaysShow: false

    FileView {
        id: settingsFile

        path: Quickshell.statePath("dock-settings.json")
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                root.alwaysShow = JSON.parse(text()).alwaysShow === true;
            } catch (e) {}
        }
    }

    function setAlwaysShow(on: bool): void {
        alwaysShow = on;
        settingsFile.setText(JSON.stringify({
            alwaysShow: on
        }, null, 2));
    }

    // held up from the keyboard (`qs ipc call dock toggle`), on every monitor
    property bool forced: false

    IpcHandler {
        target: "dock"

        function toggle(): void {
            root.forced = !root.forced;
        }

        function pin(id: string): void {
            root.pin(id);
        }
        function unpin(id: string): void {
            root.unpin(id);
        }
    }
}
