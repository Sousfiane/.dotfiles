import QtQuick
import qs.config

Item {
    id: root

    property string icon: ""
    property string label: ""             // optional text after the icon (a count, the clock...)

    // state, the same rule for every bar item: alert > open > off > normal.
    // Events (unread, updates, a connected device) show through the glyph or the label, not the color.
    property bool alert: false            // something is wrong (a check failed, no internet)
    property bool open: false             // its panel is showing
    property bool off: false              // what it controls is disabled (muted, powered off, offline, DND)

    readonly property color stateColor: alert ? Theme.urgent : open ? Theme.accent : off ? Theme.dim : Theme.fg
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
        anchors.fill: parent
        anchors.margins: -4
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
