import QtQuick
import QtQuick.Layouts
import qs.config
import qs.components.ui

// The chooser that expands under a mixer row: target devices for an app, profiles for a card.
// The highlighted entry follows the keyboard or the pointer; the current one has a dot.
ColumnLayout {
    id: root

    property var choices: []
    property int highlight: 0
    property var labelOf: c => String(c)
    property var isCurrent: c => false
    property var isAvailable: c => true

    signal hovered(int i)
    signal picked(var choice)

    Layout.fillWidth: true
    spacing: 2

    Repeater {
        model: root.visible ? root.choices : []

        delegate: Rectangle {
            id: option
            required property var modelData
            required property int index

            readonly property bool highlighted: root.highlight === index
            readonly property bool available: root.isAvailable(modelData)

            Layout.fillWidth: true
            implicitHeight: 26
            radius: Theme.radius
            color: highlighted ? Theme.accent : Theme.bgSolid
            Behavior on color {
                CAnim {}
            }

            Txt {
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 10
                    rightMargin: 10
                }
                variant: "dim"
                color: option.highlighted ? Theme.bgSolid : option.available ? Theme.fg : Theme.dim
                Behavior on color {
                    CAnim {}
                }
                text: (root.isCurrent(option.modelData) ? "● " : "   ") + root.labelOf(option.modelData) + (option.available ? "" : "  (unavailable)")
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: root.hovered(option.index)
                onClicked: root.picked(option.modelData)
            }
        }
    }
}
