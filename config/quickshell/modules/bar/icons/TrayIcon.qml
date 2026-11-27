import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// The system tray as a drawer: three quiet dots in the bar, the apps' icons popping out of them on hover.
// Tucked away behind the dots, they keep their own colours. Left click: the app's action; right click: its menu, as a dropdown.
Item {
    id: root

    visible: Tray.items.length > 0

    property bool expanded: false

    // stays out while the pointer is on it or one of its menus is open, then tucks itself away
    readonly property bool keepOpen: hover.hovered || Tray.open
    onKeepOpenChanged: {
        if (keepOpen) {
            collapse.stop();
            expanded = true;
        } else {
            collapse.restart();
        }
    }

    Timer {
        id: collapse
        interval: 700
        onTriggered: root.expanded = false
    }

    readonly property int iconSize: 16
    readonly property int gap: 9                   // between the icons and the chevron (+ the row's padding: 14)

    implicitHeight: toggle.implicitHeight
    implicitWidth: toggle.implicitWidth + (expanded ? icons.implicitWidth + gap : 0)
    Behavior on implicitWidth {
        Anim {
            duration: root.expanded ? Motion.normal : Motion.out
            curve: root.expanded ? Motion.enter : Motion.exit
        }
    }

    HoverHandler {
        id: hover
        margin: 9                                  // the bar's padding around each item
    }

    // the icons, revealed from the dots leftwards
    Item {
        anchors {
            left: parent.left
            right: toggle.left
            rightMargin: root.gap
            verticalCenter: parent.verticalCenter
        }
        height: Theme.barHeight
        clip: true

        Row {
            id: icons
            anchors {
                right: parent.right
                verticalCenter: parent.verticalCenter
            }
            spacing: 12
            // room for the hover highlight of the first and last icon, which the drawer would clip
            leftPadding: 5
            rightPadding: 5

            Repeater {
                model: Tray.items

                delegate: Item {
                    id: slot
                    required property SystemTrayItem modelData
                    required property int index

                    // opening, the icons pop out one after the other, the one next to the dots first: each fades
                    // in, grows to its size and slides out of the dots. Closing is quick and all at once.
                    readonly property int order: Tray.items.length - 1 - index
                    property real shown: root.expanded ? 1 : 0
                    Behavior on shown {
                        SequentialAnimation {
                            PauseAnimation {
                                duration: root.expanded ? slot.order * 45 : 0
                            }
                            Anim {
                                duration: root.expanded ? Motion.normal : Motion.fast
                                curve: root.expanded ? Motion.enter : Motion.exit
                            }
                        }
                    }
                    opacity: shown
                    scale: 0.6 + 0.4 * shown
                    transform: Translate {
                        x: (1 - slot.shown) * 10
                    }

                    readonly property bool lit: area.containsMouse || (Tray.open && Tray.menuItem === modelData)

                    width: root.iconSize
                    height: root.iconSize

                    // the hover shows as a backdrop, so it reads on grey symbolic icons too (nm-applet's)
                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width + 10
                        height: parent.height + 10
                        radius: Theme.radius
                        color: slot.lit ? Theme.surface : Theme.surfaceClear
                        Behavior on color {
                            CAnim {}
                        }
                    }

                    AppIcon {
                        anchors.fill: parent
                        implicitSize: root.iconSize
                        source: slot.modelData.icon
                    }

                    MouseArea {
                        id: area
                        anchors {
                            fill: parent
                            margins: -6
                        }
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                        onClicked: mouse => Tray.click(slot.modelData, mouse.button)
                        onWheel: wheel => slot.modelData.scroll(wheel.angleDelta.y, false)
                    }
                }
            }
        }
    }

    // the dots: a quarter turn while the drawer is open; clicking them works too (no hover on touch)
    BarButton {
        id: toggle
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        icon: Icons.dots
        iconRotation: root.expanded ? 90 : 0
        open: Tray.open
        onClicked: root.expanded = !root.expanded

        // an app asking for attention while the drawer is shut
        Rectangle {
            visible: Tray.attention && !root.expanded
            x: toggle.iconSlot - 2
            y: -1
            width: 5
            height: 5
            radius: width / 2
            color: Theme.gold
        }
    }
}
