import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

RowLayout {
    id: root
    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    // distance from the screen edge: the first cell reaches out to it
    property real edgeGap: 0

    readonly property var mine: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === monitor).sort((a, b) => a.id - b.id)

    // cells touch, so the whole strip is clickable; the gap between dots is inside each cell
    spacing: 0

    Repeater {
        model: ScriptModel {
            values: root.mine
        }

        delegate: Item {
            id: workspace

            required property var modelData
            required property int index

            // the first cell extends to the screen edge (backdrop and click area)
            readonly property real reach: index === 0 ? root.edgeGap : 0

            implicitWidth: 24
            implicitHeight: Theme.barHeight

            HoverBackdrop {
                x: -workspace.reach
                width: parent.width + workspace.reach
                anchors.verticalCenter: parent.verticalCenter
                hovered: mouse.containsMouse
                pressed: mouse.pressed
                squareLeft: workspace.reach > 0
            }

            Txt {
                anchors.centerIn: parent

                text: workspace.modelData.focused ? Icons.workspaceFocused : Icons.workspace
                font.pixelSize: Theme.fontSize
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
