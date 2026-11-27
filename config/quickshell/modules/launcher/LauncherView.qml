import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The app launcher (SUPER + Space): search the installed apps and their actions, Enter starts one.
// = calculates, : finds an emoji, > runs a command, ? searches the web, / opens a file (the modes are
// Launcher's).
// Shown in its own panel and as the hub's tab (the app launcher).
ColumnLayout {
    id: view
    spacing: 8

    SearchBox {
        placeholder: "Apps..."

        onTextChanged: {
            Launcher.query = text;
            list.currentIndex = 0;
            list.positionViewAtBeginning();
        }

        onMoved: direction => {
            if (direction === "down")
                list.incrementCurrentIndex();
            else if (direction === "up")
                list.decrementCurrentIndex();
        }
        onAccepted: Launcher.launch(Launcher.results[list.currentIndex])
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        // diffed, so typing only adds and removes the rows that changed (icons aren't reloaded)
        model: ScriptModel {
            values: Launcher.results
        }
        currentIndex: 0

        // rows leave a gutter for the scrollbar while it shows (same as ScrollList)
        readonly property real rowWidth: width - (vbar.size < 1 ? vbar.width + 6 : 0)

        ScrollBar.vertical: ScrollBar {
            id: vbar
            policy: ScrollBar.AsNeeded
        }

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index

            width: ListView.view.rowWidth
            height: 36
            radius: Theme.radius
            color: ListView.isCurrentItem ? Theme.surface : Theme.surfaceClear

            MotionArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onMoved: list.currentIndex = row.index
                // right click pins an app to the dock (or unpins it), or opens a file's folder
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton)
                        Launcher.launch(row.modelData);
                    else if (row.modelData.entry)
                        Dock.togglePin(row.modelData.entry.id);
                    else if (row.modelData.alt)
                        Launcher.launchAlt(row.modelData);
                }
            }

            Behavior on color {
                CAnim {}
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 10
                spacing: 10

                AppIcon {
                    visible: !row.modelData.glyph
                    implicitSize: 24
                    source: row.modelData.glyph ? "" : Quickshell.iconPath(row.modelData.icon, "application-x-executable")
                }

                // a mode's row: its glyph, or the emoji itself
                Txt {
                    visible: !!row.modelData.glyph
                    Layout.preferredWidth: 24
                    horizontalAlignment: Text.AlignHCenter
                    text: row.modelData.glyph ?? ""
                    color: row.modelData.run ? Theme.accent : Theme.dim
                    font.pixelSize: row.modelData.emoji ? Theme.fontSize + 6 : Theme.fontSize + 4
                }

                Txt {
                    Layout.fillWidth: true
                    text: row.modelData.name
                    elide: Text.ElideRight
                }

                // pinned to the dock
                Txt {
                    visible: !!row.modelData.entry && !row.modelData.action && Dock.isPinned(row.modelData.entry.id)
                    variant: "dim"
                    text: Icons.glyph(0xF0403)
                }

                // for an action, the app it belongs to
                Txt {
                    Layout.maximumWidth: list.width * 0.4
                    visible: text !== ""
                    variant: "dim"
                    text: row.modelData.detail ?? ""
                    elide: Text.ElideRight
                }
            }
        }
    }

    Hint {
        text: Launcher.hint
    }
}
