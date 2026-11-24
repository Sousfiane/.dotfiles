import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Effects
import qs.config
import qs.services
import qs.components.ui

// The system tray as a drawer: one quiet chevron in the bar, the apps' icons sliding out of it on hover.
// They're drawn in greyscale so they sit in the bar like its own glyphs, and get their colours back
// under the pointer. Left click: the app's action; right click: its menu, as a dropdown.
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

    // the icons, revealed from the chevron leftwards
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

            opacity: root.expanded ? 1 : 0
            Behavior on opacity {
                Anim {
                    duration: root.expanded ? Motion.normal : Motion.fast
                    curve: root.expanded ? Motion.enter : Motion.exit
                }
            }

            Repeater {
                model: Tray.items

                delegate: Item {
                    id: slot
                    required property SystemTrayItem modelData

                    readonly property bool lit: area.containsMouse || (Tray.open && Tray.menuItem === modelData)
                    readonly property bool wantsAttention: modelData.status === Status.NeedsAttention

                    width: root.iconSize
                    height: root.iconSize

                    // the hover shows even on icons that are grey to begin with (symbolic ones like nm-applet's)
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

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            saturation: slot.lit || slot.wantsAttention ? 0 : -1
                            Behavior on saturation {
                                Anim {
                                    duration: Motion.fast
                                }
                            }
                        }
                        opacity: slot.lit ? 1 : 0.75
                        Behavior on opacity {
                            Anim {
                                duration: Motion.fast
                            }
                        }
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

    // the chevron: points to where the icons come from; clicking it works too (no hover on touch)
    BarButton {
        id: toggle
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        icon: root.expanded ? Icons.chevronRight : Icons.chevronLeft
        glyphs: [Icons.chevronLeft, Icons.chevronRight]
        open: Tray.open
        onClicked: root.expanded = !root.expanded

        // an app asking for attention while the drawer is shut
        Rectangle {
            visible: Tray.attention && !root.expanded
            x: toggle.iconSlot - 2
            y: -1
            width: 5
            height: 5
            radius: 2.5
            color: Theme.gold
        }
    }
}
