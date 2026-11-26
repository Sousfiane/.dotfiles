import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// Workspace dots. Idle workspaces are small dots; the one this monitor shows stretches into a
// wide pill. Each cell animates its own width, so switching squashes the pill across: the old one
// shrinks while the new one grows and the dots in between slide over.
// Same color rule as the other bar items: urgent > card open > shown > idle.
Item {
    id: root
    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    // distance from the screen edge: the first cell reaches out to it
    property real edgeGap: 0

    readonly property var mine: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === monitor).sort((a, b) => a.id - b.id)

    // the workspace shown on this monitor (focused or not)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1
    readonly property bool monitorFocused: Hyprland.focusedMonitor === monitor

    readonly property int dotSize: 6
    readonly property int pillWidth: 22
    readonly property int cellPadding: 5     // each side of a dot; also the gap between cells

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    // cells touch, so the whole strip is clickable; the gap between dots is inside each cell
    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Repeater {
            model: ScriptModel {
                values: root.mine
            }

            delegate: Item {
                id: workspace

                required property var modelData
                required property int index

                readonly property bool shown: modelData.id === root.activeId
                readonly property bool cardOpen: Ws.open && Ws.screenName === root.screen.name && Ws.wsId === modelData.id

                // the first cell extends to the screen edge (click area)
                readonly property real reach: index === 0 ? root.edgeGap : 0

                implicitWidth: dot.width + root.cellPadding * 2
                implicitHeight: Theme.barHeight

                Rectangle {
                    id: dot

                    readonly property real grow: mouse.containsMouse && !workspace.shown ? 2 : 0

                    anchors.centerIn: parent
                    width: (workspace.shown ? root.pillWidth : root.dotSize) + dot.grow
                    height: root.dotSize + dot.grow
                    radius: height / 2

                    color: workspace.modelData.urgent ? Theme.urgent : workspace.cardOpen || workspace.shown ? Theme.accent : Theme.dim
                    // the shown pill dims when another monitor has focus
                    opacity: workspace.shown && !root.monitorFocused ? 0.5 : 1

                    Behavior on width {
                        Anim {}
                    }
                    Behavior on height {
                        Anim {
                            duration: Motion.fast
                        }
                    }
                    Behavior on color {
                        CAnim {}
                    }
                    Behavior on opacity {
                        Anim {
                            duration: Motion.fast
                        }
                    }
                }

                MouseArea {
                    id: mouse
                    x: -workspace.reach
                    width: parent.width + workspace.reach
                    height: parent.height
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: workspace.modelData.activate()
                    onEntered: Ws.enterBar(root.screen.name, workspace.modelData.id)
                    onExited: Ws.leaveBar(root.screen.name, workspace.modelData.id)
                }
            }
        }

        // after the dots: a small plus that opens the first empty workspace, same as SUPER + SHIFT + N.
        // Drawn like the dots (dim, grows a little on hover) so it reads as part of the strip.
        Item {
            id: add

            readonly property int arm: root.dotSize + 2 + (addMouse.containsMouse ? 2 : 0)
            readonly property int thickness: 2

            implicitWidth: root.dotSize + 2 + root.cellPadding * 2
            implicitHeight: Theme.barHeight

            Repeater {
                model: 2     // one horizontal bar, one vertical

                delegate: Rectangle {
                    required property int index

                    anchors.centerIn: parent
                    width: index === 0 ? add.arm : add.thickness
                    height: index === 0 ? add.thickness : add.arm
                    radius: add.thickness / 2
                    color: addMouse.containsMouse ? Theme.accent : Theme.dim

                    Behavior on width {
                        Anim {
                            duration: Motion.fast
                        }
                    }
                    Behavior on height {
                        Anim {
                            duration: Motion.fast
                        }
                    }
                    Behavior on color {
                        CAnim {}
                    }
                }
            }

            MouseArea {
                id: addMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: Hyprland.dispatch(`hl.dsp.focus({ workspace = "empty" })`)
            }
        }
    }
}
