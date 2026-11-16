import Quickshell
import QtQuick
import qs.config
import qs.services

Item {
    id: root

    property string icon: ""
    property string label: ""             // optional text after the icon (a count, the clock...)

    // state, the same rule for every bar item: alert > open > off > normal.
    // Events (unread, updates, a connected device) show through the glyph or the label, not the color.
    property bool alert: false            // something is wrong (a check failed, no internet)
    property bool open: false             // its panel is showing
    property bool off: false              // what it controls is disabled (muted, powered off, offline, DND)

    // only the bar on the monitor showing the panel lights up
    readonly property string screenName: root.QsWindow.window?.screen?.name ?? ""
    readonly property bool openHere: open && (Panels.activeScreen === "" || Panels.activeScreen === screenName)

    readonly property color stateColor: alert ? Theme.urgent : openHere ? Theme.accent : off ? Theme.dim : Theme.fg
    property color iconColor: stateColor
    property color labelColor: stateColor
    readonly property bool hovered: mouse.containsMouse

    // extra children (a tooltip PopupWindow, a SystemClock...) go here
    default property alias extras: extraHolder.data

    signal clicked
    signal rightClicked
    signal scrolled(real delta)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    // the item at an end of the bar: its backdrop and click area reach the screen edge, square on that side
    property string edge: ""              // "" | "left" | "right"
    property real edgeGap: 0              // its distance from that screen edge

    // padding on each side; neighbours are 12 px apart, so 6 + 6 makes their areas just meet
    readonly property real padLeft: edge === "left" ? edgeGap : 6
    readonly property real padRight: edge === "right" ? edgeGap : 6

    HoverBackdrop {
        x: row.x - root.padLeft
        width: row.width + root.padLeft + root.padRight
        anchors.verticalCenter: row.verticalCenter
        hovered: mouse.containsMouse
        pressed: mouse.pressed
        squareLeft: root.edge === "left"
        squareRight: root.edge === "right"
    }

    Row {
        id: row
        spacing: 6

        Txt {
            visible: root.icon !== ""
            text: root.icon
            color: root.iconColor
            font.pixelSize: Theme.fontSize + 3
            anchors.verticalCenter: parent.verticalCenter
        }

        Txt {
            visible: root.label !== ""
            text: root.label
            color: root.labelColor
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        // as wide as the backdrop and as tall as the bar, so the top edge of the screen is clickable too
        x: -root.padLeft
        width: root.width + root.padLeft + root.padRight
        height: Theme.barHeight
        anchors.verticalCenter: parent.verticalCenter
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.RightButton)
                root.rightClicked();
            else
                root.clicked();
        }
        onWheel: wheel => root.scrolled(wheel.angleDelta.y)
    }

    Item {
        id: extraHolder
    }
}
