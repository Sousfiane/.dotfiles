import QtQuick
import QtQuick.Layouts
import qs.config

RowLayout {
    id: root

    property string icon: ""
    property color iconColor: Theme.accent
    property string title: ""
    property string subtitle: ""
    property color subtitleColor: Theme.dim

    // children (pills, switches...) are placed on the right
    default property alias actions: actionRow.data

    Layout.fillWidth: true
    spacing: 10

    Txt {
        visible: root.icon !== ""
        text: root.icon
        color: root.iconColor
        font.pixelSize: Theme.fontSize + 6
    }

    ColumnLayout {
        spacing: 0

        Txt {
            text: root.title
            variant: "title"
        }

        Txt {
            visible: root.subtitle !== ""
            variant: "small"
            color: root.subtitleColor
            text: root.subtitle
        }
    }

    Item {
        Layout.fillWidth: true
    }

    RowLayout {
        id: actionRow
        spacing: 8
    }
}
