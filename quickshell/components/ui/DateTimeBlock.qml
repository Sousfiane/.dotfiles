import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config

// big time with the date under it (hub header, lockscreen)
ColumnLayout {
    id: root

    property int timeSize: Theme.fontSize + 18
    property int dateSize: Theme.fontSize - 2
    property int align: Qt.AlignLeft

    spacing: 0

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Txt {
        Layout.alignment: root.align
        text: Qt.formatDateTime(clock.date, "HH:mm")
        font.pixelSize: root.timeSize
        font.bold: true
    }

    Txt {
        Layout.alignment: root.align
        variant: "dim"
        font.pixelSize: root.dateSize
        text: Qt.formatDateTime(clock.date, "dddd d MMMM")
    }
}
