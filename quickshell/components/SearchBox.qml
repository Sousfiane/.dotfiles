import QtQuick
import QtQuick.Layouts
import qs.config

Rectangle {
    id: root

    property string placeholder: ""
    property alias text: input.text
    property bool horizontalNav: false      // forward Left/Right (a grid) instead of moving the text cursor

    signal moved(string direction)          // "up" | "down" | "left" | "right"
    signal accepted

    Layout.fillWidth: true
    Layout.preferredHeight: 40
    radius: Theme.radius
    color: Theme.surface

    TextInput {
        id: input

        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }
        verticalAlignment: TextInput.AlignVCenter

        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 2
        clip: true
        selectByMouse: true

        focus: true
        Component.onCompleted: forceActiveFocus()

        Keys.onUpPressed: root.moved("up")
        Keys.onDownPressed: root.moved("down")
        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()

        Keys.onLeftPressed: event => {
            event.accepted = root.horizontalNav;
            if (root.horizontalNav)
                root.moved("left");
        }
        Keys.onRightPressed: event => {
            event.accepted = root.horizontalNav;
            if (root.horizontalNav)
                root.moved("right");
        }

        Txt {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: input.text.length === 0
            enabled: false
            variant: "dim"
            text: root.placeholder
        }
    }
}
