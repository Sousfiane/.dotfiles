import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services

Scope {
    id: root
    property bool shown: false
    property bool ready: false   // ignore the initial Pipewire values at startup

    Timer { running: true; interval: 1500; onTriggered: root.ready = true }
    Timer { id: hideTimer; interval: 1500; onTriggered: root.shown = false }

    Connections {
        target: Audio
        function onChanged() {
            if (!root.ready) return;
            root.shown = true;
            hideTimer.restart();
        }
    }

    LazyLoader {
        active: root.shown

        PanelWindow {
            anchors.bottom: true
            margins.bottom: 100
            implicitWidth: 280
            implicitHeight: 48
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            mask: Region {}   // click-through

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.bg
                border.color: Theme.border

                Rectangle {
                    anchors {
                        left: parent.left; right: valueText.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 14; rightMargin: 12
                    }
                    height: 8
                    radius: 4
                    color: Theme.surface

                    Rectangle {
                        width: parent.width * Math.min(Audio.volume, 1)
                        height: parent.height
                        radius: 4
                        color: Audio.muted ? Theme.dim : Theme.accent
                    }
                }

                Text {
                    id: valueText
                    anchors { right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
                    width: 50
                    horizontalAlignment: Text.AlignRight
                    text: Audio.muted ? "muted" : Math.round(Audio.volume * 100) + "%"
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                }
            }
        }
    }
}
