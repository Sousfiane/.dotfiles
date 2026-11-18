import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// cover, title / artist, progress and controls of the current MPRIS player (hub)
RowLayout {
    id: root

    readonly property var player: Media.player
    readonly property bool hasLength: (player?.lengthSupported ?? false) && player.length > 0

    property int coverSize: 64

    visible: Media.active
    spacing: 12

    // ---------- cover ----------
    Rectangle {
        implicitWidth: root.coverSize
        implicitHeight: root.coverSize
        radius: Theme.radius
        color: Theme.surface
        clip: true

        Txt {
            anchors.centerIn: parent
            visible: cover.status !== Image.Ready
            text: Icons.music
            color: Theme.dim
            font.pixelSize: Theme.fontSize + 14
        }

        Image {
            id: cover
            anchors.fill: parent
            source: root.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize.width: 128
            sourceSize.height: 128
            asynchronous: true
            smooth: true
            mipmap: true
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        // ---------- track ----------
        Txt {
            Layout.fillWidth: true
            variant: "heading"
            elide: Text.ElideRight
            text: root.player?.trackTitle ?? ""
        }

        Txt {
            Layout.fillWidth: true
            variant: "dim"
            elide: Text.ElideRight
            text: [root.player?.trackArtist ?? "", root.player?.identity ?? ""].filter(s => s !== "").join("  ·  ")
        }

        // ---------- progress ----------
        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            visible: root.hasLength
            implicitHeight: 4
            radius: 2
            color: Theme.surface

            Rectangle {
                height: parent.height
                radius: parent.radius
                color: Theme.accent
                width: root.hasLength ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
            }

            // click to seek
            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                enabled: root.player?.canSeek ?? false
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: event => root.player.position = root.player.length * Math.max(0, Math.min(1, (event.x - 4) / parent.width))
            }
        }

        // ---------- time and controls ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Txt {
                Layout.fillWidth: true
                variant: "small"
                text: root.hasLength ? Media.fmt(root.player.position) + " / " + Media.fmt(root.player.length) : ""
            }

            Repeater {
                model: [
                    {
                        icon: Icons.previous,
                        enabled: root.player?.canGoPrevious ?? false,
                        action: () => Media.previous()
                    },
                    {
                        icon: (root.player?.isPlaying ?? false) ? Icons.pause : Icons.play,
                        enabled: root.player?.canTogglePlaying ?? false,
                        action: () => Media.toggle()
                    },
                    {
                        icon: Icons.next,
                        enabled: root.player?.canGoNext ?? false,
                        action: () => Media.next()
                    }
                ]

                delegate: Rectangle {
                    id: ctl
                    required property var modelData

                    implicitWidth: 28
                    implicitHeight: 28
                    radius: 14
                    color: ctlMouse.containsMouse && modelData.enabled ? Theme.surface : "transparent"
                    opacity: modelData.enabled ? 1 : 0.4

                    Txt {
                        anchors.centerIn: parent
                        text: ctl.modelData.icon
                        color: ctlMouse.containsMouse && ctl.modelData.enabled ? Theme.accent : Theme.fg
                        font.pixelSize: Theme.fontSize + 4
                    }

                    MouseArea {
                        id: ctlMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: ctl.modelData.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: ctl.modelData.action()
                    }
                }
            }
        }
    }
}
