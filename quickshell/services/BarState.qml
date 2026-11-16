pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // ---------- when the bar must be visible ----------

    readonly property bool anyOpen: Panels.current !== "" || Ws.open

    // the monitor whose bar must be visible: the one showing the open dropdown,
    // or the one showing the workspace hover panel
    readonly property string activeScreen: Panels.current !== "" ? Panels.activeScreen : Ws.open ? Ws.screenName : ""

    // what the bars listen to: both stay set for 300 ms after the last panel closes
    property bool raised: false
    property string raisedScreen: ""

    onActiveScreenChanged: if (activeScreen !== "")
        raisedScreen = activeScreen

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
        onTriggered: {
            root.raised = false;
            root.raisedScreen = "";
        }
    }

    // ---------- bar fully slid in ----------

    // monitor name -> true once that monitor's bar is completely in.
    // SlideArea waits for this before dropping a panel.
    property var barReady: ({})

    function setBarReady(name, ready) {
        if (barReady[name] === ready)
            return;
        const next = Object.assign({}, barReady);
        next[name] = ready;
        barReady = next;
    }

    // ---------- underline gaps ----------

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
