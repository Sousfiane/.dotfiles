import QtQuick
import qs.config

Rectangle {
    id: root

    property string text: ""
    property bool active: false       // filled with the accent color (a toggle that is on)
    property bool primary: false      // accent-filled call to action
    property bool bold: primary
    property real fontSize: Theme.fontSize - 3
    property real minWidth: 0         // keeps buttons whose label changes from jumping around
    property real maxWidth: 0         // 0 = no limit; longer labels are elided

    signal clicked

    readonly property bool filled: active || primary
    readonly property real natural: label.implicitWidth + 18

    implicitWidth: Math.max(minWidth, maxWidth > 0 ? Math.min(natural, maxWidth) : natural)
    implicitHeight: 24
    radius: height / 2
    color: filled ? Theme.accent : Theme.surface

    Txt {
        id: label
        anchors.centerIn: parent
        width: Math.min(implicitWidth, root.width - 18)
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        text: root.text
        color: root.filled ? Theme.bgSolid : Theme.fg
        font.pixelSize: root.fontSize
        font.bold: root.bold
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
