import QtQuick

// The keyboard-selected row of a list: clamped to the list's length, and kept on screen in `view`.
QtObject {
    property int count: 0
    property var view: null          // a ListView scrolled so the selected row stays visible
    property int sel: 0              // the requested row; `index` is the one actually selected

    readonly property int index: Math.max(0, Math.min(sel, count - 1))

    onIndexChanged: if (view)
        view.positionViewAtIndex(index, ListView.Contain)

    function select(i) {
        sel = Math.max(0, Math.min(count - 1, i));
    }

    function move(d) {
        select(index + d);
    }

    // j/k and the arrows move the selection: a panel's Keys.onPressed calls this first, and returns
    // when it is true (the key is then accepted)
    function navigate(event) {
        const d = event.key === Qt.Key_J || event.key === Qt.Key_Down ? 1 : event.key === Qt.Key_K || event.key === Qt.Key_Up ? -1 : 0;
        if (d === 0)
            return false;
        move(d);
        event.accepted = true;
        return true;
    }
}
