import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

RowLayout {
    id: root
    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)

    readonly property var mine: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === monitor).sort((a, b) => a.id - b.id)

    spacing: 6

    Repeater {
        model: root.mine

        delegate: Item {
            id: workspace

            required property var modelData

            implicitWidth: 16
            implicitHeight: 22

            Text {
                anchors.centerIn: parent

                text: workspace.modelData.focused ? "󱓻" : ""

                color: Theme.fg

                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: workspace.modelData.activate()
                onEntered: WsPanel.enterBar(root.screen.name, workspace.modelData.id)
                onExited: WsPanel.leaveBar()
            }
        }
    }
}
