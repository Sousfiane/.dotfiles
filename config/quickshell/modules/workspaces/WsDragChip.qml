import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// While a workspace dot is dragged out of the bar, a chip rides under the cursor: the workspace's
// pill and number, plus the monitor it would move to once the cursor is over that bar.
// One click-through overlay per screen, each drawing the chip only where the cursor is on it;
// they exist only during a drag.
Variants {
    model: Quickshell.screens

    LazyLoader {
        id: loader
        required property var modelData

        active: Ws.dragging

        PanelWindow {
            id: win
            screen: loader.modelData

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-drag"
            mask: Region {}   // click-through: the bar the drag started on keeps the pointer anyway

            Rectangle {
                id: chip

                readonly property bool target: Ws.dragTo !== ""

                // below and right of the cursor, clear of the pointer itself
                x: Ws.dragX - loader.modelData.x + 14
                y: Ws.dragY - loader.modelData.y + 18
                width: row.implicitWidth + 20
                height: 26
                radius: height / 2
                color: Theme.bg
                border.color: chip.target ? Theme.accent : Theme.line

                Behavior on width {
                    Anim {
                        duration: Motion.fast
                    }
                }
                Behavior on border.color {
                    CAnim {}
                }

                // created at 0, so it fades in on the first frame too
                property bool started: false
                Component.onCompleted: Qt.callLater(() => started = true)
                opacity: started ? 1 : 0
                Behavior on opacity {
                    Anim {
                        duration: Motion.fast
                    }
                }

                RowLayout {
                    id: row
                    anchors.centerIn: parent
                    spacing: 7

                    // the bar's shown-workspace pill
                    Rectangle {
                        implicitWidth: 14
                        implicitHeight: 6
                        radius: height / 2
                        color: Theme.accent
                    }

                    Txt {
                        variant: "row"
                        text: chip.target ? `${Ws.dragId}  →  ${Ws.dragTo}` : `${Ws.dragId}`
                    }
                }
            }
        }
    }
}
