import QtQuick
import qs.config

// The hover feedback shared by everything clickable in the bar: a rounded backdrop of a fixed height,
// centered on the bar, brighter while pressed. Neutral on purpose, so it never competes with the
// state colors of what it sits behind. Size it horizontally; the height is the same everywhere.
Rectangle {
    property bool hovered: false
    property bool pressed: false

    height: Theme.barHeight - 8
    radius: Theme.radius
    color: pressed ? Theme.highlightMed : Theme.surface
    opacity: hovered ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 120
        }
    }
}
