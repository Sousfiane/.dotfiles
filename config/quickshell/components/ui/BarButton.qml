import Quickshell
import QtQuick
import qs.config
import qs.services

Item {
    id: root

    property string icon: ""
    property string label: ""             // optional text after the icon (a count, the clock...)

    property int iconSize: Theme.fontSize + 3                            // a button can shrink a heavy glyph

    // every glyph this button can show (volume levels, wifi strengths...). The icon slot is as wide as
    // the widest one's ink, so the visible gap between neighbours is just the bar spacing, and a
    // changing glyph never shifts the bar
    property var glyphs: [icon]
    property string inkAlign: "center"   // "left" keeps a glyph's base still when its variants grow on one side
    property real iconRotation: 0         // degrees; turns smoothly, around the middle of the glyph's ink
    readonly property int iconSlot: {
        let w = 0;
        for (const g of glyphs)
            w = Math.max(w, Math.ceil(glyphMetrics.tightBoundingRect(g).width));
        return w;
    }

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

    // the item at an end of the bar: its click area reaches the screen edge
    property string edge: ""              // "" | "left" | "right"
    property real edgeGap: 0              // its distance from that screen edge

    // padding on each side; neighbours are 18 px apart, so 9 + 9 makes their areas just meet
    readonly property real padLeft: edge === "left" ? edgeGap : 9
    readonly property real padRight: edge === "right" ? edgeGap : 9

    FontMetrics {
        id: glyphMetrics
        font: iconText.font
    }

    Row {
        id: row
        spacing: 6

        // the icon sits in a slot sized to its ink, not its advance: Nerd Font glyphs all advance the
        // same width but their drawing can be half or twice as wide
        Item {
            visible: root.icon !== ""
            width: root.iconSlot
            height: iconText.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

            TextMetrics {
                id: ink
                font: iconText.font
                text: root.icon
            }

            Txt {
                id: iconText
                text: root.icon
                color: root.iconColor
                Behavior on color {
                    CAnim {}
                }
                font.pixelSize: root.iconSize
                x: Math.round((root.inkAlign === "left" ? 0 : (root.iconSlot - ink.tightBoundingRect.width) / 2) - ink.tightBoundingRect.x)

                // around the ink's centre, not the text box's (whose line height would make the glyph drift)
                transform: Rotation {
                    origin.x: ink.tightBoundingRect.x + ink.tightBoundingRect.width / 2
                    origin.y: iconText.baselineOffset + ink.tightBoundingRect.y + ink.tightBoundingRect.height / 2
                    angle: root.iconRotation
                    Behavior on angle {
                        Anim {}
                    }
                }
            }
        }

        Txt {
            visible: root.label !== ""
            text: root.label
            color: root.labelColor
            Behavior on color {
                CAnim {}
            }
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        // as wide as the padded row and as tall as the bar, so the top edge of the screen is clickable too
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
