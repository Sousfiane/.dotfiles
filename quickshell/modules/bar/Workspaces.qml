import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config

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
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: workspace.modelData.activate()
            }

            // Window tooltip
            Rectangle {
                id: popup

                visible: mouse.containsMouse
                z: 100

                anchors.bottom: parent.top
                anchors.bottomMargin: 8
                anchors.horizontalCenter: parent.horizontalCenter

                width: Math.max(140, tooltipText.implicitWidth + 20)
                height: tooltipText.implicitHeight + 16

                radius: Theme.radius
                color: Theme.surface
                border.color: Theme.bg

                Text {
                    id: tooltipText

                    anchors.centerIn: parent

                    text: {
                        const windows = Hyprland.toplevels.values.filter(w => w.workspace?.id === workspace.modelData.id);

                        if (windows.length === 0)
                            return `Workspace ${workspace.modelData.id}: empty`;

                        return windows.map(w => `${w.appId || ""} : ${w.title || ""}`).join("\n");
                    }

                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize

                    wrapMode: Text.Wrap
                }
            }
        }
    }
}
