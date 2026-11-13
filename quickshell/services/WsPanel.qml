pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQml

Singleton {
    id: root

    property string screenName: ""      // monitor whose panel is shown
    property int wsId: -1               // workspace being shown

    property bool hoverBar: false       // mouse over a workspace dot
    property bool hoverCard: false      // mouse over the card
    property bool hovered: false        // debounced version of the two above
    property bool peek: false           // briefly shown after a workspace switch
    property bool ready: false          // ignore the startup workspace events

    readonly property bool open: screenName !== "" && (hovered || peek)

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

    function leaveBar() {
        hoverBar = false;
    }

    function showPeek(monitor) {
        if (!ready || !monitor.activeWorkspace)
            return;
        screenName = monitor.name;
        wsId = monitor.activeWorkspace.id;
        peek = true;
        peekTimer.restart();
    }

    Timer {
        id: hoverTimer
        interval: 180
        onTriggered: root.hovered = false
    }
    Timer {
        id: peekTimer
        interval: 1500
        onTriggered: root.peek = false
    }
    Timer {
        running: true
        interval: 1500
        onTriggered: root.ready = true
    }

    // one watcher per monitor: switching workspace on a monitor shows its panel
    Instantiator {
        model: Hyprland.monitors

        delegate: QtObject {
            id: watcher
            required property var modelData

            property var conn: Connections {
                target: watcher.modelData

                function onActiveWorkspaceChanged() {
                    root.showPeek(watcher.modelData);
                }
            }
        }
    }
}
