import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

Rectangle {
    id: root

    required property var node
    property bool device: false      // hardware device (vs. application stream)
    property bool input: false       // microphone side
    property bool selected: false
    property bool choosing: false    // device chooser open on this row
    property int chooseIndex: 0

    signal selectRequested
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
    radius: Theme.radius
    color: selected ? Theme.surface : "transparent"
    border.width: selected ? 1 : 0
    border.color: Theme.accent

    // clicking anywhere on the row selects it
    MouseArea {
        anchors.fill: parent
        onClicked: root.selectRequested()
    }

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

                IconImage {
                    anchors.fill: parent
                    visible: !root.device
                    source: Quickshell.iconPath(root.iconName, "audio-volume-high")
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.device
                    // nf-md: microphone / speaker
                    text: String.fromCodePoint(root.input ? 0xF036C : 0xF04C3)
                    color: root.isDefault ? Theme.accent : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize + 5
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    elide: Text.ElideRight
                    color: Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 1
                    font.bold: true
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.subtitle !== ""
                    text: root.subtitle
                    elide: Text.ElideRight
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 2
                }
            }

            // stream rows: current device, click to change it
            Rectangle {
                visible: !root.device
                Layout.preferredWidth: 130
                implicitHeight: 22
                radius: 11
                color: root.choosing ? Theme.accent : Theme.surface
                border.width: 1
                border.color: Theme.border

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: 8
                        rightMargin: 8
                    }
                    text: "→ " + (root.currentTarget ? (root.currentTarget.description || root.currentTarget.name) : "no device")
                    elide: Text.ElideRight
                    color: root.choosing ? Theme.bg : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.selectRequested();
                        root.chooseRequested();
                    }
                }
            }

            // device rows: default indicator / button
            Rectangle {
                visible: root.device
                implicitWidth: defaultLabel.implicitWidth + 14
                implicitHeight: 20
                radius: 10
                color: root.isDefault ? Theme.accent : Theme.surface

                Text {
                    id: defaultLabel
                    anchors.centerIn: parent
                    text: root.isDefault ? "Default" : "Set default"
                    color: root.isDefault ? Theme.bg : Theme.fg
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize - 3
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !root.isDefault
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Mixer.makeDefault(root.node)
                }
            }

            Text {
                Layout.preferredWidth: 42
                horizontalAlignment: Text.AlignRight
                text: Math.round(root.vol * 100) + "%"
                color: root.muted ? Theme.dim : (root.vol > 1 ? Theme.urgent : Theme.fg)
                font.family: Theme.font
                font.pixelSize: Theme.fontSize - 1
            }

            // mute button
            Text {
                // nf-md: microphone / microphone_off / volume_high / volume_off
                text: String.fromCodePoint(root.input ? (root.muted ? 0xF036D : 0xF036C) : (root.muted ? 0xF0581 : 0xF057E))
                color: root.muted ? Theme.urgent : Theme.fg
                font.family: Theme.font
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
                id: track
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
        ColumnLayout {
            Layout.fillWidth: true
            visible: root.choosing
            spacing: 2

            Repeater {
                model: root.choosing ? Mixer.targets(root.node) : []

                delegate: Rectangle {
                    id: option
                    required property var modelData
                    required property int index

                    readonly property bool highlighted: root.chooseIndex === index
                    readonly property bool isCurrent: modelData === root.currentTarget

                    Layout.fillWidth: true
                    implicitHeight: 26
                    radius: 6
                    color: highlighted ? Theme.accent : Theme.bg

                    Text {
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                            rightMargin: 10
                        }
                        text: (option.isCurrent ? "● " : "   ") + (option.modelData.description || option.modelData.name)
                        elide: Text.ElideRight
                        color: option.highlighted ? Theme.bg : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize - 2
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.choiceHovered(option.index)
                        onClicked: root.choicePicked(option.modelData)
                    }
                }
            }
        }
    }
}
