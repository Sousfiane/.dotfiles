pragma Singleton
import Quickshell
import QtQuick
import qs.config

Singleton {
    id: root

    // "" = none. Only one dropdown can be open, by construction.
    property string current: ""

    // how long a dropdown takes to be fully gone after closing (its slide out, plus a margin)
    readonly property int closeMs: Motion.out + 40

    function isOpen(name) {
        return current === name;
    }

    function show(name) {
        current = name;
    }

    function toggle(name) {
        current = current === name ? "" : name;
    }

    // closes `name`, but only if it is the open one: a panel that is still sliding out
    // must not be able to close the panel that replaced it
    function hide(name) {
        if (current === name)
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
}
