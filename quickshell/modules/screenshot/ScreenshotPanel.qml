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

        Selection {
            id: nav
            count: Screenshot.all.length
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_J)
                nav.move(1);
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
                nav.move(-1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                Screenshot.take(Screenshot.all[nav.index]);
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

                delegate: MenuRow {
                    required property var modelData
                    required property int index

                    implicitHeight: 40
                    icon: modelData.icon
                    label: modelData.label
                    key: modelData.key
                    current: nav.index === index
                    onEntered: nav.select(index)
                    onClicked: Screenshot.take(modelData)
                }
            }
        }

        Hint {
            text: "j k select • Enter or letter capture • Esc close"
        }
    }
}
