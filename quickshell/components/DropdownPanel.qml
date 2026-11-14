import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import qs.config

Scope {
    id: root

    // ---------- what a panel provides ----------

    required property string name             // IPC target: qs ipc call <name> toggle|close
    property bool open: false                 // bind to the panel's open state
    property string edge: "center"            // "left" | "right" | "center"
    property real cardWidth: 460
    property real cardHeight: 0               // 0 = fit the content
    property real padding: 16
    property string namespace: "qs-" + name   // what Hyprland layer rules match on
    property bool autoFocus: true             // false when the content has its own text input

    // the panel's content: exactly one item, usually a ColumnLayout
    default property Component content

    signal toggleRequested
    signal closeRequested

    // ---------- plumbing ----------

    IpcHandler {
        target: root.name

        function toggle(): void {
            root.toggleRequested();
        }
        function close(): void {
            root.closeRequested();
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
            screen: root.focusedScreen()
            margins.top: Theme.barHeight
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            WlrLayershell.namespace: root.namespace

            Item {
                id: shell
                anchors.fill: parent
                focus: true
                Component.onCompleted: if (root.autoFocus)
                    forceActiveFocus()

                // the content sees every key first; Escape closes if it didn't use it
                Keys.forwardTo: loader.item ? [loader.item] : []
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.closeRequested();
                        event.accepted = true;
                    }
                }

                // click outside to close
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.closeRequested()
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

                        width: Math.min(root.cardWidth, parent.width - 64)
                        height: Math.min(root.cardHeight > 0 ? root.cardHeight : loader.implicitHeight + 2 * root.padding, parent.height - 16)

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
