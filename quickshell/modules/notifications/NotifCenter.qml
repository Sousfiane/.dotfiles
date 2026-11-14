import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

DropdownPanel {
    name: "notifs"
    open: Notifs.centerOpen
    edge: "right"
    cardWidth: 380

    onToggleRequested: Notifs.centerOpen = !Notifs.centerOpen
    onCloseRequested: Notifs.centerOpen = false

    ColumnLayout {
        spacing: 10

        // ---------- header ----------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Txt {
                Layout.fillWidth: true
                text: "Notifications"
                variant: "heading"
            }

            Pill {
                text: "Do not disturb"
                active: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }

            Pill {
                text: "Clear"
                onClicked: Notifs.clearHistory()
            }
        }

        Txt {
            visible: Notifs.history.count === 0
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            horizontalAlignment: Text.AlignHCenter
            text: "No notifications"
        }

        // ---------- history ----------
        ListView {
            id: list
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, 480)
            visible: Notifs.history.count > 0
            clip: true
            spacing: 8
            model: Notifs.history

            delegate: Rectangle {
                id: item
                required property int index
                required property string appName
                required property string summary
                required property string body
                required property int urgency
                required property string time

                width: ListView.view.width
                height: itemCol.implicitHeight + 20
                radius: 6
                color: Theme.surface
                border.width: urgency === NotificationUrgency.Critical ? 1 : 0
                border.color: Theme.urgent

                ColumnLayout {
                    id: itemCol
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 10
                    }
                    spacing: 2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Txt {
                            Layout.fillWidth: true
                            variant: "dim"
                            text: item.appName
                            elide: Text.ElideRight
                        }

                        Txt {
                            variant: "dim"
                            text: item.time
                        }

                        Txt {
                            variant: "dim"
                            text: "×"
                            font.pixelSize: Theme.fontSize + 2

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -4
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Notifs.removeAt(item.index)
                            }
                        }
                    }

                    Txt {
                        Layout.fillWidth: true
                        text: item.summary
                        wrapMode: Text.Wrap
                        font.bold: true
                    }

                    Txt {
                        Layout.fillWidth: true
                        visible: item.body !== ""
                        variant: "row"
                        text: item.body
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}
