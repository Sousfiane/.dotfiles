import QtQuick
import QtQuick.Layouts
import qs.config

// A small figure in a box (the hub's Home row): its name and a detail on top, the value, and a bar
// that turns to the urgent colour past 85%.
Rectangle {
    id: cell

    property string label
    property string value
    property string detail: ""
    property real fraction: -1       // the bar; -1 = not known yet

    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: 58
    radius: Theme.radius
    color: Theme.surfaceClear
    border.width: 1
    border.color: Theme.border

    ColumnLayout {
        anchors {
            fill: parent
            margins: 8
        }
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Txt {
                variant: "small"
                text: cell.label
            }

            Item {
                Layout.fillWidth: true
            }

            Txt {
                variant: "small"
                text: cell.detail
            }
        }

        Txt {
            font.bold: true
            text: cell.value
        }

        Meter {
            Layout.fillWidth: true
            fraction: cell.fraction
        }
    }
}
