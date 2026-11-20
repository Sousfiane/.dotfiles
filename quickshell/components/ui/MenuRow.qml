import QtQuick
import QtQuick.Layouts
import qs.config

// one entry of a keyboard menu (power, screenshot): icon, label and shortcut key.
// Hovering selects it, clicking runs it.
Rectangle {
    id: root

    property string icon: ""
    property string label: ""
    property string key: ""
    property bool current: false

    signal entered
    signal clicked

    Layout.fillWidth: true
    implicitHeight: 44
    radius: Theme.radius
    color: current ? Theme.surface : "transparent"
    border.width: current ? 1 : 0
    border.color: Theme.accent

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 12

        Txt {
            Layout.preferredWidth: 26
            horizontalAlignment: Text.AlignHCenter
            text: root.icon
            color: root.current ? Theme.accent : Theme.fg
            font.pixelSize: Theme.fontSize + 6
        }

        Txt {
            Layout.fillWidth: true
            text: root.label
            font.bold: root.current
            elide: Text.ElideRight
        }

        KeyBadge {
            text: root.key
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: root.entered()
        onClicked: root.clicked()
    }
}
