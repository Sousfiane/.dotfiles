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
    id: win

    anchors {
        top: true
        right: true
    }
    margins {
        top: 8
        right: 8
    }
    implicitWidth: 360
    // taller than the stack, so cards sliding around are never cut off by the window resizing;
    // only the cards themselves take clicks
    implicitHeight: Math.max(1, (screen?.height ?? 1080) - 16 - Theme.barHeight)
    mask: Region {
        item: list
    }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-toasts"

    // stays up a moment after the last toast goes, so it can slide out
    readonly property bool any: Notifs.popups.length > 0
    onAnyChanged: if (!any)
        linger.restart()
    visible: any || linger.running

    Timer {
        id: linger
        interval: Motion.out + 20
    }

    ListView {
        id: list
        width: parent.width
        height: contentHeight
        interactive: false
        spacing: 8

        model: ScriptModel {
            values: Notifs.popupIds
        }

        // new toasts slide in from the screen edge, gone ones slide back out to it,
        // and the rest move to their new place
        add: Transition {
            Anim {
                property: "x"
                from: list.width
                to: 0
                curve: Motion.enter
            }
            Anim {
                property: "opacity"
                from: 0
                to: 1
                curve: Motion.enter
            }
        }
        remove: Transition {
            Anim {
                property: "x"
                to: list.width
                duration: Motion.out
                curve: Motion.exit
            }
            Anim {
                property: "opacity"
                to: 0
                duration: Motion.out
                curve: Motion.exit
            }
        }
        displaced: Transition {
            Anim {
                property: "y"
            }
        }

        delegate: Rectangle {
            id: card
            required property var modelData   // the entry's id (see Notifs)

            property var note: Notifs.view(modelData)

            // freeze what it shows while it slides out: the entry may already be gone from Notifs
            ListView.onRemove: note = note

            readonly property string imageSource: note.image
            readonly property string iconSource: note.icon

            readonly property bool hasPicture: imageSource !== "" || iconSource !== ""
            readonly property bool critical: note.urgency === NotificationUrgency.Critical

            width: ListView.view.width
            implicitHeight: content.implicitHeight + 24
            radius: Theme.radius
            color: Theme.bg
            border.width: 2
            border.color: critical ? Theme.urgent : Theme.border

            // hides the toast only; the notification stays in the center
            Timer {
                running: !card.critical
                interval: card.note.timeout
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

                    AppIcon {
                        id: pic
                        anchors.fill: parent
                        source: card.imageSource !== "" ? card.imageSource : card.iconSource
                        fillMode: card.imageSource !== "" ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                        // keep a copy of a raw image, for the center (see Notifs.saveImage)
                        onStatusChanged: if (status === Image.Ready && card.imageSource !== "")
                            Notifs.saveImage(card.modelData, pic)
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 2

                    Txt {
                        Layout.fillWidth: true
                        variant: "dim"
                        text: card.note.appName
                        elide: Text.ElideRight
                    }

                    Txt {
                        Layout.fillWidth: true
                        font.bold: true
                        text: card.note.summary
                        wrapMode: Text.Wrap
                    }

                    Txt {
                        Layout.fillWidth: true
                        visible: card.note.body !== ""
                        variant: "row"
                        text: card.note.body
                        wrapMode: Text.Wrap
                    }
                }
            }
        }
    }
}
