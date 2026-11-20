import QtQuick
import qs.config

// One tile of a GridPicker: a rounded card with an accent outline on the current tile.
// Moving the pointer over it makes it current, clicking emits `clicked`.
// Children land in the card, under the outline.
Item {
    id: root

    required property int index
    readonly property bool highlighted: GridView.isCurrentItem

    default property alias content: card.data

    signal clicked

    width: GridView.view.cellWidth
    height: GridView.view.cellHeight

    Rectangle {
        id: card
        anchors.fill: parent
        anchors.margins: 6
        radius: Theme.radius
        color: Theme.surface
        clip: true

        // highlight outline, above the content
        Rectangle {
            z: 1
            anchors.fill: parent
            radius: Theme.radius
            color: "transparent"
            border.width: root.highlighted ? 2 : 0
            border.color: Theme.accent

            Behavior on border.width {
                NumberAnimation {
                    duration: 100
                }
            }
        }

        MotionArea {
            z: 2
            anchors.fill: parent
            onMoved: root.GridView.view.currentIndex = root.index
            onClicked: root.clicked()
        }
    }
}
