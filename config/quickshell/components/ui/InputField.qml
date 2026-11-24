import QtQuick
import QtQuick.Layouts
import qs.config

// One-line text field: a rounded box with a placeholder, Enter accepts and Esc cancels.
// A FocusScope, so forceActiveFocus() and activeFocus work on the field as a whole.
FocusScope {
    id: root

    property alias text: input.text
    property string placeholder: ""
    property bool password: false
    property alias color: box.color
    property alias borderWidth: box.border.width

    signal accepted
    signal cancelled

    Layout.fillWidth: true
    implicitHeight: 30

    Rectangle {
        id: box
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.surface
        border.width: 1
        border.color: Theme.border
    }

    TextInput {
        id: input
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        focus: true
        verticalAlignment: TextInput.AlignVCenter
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        color: Theme.fg
        font.family: Theme.font
        font.pixelSize: Theme.fontSize - 1
        clip: true
        selectByMouse: true

        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
        Keys.onEscapePressed: event => {
            root.cancelled();
            event.accepted = true;
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
