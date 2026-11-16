import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components

DropdownPanel {
    name: "power"
    edge: "right"
    cardWidth: 300

    ColumnLayout {
        id: menu
        spacing: 12

        property int sel: 0

        function move(d) {
            sel = Math.max(0, Math.min(Power.actions.length - 1, sel + d));
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_J)
                move(1);
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
                move(-1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                Power.run(Power.actions[sel]);
            else {
                // a single letter runs the matching action directly
                const a = Power.actions.find(x => x.key === event.text.toUpperCase());
                if (!a)
                    return;
                Power.run(a);
            }
            event.accepted = true;
        }

        Txt {
            text: "Power"
            variant: "title"
        }

        Divider {}

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: Power.actions

                delegate: Rectangle {
                    id: btn
                    required property var modelData
                    required property int index

                    readonly property bool current: menu.sel === index

                    Layout.fillWidth: true
                    implicitHeight: 44
                    radius: Theme.radius
                    color: current ? Theme.surface : "transparent"
                    border.width: current ? 1 : 0
                    border.color: Theme.accent

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        spacing: 12

                        Txt {
                            Layout.preferredWidth: 26
                            horizontalAlignment: Text.AlignHCenter
                            text: btn.modelData.icon
                            color: btn.current ? Theme.accent : Theme.fg
                            font.pixelSize: Theme.fontSize + 6
                        }

                        Txt {
                            Layout.fillWidth: true
                            text: btn.modelData.label
                            font.bold: btn.current
                        }

                        // shortcut key
                        Rectangle {
                            implicitWidth: 22
                            implicitHeight: 22
                            radius: 6
                            color: Theme.surface
                            border.width: 1
                            border.color: Theme.border

                            Txt {
                                anchors.centerIn: parent
                                variant: "small"
                                text: btn.modelData.key
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: menu.sel = btn.index
                        onClicked: Power.run(btn.modelData)
                    }
                }
            }
        }

        Hint {
            text: "j k select • Enter run • letter shortcut • Esc close"
        }
    }
}
