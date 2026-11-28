import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// The app switcher on screen (services/Switcher.qml: what it lists and does): a card on the focused monitor,
// the apps' icons or the front app's windows as live previews, the chosen one's name under them.
Scope {
    // ---------- drawing, on the focused monitor ----------

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            id: win

            required property ShellScreen modelData
            readonly property bool here: Switcher.open && Switcher.screenName === modelData.name

            screen: modelData
            visible: here
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "qs-switcher"
            WlrLayershell.keyboardFocus: here ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            implicitWidth: Math.min(modelData.width - 80, card.implicitWidth)
            implicitHeight: card.implicitHeight

            onHereChanged: if (here)
                keys.forceActiveFocus()

            Item {
                id: keys
                focus: true
                Keys.onPressed: event => {
                    const k = event.key;
                    if (k === Qt.Key_Escape)
                        Switcher.close();
                    else if (k === Qt.Key_Return || k === Qt.Key_Enter)
                        Switcher.commit();
                    else if (k === Qt.Key_L || k === Qt.Key_Right)
                        Switcher.step(1);
                    else if (k === Qt.Key_H || k === Qt.Key_Left)
                        Switcher.step(-1);
                    else if (k === Qt.Key_Q)
                        Switcher.quitChosen();
                    else
                        return;
                    event.accepted = true;
                }
                // ALT let go while the keyboard is here (Hyprland's release bind does it too)
                Keys.onReleased: event => {
                    if (event.key === Qt.Key_Alt || event.key === Qt.Key_AltGr)
                        Switcher.commit();
                }
            }

            Rectangle {
                id: card

                readonly property int pad: 14

                anchors.centerIn: parent
                implicitWidth: (Switcher.mode === "apps" ? appRow.implicitWidth : winRow.implicitWidth) + 2 * pad
                implicitHeight: (Switcher.mode === "apps" ? appRow.implicitHeight : winRow.implicitHeight) + label.implicitHeight + 3 * pad
                radius: Theme.radiusLarge + 6
                color: Theme.bg
                border.width: 1
                border.color: Theme.border
                opacity: Switcher.uiShown ? 1 : 0
                scale: Switcher.uiShown ? 1 : 0.96

                Behavior on opacity {
                    Anim {
                        duration: Motion.fast
                    }
                }
                Behavior on scale {
                    Anim {
                        curve: Motion.enter
                        duration: Motion.fast
                    }
                }

                // the apps: their icons, the chosen one on a plate
                Row {
                    id: appRow

                    visible: Switcher.mode === "apps"
                    x: card.pad
                    y: card.pad
                    spacing: 6

                    Repeater {
                        model: Switcher.mode === "apps" ? Switcher.apps : []

                        delegate: Item {
                            id: app

                            required property var modelData
                            required property int index
                            readonly property bool chosen: index === Switcher.index

                            width: 92
                            height: 92

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radiusLarge + 2
                                color: app.chosen ? Theme.surface : "transparent"
                                border.width: app.chosen ? 1 : 0
                                border.color: Theme.withAlpha(Theme.fg, 0.12)
                            }

                            AppIcon {
                                anchors.centerIn: parent
                                implicitSize: 64
                                source: app.modelData.icon
                            }

                            // how many windows it has, when more than one
                            Rectangle {
                                visible: app.modelData.windows.length > 1
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    margins: 6
                                }
                                width: Math.max(height, n.implicitWidth + 8)
                                height: 18
                                radius: height / 2
                                color: Theme.accent

                                Txt {
                                    id: n
                                    anchors.centerIn: parent
                                    variant: "small"
                                    font.bold: true
                                    color: Theme.bgSolid
                                    text: app.modelData.windows.length
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: Switcher.index = app.index
                                onClicked: Switcher.commit()
                            }
                        }
                    }
                }

                // the windows of the app in front: live previews
                Row {
                    id: winRow

                    readonly property int tileH: 150

                    visible: Switcher.mode === "windows"
                    x: card.pad
                    y: card.pad
                    spacing: 10

                    Repeater {
                        model: Switcher.mode === "windows" ? Switcher.appWindows : []

                        delegate: Item {
                            id: tile

                            required property var modelData
                            required property int index
                            readonly property bool chosen: index === Switcher.index
                            readonly property var size: modelData.lastIpcObject?.size ?? [16, 9]

                            height: winRow.tileH
                            width: Math.max(100, Math.min(300, height * size[0] / Math.max(1, size[1])))

                            ClippingRectangle {
                                anchors.fill: parent
                                radius: Theme.radiusLarge
                                color: Theme.surface

                                ScreencopyView {
                                    anchors.fill: parent
                                    captureSource: win.here ? (tile.modelData.wayland ?? null) : null
                                    live: true
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: Theme.radiusLarge
                                color: "transparent"
                                border.width: tile.chosen ? 2 : 1
                                border.color: tile.chosen ? Theme.accent : Theme.withAlpha(Theme.fg, 0.12)
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: Switcher.index = tile.index
                                onClicked: Switcher.commit()
                            }
                        }
                    }
                }

                // the chosen one's name (an app) or title (a window)
                Txt {
                    id: label
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: card.pad
                    }
                    width: card.width - 2 * card.pad
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    variant: "body"
                    text: Switcher.mode === "apps" ? (Switcher.apps[Switcher.index]?.name ?? "") : (Switcher.appWindows[Switcher.index]?.title ?? "")
                }
            }
        }
    }
}
