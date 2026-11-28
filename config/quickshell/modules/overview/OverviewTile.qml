import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import qs.config
import qs.services
import qs.components.ui

// A window in Mission Control (OverviewWindow.qml): its live preview where the layout has it, scaled, the
// app's icon on its bottom edge, its title under the pointer or the keyboard. A click goes to it, a drag
// moves it to another workspace, a middle-click closes it.
Item {
    id: tile

    // the window: one of OverviewWindow's rows[].windows ({ toplevel, address, title, x, y, w, h, floating })
    required property var modelData
    required property var overview       // the OverviewWindow: its scale, view, selection and drag
    required property var strip          // the row it's in: where its strip starts (mapX)

    readonly property bool onScreen: modelData.x + modelData.w > overview.view.x + 1 && modelData.x < overview.view.x + overview.view.w - 1
    readonly property bool lit: mouse.containsMouse || overview.selected === modelData.address
    readonly property bool lifted: overview.dragged?.address === modelData.address

    x: strip.mapX(modelData.x)
    y: (modelData.y - overview.view.y) * overview.scale
    width: modelData.w * overview.scale
    height: modelData.h * overview.scale
    z: modelData.floating ? 2 : 1
    opacity: lifted ? 0.3 : onScreen ? 1 : 0.55

    Behavior on x {
        Anim {}
    }
    Behavior on opacity {
        Anim {
            duration: Motion.fast
        }
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: 8
        color: Theme.surface

        ScreencopyView {
            anchors.fill: parent
            captureSource: overview.visible ? (tile.modelData.toplevel?.wayland ?? null) : null
            live: Overview.open
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: "transparent"
        border.width: tile.lit ? 2 : 1
        border.color: tile.lit ? Theme.accent : Theme.withAlpha(Theme.fg, 0.12)
    }

    // the app, at the bottom edge as macOS does
    AppIcon {
        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.bottom
        }
        implicitSize: 32
        source: Icons.source(Apps.entryForWindow(tile.modelData.toplevel)?.icon ?? Windows.appClass(tile.modelData.toplevel).toLowerCase(), "application-x-executable")
    }

    // its title, under the pointer or the keyboard
    Rectangle {
        visible: tile.lit && tile.modelData.title !== ""
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 22
        }
        width: Math.min(title.implicitWidth + 16, tile.width + 40)
        height: title.implicitHeight + 8
        radius: height / 2
        color: Theme.withAlpha(Theme.base, 0.9)

        Txt {
            id: title
            anchors.centerIn: parent
            width: parent.width - 16
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            variant: "row"
            text: tile.modelData.title
        }
    }

    MouseArea {
        id: mouse

        property real pressX: 0
        property real pressY: 0
        property bool moved: false

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: overview.dragged ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        preventStealing: true

        onPressed: m => {
            pressX = m.x;
            pressY = m.y;
            moved = false;
        }
        onPositionChanged: m => {
            if (!pressed || !(pressedButtons & Qt.LeftButton))
                return;
            const p = mapToItem(content, m.x, m.y);
            if (!moved && Math.hypot(m.x - pressX, m.y - pressY) > 8) {
                moved = true;
                overview.grabX = pressX;
                overview.grabY = pressY;
                overview.dragged = tile.modelData;
            }
            if (moved) {
                overview.dragX = p.x;
                overview.dragY = p.y;
            }
        }
        onReleased: m => {
            if (moved)
                overview.drop();
            else if (m.button === Qt.MiddleButton)
                Windows.close(tile.modelData.toplevel);
            else
                overview.goToWindow(tile.modelData.address);
            moved = false;
        }
    }
}
