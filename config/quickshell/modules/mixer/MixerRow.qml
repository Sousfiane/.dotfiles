import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// A stream or device in the mixer: name, volume slider and mute, and for a stream the device it plays to
// (which can be changed).
SelectableCard {
    id: root

    required property var node
    property bool device: false      // hardware device (vs. application stream)
    property bool input: false       // microphone side
    property bool choosing: false    // device chooser open on this row
    property int chooseIndex: 0

    signal chooseRequested
    signal choiceHovered(int i)
    signal choicePicked(var target)

    readonly property var audio: node?.audio ?? null
    readonly property real vol: audio?.volume ?? 0
    readonly property bool muted: audio?.muted ?? false
    readonly property var props: node?.properties ?? ({})
    readonly property bool isDefault: Mixer.isDefault(node)
    readonly property var currentTarget: device ? null : Mixer.currentTarget(node)

    readonly property string appName: props["application.name"] || props["application.process.binary"] || ""
    readonly property string title: device ? (node.description || node.nickname || node.name) : (appName || node.description || node.name)
    readonly property string subtitle: device ? "" : (props["media.name"] || "")
    readonly property string iconName: props["application.icon-name"] || appName.toLowerCase()

    implicitHeight: body.implicitHeight + 20

    ColumnLayout {
        id: body
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 10
        }
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // app icon for streams, glyph for devices
            Item {
                Layout.preferredWidth: 24
                Layout.preferredHeight: 24

                AppIcon {
                    anchors.fill: parent
                    visible: !root.device
                    source: Quickshell.iconPath(root.iconName, "audio-volume-high")
                }

                Txt {
                    anchors.centerIn: parent
                    visible: root.device
                    text: root.input ? Icons.mic : Icons.speaker
                    color: root.isDefault ? Theme.accent : Theme.dim
                    font.pixelSize: Theme.fontSize + 5
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Txt {
                    Layout.fillWidth: true
                    variant: "row"
                    font.bold: true
                    text: root.title
                    elide: Text.ElideRight
                }

                Txt {
                    Layout.fillWidth: true
                    visible: root.subtitle !== ""
                    variant: "dim"
                    text: root.subtitle
                    elide: Text.ElideRight
                }
            }

            // stream rows: current device, click to change it
            Pill {
                visible: !root.device
                maxWidth: 160
                active: root.choosing
                text: "→ " + (root.currentTarget ? (root.currentTarget.description || root.currentTarget.name) : "no device")
                onClicked: {
                    root.selectRequested();
                    root.chooseRequested();
                }
            }

            // device rows: default indicator / button
            Pill {
                visible: root.device
                active: root.isDefault
                text: root.isDefault ? "Default" : "Set default"
                onClicked: if (!root.isDefault)
                    Mixer.makeDefault(root.node)
            }

            Txt {
                Layout.preferredWidth: 42
                horizontalAlignment: Text.AlignRight
                variant: "row"
                text: Math.round(root.vol * 100) + "%"
                color: root.muted ? Theme.dim : (root.vol > 1 ? Theme.urgent : Theme.fg)
            }

            // mute button
            Txt {
                text: root.input ? (root.muted ? Icons.micOff : Icons.mic) : (root.muted ? Icons.volumeOff : Icons.volumeHigh)
                color: root.muted ? Theme.urgent : Theme.fg
                font.pixelSize: Theme.fontSize + 3

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Mixer.toggleMute(root.node)
                }
            }
        }

        // volume slider: click or drag, wheel adjusts by 5%
        Item {
            Layout.fillWidth: true
            implicitHeight: 18

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 8
                radius: 4
                color: Theme.surface

                Rectangle {
                    width: parent.width * Math.min(root.vol / Mixer.maxVolume, 1)
                    height: parent.height
                    radius: 4
                    color: root.muted ? Theme.dim : (root.vol > 1 ? Theme.urgent : Theme.accent)
                }

                // 100% marker
                Rectangle {
                    x: parent.width / Mixer.maxVolume - 1
                    y: -2
                    width: 2
                    height: parent.height + 4
                    color: Theme.dim
                    opacity: 0.6
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                // keep the drag until release, even when the pointer leaves the slider:
                // otherwise the ListView takes it over as a flick once the pointer drifts vertically
                preventStealing: true

                function setFrom(x) {
                    Mixer.setVolume(root.node, Math.max(0, Math.min(1, x / width)) * Mixer.maxVolume);
                }

                onPressed: mouse => {
                    root.selectRequested();
                    setFrom(mouse.x);
                }
                onPositionChanged: mouse => {
                    if (pressed)
                        setFrom(mouse.x);
                }
                onWheel: wheel => Mixer.adjust(root.node, wheel.angleDelta.y > 0 ? 0.05 : -0.05)
            }
        }

        // device chooser, expands under the slider
        ChoiceList {
            visible: root.choosing
            choices: Mixer.targets(root.node)
            highlight: root.chooseIndex
            labelOf: t => t.description || t.name
            isCurrent: t => t === root.currentTarget
            onHovered: i => root.choiceHovered(i)
            onPicked: t => root.choicePicked(t)
        }
    }
}
