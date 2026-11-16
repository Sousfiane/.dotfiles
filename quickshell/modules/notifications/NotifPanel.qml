import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

DropdownPanel {
    name: "notifs"
    edge: "right"
    cardWidth: 380

    ColumnLayout {
        spacing: 10

        // ---------- header ----------
        PanelHeader {
            icon: Notifs.dnd ? Icons.bellOff : Icons.bell
            iconColor: Notifs.dnd ? Theme.dim : Theme.accent
            title: "Notifications"

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
            visible: Notifs.history.length === 0
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            horizontalAlignment: Text.AlignHCenter
            variant: "dim"
            text: "No notifications"
        }

        // ---------- history ----------
        ScrollList {
            id: list
            maxHeight: 480
            visible: Notifs.history.length > 0
            spacing: 8
            model: Notifs.history

            delegate: Rectangle {
                id: item
                required property var modelData
                required property int index

                // live text while the app still has the notification open (it may update it)
                readonly property var live: modelData.notif
                readonly property string appName: live?.appName ?? modelData.appName
                readonly property string summary: live?.summary ?? modelData.summary
                readonly property string body: live?.body ?? modelData.body
                readonly property int urgency: live?.urgency ?? modelData.urgency
                readonly property string time: modelData.time

                width: ListView.view.width
                height: itemCol.implicitHeight + 20
                radius: Theme.radius
                color: Theme.surface
                border.width: urgency === NotificationUrgency.Critical || cardMouse.containsMouse ? 1 : 0
                border.color: urgency === NotificationUrgency.Critical ? Theme.urgent : Theme.accent

                // click: go to the app that sent it
                MouseArea {
                    id: cardMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.activate(item.modelData)
                }

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
