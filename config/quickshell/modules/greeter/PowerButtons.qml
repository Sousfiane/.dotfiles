import Quickshell
import QtQuick

// Restart and shut down, in the greeter's corner. In test mode they only quit.
Row {
    id: root

    required property GreeterTheme theme
    required property bool testing

    spacing: 10

    Repeater {
        model: [
            {
                glyph: "\u{F0709}",            // md-restart
                label: "Restart",
                command: ["systemctl", "reboot"]
            },
            {
                glyph: "\u{F0425}",            // md-power
                label: "Shut down",
                command: ["systemctl", "poweroff"]
            }
        ]

        delegate: Rectangle {
            id: power
            required property var modelData

            implicitWidth: row.implicitWidth + 28
            implicitHeight: 40
            radius: height / 2
            // the bar's fill, and its rows' on hover
            color: mouse.containsMouse ? root.theme.alpha(root.theme.colors.overlay, root.theme.controlAlpha) : root.theme.alpha(root.theme.colors.base, root.theme.panelAlpha)
            border.width: 1
            border.color: mouse.containsMouse ? root.theme.colors.iris : root.theme.alpha(root.theme.colors.text, 0.12)

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: power.modelData.glyph
                    color: root.theme.colors.text
                    font.family: root.theme.font
                    font.pixelSize: root.theme.fontSize + 3
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: power.modelData.label
                    color: root.theme.colors.text
                    font.family: root.theme.font
                    font.pixelSize: root.theme.fontSize
                }
            }

            MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.testing ? Qt.quit() : Quickshell.execDetached(power.modelData.command)
            }
        }
    }
}
