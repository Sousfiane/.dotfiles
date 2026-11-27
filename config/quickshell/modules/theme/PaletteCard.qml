import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// One palette in the theme picker: a check on the current one, its name over a strip of its colours, dark
// or light, and its number key. A click applies it.
SelectableCard {
    id: row

    required property var modelData         // a Themes.palettes entry
    required property int index

    readonly property bool current: modelData.id === Themes.current

    signal pointed                          // the mouse is over it: the keyboard selection follows

    implicitHeight: 56

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 12

        // the current one
        Txt {
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
            text: row.current ? Icons.check : ""
            color: Theme.accent
            font.pixelSize: Theme.fontSize + 4
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Txt {
                text: row.modelData.name
                font.bold: row.selected || row.current
                elide: Text.ElideRight
            }

            // the palette at a glance: its background, then its accents
            Row {
                spacing: 4

                Repeater {
                    model: ["base", "overlay", "text", "love", "gold", "rose", "pine", "foam", "iris"]

                    delegate: Rectangle {
                        required property string modelData

                        width: 16
                        height: 10
                        radius: Theme.radiusSmall
                        color: row.modelData.colors[modelData] ?? "transparent"
                        border.width: 1
                        border.color: Theme.withAlpha(Theme.line, 0.6)
                    }
                }
            }
        }

        Txt {
            text: row.modelData.dark ? "dark" : "light"
            color: Theme.dim
            variant: "small"
        }

        KeyBadge {
            text: row.index < 9 ? String(row.index + 1) : ""
            visible: row.index < 9
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: row.pointed()
        onClicked: Themes.set(row.modelData.id)
    }
}
