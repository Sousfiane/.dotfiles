import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services

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

    // hover panels: no keyboard focus, no click-outside, and a window only as big as the card,
    // so the rest of the screen stays clickable
    property bool compact: false
    property var targetScreen: null           // a specific monitor; null = the focused one

    // the panel's content: exactly one item, usually a ColumnLayout
    default property Component content

    signal cardHoverChanged(bool hovered)

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

    SlideLoader {
        open: root.open

        PanelWindow {
            screen: root.targetScreen ?? root.focusedScreen()
            margins.top: Theme.barHeight

            // full-screen overlay for click-driven panels, a card-sized window for hover panels
            anchors {
                top: true
                bottom: !root.compact
                left: !root.compact || root.edge === "left"
                right: !root.compact || root.edge === "right"
            }
            implicitWidth: root.compact ? card.width + card.fl + card.fr + 2 * card.pad + 40 : 0
            implicitHeight: root.compact ? card.height + card.pad + 40 : 0

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: root.compact ? WlrKeyboardFocus.None : WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: root.namespace

            Item {
                id: shell
                anchors.fill: parent
                focus: !root.compact
                Component.onCompleted: if (root.autoFocus && !root.compact)
                    forceActiveFocus()

                // the content sees every key first; Escape closes if it didn't use it
                Keys.forwardTo: loader.item ? [loader.item] : []
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
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
                    open: root.open

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
                        height: {
                            const natural = root.cardHeight > 0 ? root.cardHeight : loader.implicitHeight + 2 * root.padding;
                            return root.compact ? natural : Math.min(natural, parent.height - 16);
                        }

                        // tells hover-driven panels whether the pointer is on the card
                        HoverHandler {
                            onHoveredChanged: root.cardHoverChanged(hovered)
                            Component.onDestruction: root.cardHoverChanged(false)
                        }

                        // swallow clicks on the card
                        MouseArea {
                            anchors.fill: parent
                        }

                        Loader {
                            id: loader
                            anchors {
                                fill: parent
                                margins: root.padding
                            }
                            sourceComponent: root.content
                        }
                    }
                }
            }
        }
    }
}
