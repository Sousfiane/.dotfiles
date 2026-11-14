pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // ---------- which dropdown is open ----------

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

    // ---------- bar visibility ----------

    readonly property bool anyOpen: current !== "" || WsPanel.open

    // what the bars listen to: stays true 300 ms after the last panel closes
    property bool raised: false

    onAnyOpenChanged: {
        if (anyOpen) {
            lowerTimer.stop();
            raised = true;
        } else {
            lowerTimer.restart();
        }
    }

    Timer {
        id: lowerTimer
        interval: 300
        onTriggered: root.raised = false
    }

    // monitor name -> true once that monitor's bar is completely slid in.
    // SlideArea waits for this before dropping a panel.
    property var barReady: ({})

    function setBarReady(name, ready) {
        if (barReady[name] === ready)
            return;
        const next = Object.assign({}, barReady);
        next[name] = ready;
        barReady = next;
    }

    // monitor name -> { key: [from, to] }: where each dropdown joins the bar.
    // The bar leaves its underline open over these spans.
    property var gaps: ({})

    function setGap(screen, key, from, to) {
        const cur = gaps[screen]?.[key];
        if (cur && cur[0] === from && cur[1] === to)
            return;
        const next = Object.assign({}, gaps);
        next[screen] = Object.assign({}, next[screen] ?? {}, {
            [key]: [from, to]
        });
        gaps = next;
    }

    function clearGap(screen, key) {
        if (!gaps[screen] || !(key in gaps[screen]))
            return;
        const next = Object.assign({}, gaps);
        const inner = Object.assign({}, next[screen]);
        delete inner[key];
        next[screen] = inner;
        gaps = next;
    }
}
