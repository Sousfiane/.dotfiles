import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The notification center (SUPER + N, or the bell): the history, newest first, to open, dismiss or clear.
DropdownPanel {
    id: panel
    name: "notifs"
    edge: "right"
    cardWidth: 380
    animateHeight: false          // the history list animates its own height, the card follows it

    ColumnLayout {
        id: menu
        spacing: 10

        Selection {
            id: nav
            count: Notifs.history.length
            view: list
        }
        readonly property Notif selected: Notifs.history[nav.index] ?? null

        // the same slide-out as the × and the swipe; the next card takes the selection
        function dismissSelected() {
            if (!selected)
                return;
            const card = list.itemAtIndex(nav.index);
            if (card)
                card.dismiss();
            else
                Notifs.remove(selected);
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_J:
            case Qt.Key_Down:
                nav.move(1);
                break;
            case Qt.Key_K:
            case Qt.Key_Up:
                nav.move(-1);
                break;
            case Qt.Key_G:
                nav.select(event.modifiers & Qt.ShiftModifier ? nav.count - 1 : 0);
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
            case Qt.Key_L:
                if (selected)
                    Notifs.activate(selected);
                break;
            case Qt.Key_D:
            case Qt.Key_X:
            case Qt.Key_Delete:
                dismissSelected();
                break;
            case Qt.Key_C:
                Notifs.clearHistory();
                break;
            case Qt.Key_N:
                Notifs.dnd = !Notifs.dnd;
                break;
            case Qt.Key_Q:
                panel.close();
                break;
            default:
                return;
            }
            event.accepted = true;
        }

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

        EmptyState {
            visible: Notifs.history.length === 0
            text: "No notifications"
        }

        // ---------- history ----------
        ScrollList {
            id: list
            maxHeight: 480
            animateHeight: panel.settled
            visible: Notifs.history.length > 0
            spacing: 8
            // diffed: a new notification adds one card instead of rebuilding them all
            model: ScriptModel {
                values: Notifs.history
            }

            // a new card fades in while the others make room for it
            add: Transition {
                Anim {
                    property: "opacity"
                    from: 0
                    to: 1
                    curve: Motion.enter
                }
            }

            // the cards below a removed one slide up into its place
            displaced: Transition {
                Anim {
                    property: "y"
                }
            }

            // the delegate holds the card in place; the card itself slides right when dismissed
            delegate: Item {
                id: item
                required property Notif modelData
                required property int index

                readonly property bool selected: index === nav.index

                readonly property Notif notif: modelData

                // dragged past this far, a released card goes; short of it, it springs back
                readonly property real dismissAt: width * 0.3
                property bool leaving: false

                // slide out to the right, then drop it from the history
                function dismiss() {
                    if (leaving)
                        return;
                    leaving = true;
                    snapBack.stop();
                    slideOut.start();
                }

                width: ListView.view.rowWidth
                height: card.height

                Anim {
                    id: slideOut
                    target: card
                    property: "x"
                    to: item.width
                    duration: Motion.out
                    curve: Motion.exit
                    onFinished: Notifs.remove(item.notif)
                }

                Anim {
                    id: snapBack
                    target: card
                    property: "x"
                    to: 0
                    curve: Motion.enter
                }

                Rectangle {
                    id: card
                    width: parent.width
                    height: itemCol.implicitHeight + 20
                    radius: Theme.radius
                    color: Theme.surface
                    border.width: 1
                    border.color: item.notif.critical ? Theme.urgent : item.selected || cardMouse.containsMouse ? Theme.accent : Theme.accentClear
                    Behavior on border.color {
                        CAnim {}
                    }
                    // fades as it is pushed away
                    opacity: 1 - 0.8 * Math.min(1, x / width)

                    // click: go to the app that sent it. Drag right: dismiss it
                    MouseArea {
                        id: cardMouse

                        property bool swiped: false

                        anchors.fill: parent
                        enabled: !item.leaving
                        hoverEnabled: true
                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.PointingHandCursor

                        drag.target: card
                        drag.axis: Drag.XAxis
                        drag.minimumX: 0
                        drag.maximumX: card.width

                        onPressed: {
                            swiped = false;
                            snapBack.stop();
                        }
                        onPositionChanged: {
                            if (drag.active)
                                swiped = true;
                        }
                        onReleased: {
                            if (card.x > item.dismissAt)
                                item.dismiss();
                            else if (card.x > 0)
                                snapBack.start();
                        }
                        // a drag that ends is not a click
                        onClicked: {
                            if (!swiped)
                                Notifs.activate(item.notif);
                        }
                    }

                    RowLayout {
                        id: itemCol
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: parent.top
                            margins: 10
                        }
                        spacing: 10

                        // same as the toast: a real image gets a larger rounded thumbnail, a plain app icon stays small.
                        // Hidden if it doesn't load (a file gone since, an image never saved)
                        ClippingRectangle {
                            id: thumb
                            readonly property bool isImage: item.notif.image !== ""
                            visible: (isImage || item.notif.iconSource !== "") && pic.status !== Image.Error
                            Layout.alignment: Qt.AlignTop
                            Layout.topMargin: 2
                            Layout.preferredWidth: isImage ? 56 : 32
                            Layout.preferredHeight: isImage ? 56 : 32
                            radius: isImage ? Theme.radius : 0
                            color: "transparent"

                            AppIcon {
                                id: pic
                                anchors.fill: parent
                                source: thumb.isImage ? item.notif.image : item.notif.iconSource
                                fillMode: thumb.isImage ? Image.PreserveAspectCrop : Image.PreserveAspectFit
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Txt {
                                    Layout.fillWidth: true
                                    variant: "dim"
                                    text: item.notif.appName
                                    elide: Text.ElideRight
                                }

                                Txt {
                                    variant: "dim"
                                    text: item.notif.timeText
                                }

                                IconButton {
                                    flat: true
                                    icon: "×"
                                    size: Theme.fontSize + 2
                                    color: Theme.dim
                                    onClicked: item.dismiss()      // ignored while already leaving
                                }
                            }

                            Txt {
                                Layout.fillWidth: true
                                text: item.notif.summary
                                wrapMode: Text.Wrap
                                font.bold: true
                            }

                            Txt {
                                Layout.fillWidth: true
                                visible: item.notif.body !== ""
                                variant: "row"
                                text: item.notif.body
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        Hint {
            text: "j k select • Enter open • d dismiss • c clear • n do not disturb • Esc close"
        }
    }
}
