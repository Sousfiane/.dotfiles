import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
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
    implicitHeight: Theme.barHeight
    color: "transparent"

    // ---------- auto-hide ----------
    readonly property bool fullscreen: Fullscreen.on(screen?.name ?? "")

    // a dropdown is open on this monitor (they open on the focused one)
    readonly property bool panelHere: Panels.raised && screen?.name === Hyprland.focusedMonitor?.name

    // set by the pointer touching the top edge
    property bool revealed: false

    readonly property bool shown: !fullscreen || panelHere || revealed

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

        y: win.shown ? 0 : -height
        // true only when the bar has fully finished sliding in
        readonly property bool fullyIn: win.shown && y === 0

        onFullyInChanged: Panels.setBarReady(win.screen?.name ?? "", fullyIn)
        Component.onCompleted: Panels.setBarReady(win.screen?.name ?? "", fullyIn)

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
                leftMargin: 8
                verticalCenter: parent.verticalCenter
            }
        }

        Clock {
            anchors.centerIn: parent
        }

        PowerIcon {
            id: power
            anchors {
                right: parent.right
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
        }

        BellIcon {
            id: bell
            anchors {
                right: power.left
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
        }

        Volume {
            id: volume
            anchors {
                right: bell.left
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
        }

        BtIcon {
            id: bt
            anchors {
                right: volume.left
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
        }

        UpdatesIcon {
            id: updates
            anchors {
                right: bt.left
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
        }

        DotIcon {
            anchors {
                right: updates.left
                rightMargin: 12
                verticalCenter: parent.verticalCenter
            }
        }
    }
}
