import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

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
    visible: Notifs.popups.length > 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-toasts"

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.popups

            delegate: Rectangle {
                id: card
                required property var modelData   // an entry from Notifs (see there)

                readonly property var live: modelData.notif
                readonly property string appName: live?.appName ?? modelData.appName
                readonly property string summary: live?.summary ?? modelData.summary
                readonly property string body: live?.body ?? modelData.body

                // image sent with the notification (cover art, screenshot, avatar...)
                readonly property string imageSource: live?.image ?? ""

                // app icon: either an icon name or an absolute path
                readonly property string iconSource: {
                    const icon = live?.appIcon ?? "";
                    if (icon === "")
                        return "";
                    return icon.startsWith("/") ? "file://" + icon : Quickshell.iconPath(icon, true);
                }

                readonly property bool hasPicture: imageSource !== "" || iconSource !== ""
                readonly property bool critical: (live?.urgency ?? modelData.urgency) === NotificationUrgency.Critical

                Layout.fillWidth: true
                implicitHeight: content.implicitHeight + 24
                radius: Theme.radius
                color: Theme.bg
                border.width: 2
                border.color: critical ? Theme.urgent : Theme.border

                // hides the toast only; the notification stays in the center
                Timer {
                    running: card.modelData.popupUntil > 0
                    interval: Math.max(1, card.modelData.popupUntil - Date.now())
                    onTriggered: Notifs.hidePopup(card.modelData)
                }

                // click: go to the app that sent it
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.activate(card.modelData)
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

                    // a real image gets a larger rounded thumbnail, a plain app icon stays small
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

                        Txt {
                            Layout.fillWidth: true
                            variant: "dim"
                            text: card.appName
                            elide: Text.ElideRight
                        }

                        Txt {
                            Layout.fillWidth: true
                            font.bold: true
                            text: card.summary
                            wrapMode: Text.Wrap
                        }

                        Txt {
                            Layout.fillWidth: true
                            visible: card.body !== ""
                            variant: "row"
                            text: card.body
                            wrapMode: Text.Wrap
                        }
                    }
                }
            }
        }
    }
}
