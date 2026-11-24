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
}
