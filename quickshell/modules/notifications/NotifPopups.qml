import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services

PanelWindow {
    anchors {
        top: true
        right: true
    }
    margins {
        top: 8
        right: 8
    }
    implicitWidth: 360
    implicitHeight: column.implicitHeight
    visible: Notifs.list.values.length > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.list

            delegate: Rectangle {
                id: card
                required property var modelData   // a Notification

                // Image sent with the notification (cover art, screenshot, avatar...)
                readonly property string imageSource: modelData.image ?? ""

                // App icon: either an icon name or an absolute path
                readonly property string iconSource: {
                    const icon = modelData.appIcon ?? "";
                    if (icon === "")
                        return "";
                    return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, true);
                }

                readonly property bool hasPicture: imageSource !== "" || iconSource !== ""

                Layout.fillWidth: true
                implicitHeight: content.implicitHeight + 24
                radius: Theme.radius
                color: Theme.bg
                border.width: 2
                border.color: modelData.urgency === NotificationUrgency.Critical ? Theme.urgent : Theme.border

                Timer {
                    running: card.modelData.urgency !== NotificationUrgency.Critical
                    interval: card.modelData.expireTimeout > 0 ? card.modelData.expireTimeout * 1000 : 5000
                    onTriggered: card.modelData.expire()
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: card.modelData.dismiss()
                }

                RowLayout {
                    id: content
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 12
                    }
                    spacing: 12

                    // Picture: a real image gets a larger rounded thumbnail,
                    // a plain app icon stays small
                    ClippingRectangle {
                        visible: card.hasPicture
                        Layout.alignment: Qt.AlignTop
                        Layout.preferredWidth: card.imageSource !== "" ? 64 : 40
                        Layout.preferredHeight: card.imageSource !== "" ? 64 : 40
                        radius: card.imageSource !== "" ? Theme.radius : 0
                        color: "transparent"

                        Image {
                            anchors.fill: parent
                            source: card.imageSource !== "" ? card.imageSource : card.iconSource
                            fillMode: card.imageSource !== "" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                            sourceSize.width: 128
                            sourceSize.height: 128
                            asynchronous: true
                            smooth: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.appName
                            elide: Text.ElideRight
                            color: Theme.dim
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 2
                        }
                        Text {
                            Layout.fillWidth: true
                            text: card.modelData.summary
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize
                            font.bold: true
                            wrapMode: Text.Wrap
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: card.modelData.body !== ""
                            text: card.modelData.body
                            color: Theme.fg
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSize - 1
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }
}
