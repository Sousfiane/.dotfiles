import QtQuick
import QtQuick.Layouts

ListView {
    property real maxHeight: 420

    function scrollBy(d) {
        const max = Math.max(0, contentHeight - height);
        contentY = Math.max(0, Math.min(max, contentY + d));
    }

    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(contentHeight, maxHeight)
    clip: true
    spacing: 2
}
