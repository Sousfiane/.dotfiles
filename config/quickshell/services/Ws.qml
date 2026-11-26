pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config

Singleton {
    id: root

    property string screenName: ""      // monitor whose panel is shown
    property int wsId: -1               // workspace being shown

    property bool hoverBar: false       // mouse over a workspace dot
    property bool hoverCard: false      // mouse over the card
    property bool hovered: false        // debounced version of the two above

    // ---------- dragging a dot to another monitor's bar ----------
    // the bar the drag started on keeps the pointer until release, so it reports the cursor here
    // and the other bars read it to show where the workspace would land
    property int dragId: -1             // workspace being dragged, -1 when none
    property string dragFrom: ""        // monitor it is on
    property string dragTo: ""          // another monitor whose bar is under the cursor, "" when none
    readonly property bool dragging: dragId >= 0
    property real dragX: 0              // cursor, global (layout) coordinates
    property real dragY: 0

    readonly property bool open: screenName !== "" && hovered && !dragging

    readonly property bool hoverNow: hoverBar || hoverCard
    onHoverNowChanged: {
        if (hoverNow) {
            hoverTimer.stop();
            hovered = true;
        } else {
            hoverTimer.restart();   // short grace period while moving between dot and card
        }
    }

    // make sure window data is fresh whenever the panel opens
    onOpenChanged: if (open)
        Hyprland.refreshToplevels()

    // a Hyprland window's app id (Wayland) or class (XWayland), "" when unknown
    function windowClass(w) {
        return w.wayland?.appId || w.lastIpcObject?.class || "";
    }

    function enterBar(screen, id) {
        screenName = screen;
        wsId = id;
        hoverBar = true;
    }

    // adjacent dots can report the new dot's enter before the old dot's exit:
    // only the dot currently shown may clear the hover
    function leaveBar(screen, id) {
        if (screen === screenName && id === wsId)
            hoverBar = false;
    }

    function startDrag(screen, id) {
        dragFrom = screen;
        dragTo = "";
        dragId = id;
    }

    // gx, gy: the cursor in global (layout) coordinates. A bar counts a little below its own
    // height, so the drop doesn't need a pixel-exact aim.
    function moveDrag(gx, gy) {
        dragX = gx;
        dragY = gy;
        const s = Quickshell.screens.find(s => gx >= s.x && gx < s.x + s.width && gy >= s.y && gy < s.y + Theme.barHeight + 24);
        dragTo = s && s.name !== dragFrom ? s.name : "";
    }

    // the dropped workspace moves to the new monitor and takes the focus there
    function endDrag() {
        if (dragging && dragTo !== "") {
            Hyprland.dispatch(`hl.dsp.workspace.move({ workspace = ${dragId}, monitor = "${dragTo}" })`);
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${dragId} })`);
        }
        dragId = -1;
        dragFrom = "";
        dragTo = "";
    }

    Timer {
        id: hoverTimer
        interval: 180
        onTriggered: root.hovered = false
    }
}
