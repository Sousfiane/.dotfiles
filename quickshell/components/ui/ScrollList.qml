import QtQuick
import QtQuick.Layouts

import qs.config

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
}
