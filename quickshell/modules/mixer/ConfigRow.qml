import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components

Rectangle {
    id: root

    required property var card
    property bool selected: false
    property bool choosing: false
    property int chooseIndex: 0

    signal selectRequested
    signal chooseRequested
    signal choiceHovered(int i)
    signal choicePicked(var profile)

    readonly property var activeProfile: card.profiles.find(p => p.name === card.active) ?? null

    implicitHeight: body.implicitHeight + 20
    radius: Theme.radius
    color: selected ? Theme.surface : "transparent"
    border.width: selected ? 1 : 0
    border.color: Theme.accent

    MouseArea {
        anchors.fill: parent
        onClicked: root.selectRequested()
    }

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
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.choosing
            spacing: 2

            Repeater {
                model: root.choosing ? root.card.profiles : []

                delegate: Rectangle {
                    id: option
                    required property var modelData
                    required property int index

                    readonly property bool highlighted: root.chooseIndex === index
                    readonly property bool isCurrent: modelData.name === root.card.active

                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: 6
                    color: highlighted ? Theme.accent : Theme.bgSolid

                    Txt {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                            rightMargin: 10
                        }
                        variant: "dim"
                        color: option.highlighted ? Theme.bgSolid : option.modelData.available ? Theme.fg : Theme.dim
                        text: (option.isCurrent ? "● " : "   ") + option.modelData.description + (option.modelData.available ? "" : "  (unavailable)")
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.choiceHovered(option.index)
                        onClicked: root.choicePicked(option.modelData)
                    }
                }
            }
        }
    }
}
