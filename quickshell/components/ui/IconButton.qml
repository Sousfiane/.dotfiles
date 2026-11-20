import QtQuick
import qs.config

// A clickable glyph. By default a 28 px round button that lights up on hover;
// `flat` drops the background and just widens the click area (×, ‹ inside rows).
Item {
    id: root

    property string icon: ""
    property real size: Theme.fontSize + 4      // glyph size
    property color color: Theme.fg
    property color hoverColor: color
    property bool flat: false

    readonly property bool hovered: mouse.containsMouse

    signal clicked

    implicitWidth: flat ? glyph.implicitWidth : 28
    implicitHeight: flat ? glyph.implicitHeight : 28
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        visible: !root.flat
        radius: width / 2
        color: root.hovered ? Theme.surface : "transparent"
    }

    Txt {
        id: glyph
        anchors.centerIn: parent
        text: root.icon
        color: root.hovered ? root.hoverColor : root.color
        font.pixelSize: root.size
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        anchors.margins: root.flat ? -4 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
