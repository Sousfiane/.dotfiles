import QtQuick
import QtQuick.Layouts
import qs.config

// one entry of a keyboard menu (power, screenshot): icon, label and shortcut key.
// Hovering selects it, clicking runs it.
SelectableCard {
    id: root

    property string icon: ""
    property string label: ""
    property string key: ""

    signal entered
    signal clicked

    Layout.fillWidth: true
    implicitHeight: 44

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
            color: root.selected ? Theme.accent : Theme.fg
            Behavior on color {
                CAnim {}
            }
            font.pixelSize: Theme.fontSize + 6
        }

        Txt {
            Layout.fillWidth: true
            text: root.label
            font.bold: root.selected
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
