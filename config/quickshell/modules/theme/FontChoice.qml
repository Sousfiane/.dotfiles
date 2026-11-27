import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// One installed font in the theme picker's font list, drawn in itself: a check on the one in use, and
// "default" on theme.json's. A click applies it.
SelectableCard {
    id: choice

    required property string modelData      // the family
    required property int index
    required property string role           // the font being picked: "ui", "mono" or "app"

    readonly property bool current: modelData === Theme.fonts[role]
    readonly property bool isDefault: modelData === (Theme.settings.font[role] ?? Theme.settings.font.ui)

    signal pointed                          // the mouse is over it: the keyboard selection follows

    implicitHeight: 36

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 12
            rightMargin: 12
        }
        spacing: 12

        Txt {
            Layout.preferredWidth: 18
            horizontalAlignment: Text.AlignHCenter
            text: choice.current ? Icons.check : ""
            color: Theme.accent
        }

        Txt {
            Layout.fillWidth: true
            text: choice.modelData
            font.family: choice.modelData
            font.bold: choice.selected || choice.current
            elide: Text.ElideRight
        }

        // theme.json's, which a new machine starts with
        Txt {
            visible: choice.isDefault
            text: "default"
            variant: "small"
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: choice.pointed()
        onClicked: Themes.setFont(choice.role, choice.modelData)
    }
}
