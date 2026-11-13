pragma Singleton
import Quickshell
import QtQuick

Singleton {
    id: root

    // the launcher and wallpaper picker keep their `open` state inside their own modules,
    // so they report it here
    property bool launcherOpen: false
    property bool wallpaperOpen: false

    readonly property bool anyOpen: Mixer.open || Bt.panelOpen || Notifs.centerOpen || Power.open || Updates.panelOpen || Dotfiles.panelOpen || Hub.open || WsPanel.open || ClipHistory.open || launcherOpen || wallpaperOpen

    // what the bar listens to
    property bool raised: false

    onAnyOpenChanged: {
        if (anyOpen) {
            lowerTimer.stop();
            raised = true;
        } else {
            lowerTimer.restart();
        }
    }

    Timer {
        id: lowerTimer
        interval: 300
        onTriggered: root.raised = false
    }
}
