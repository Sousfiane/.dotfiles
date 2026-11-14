import QtQuick
import qs.config

Rectangle {
    id: root

    property string text: ""
    property bool active: false       // filled with the accent color (a toggle that is on)
    property bool primary: false      // accent-filled call to action
    property bool bold: primary
    property real fontSize: Theme.fontSize - 3

    signal clicked

    readonly property bool filled: active || primary

    implicitWidth: label.implicitWidth + 18
    implicitHeight: 24
    radius: height / 2
    color: filled ? Theme.accent : Theme.surface

    Txt {
        id: label
        anchors.centerIn: parent
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
