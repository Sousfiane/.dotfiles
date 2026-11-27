import QtQuick
import qs.config
import qs.services
import qs.components.ui

// One dock icon (or the separator between pins and running apps): magnified near the pointer, a dot
// under it while the app runs, its name above it on hover, a bounce while it starts. A pin dragged a
// few px becomes a drag that reorders it (AppDock holds the drag state).
Item {
    id: cell

    required property var dock         // the AppDock window: sizes, the resting layout, drag and menu state
    required property var modelData
    required property int index

    readonly property bool isSep: modelData.separator === true
    readonly property real scale_: isSep ? 1 : dock.scaleAt(index)
    readonly property var windows: isSep ? [] : (Dock.windowsByApp[modelData.key] ?? [])
    readonly property bool running: windows.length > 0
    readonly property bool focused: !isSep && Dock.activeKey === modelData.key
    readonly property bool urgent: windows.some(w => w.urgent)
    readonly property bool last: index === dock.items.length - 1
    readonly property bool beforeSep: dock.items[index + 1]?.separator === true

    width: isSep ? dock.sepWidth : dock.iconSize * scale_ + (last || beforeSep ? 0 : dock.spacing)
    height: dock.iconSize * (isSep ? 1 : scale_)

    // dragged: follows the pointer. Its neighbours slide over to make room
    readonly property bool dragged: !isSep && dock.dragKey === modelData.key
    property real shift: dragged ? dock.dragX - dock.restCenters[index] : dock.shiftAt(index)
    Behavior on shift {
        enabled: !cell.dragged && !dock.dropping
        Anim {}
    }
    transform: Translate {
        x: cell.shift
    }
    z: dragged ? 1 : 0

    // ---- separator ----
    Rectangle {
        visible: cell.isSep
        anchors.centerIn: parent
        width: 1
        height: dock.iconSize * 0.6
        color: Theme.line
    }

    // ---- icon ----
    Item {
        id: tile
        visible: !cell.isSep
        width: dock.iconSize * cell.scale_
        height: width
        anchors.bottom: parent.bottom

        property real hop: 0       // the launch bounce

        AppIcon {
            anchors.fill: parent
            anchors.bottomMargin: -tile.hop
            anchors.topMargin: tile.hop
            implicitSize: dock.iconSize
            source: cell.isSep ? "" : Icons.source(cell.modelData.icon, "application-x-executable")
            opacity: area.pressed ? 0.7 : 1
        }

        SequentialAnimation {
            id: bounce
            loops: 2
            Anim {
                target: tile
                property: "hop"
                to: -16
                duration: 220
                curve: Motion.enter
            }
            Anim {
                target: tile
                property: "hop"
                to: 0
                duration: 260
                curve: [0.5, 0, 0.75, 0, 1, 1]
            }
        }
        // stops once the window shows up
        Connections {
            target: cell
            function onRunningChanged() {
                if (cell.running && bounce.running) {
                    bounce.stop();
                    tile.hop = 0;
                }
            }
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            preventStealing: true

            // a pin pressed and moved a few px becomes a drag (and is no click)
            property real pressX: 0
            property bool wasDrag: false

            function windowX(mouse) {
                return mapToItem(null, mouse.x, mouse.y).x;
            }

            onPressed: mouse => {
                pressX = windowX(mouse);
                wasDrag = false;
            }
            onPositionChanged: mouse => {
                if (!(pressed && pressedButtons & Qt.LeftButton) || !cell.modelData.pinned)
                    return;
                const x = windowX(mouse);
                if (dock.dragKey === "" && Math.abs(x - pressX) > 6) {
                    dock.menuItem = null;
                    dock.dragX = x;
                    dock.dragFrom = cell.index;
                    dock.dragKey = cell.modelData.key;
                    wasDrag = true;
                }
                if (dock.dragKey === cell.modelData.key)
                    dock.dragX = x;
            }
            onReleased: if (dock.dragKey === cell.modelData.key)
                dock.drop()
            onCanceled: if (dock.dragKey === cell.modelData.key) {
                dock.dragKey = "";
                dock.dragFrom = -1;
            }

            onClicked: mouse => {
                if (wasDrag)
                    return;
                if (mouse.button === Qt.RightButton) {
                    const open = dock.menuItem?.key === cell.modelData.key;
                    dock.menuCenter = dock.restCenters[cell.index];
                    dock.menuItem = open ? null : cell.modelData;
                    return;
                }
                dock.menuItem = null;
                if (mouse.button === Qt.MiddleButton || !cell.running) {
                    if (cell.modelData.entry) {
                        bounce.restart();
                        Dock.launch(cell.modelData);
                    }
                } else {
                    Dock.activate(cell.modelData);
                }
            }
        }
    }

    // ---- running indicator: a dot, a short pill on the focused app ----
    Rectangle {
        visible: !cell.isSep
        anchors.horizontalCenter: tile.horizontalCenter
        y: cell.height + dock.pad + (dock.dotRow - height) / 2 + 1
        height: 4
        width: cell.focused ? 12 : 4
        radius: 2
        opacity: cell.running ? 1 : 0
        color: cell.urgent ? Theme.urgent : cell.focused ? Theme.accent : Theme.dim

        Behavior on width {
            Anim {}
        }
        Behavior on opacity {
            Anim {
                duration: Motion.fast
            }
        }
        Behavior on color {
            CAnim {}
        }
    }

    // ---- name, above the icon ----
    Rectangle {
        visible: opacity > 0
        opacity: area.containsMouse && dock.menuItem === null && dock.dragKey === "" ? 1 : 0
        anchors.horizontalCenter: tile.horizontalCenter
        y: tile.y - height - 10
        width: label.implicitWidth + 16
        height: label.implicitHeight + 8
        radius: Theme.radius
        color: Theme.bg
        border.width: 1
        border.color: Theme.line

        Behavior on opacity {
            Anim {
                duration: Motion.fast
            }
        }

        Txt {
            id: label
            anchors.centerIn: parent
            // a window title can be long
            width: Math.min(implicitWidth, 320)
            elide: Text.ElideRight
            variant: "row"
            text: Dock.nameFor(cell.modelData)
        }
    }
}
