import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// The minimap of the scrolling layout, next to the workspace dots: the columns of the workspace this
// monitor shows, side by side at their widths (a screen is 40 px wide here), a column of several windows
// split across, and a frame round what's on screen. The focused column is in the accent, what's out of
// view fainter. Shown once the workspace has two columns.
//
// The frame stands in a gap of its own: what's on screen is drawn `pad` px further right than what's left
// of it, and what's right of it another `pad`, so no block ever touches or crosses it; a column the screen's
// edge cuts is drawn in two, each part on its side. Everything moves on the plain curve, not the windows'
// spring: an overshoot would carry the blocks over the frame.
//
// A click on a column focuses it (the layout scrolls it into view), the wheel goes along the strip as
// SUPER + wheel does.
Item {
    id: root
    required property ShellScreen screen

    // looked up in the live list, as WsIcons does (the object monitorFor() hands out can go away)
    readonly property HyprlandMonitor monitor: Hyprland.monitors.values.find(m => m.name === screen?.name) ?? null

    readonly property var cols: Strip.columns(monitor)
    readonly property var view: Strip.viewport(monitor)
    readonly property bool shown: cols.length >= 2 && view.w > 0

    // the strip and the screen together, left to right
    readonly property real minX: Math.min(view.x, ...cols.map(c => c.x))
    readonly property real maxX: Math.max(view.x + view.w, ...cols.map(c => c.x + c.w))
    readonly property int screenWidth: 40          // the screen's width here
    readonly property int maxWidth: 180            // a longer strip is drawn smaller to fit
    readonly property real scale: view.w > 0 ? Math.min(screenWidth / view.w, maxWidth / Math.max(1, maxX - minX)) : 0
    readonly property int mapHeight: 12
    readonly property int pad: 4                   // the room on each side of the frame

    // a layout x on the map, `off` being 0 left of the screen, `pad` on it, 2 * pad right of it
    function px(x, off) {
        return (x - minX) * scale + off;
    }

    implicitWidth: shown ? (maxX - minX) * scale + 2 * pad : 0
    implicitHeight: Theme.barHeight
    opacity: shown ? 1 : 0
    visible: opacity > 0

    Behavior on implicitWidth {
        Anim {}
    }
    Behavior on opacity {
        Anim {
            duration: Motion.fast
        }
    }

    // the wheel along the strip
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => Strip.step(event.angleDelta.y < 0)
    }

    // what's on screen: the frame, in the middle of its gaps (3 px clear of the blocks on either side)
    Rectangle {
        x: root.px(root.view.x, 1)
        width: root.view.w * root.scale + 2 * root.pad - 2
        height: root.mapHeight + 6
        anchors.verticalCenter: parent.verticalCenter
        radius: 4
        color: "transparent"
        border.width: 1
        border.color: Theme.withAlpha(Theme.fg, 0.22)

        Behavior on x {
            Anim {}
        }
        Behavior on width {
            Anim {}
        }
    }

    Repeater {
        model: ScriptModel {
            values: root.cols
            objectProp: "key"
        }

        delegate: Item {
            id: column

            required property var modelData

            // the column's parts left of the screen, on it and right of it: { side, l, r, off, onScreen }
            readonly property var parts: {
                const c = modelData, vl = root.view.x, vr = root.view.x + root.view.w;
                const L = c.x, R = c.x + c.w, out = [];
                if (L < vl)
                    out.push({ side: "left", l: L, r: Math.min(R, vl), off: 0, onScreen: false });
                if (R > vl && L < vr)
                    out.push({ side: "on", l: Math.max(L, vl), r: Math.min(R, vr), off: root.pad, onScreen: true });
                if (R > vr)
                    out.push({ side: "right", l: Math.max(L, vr), r: R, off: 2 * root.pad, onScreen: false });
                return out;
            }
            readonly property real total: modelData.windows.reduce((a, w) => a + w.h, 0)
            readonly property bool hovered: mouse.containsMouse

            anchors.fill: parent

            // kept by side and by window, so a refresh moves the blocks instead of making new ones
            Repeater {
                model: ScriptModel {
                    values: column.parts
                    objectProp: "side"
                }

                // one part: its windows, top to bottom, each as tall as its share
                delegate: Item {
                    id: part

                    required property var modelData

                    x: root.px(modelData.l, modelData.off) + 1
                    width: Math.max(1, (modelData.r - modelData.l) * root.scale - 2)
                    height: root.mapHeight
                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on x {
                        Anim {}
                    }
                    Behavior on width {
                        Anim {}
                    }

                    Column {
                        anchors.fill: parent
                        spacing: 1

                        Repeater {
                            model: ScriptModel {
                                values: column.modelData.windows
                                objectProp: "address"
                            }

                            delegate: Rectangle {
                                required property var modelData

                                width: part.width
                                height: Math.max(1, (part.height - (column.modelData.windows.length - 1)) * modelData.h / Math.max(1, column.total))
                                radius: 2
                                color: column.hovered ? Theme.fg : column.modelData.focused ? (modelData.focused ? Theme.accent : Theme.withAlpha(Theme.accent, 0.55)) : Theme.dim
                                opacity: part.modelData.onScreen ? 1 : 0.4

                                Behavior on color {
                                    CAnim {}
                                }
                            }
                        }
                    }
                }
            }

            // the whole column, both sides of the frame
            MouseArea {
                id: mouse

                readonly property var first: column.parts[0] ?? { l: 0, off: 0 }
                readonly property var last: column.parts[column.parts.length - 1] ?? { r: 0, off: 0 }

                x: root.px(first.l, first.off) - 1
                width: root.px(last.r, last.off) - x + 1
                height: root.mapHeight + 6
                anchors.verticalCenter: parent.verticalCenter
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Strip.focusColumn(column.modelData)
            }
        }
    }
}
