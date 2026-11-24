import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

PanelWindow {
    id: win

    // ---------- always above fullscreen apps ----------
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        left: true
        right: true
    }
    // in fullscreen the window grows to hold the stand-in title bar under the underline
    implicitHeight: Theme.barHeight + 1 + (fullscreen ? fsTitle.height : 0)

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

    // the stand-in title bar only answers the pointer: a dropdown alone brings back just the bar
    readonly property bool titleShown: fullscreen && revealed

    // the title bar is down, or riding the bar out of the screen. Only then does the bar's slide take
    // the title bar's height too: a bar hiding on its own (a fullscreen window landing on this monitor,
    // a dropdown closing) travels just its own height, at its own pace.
    property bool titleOut: false
    onTitleShownChanged: {
        if (titleShown)
            titleOut = true;
        else if (shown)
            titleOut = false;          // the bar stays: only the title bar tucks back
    }
    onShownChanged: {
        if (shown && !titleShown)
            titleOut = false;          // back for a dropdown: the bar comes alone
    }

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
        // shown in fullscreen: the title bar below is clickable too, but only while it is down
        height: !win.shown ? 2 : win.titleShown ? win.height : Theme.barHeight + 1
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

        // in fullscreen it also takes the title bar hanging under it out of the screen: one block, like macOS
        y: win.shown ? 0 : -(bar.height + 1 + (win.titleOut ? fsTitle.height : 0))
        // true only when the bar has fully finished sliding in
        readonly property bool fullyIn: win.shown && y === 0

        onFullyInChanged: BarState.setBarReady(win.screen?.name ?? "", fullyIn)
        Component.onCompleted: BarState.setBarReady(win.screen?.name ?? "", fullyIn)

        Behavior on y {
            Anim {
                duration: win.shown ? Motion.normal : Motion.out
                curve: win.shown ? Motion.enter : Motion.exit
            }
        }

        WsIcons {
            screen: win.screen
            edgeGap: 11                   // the cells carry 5 px of padding: the first dot stays 16 px in
            anchors {
                left: parent.left
                leftMargin: edgeGap
                verticalCenter: parent.verticalCenter
            }
        }

        ClockButton {
            anchors.centerIn: parent
        }

        RowLayout {
            id: rightItems
            readonly property real edgeGap: 16   // same as the first workspace dot on the left

            anchors {
                right: parent.right
                rightMargin: edgeGap
                verticalCenter: parent.verticalCenter
            }
            spacing: 18                          // the visible gap: each slot is exactly its glyph's ink

            TrayIcon {}
            DotIcon {}
            UpdatesIcon {}
            NetIcon {}
            BtIcon {}
            VolumeIcon {}
            BellIcon {}
            PowerIcon {
                edge: "right"                         // last one: reaches the screen edge
                edgeGap: rightItems.edgeGap
            }
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

    // ---------- fullscreen: the window's title bar comes back with the bar ----------
    FullscreenTitleBar {
        id: fsTitle
        screenName: win.screen?.name ?? ""
        visible: win.fullscreen
        width: parent.width
        z: -1                          // tucks behind the bar when it is pulled up

        // pulled up behind the bar while only a dropdown holds the bar out
        property real tuck: win.titleOut ? 0 : -(height + bar.height + 1)
        // tucking in while the bar slides down (it came back for a dropdown) runs on the bar's own
        // curve, so the two cancel out and the title bar never peeks out under it
        readonly property bool withBar: win.titleOut || bar.y !== 0
        Behavior on tuck {
            Anim {
                duration: fsTitle.withBar ? Motion.normal : Motion.out
                curve: fsTitle.withBar ? Motion.enter : Motion.exit
            }
        }

        // hangs right under the underline and rides the bar's slide, so the two move as one block
        y: bar.y + bar.height + 1 + tuck
    }
}
