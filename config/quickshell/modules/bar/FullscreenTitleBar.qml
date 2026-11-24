import QtQuick
import qs.config
import qs.services

// Stand-in for the hyprbars title bar while a window is fullscreen (hyprbars draws none then).
// It slides down under the bar on a top-edge hover, like macOS brings back the window's title bar
// with the menu bar. Looks like config/hypr/config/plugins.lua: keep the two in sync.
Rectangle {
    id: root

    property string screenName: ""
    readonly property var target: Fullscreen.window(screenName)

    // hyprbars: bar_height, bar_color, col.text, bar_text_font/size, button size/padding, bar_padding
    readonly property int barHeight: 24
    readonly property int dotSize: 10
    readonly property int dotGap: 6
    readonly property int edgePad: 8

    height: barHeight
    color: Theme.withAlpha(Theme.base, 0.8)

    Text {
        anchors.centerIn: parent
        width: parent.width - 2 * (root.edgePad + 3 * root.dotSize + 2 * root.dotGap) - 16
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.target?.title ?? ""
        color: Theme.text
        font.family: "JetBrainsMonoNL NF"
        font.pixelSize: 10             // hyprbars bar_text_size is in pixels
        font.weight: Font.DemiBold     // bar_text_weight = "semibold"
    }

    // double-click anywhere on the bar leaves fullscreen, like hyprbars' on_double_click enters it
    MouseArea {
        anchors.fill: parent
        onDoubleClicked: Fullscreen.exit(root.screenName)
    }

    // rightmost first, same order as the hyprbars buttons
    Row {
        anchors {
            right: parent.right
            rightMargin: root.edgePad
            verticalCenter: parent.verticalCenter
        }
        layoutDirection: Qt.RightToLeft
        spacing: root.dotGap

        Repeater {
            model: [
                { color: Theme.love, run: () => Fullscreen.close(root.screenName) },
                { color: Theme.gold, run: () => Fullscreen.exit(root.screenName) },
                { color: Theme.foam, run: () => Fullscreen.float(root.screenName) },
            ]

            delegate: Rectangle {
                required property var modelData
                width: root.dotSize
                height: root.dotSize
                radius: width / 2
                color: modelData.color

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -3          // a little easier to hit than the 10 px dot
                    cursorShape: Qt.PointingHandCursor
                    onClicked: parent.modelData.run()
                }
            }
        }
    }
}
