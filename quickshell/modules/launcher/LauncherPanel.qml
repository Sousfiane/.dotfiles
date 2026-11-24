import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

DropdownPanel {
    name: "launcher"
    edge: "center"
    cardWidth: 560
    cardHeight: 440
    autoFocus: false            // the search box takes the focus itself

    ColumnLayout {
        spacing: 8

        SearchBox {
            placeholder: "Apps..."

            onTextChanged: {
                Launcher.query = text;
                list.currentIndex = 0;
                list.positionViewAtBeginning();
            }

            onMoved: direction => {
                if (direction === "down")
                    list.incrementCurrentIndex();
                else if (direction === "up")
                    list.decrementCurrentIndex();
            }
            onAccepted: Launcher.launch(Launcher.results[list.currentIndex])
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            // diffed, so typing only adds and removes the rows that changed (icons aren't reloaded)
            model: ScriptModel {
                values: Launcher.results
            }
            currentIndex: 0

            // rows leave a gutter for the scrollbar while it shows (same as ScrollList)
            readonly property real rowWidth: width - (vbar.size < 1 ? vbar.width + 6 : 0)

            ScrollBar.vertical: ScrollBar {
                id: vbar
                policy: ScrollBar.AsNeeded
            }

            delegate: Rectangle {
                id: row

                required property var modelData
                required property int index

                width: ListView.view.rowWidth
                height: 36
                radius: Theme.radius
                color: ListView.isCurrentItem ? Theme.surface : Theme.surfaceClear

                MotionArea {
                    anchors.fill: parent
                    onMoved: list.currentIndex = row.index
                    onClicked: Launcher.launch(row.modelData)
                }

                Behavior on color {
                    CAnim {}
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 10
                    spacing: 10

                    AppIcon {
                        implicitSize: 24
                        source: Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                    }

                    Txt {
                        Layout.fillWidth: true
                        text: row.modelData.name
                        elide: Text.ElideRight
                    }

                    // for an action, the app it belongs to
                    Txt {
                        Layout.maximumWidth: list.width * 0.4
                        visible: text !== ""
                        variant: "dim"
                        text: row.modelData.detail ?? ""
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
