import Quickshell
import QtQuick
import qs.config
import qs.services

Item {
    id: root

    property string terminal: "kitty"      // change to foot, alacritty, ghostty...
    property bool showPercent: false

    readonly property int pct: Math.round(Audio.volume * 100)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 6

        Text {
            // nf-md: volume_off, volume_low, volume_medium, volume_high
            text: (Audio.muted || root.pct === 0) ? String.fromCodePoint(0xF0581) : root.pct < 34 ? String.fromCodePoint(0xF057F) : root.pct < 67 ? String.fromCodePoint(0xF0580) : String.fromCodePoint(0xF057E)

            color: Audio.muted ? Theme.dim : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 3
        }

        Text {
            visible: root.showPercent
            anchors.verticalCenter: parent.verticalCenter
            text: Audio.muted ? "muted" : root.pct + "%"
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: Theme.fontSize
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["uwsm", "app", "--", root.terminal, "--app-id=FloatingTerm", "-e", "wiremix"])
    }
}
