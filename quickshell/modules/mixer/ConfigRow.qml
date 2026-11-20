import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.ui

SelectableCard {
    id: root

    required property var card
    property bool choosing: false
    property int chooseIndex: 0

    signal chooseRequested
    signal choiceHovered(int i)
    signal choicePicked(var profile)

    readonly property var activeProfile: card.profiles.find(p => p.name === card.active) ?? null

    implicitHeight: body.implicitHeight + 20

    ColumnLayout {
        id: body
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 6

        // card name
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Txt {
                text: Icons.chip
                color: Theme.dim
                font.pixelSize: Theme.fontSize + 4
            }

            Txt {
                Layout.fillWidth: true
                variant: "row"
                font.bold: true
                text: root.card.description
                elide: Text.ElideRight
            }
        }

        // active profile: click to change
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 28
            radius: 8
            color: root.choosing ? Theme.accent : Theme.surface
            border.width: 1
            border.color: Theme.border

            Txt {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                    rightMargin: 10
                }
                variant: "dim"
                color: root.choosing ? Theme.bgSolid : Theme.fg
                text: "▼  " + (root.activeProfile ? root.activeProfile.description : root.card.active)
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.selectRequested();
                    root.chooseRequested();
                }
            }
        }

        // profile chooser, expands under the pill
        ChoiceList {
            visible: root.choosing
            choices: root.card.profiles
            highlight: root.chooseIndex
            labelOf: p => p.description
            isCurrent: p => p.name === root.card.active
            isAvailable: p => p.available
            onHovered: i => root.choiceHovered(i)
            onPicked: p => root.choicePicked(p)
        }
    }
}
