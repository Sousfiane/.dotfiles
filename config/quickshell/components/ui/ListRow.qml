import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property bool selected: false
    readonly property bool hovered: hover.hovered

    default property alias content: row.data

    width: ListView.view ? (ListView.view.rowWidth ?? ListView.view.width) : implicitWidth
    implicitHeight: 30
    radius: Theme.radius
    color: selected || hovered ? Theme.surface : Theme.surfaceClear
    Behavior on color {
        CAnim {}
    }

    HoverHandler {
        id: hover
    }

    RowLayout {
        id: row
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 12
    }
}
