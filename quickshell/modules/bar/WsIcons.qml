import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// Workspace numbers. Same color rule as the other bar items: urgent > card open > shown > idle.
// The workspace this monitor shows sits on a small rounded chip that slides from number to number.
Item {
    id: root
    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    // distance from the screen edge: the first cell reaches out to it
    property real edgeGap: 0

    readonly property var mine: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === monitor).sort((a, b) => a.id - b.id)

    // the workspace shown on this monitor (focused or not)
    readonly property int activeId: monitor?.activeWorkspace?.id ?? -1
    readonly property int activeIndex: mine.findIndex(w => w.id === activeId)
    readonly property bool monitorFocused: Hyprland.focusedMonitor === monitor

    readonly property int cellWidth: 24

    implicitWidth: row.implicitWidth
    implicitHeight: Theme.barHeight

    // the active chip: a small rounded block behind the shown number, sliding between workspaces.
    // Dimmer when another monitor has focus
    Rectangle {
        visible: root.activeIndex >= 0
        width: root.cellWidth - 4
        height: 20
        radius: Theme.radius
        anchors.verticalCenter: parent.verticalCenter
        x: root.activeIndex * root.cellWidth + (root.cellWidth - width) / 2
        color: Theme.highlightMed
        opacity: root.monitorFocused ? 1 : 0.5

        Behavior on x {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    // cells touch, so the whole strip is clickable; the gap between numbers is inside each cell
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

                // named workspaces show their first letter
                readonly property string label: String(modelData.name) === String(modelData.id) ? String(modelData.id) : String(modelData.name).charAt(0).toUpperCase()

                // the first cell extends to the screen edge (click area)
                readonly property real reach: index === 0 ? root.edgeGap : 0

                implicitWidth: root.cellWidth
                implicitHeight: Theme.barHeight

                Txt {
                    anchors.centerIn: parent
                    text: workspace.label
                    font.pixelSize: Theme.fontSize
                    font.bold: workspace.shown
                    color: workspace.modelData.urgent ? Theme.urgent : workspace.cardOpen ? Theme.accent : workspace.shown ? Theme.fg : Theme.dim

                    Behavior on color {
                        ColorAnimation {
                            duration: 120
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
    }
}
