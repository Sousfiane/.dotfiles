import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// One font of the theme picker's main page (the shell's, the terminal's or the apps'): the font in use,
// drawn in itself, and its size with − and +. A click on the card opens the list of fonts to pick from.
SelectableCard {
    id: fontRow

    required property var modelData         // a Themes.fontRoles entry
    required property int index

    readonly property string family: Theme.fonts[modelData.key] ?? ""

    signal pointed                          // the mouse is over it: the keyboard selection follows

    implicitHeight: 44

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 12

        Txt {
            Layout.preferredWidth: 70
            text: fontRow.modelData.label
            font.bold: fontRow.selected
        }

        // the font in use, drawn in itself
        Txt {
            Layout.fillWidth: true
            text: fontRow.family
            font.family: fontRow.family
            color: Theme.dim
            elide: Text.ElideRight
        }

        // its size, with − and + (or the - and + keys on this row)
        Row {
            spacing: 2

            IconButton {
                icon: "−"
                size: Theme.fontSize
                onClicked: Themes.changeFontSize(fontRow.modelData, -1)
            }
            Txt {
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                horizontalAlignment: Text.AlignHCenter
                variant: "row"
                text: Themes.fontSize(fontRow.modelData) + " " + fontRow.modelData.unit
            }
            IconButton {
                icon: "+"
                size: Theme.fontSize
                onClicked: Themes.changeFontSize(fontRow.modelData, 1)
            }
        }

        Txt {
            text: Icons.chevronRight
            color: fontRow.selected ? Theme.accent : Theme.dim
        }
    }

    // hover only: under the card's click and the size buttons
    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        cursorShape: Qt.PointingHandCursor
        onEntered: fontRow.pointed()
    }
}
