import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

DropdownPanel {
    name: "power"
    edge: "right"
    cardWidth: 300

    ColumnLayout {
        id: menu
        spacing: 12

        Selection {
            id: nav
            count: Power.actions.length
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_J)
                nav.move(1);
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
                nav.move(-1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                Power.run(Power.actions[nav.index]);
            else {
                // a single letter runs the matching action directly
                const a = Power.actions.find(x => x.key === event.text.toUpperCase());
                if (!a)
                    return;
                Power.run(a);
            }
            event.accepted = true;
        }

        PanelHeader {
            icon: Icons.power
            title: "Power"
        }

        Divider {}

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: Power.actions

                delegate: MenuRow {
                    required property var modelData
                    required property int index

                    icon: modelData.icon
                    label: modelData.label
                    key: modelData.key
                    selected: nav.index === index
                    onEntered: nav.select(index)
                    onClicked: Power.run(modelData)
                }
            }
        }

        Hint {
            text: "j k select • Enter run • letter shortcut • Esc close"
        }
    }
}
