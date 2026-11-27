import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// What shows a DropdownPanel: a layer window on the right monitor, the card sliding out from under the bar,
// keyboard focus, click-outside and Esc to close. Each panel has its own, except those on the right edge,
// which share one (shell.qml): switching between them swaps the content inside the same card, which grows or
// shrinks to the new one's size, as the hub does between its tabs.
Scope {
    id: root

    // the panel shown (its size, edge, padding and content); it may change while open (the shared one)
    property var panel: null
    property bool open: false
    property string namespace: panel?.namespace ?? "qs-dropdown"

    readonly property bool compact: panel?.compact ?? false
    readonly property string edge: panel?.edge ?? "center"

    // the monitor it appears on: it follows the focused monitor while closed, then stays put for as long as
    // it is open
    property var lockedScreen: null

    Binding {
        target: root
        property: "lockedScreen"
        value: root.focusedScreen()
        when: !slide.alive              // frozen while open AND while sliding out
        restoreMode: Binding.RestoreNone
    }

    function focusedScreen() {
        const name = Hyprland.focusedMonitor?.name;
        for (let i = 0; i < Quickshell.screens.length; i++)
            if (Quickshell.screens[i].name === name)
                return Quickshell.screens[i];
        return Quickshell.screens[0];
    }

    function close() {
        root.panel?.close();
    }

    // tell Panels where the panel is shown, so the right bar can come in
    function reportScreen() {
        if (root.panel && !root.compact)
            Panels.setScreen(root.panel.name, root.lockedScreen?.name ?? "");
    }
    onLockedScreenChanged: reportScreen()

    // ---------- switching panels while open ----------

    // the panel's `settled`: only the one shown, while the card is fully in
    property bool areaSettled: false
    property var settledPanel: null
    function syncSettled() {
        const now = root.areaSettled ? root.panel : null;
        if (root.settledPanel && root.settledPanel !== now)
            root.settledPanel.settled = false;
        if (now)
            now.settled = true;
        root.settledPanel = now;
    }
    onAreaSettledChanged: syncSettled()

    // another panel while open: its content at once, the card growing or shrinking to it (even for a panel
    // whose content animates its own size)
    property bool switching: false
    onPanelChanged: {
        reportScreen();
        syncSettled();
        if (slide.alive) {
            switching = true;
            switchEnd.restart();
        }
    }
    Timer {
        id: switchEnd
        interval: Motion.normal + 50
        onTriggered: root.switching = false
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
        open: root.open && root.panel !== null

        PanelWindow {
            screen: root.panel?.targetScreen ?? root.lockedScreen
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

                function takeFocus() {
                    if ((root.panel?.autoFocus ?? false) && !root.compact)
                        forceActiveFocus();
                }
                Component.onCompleted: takeFocus()

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
                    onSettledChanged: root.areaSettled = settled
                    Component.onDestruction: root.areaSettled = false

                    DropCard {
                        id: card
                        edge: root.edge

                        readonly property real padding: root.panel?.padding ?? 16

                        anchors {
                            top: parent.top
                            left: root.edge === "left" ? parent.left : undefined
                            right: root.edge === "right" ? parent.right : undefined
                            horizontalCenter: root.edge === "center" ? parent.horizontalCenter : undefined
                        }

                        // compact windows size themselves from the card, so the card must not size itself from the window
                        readonly property real targetWidth: {
                            const w = root.panel?.cardWidth ?? 0;
                            return root.compact ? w : Math.min(w, parent.width - 64);
                        }
                        readonly property real targetHeight: {
                            const h = root.panel?.cardHeight ?? 0;
                            const natural = h > 0 ? h : loader.implicitHeight + 2 * padding;
                            return root.compact ? natural : Math.min(natural, parent.height - 16);
                        }

                        // content that changes size (a prompt, a diff, a list growing, the hub's tabs, another
                        // panel) resizes the card smoothly; not while it slides in or out, where it just takes its size
                        readonly property bool animates: area.settled && ((root.panel?.animateHeight ?? true) || root.switching)
                        width: targetWidth
                        height: targetHeight
                        Behavior on width {
                            enabled: card.animates
                            Anim {}
                        }
                        Behavior on height {
                            enabled: card.animates
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
                            onHoveredChanged: root.panel?.cardHoverChanged(hovered)
                            Component.onDestruction: root.panel?.cardHoverChanged(false)
                        }

                        // swallow clicks on the card
                        MouseArea {
                            anchors.fill: parent
                        }

                        // the content takes its new size at once; the card reveals or trims it as it resizes,
                        // the content staying where it will be once the card has grown or shrunk around it
                        Item {
                            anchors.fill: parent
                            clip: card.height !== card.targetHeight || card.width !== card.targetWidth

                            Loader {
                                id: loader
                                anchors {
                                    top: parent.top
                                    topMargin: card.padding
                                }
                                x: (root.edge === "right" ? card.width - card.targetWidth : root.edge === "center" ? (card.width - card.targetWidth) / 2 : 0) + card.padding
                                width: card.targetWidth - 2 * card.padding
                                height: card.targetHeight - 2 * card.padding
                                sourceComponent: root.panel?.content ?? null
                                // another panel's content: the keyboard comes back to it
                                onLoaded: shell.takeFocus()
                            }
                        }
                    }
                }
            }
        }
    }
}
