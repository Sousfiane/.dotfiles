import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

DropdownPanel {
    id: panel
    name: "notifs"
    edge: "right"
    cardWidth: 380

    ColumnLayout {
        id: menu
        spacing: 10

        Selection {
            id: nav
            count: Notifs.historyIds.length
            view: list
        }
        readonly property var selId: Notifs.historyIds[nav.index] ?? null

        // the same slide-out as the × and the swipe; the next card takes the selection
        function dismissSelected() {
            if (selId === null)
                return;
            const card = list.itemAtIndex(nav.index);
            if (card)
                card.dismiss();
            else
                Notifs.remove(selId);
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
                if (selId !== null)
                    Notifs.activate(selId);
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
            // diffed: a new notification adds one card instead of rebuilding them all
            model: ScriptModel {
                values: Notifs.historyIds
            }

            // the cards below a removed one slide up into its place
            displaced: Transition {
                NumberAnimation {
                    property: "y"
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            // the delegate holds the card in place; the card itself slides right when dismissed
            delegate: Item {
                id: item
                required property var modelData      // the entry's id
                required property int index

                readonly property bool selected: index === nav.index

                readonly property var entry: Notifs.entry(modelData)

                // live text while the app still has the notification open (it may update it)
                readonly property var live: entry?.notif ?? null
                readonly property string appName: live?.appName ?? entry?.appName ?? ""
                readonly property string summary: live?.summary ?? entry?.summary ?? ""
                readonly property string body: live?.body ?? entry?.body ?? ""
                readonly property int urgency: live?.urgency ?? entry?.urgency ?? 0
                readonly property string time: entry?.time ?? ""

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

                width: ListView.view.width
                height: card.height

                NumberAnimation {
                    id: slideOut
                    target: card
                    property: "x"
                    to: item.width
                    duration: 180
                    easing.type: Easing.InCubic
                    onFinished: Notifs.remove(item.modelData)
                }

                NumberAnimation {
                    id: snapBack
                    target: card
                    property: "x"
                    to: 0
                    duration: 200
                    easing.type: Easing.OutCubic
                }

                Rectangle {
                    id: card
                    width: parent.width
                    height: itemCol.implicitHeight + 20
                    radius: Theme.radius
                    color: Theme.surface
                    border.width: item.urgency === NotificationUrgency.Critical || item.selected || cardMouse.containsMouse ? 1 : 0
                    border.color: item.urgency === NotificationUrgency.Critical ? Theme.urgent : Theme.accent
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
                                Notifs.activate(item.modelData);
                        }
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
                                    enabled: !item.leaving
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: item.dismiss()
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

        Hint {
            text: "j k select • Enter open • d dismiss • c clear • n do not disturb • Esc close"
        }
    }
}
