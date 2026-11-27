import QtQuick
import qs.config

// A round button holding one glyph (the hub's tabs), filled with the accent when `active`. The glyph is
// centred by its ink, not its text box: Nerd Font icons sit off-centre in their box, each differently.
Rectangle {
    id: root

    property string icon: ""
    property bool active: false
    property real iconSize: Theme.fontSize + 1

    signal clicked

    implicitWidth: 30
    implicitHeight: 28
    radius: height / 2
    color: active ? Theme.accent : mouse.containsMouse ? Theme.surfaceSolid : Theme.surface
    Behavior on color {
        CAnim {}
    }

    TextMetrics {
        id: ink
        font: glyph.font
        text: root.icon
    }

    Txt {
        id: glyph
        text: root.icon
        color: root.active ? Theme.bgSolid : Theme.fg
        font.pixelSize: root.iconSize
        x: Math.round((root.width - ink.tightBoundingRect.width) / 2 - ink.tightBoundingRect.x)
        y: Math.round((root.height - ink.tightBoundingRect.height) / 2 - baselineOffset - ink.tightBoundingRect.y)
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
