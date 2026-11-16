import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.config
import qs.services
import qs.components.ui

Scope {
    id: root

    property bool shown: false
    property string mode: "volume"     // "volume" or "caps"
    property bool ready: false         // ignore the initial values at startup

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

    function show(newMode) {
        if (!ready)
            return;
        mode = newMode;
        shown = true;
        hideTimer.restart();
    }

    Connections {
        target: Audio
        function onChanged() {
            root.show("volume");
        }
    }

    Connections {
        target: Caps
        function onToggled() {
            root.show("caps");
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
            WlrLayershell.namespace: "qs-osd"
            mask: Region {}   // click-through

            Rectangle {
                anchors.fill: parent
                radius: Theme.radius
                color: Theme.bg
                border.color: Theme.border

                // ---------- volume view ----------
                Item {
                    anchors.fill: parent
                    visible: root.mode === "volume"

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: valueText.left
                            verticalCenter: parent.verticalCenter
                            leftMargin: 14
                            rightMargin: 12
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

                    Txt {
                        id: valueText
                        anchors {
                            right: parent.right
                            rightMargin: 14
                            verticalCenter: parent.verticalCenter
                        }
                        width: 50
                        horizontalAlignment: Text.AlignRight
                        text: Audio.muted ? "muted" : Math.round(Audio.volume * 100) + "%"
                    }
                }

                // ---------- caps lock view ----------
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    visible: root.mode === "caps"

                    Txt {
                        text: Icons.capsLock
                        color: Caps.on ? Theme.accent : Theme.dim
                        font.pixelSize: Theme.fontSize + 6
                    }

                    Txt {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Caps Lock " + (Caps.on ? "on" : "off")
                        color: Caps.on ? Theme.fg : Theme.dim
                        font.pixelSize: Theme.fontSize + 1
                        font.bold: Caps.on
                    }
                }
            }
        }
    }
}
