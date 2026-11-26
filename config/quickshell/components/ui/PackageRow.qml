import QtQuick
import QtQuick.Layouts
import qs.config

// A package in the Install or Remove list: its name and version, its description under them, and small
// tags on the right (its repository, "installed", the dotfiles list it's in...).
Rectangle {
    id: row

    property string name: ""
    property string version: ""
    property string description: ""
    property var tags: []               // [{ text, color }]
    property bool current: false

    signal moved
    signal clicked

    implicitHeight: description ? 50 : 36
    radius: Theme.radius
    color: current ? Theme.surface : Theme.surfaceClear
    Behavior on color {
        CAnim {}
    }

    MotionArea {
        anchors.fill: parent
        onMoved: row.moved()
        onClicked: row.clicked()
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Txt {
                    text: row.name
                    font.bold: row.current
                    elide: Text.ElideRight
                    Layout.maximumWidth: row.width * 0.5
                }

                Txt {
                    Layout.fillWidth: true
                    variant: "small"
                    text: row.version
                    elide: Text.ElideRight
                }
            }

            Txt {
                visible: row.description !== ""
                Layout.fillWidth: true
                variant: "dim"
                text: row.description
                elide: Text.ElideRight
            }
        }

        Repeater {
            model: row.tags

            delegate: Rectangle {
                required property var modelData

                implicitWidth: tagText.implicitWidth + 12
                implicitHeight: tagText.implicitHeight + 4
                radius: Theme.radiusSmall
                color: "transparent"
                border.width: 1
                border.color: modelData.color ?? Theme.line

                Txt {
                    id: tagText
                    anchors.centerIn: parent
                    variant: "small"
                    color: parent.modelData.color ?? Theme.dim
                    text: parent.modelData.text
                }
            }
        }
    }
}
