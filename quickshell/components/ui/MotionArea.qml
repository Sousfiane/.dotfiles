import QtQuick
import qs.services

// A MouseArea that tells you when the pointer itself moved over it. Content sliding under a resting
// pointer (a search narrowing a list, scrolling) does not emit `moved`.
MouseArea {
    id: root

    signal moved

    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onPositionChanged: mouse => {
        const p = root.mapToGlobal(mouse.x, mouse.y);
        if (p.x === Pointer.last.x && p.y === Pointer.last.y)
            return;
        Pointer.last = p;
        root.moved();
    }
}
