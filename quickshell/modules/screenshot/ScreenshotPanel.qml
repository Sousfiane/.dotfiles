import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

DropdownPanel {
    name: "screenshot"
    edge: "center"
    cardWidth: 360

    ColumnLayout {
        id: shot
        spacing: 12

        property int sel: 0

        function move(d) {
            sel = Math.max(0, Math.min(Screenshot.all.length - 1, sel + d));
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_J)
                move(1);
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
                move(-1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                Screenshot.take(Screenshot.all[sel]);
            else {
                // a mode's letter (or a monitor's number) captures directly
                const mode = Screenshot.all.find(x => x.key === event.text.toUpperCase());
                if (!mode)
                    return;
                Screenshot.take(mode);
            }
            event.accepted = true;
        }

        PanelHeader {
            icon: Icons.screenshot
            title: "Screenshot"
            subtitle: "Copied to the clipboard"
        }

        Divider {}

        // ---------- capture modes, then each monitor by name ----------
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: Screenshot.all

                delegate: Rectangle {
                    id: btn
                    required property var modelData
                    required property int index

                    readonly property bool current: shot.sel === index

                    Layout.fillWidth: true
                    implicitHeight: 40
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
                            elide: Text.ElideRight
                        }

                        KeyBadge {
                            text: btn.modelData.key
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: shot.sel = btn.index
                        onClicked: Screenshot.take(btn.modelData)
                    }
                }
            }
        }

        Hint {
            text: "j k select • Enter or letter capture • Esc close"
        }
    }

    component KeyBadge: Rectangle {
        property alias text: label.text

        implicitWidth: 22
        implicitHeight: 22
        radius: 6
        color: Theme.surface
        border.width: 1
        border.color: Theme.border

        Txt {
            id: label
            anchors.centerIn: parent
            variant: "small"
        }
    }
}
