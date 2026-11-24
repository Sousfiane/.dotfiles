import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// a short-lived bubble at the bottom of the screen: the volume, the microphone, Caps Lock
Scope {
    id: root

    property bool shown: false
    property bool loaded: false        // stays true while it fades out after `shown` goes false
    property bool ready: false         // ignore the initial values at startup

    property string kind: "volume"     // "volume" | "mic" | "caps"
    property bool capsOn: false

    Timer {
        running: true
        interval: 1500
        onTriggered: root.ready = true
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }

    function show(what) {
        if (!ready)
            return;
        kind = what;
        loaded = true;
        shown = true;
        hideTimer.restart();
    }

    // unload once the fade out is over
    Timer {
        running: root.loaded && !root.shown
        interval: Motion.out + 20
        onTriggered: root.loaded = false
    }

    Connections {
        target: Audio
        function onChanged() {
            root.show("volume");
        }
        function onMicChanged() {
            root.show("mic");
        }
    }

    // ---------- Caps Lock ----------

    // bound on the key's release, so Hyprland already has the new state: read it from the main keyboard
    Process {
        id: capsProc
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(text).keyboards ?? [];
                    const kb = kbs.find(k => k.main) ?? kbs[0];
                    root.capsOn = kb?.capsLock ?? false;
                    root.show("caps");
                } catch (e) {}
            }
        }
    }

    IpcHandler {
        target: "osd"

        // `qs ipc call osd caps`
        function caps(): void {
            capsProc.running = true;
        }
    }

    // ---------- what it shows ----------

    readonly property bool isCaps: kind === "caps"
    readonly property real value: kind === "mic" ? Audio.micVolume : Audio.volume
    readonly property bool off: kind === "mic" ? Audio.micMuted : kind === "caps" ? !capsOn : Audio.muted

    readonly property string icon: {
        if (kind === "mic")
            return off ? Icons.micOff : Icons.mic;
        if (kind === "caps")
            return Icons.capsLock;
        const pct = Math.round(value * 100);
        return off ? Icons.volumeOff : pct === 0 ? Icons.volumeZero : pct < 34 ? Icons.volumeLow : pct < 67 ? Icons.volumeMedium : Icons.volumeHigh;
    }

    readonly property string text: {
        if (kind === "caps")
            return capsOn ? "Caps Lock on" : "Caps Lock off";
        return off ? "muted" : Math.round(value * 100) + "%";
    }

    LazyLoader {
        active: root.loaded

        PanelWindow {
            anchors.bottom: true
            margins.bottom: 100
            implicitWidth: 280
            implicitHeight: 48
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-osd"
            mask: Region {}   // click-through

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.bg
                border.color: Theme.border

                // created at 0, so it fades in on the first frame too
                property bool started: false
                Component.onCompleted: Qt.callLater(() => started = true)

                opacity: root.shown && started ? 1 : 0
                Behavior on opacity {
                    Anim {
                        duration: root.shown ? Motion.normal : Motion.out
                        curve: root.shown ? Motion.enter : Motion.exit
                    }
                }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 14
                        rightMargin: 14
                    }
                    spacing: 12

                    Txt {
                        Layout.preferredWidth: 20
                        horizontalAlignment: Text.AlignHCenter
                        text: root.icon
                        color: root.off ? Theme.dim : Theme.accent
                        font.pixelSize: Theme.fontSize + 3
                    }

                    // Caps Lock has no level: its text takes the bar's place
                    Rectangle {
                        visible: !root.isCaps
                        Layout.fillWidth: true
                        implicitHeight: 8
                        radius: 4
                        color: Theme.surface

                        Rectangle {
                            width: parent.width * Math.min(root.value, 1)
                            height: parent.height
                            radius: 4
                            color: root.off ? Theme.dim : Theme.accent
                        }
                    }

                    Txt {
                        Layout.fillWidth: root.isCaps
                        Layout.preferredWidth: root.isCaps ? -1 : 50
                        horizontalAlignment: root.isCaps ? Text.AlignLeft : Text.AlignRight
                        text: root.text
                    }
                }
            }
        }
    }
}
