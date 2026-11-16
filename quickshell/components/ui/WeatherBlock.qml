import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

// icon + temperature, description, high/low and place (hub header, lockscreen)
ColumnLayout {
    id: root

    property int iconSize: Theme.fontSize + 14
    property int tempSize: Theme.fontSize + 10
    property int descSize: Theme.fontSize - 2
    property int smallSize: Theme.fontSize - 3
    property int align: Qt.AlignRight
    property int descWidth: 150         // the description elides past this

    readonly property int textAlign: align === Qt.AlignLeft ? Text.AlignLeft : align === Qt.AlignHCenter ? Text.AlignHCenter : Text.AlignRight

    visible: Weather.ready
    spacing: 0

    RowLayout {
        Layout.alignment: root.align
        spacing: 6

        Txt {
            text: Weather.icon
            font.pixelSize: root.iconSize
        }

        Txt {
            text: Weather.temp + "°"
            font.pixelSize: root.tempSize
            font.bold: true
        }
    }

    Txt {
        Layout.alignment: root.align
        Layout.maximumWidth: root.descWidth
        variant: "dim"
        font.pixelSize: root.descSize
        horizontalAlignment: root.textAlign
        elide: Text.ElideRight
        text: Weather.desc
    }

    Txt {
        Layout.alignment: root.align
        variant: "small"
        font.pixelSize: root.smallSize
        text: "↑" + Weather.high + "° ↓" + Weather.low + "°  " + Weather.area
    }
}
