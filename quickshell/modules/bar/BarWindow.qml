import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

PanelWindow {
    id: win

    // ---------- always above fullscreen apps ----------
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Theme.barHeight + 1

    // the extra row only holds the underline, so tiled windows still start at the old position
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: Theme.barHeight
    color: "transparent"

    // ---------- auto-hide ----------
    readonly property bool fullscreen: Fullscreen.on(screen?.name ?? "")

    // a dropdown is open on this monitor (or just closed on it), so the bar must be visible
    readonly property bool panelHere: BarState.raised && screen?.name === BarState.raisedScreen

    // set by the pointer touching the top edge
    property bool revealed: false

    readonly property bool shown: !fullscreen || panelHere || revealed

    // the underline, split around every dropdown that is attached to this bar
    readonly property var segments: {
        const gaps = Object.values(BarState.gaps[screen?.name ?? ""] ?? {}).sort((a, b) => a[0] - b[0]);
        const out = [];
        let x = 0;
        for (const g of gaps) {
            if (g[0] > x)
                out.push([x, g[0]]);
            x = Math.max(x, g[1]);
        }
        if (x < width)
            out.push([x, width]);
        return out;
    }

    Timer {
        id: showTimer
        interval: 120                  // small delay so brushing the edge doesn't trigger it
        onTriggered: win.revealed = true
    }
    Timer {
        id: hideTimer
        interval: 400
        onTriggered: win.revealed = false
    }

    // while hidden, only a thin strip at the top receives input, so the app underneath stays clickable
    mask: Region {
        x: 0
        y: 0
        width: win.width
        height: win.shown ? win.height : 2
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered) {
                hideTimer.stop();
                showTimer.restart();
            } else {
                showTimer.stop();
                hideTimer.restart();
            }
        }
    }

    // ---------- the bar itself: this is what slides ----------
    Rectangle {
        id: bar
        width: parent.width
        height: Theme.barHeight
        color: Theme.bg

        y: win.shown ? 0 : -(height + 1)
        // true only when the bar has fully finished sliding in
        readonly property bool fullyIn: win.shown && y === 0

        onFullyInChanged: BarState.setBarReady(win.screen?.name ?? "", fullyIn)
        Component.onCompleted: BarState.setBarReady(win.screen?.name ?? "", fullyIn)

        Behavior on y {
            NumberAnimation {
                duration: 200
                easing.type: win.shown ? Easing.OutCubic : Easing.InCubic
            }
        }

        Workspaces {
            screen: win.screen
            anchors {
                left: parent.left
                leftMargin: 4             // the cells carry their own padding: the first dot stays 16 px in
                verticalCenter: parent.verticalCenter
            }
        }

        ClockButton {
            anchors.centerIn: parent
        }

        RowLayout {
            anchors {
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
            spacing: 12

            DotIcon {}
            UpdatesIcon {}
            NetIcon {}
            BtIcon {}
            VolumeIcon {}
            BellIcon {}
            PowerIcon {}
        }
        // 1px underline. The segments change every frame while a dropdown slides, so the model is only
        // their count: the rectangles are kept and just follow the new positions.
        Repeater {
            model: win.segments.length

            delegate: Rectangle {
                required property int index
                readonly property var seg: win.segments[index] ?? [0, 0]

                x: seg[0]
                y: parent.height
                width: seg[1] - seg[0]
                height: 1
                color: Theme.line
            }
        }
    }
}
