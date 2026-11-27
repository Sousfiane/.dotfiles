import QtQuick
import QtQuick.Controls
import qs.config

// The shell's scrollbar, for every list and grid that scrolls (`ScrollBar.vertical: Scroller {}`): hidden
// until the content scrolls or the pointer is on it, then a thin pill on a faint track in the theme's
// colours, brighter under the pointer and in the accent while dragged; it fades out once left alone.
// (Not shown whenever the content overflows: a list that has just opened isn't measured yet for a moment,
// and the bar would flash.)
ScrollBar {
    id: root

    readonly property bool wanted: size < 1 && (active || hovered || pressed)
    // stays a moment once left alone, so a pause in scrolling doesn't blink it
    property bool shown: false
    onWantedChanged: {
        if (wanted) {
            hideDelay.stop();
            shown = true;
        } else {
            hideDelay.restart();
        }
    }
    Timer {
        id: hideDelay
        interval: 600
        onTriggered: root.shown = false
    }

    policy: ScrollBar.AsNeeded
    // not left to the platform's hint, which is off here: the pointer on the bar shows it
    hoverEnabled: true
    padding: 2
    minimumSize: 0.08

    contentItem: Rectangle {
        implicitWidth: 6
        implicitHeight: 6
        radius: width / 2
        color: root.pressed ? Theme.accent : root.hovered ? Theme.fg : Theme.dim
        opacity: root.shown ? 1 : 0
        Behavior on color {
            CAnim {}
        }
        Behavior on opacity {
            Anim {
                duration: root.shown ? Motion.fast : Motion.out
            }
        }
    }

    background: Rectangle {
        implicitWidth: 6 + 2 * root.padding
        radius: width / 2
        color: Theme.withAlpha(Theme.fg, 0.08)
        opacity: root.contentItem.opacity
    }
}
