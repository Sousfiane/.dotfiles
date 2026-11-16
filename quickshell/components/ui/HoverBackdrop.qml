import QtQuick
import qs.config

// The hover feedback shared by everything clickable in the bar: a block as tall as the bar, square like
// the bar itself, brighter while pressed. Neutral on purpose, so it never competes with the state colors
// of what it sits behind. Center it on the bar and size it horizontally.
Rectangle {
    property bool hovered: false
    property bool pressed: false

    height: Theme.barHeight
    color: pressed ? Theme.highlightMed : Theme.surface
    opacity: hovered ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 120
        }
    }
}
