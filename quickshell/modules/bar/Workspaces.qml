import Quickshell
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root
    required property ShellScreen screen

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property var mine: Hyprland.workspaces.values.filter(w => w.id > 0 && w.monitor === monitor)   // id > 0 skips special workspaces
    .sort((a, b) => a.id - b.id)

    spacing: 4

    Repeater {
        model: root.mine

        delegate: Rectangle {
            id: pill

            required property var modelData

            implicitWidth: 26
            implicitHeight: 22
            radius: Theme.radius

            color: {
                if (modelData.focused)
                    return Theme.accent;

                if (modelData.active)
                    return Theme.surface;

                return Theme.bg;
            }

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }

            Text {
                anchors.centerIn: parent
                text: pill.modelData.id

                color: pill.modelData.focused ? Theme.bg : Theme.fg

                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: pill.modelData.activate()
            }
        }
    }
}
