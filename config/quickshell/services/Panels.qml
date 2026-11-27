pragma Singleton
import Quickshell
import QtQuick
import qs.config

// Which dropdown is open: one at a time, on the monitor it was opened from, with the helpers to open,
// close and chain them.
Singleton {
    id: root

    // "" = none. Only one dropdown can be open, by construction.
    property string current: ""

    // how long a dropdown takes to be fully gone after closing (its slide out, plus a margin)
    readonly property int closeMs: Motion.out + 40

    function isOpen(name) {
        return current === name;
    }

    // ---------- pickers shown inside the hub ----------

    // each picker's card, [width, height] (0 = as tall as its content), the same in its own panel and as
    // the hub's tab (the hub grows or shrinks to it)
    readonly property var pickerSizes: ({
            launcher: [560, 440],
            wallpaper: [1000, 760],
            theme: [420, 0],
            clipboard: [1000, 760],
            screenshot: [420, 0],
            keybinds: [640, 620],
            install: [640, 520],
            remove: [640, 520]
        })

    // the hub's tab: "home", "system", "about", or a picker's name ("launcher", "wallpaper"...), whose
    // content the hub then shows as that tab
    property string hubTab: "home"

    // a picker is on screen: in its own panel, or as the hub's tab. What services go by
    function isShown(name) {
        return current === name || (current === "hub" && hubTab === name);
    }

    function show(name) {
        current = name;
    }

    function toggle(name) {
        current = current === name ? "" : name;
    }

    // closes `name`, but only if it is the open one: a panel that is still sliding out
    // must not be able to close the panel that replaced it. A picker shown as the hub's tab closes the hub
    function hide(name) {
        if (isShown(name))
            current = "";
    }

    function closeAll() {
        current = "";
    }

    // close whatever is open, then run `fn` once it has slid away (after `delay` ms, closeMs by default).
    // Also waits for a panel that was closed just before: the power menu closes itself, then locks.
    // A newer call replaces a pending one.
    function closeThen(fn, delay) {
        closeAll();
        const wait = closedAt + (delay ?? closeMs) - Date.now();
        if (wait <= 0) {
            fn();
            return;
        }
        afterClose = fn;
        closeTimer.interval = wait;
        closeTimer.restart();
    }

    // when a dropdown last went away (opening another one counts too)
    property real closedAt: 0
    property string lastShown: ""
    onCurrentChanged: {
        if (lastShown !== "")
            closedAt = Date.now();
        lastShown = current;
    }

    property var afterClose: null

    Timer {
        id: closeTimer
        onTriggered: {
            const fn = root.afterClose;
            root.afterClose = null;
            if (fn)
                fn();
        }
    }

    // monitor each dropdown is (or would be) shown on, reported by the panels themselves
    property var screens: ({})

    function setScreen(name, screen) {
        if (screens[name] === screen)
            return;
        screens = Object.assign({}, screens, {
            [name]: screen
        });
    }

    // the monitor showing the open dropdown ("" when none)
    readonly property string activeScreen: current !== "" ? (screens[current] ?? "") : ""

    // edge each dropdown hangs from ("left" | "right" | "center"), reported by the panels themselves
    property var edges: ({})

    function setEdge(name, edge) {
        if (edges[name] === edge)
            return;
        edges = Object.assign({}, edges, {
            [name]: edge
        });
    }

    // the open dropdown's edge ("" when none): the clock lights up for any center panel
    readonly property string activeEdge: current !== "" ? (edges[current] ?? "") : ""

    // the dropdowns shown in the window the right edge's share (SharedDropdown), by name
    property var panels: ({})

    function setPanel(name, panel) {
        if ((panels[name] ?? null) === panel)
            return;
        const next = Object.assign({}, panels);
        if (panel)
            next[name] = panel;
        else
            delete next[name];
        panels = next;
    }
}
