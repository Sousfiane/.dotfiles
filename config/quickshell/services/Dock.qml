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

    // window classes that have no desktop entry still get an icon: keyed by "class:<name>"
    function keyFor(w) {
        const cls = windowClass(w);
        if (cls === "")
            return "";
        const e = entryFor(cls);
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
