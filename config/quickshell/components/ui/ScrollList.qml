import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.config

// A list that grows with its rows up to `maxHeight`, then scrolls, with a gutter for the scrollbar.
ListView {
    id: root

    property real maxHeight: 420

    // grow and shrink in step with the rows' add/remove/displaced transitions, instead of
    // jumping to the new size and cutting off rows that are still sliding into place
    property bool animateHeight: false
    property real shownHeight: Math.min(contentHeight, maxHeight)
    Behavior on shownHeight {
        enabled: root.animateHeight
        Anim {}
    }

    function scrollBy(d) {
        const max = Math.max(0, contentHeight - height);
        contentY = Math.max(0, Math.min(max, contentY + d));
    }

    Layout.fillWidth: true
    Layout.preferredHeight: shownHeight
    clip: true
    spacing: 2

    // rows size to this instead of `width`, leaving a gutter for the scrollbar while it shows
    readonly property real rowWidth: width - (vbar.size < 1 ? vbar.width + 6 : 0)

    // only shows when the list overflows maxHeight
    ScrollBar.vertical: Scroller {
        id: vbar
    }
}
