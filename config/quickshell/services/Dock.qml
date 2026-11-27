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

    JsonFile {
        id: pinsFile
        path: Quickshell.statePath("dock-pins.json")
    }

    Component.onCompleted: {
        pins = pinsFile.load(Config.dockPins.slice());
        alwaysShow = settingsFile.load({}).alwaysShow === true;
    }

    function save(next) {
        pins = next;
        pinsFile.save(next);
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

    // item objects hold their entry: rebuilt when the entries change (an app installed or removed)
    Connections {
        target: Apps
        function onAllChanged() {
            root.itemCache = ({});
        }
    }

    // a window with no desktop entry: a game of Steam or Heroic is keyed by "game:<name>" (its own icon
    // even when games share a class), anything else by "class:<name>"
    function keyFor(w) {
        const cls = Windows.appClass(w);
        if (cls === "")
            return "";
        const e = Apps.entryForWindow(w);
        if (e)
            return e.id;
        const g = Games.gameFor(cls, w.title ?? "");
        return g ? "game:" + g.name : "class:" + cls;
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
    //   { key, entry (null for a game or a bare class), game (its cover art for an icon), pinned }
    property var itemCache: ({})

    Connections {
        target: Games
        function onGamesChanged() {
            root.itemCache = ({});
        }
    }

    function itemFor(key, pinned) {
        const id = key + (pinned ? "#p" : "");
        if (itemCache[id])
            return itemCache[id];
        if (key.startsWith("game:")) {
            const name = key.slice(5);
            const game = Games.games.find(g => g.name === name);
            return itemCache[id] = { key, entry: null, game: true, pinned, name, icon: game?.art ?? "" };
        }
        const entry = key.startsWith("class:") ? null : DesktopEntries.byId(key);
        return itemCache[id] = {
            key,
            entry,
            game: false,
            pinned,
            name: entry?.name ?? key.slice(6),
            icon: entry?.icon ?? key.slice(6).toLowerCase()
        };
    }

    // re-read once the desktop entries are scanned: right after startup byId() still finds nothing
    readonly property var pinnedItems: Apps.all.length >= 0 ? pins.filter(id => DesktopEntries.byId(id) !== null).map(id => itemFor(id, true)) : []
    readonly property var runningItems: Object.keys(windowsByApp).filter(k => !pins.includes(k)).sort().map(k => itemFor(k, false))

    // what an icon is called: its desktop entry's or game's name, else its first window's title (a
    // cracked exe has no entry and a class like steam_app_default; its title is its name), else the class
    function nameFor(item) {
        if (!item)
            return "";
        if (item.entry || item.game)
            return item.name ?? "";
        return (windowsByApp[item.key] ?? [])[0]?.title || item.name || "";
    }

    // ---------- actions ----------

    // not running: start it. Running: focus its window, and on the next click the one after it
    function activate(item) {
        const wins = windowsByApp[item.key] ?? [];
        if (wins.length === 0) {
            launch(item);
            return;
        }
        const cur = wins.indexOf(Hyprland.activeToplevel);
        Windows.focus(wins[(cur + 1) % wins.length]);
    }

    function launch(item) {
        if (!item.entry)
            return;
        LauncherHistory.record(item.entry.id);
        Launcher.run(item.entry, null);
    }

    function closeAll(item) {
        for (const w of windowsByApp[item.key] ?? [])
            Windows.close(w);
    }

    // always up like macOS's dock (windows keep clear of it), or hidden until the bottom edge is touched.
    // Picked in the theme panel, saved next to the pins.
    property bool alwaysShow: false

    JsonFile {
        id: settingsFile
        path: Quickshell.statePath("dock-settings.json")
    }

    function setAlwaysShow(on: bool): void {
        alwaysShow = on;
        settingsFile.save({
            alwaysShow: on
        });
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
