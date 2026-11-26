import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// The frame every dropdown panel is built on: a layer window on the right monitor, the card sliding out
// from under the bar, keyboard focus, click-outside and Esc to close, and an IPC target (`qs ipc call
// <name> toggle`). A panel only sets its name, edge and size, and gives its content.
Scope {
    id: root

    // ---------- what a panel provides ----------

    required property string name             // key in Panels.current, and the IPC target
    property bool open: Panels.isOpen(name)   // hover panels override this
    property string edge: "center"            // "left" | "right" | "center"
    property real cardWidth: 460
    property real cardHeight: 0               // 0 = fit the content
    property real padding: 16
    property string namespace: "qs-" + name   // what Hyprland layer rules match on
    property bool autoFocus: true             // false when the content has its own text input
    property bool ipc: true                   // false when the panel registers its own IPC target
    // the card animates its own height changes; false when the content already animates its size
    // (then the card just follows it, frame by frame, instead of chasing it with a second animation)
    property bool animateHeight: true

    // fully slid in and staying: content can start its own size animations from here
    property bool settled: false

    // hover panels: no keyboard focus, no click-outside, and a window only as big as the card,
    // so the rest of the screen stays clickable
    property bool compact: false
    property var targetScreen: null           // a specific monitor; null = the focused one

    // the panel's content: exactly one item, usually a ColumnLayout
    default property Component content

    signal cardHoverChanged(bool hovered)

    // the monitor this panel appears on: it follows the focused monitor while the panel is
    // closed, then stays put for as long as it is open
    property var lockedScreen: null

    Binding {
        target: root
        property: "lockedScreen"
        value: root.focusedScreen()
        when: !slide.alive              // frozen while open AND while sliding out
        restoreMode: Binding.RestoreNone
    }

    // ---------- keyboard focus ----------

    readonly property var lockedMonitor: lockedScreen ? Hyprland.monitorFor(lockedScreen) : null

    // true for a few ms to take the keyboard back after a workspace switch
    property bool priming: false

    // wait until the switch has finished (and Hyprland has focused the new window), so the
    // Exclusive request never overlaps with the switch itself
    Timer {
        id: primeDelay
        interval: 120
        onTriggered: {
            root.priming = true;
            primeEnd.restart();
        }
    }

    Timer {
        id: primeEnd
        interval: 75
        onTriggered: root.priming = false
    }

    // anything that moves the keyboard elsewhere while the panel is open (a workspace switch, the pointer
    // reaching another monitor, a keybind focusing a window) is answered by taking it back, so Escape and
    // the panel's keys work whichever screen is focused. Restarts on every change: a burst primes once.
    Connections {
        target: root.lockedMonitor
        enabled: root.open && !root.compact

        function onActiveWorkspaceChanged() {
            primeDelay.restart();
        }
    }

    Connections {
        target: Hyprland
        enabled: root.open && !root.compact

        function onFocusedMonitorChanged() {
            primeDelay.restart();
        }
        function onActiveToplevelChanged() {
            primeDelay.restart();
        }
    }

    // tell Panels where this panel is shown, so the right bar can come in
    onLockedScreenChanged: if (!root.compact)
        Panels.setScreen(root.name, lockedScreen?.name ?? "")

    // and which edge it hangs from, so the bar item above it can light up
    onEdgeChanged: if (!root.compact)
        Panels.setEdge(root.name, edge)
    Component.onCompleted: if (!root.compact)
        Panels.setEdge(root.name, edge)

    function close() {
        Panels.hide(name);
    }

    function toggle() {
        Panels.toggle(name);
    }

    // ---------- plumbing ----------

    IpcHandler {
        enabled: root.ipc
        target: root.name

        function toggle(): void {
            root.toggle();
        }
        function close(): void {
            root.close();
        }
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor?.name;
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        return Quickshell.screens[0];
    }

    // ---------- the other monitors ----------

    // while a click-driven panel is open, every other monitor gets an invisible layer that closes it on click,
    // so clicking anywhere behaves the same whichever screen the pointer is on
    Variants {
        model: root.open && !root.compact ? Quickshell.screens.filter(s => s.name !== root.lockedScreen?.name) : []

        PanelWindow {
            required property var modelData

            screen: modelData
            margins.top: Theme.barHeight        // like the panel's own overlay: the bar stays usable
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None      // the keyboard stays with the panel
            WlrLayershell.namespace: "qs-catcher"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
                onClicked: root.close()
            }
        }
    }

    SlideLoader {
        id: slide
        open: root.open

        PanelWindow {
            screen: root.targetScreen ?? root.lockedScreen
            margins.top: Theme.barHeight

            // full-screen overlay for click-driven panels, a card-sized window for hover panels
            anchors {
                top: true
                bottom: !root.compact
                left: !root.compact || root.edge === "left"
                right: !root.compact || root.edge === "right"
            }
            implicitWidth: root.compact ? card.width + card.fl + card.fr + 2 * card.pad + 40 : 0
            // grows at once, so the card never outgrows its window, and never shrinks while open: resizing the
            // surface lags behind the card (stutter) or flashes a frame (blink). The window goes away on close,
            // and the mask below keeps the unused space underneath click-through.
            implicitHeight: root.compact ? card.windowHeight + card.pad + 40 : 0
            mask: root.compact ? cardRegion : null

            Region {
                id: cardRegion
                item: card
            }

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            // OnDemand most of the time: an exclusive layer makes Hyprland ignore focus changes and jump back to a
            // stale window when it closes. Exclusive is only requested briefly, to take the keyboard back.
            WlrLayershell.keyboardFocus: (root.compact || !root.open) ? WlrKeyboardFocus.None : (root.priming ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand)
            WlrLayershell.namespace: root.namespace

            Item {
                id: shell
                anchors.fill: parent
                focus: !root.compact
                Component.onCompleted: if (root.autoFocus && !root.compact)
                    forceActiveFocus()

                // the content sees every key first; Escape closes if it didn't use it.
                // Close on release, not press: closing hands the keyboard back to the window
                // underneath, which would otherwise get the still-held Escape (and e.g. a
                // fullscreen video in the browser would leave fullscreen).
                property bool escArmed: false
                Keys.forwardTo: loader.item ? [loader.item] : []
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        if (!event.isAutoRepeat)
                            escArmed = true;
                        event.accepted = true;
                    }
                }
                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Escape && !event.isAutoRepeat && escArmed) {
                        escArmed = false;
                        root.close();
                        event.accepted = true;
                    }
                }

                // click outside to close
                MouseArea {
                    anchors.fill: parent
                    enabled: !root.compact
                    onClicked: root.close()
                }

                SlideArea {
                    id: area
                    open: root.open
                    onSettledChanged: root.settled = settled
                    Component.onDestruction: root.settled = false

                    DropCard {
                        id: card
                        edge: root.edge

                        anchors {
                            top: parent.top
                            left: root.edge === "left" ? parent.left : undefined
                            right: root.edge === "right" ? parent.right : undefined
                            horizontalCenter: root.edge === "center" ? parent.horizontalCenter : undefined
                        }

                        // compact windows size themselves from the card, so the card must not size itself from the window
                        width: root.compact ? root.cardWidth : Math.min(root.cardWidth, parent.width - 64)
                        readonly property real targetHeight: {
                            const natural = root.cardHeight > 0 ? root.cardHeight : loader.implicitHeight + 2 * root.padding;
                            return root.compact ? natural : Math.min(natural, parent.height - 16);
                        }

                        // content that changes size (a prompt, a diff, a list growing) resizes the card
                        // smoothly; not while it slides in or out, where it just takes its size
                        height: targetHeight
                        Behavior on height {
                            enabled: area.settled && root.animateHeight
                            Anim {}
                        }

                        // the height the compact window holds: the tallest the card has been since it opened
                        property real windowHeight: 0
                        function syncWindow() {
                            windowHeight = Math.max(windowHeight, height, targetHeight);
                        }
                        onHeightChanged: syncWindow()
                        onTargetHeightChanged: syncWindow()
                        Component.onCompleted: syncWindow()

                        // tells hover-driven panels whether the pointer is on the card
                        HoverHandler {
                            onHoveredChanged: root.cardHoverChanged(hovered)
                            Component.onDestruction: root.cardHoverChanged(false)
                        }

                        // swallow clicks on the card
                        MouseArea {
                            anchors.fill: parent
                        }

                        // the content takes its new size at once; the card reveals or trims it as it resizes
                        Item {
                            anchors.fill: parent
                            clip: card.height !== card.targetHeight

                            Loader {
                                id: loader
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                    margins: root.padding
                                }
                                height: card.targetHeight - 2 * root.padding
                                sourceComponent: root.content
                            }
                        }
                    }
                }
            }
        }
    }
}
