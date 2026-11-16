import QtQuick
import qs.config

// The hover feedback shared by everything clickable in the bar: a rounded block as tall as the bar,
// brighter while pressed. Neutral on purpose, so it never competes with the state colors of what it sits
// behind. Center it on the bar and size it horizontally. The side against a screen edge stays square,
// like the dropdown cards, so it meets the edge without a gap.
Rectangle {
    property bool hovered: false
    property bool pressed: false
    property bool squareLeft: false
    property bool squareRight: false

    height: Theme.barHeight
    radius: Theme.radius
    topLeftRadius: squareLeft ? 0 : radius
    bottomLeftRadius: squareLeft ? 0 : radius
    topRightRadius: squareRight ? 0 : radius
    bottomRightRadius: squareRight ? 0 : radius
    color: pressed ? Theme.highlightMed : Theme.surface
    opacity: hovered ? 1 : 0

    Behavior on opacity {
        NumberAnimation {
            duration: 120
        }
    }
}
