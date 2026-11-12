import Quickshell
import QtQuick
import qs.config
import qs.services

Item {
    id: root

    property bool showPercent: false

    readonly property int pct: Math.round(Audio.volume * 100)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 6

        Text {
            // nf-md: volume_off, volume_low, volume_medium, volume_high
            text: (Audio.muted || root.pct === 0) ? String.fromCodePoint(0xeee8) : root.pct < 25 ? String.fromCodePoint(0xf026) : root.pct < 50 ? String.fromCodePoint(0xf027) : root.pct < 75 ? String.fromCodePoint(0xefcf) : String.fromCodePoint(0xf028)

            color: Audio.muted ? Theme.dim : Theme.fg
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 2
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
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: mouse => {
            if (mouse.button === Qt.RightButton)
                Mixer.toggleMute(Audio.sink);
            else
                Mixer.toggle();
        }
        onWheel: wheel => Mixer.adjust(Audio.sink, wheel.angleDelta.y > 0 ? 0.05 : -0.05)
    }
}
