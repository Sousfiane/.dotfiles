pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property string screenName: ""      // monitor whose panel is shown
    property int wsId: -1               // workspace being shown

    property bool hoverBar: false       // mouse over a workspace dot
    property bool hoverCard: false      // mouse over the card
    property bool hovered: false        // debounced version of the two above

    readonly property bool open: screenName !== "" && hovered

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

    Timer {
        id: hoverTimer
        interval: 180
        onTriggered: root.hovered = false
    }
}
