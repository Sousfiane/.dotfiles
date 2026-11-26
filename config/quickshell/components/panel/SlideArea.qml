import Quickshell
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// The clipped area under the bar a dropdown slides in and out of: it waits for the bar of its monitor to
// be fully in, then lets the content emerge from under it.
Item {
    id: root

    property bool open: false         // bind to the panel's open state

    default property alias content: holder.data

    // wait until the window has a real size before animating in
    property bool started: false
    Component.onCompleted: Qt.callLater(() => root.started = true)

    // the bar of this window's monitor has to be fully in before the panel drops.
    // `force` is a safety net so a panel can never get stuck waiting.
    readonly property string screenName: root.QsWindow.window?.screen?.name ?? ""
    property bool force: false
    readonly property bool barReady: force || BarState.barReady[screenName] !== false

    onOpenChanged: if (!open)
        force = false

    Timer {
        running: root.open && !root.barReady
        interval: 800
        onTriggered: root.force = true
    }

    readonly property bool shown: open && started && height > 0 && barReady
    property real progress: shown ? 1 : 0

    // fully slid in and staying: what the panel's own animations (a height change) wait for
    readonly property bool settled: shown && progress === 1

    Behavior on progress {
        Anim {
            duration: root.shown ? Motion.normal : Motion.out
            curve: root.shown ? Motion.enter : Motion.exit
        }
    }

    // the area below the bar, clipped so content "emerges" from under it
    anchors {
        top: parent.top
        topMargin: 0
        bottom: parent.bottom
        left: parent.left
        right: parent.right
    }
    clip: true

    Item {
        id: holder
        width: root.width
        height: root.height
        y: -(1 - root.progress) * height
    }
}
