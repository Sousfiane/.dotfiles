import QtQuick

// A MouseArea that tells you when the pointer itself moved over it. Content arriving under a resting
// pointer (a panel sliding in, a search narrowing a list, scrolling) does not emit `moved`.
MouseArea {
    id: root

    signal moved

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    // where the pointer was, on screen, when it entered (or last moved over) this area.
    // Entering alone never counts: the pointer may be resting while the content moves.
    property point last: Qt.point(-1, -1)

    function screenPos(x, y) {
        return root.mapToGlobal(x, y);
    }

    onEntered: last = screenPos(mouseX, mouseY)

    onPositionChanged: mouse => {
        const p = screenPos(mouse.x, mouse.y);
        if (p.x === last.x && p.y === last.y)
            return;
        last = p;
        root.moved();
    }
}
