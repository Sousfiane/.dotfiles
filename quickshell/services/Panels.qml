pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // "" = none. Only one dropdown can be open, by construction.
    property string current: ""

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
