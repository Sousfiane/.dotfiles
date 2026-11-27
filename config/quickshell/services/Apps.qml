pragma Singleton
import Quickshell
import QtQuick

// Finding the desktop entry an app goes by (its icon and readable name, and how to launch it) from what
// the dock, the workspace cards, the tray and the notifications know of it: a window class, a tray id,
// a notification's app name, a window title. Cached: heuristicLookup walks every entry.
Singleton {
    id: root

    readonly property var all: DesktopEntries.applications.values

    // emptied when entries change (an app installed or removed): they are new objects then
    LookupCache {
        id: cache
    }
    onAllChanged: cache.clear()

    // the entry whose id or StartupWMClass is `name` (any case), else Quickshell's best guess, else null
    function entryFor(name) {
        if (!name)
            return null;
        const key = name.toLowerCase();
        if (cache.has(key))
            return cache.get(key);
        const exact = all.find(a => a.id.toLowerCase() === key || (a.startupClass ?? "").toLowerCase() === key);
        return cache.put(key, exact ?? DesktopEntries.heuristicLookup(name) ?? null);
    }

    // the entry whose name starts a window's title: a game from Heroic runs with a shared class
    // (steam_app_default) that no entry claims, but its title begins with the game's name, the name of
    // the shortcut Heroic writes for it. The longest name wins
    function entryForTitle(title) {
        if (!title)
            return null;
        const key = "title:" + title;
        if (cache.has(key))
            return cache.get(key);
        let best = null;
        for (const a of all)
            if (!a.noDisplay && Games.titleStartsWith(title, a.name) && (!best || a.name.length > best.name.length))
                best = a;
        return cache.put(key, best);
    }

    // the entry of a Hyprland window: by its class, else by its title
    function entryForWindow(w) {
        const cls = Windows.appClass(w);
        if (cls === "")
            return null;
        return entryFor(cls) ?? entryForTitle(w.title ?? "");
    }
}
