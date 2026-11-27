import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// A tray app's menu, drawn like the other dropdowns instead of as a toolkit popup.
// Submenus open in place, with a way back.
DropdownPanel {
    name: "tray"
    edge: "right"
    cardWidth: 300

    ColumnLayout {
        id: menu
        spacing: 10

        // the submenus walked into: [{ handle, title }]; empty = the app's own menu
        property var stack: []
        readonly property var handle: stack.length > 0 ? stack[stack.length - 1].handle : Tray.menuItem?.menu ?? null

        // another icon's menu replaces this one
        Connections {
            target: Tray
            function onMenuItemChanged() {
                menu.stack = [];
                nav.select(0);
            }
        }

        QsMenuOpener {
            id: opener
            menu: menu.handle
        }

        readonly property var entries: opener.children?.values ?? []
        // what the keyboard steps through: no separators, nothing greyed out
        readonly property var pickable: entries.filter(e => !e.isSeparator && e.enabled)

        Selection {
            id: nav
            count: menu.pickable.length
        }

        function run(entry) {
            if (!entry?.enabled)
                return;
            if (entry.hasChildren) {
                stack = stack.concat([
                    {
                        handle: entry,
                        title: Tray.label(entry.text)
                    }
                ]);
                nav.select(0);
                return;
            }
            entry.triggered();
            Panels.hide("tray");
        }

        function back() {
            if (stack.length === 0)
                return false;
            stack = stack.slice(0, -1);
            nav.select(0);
            return true;
        }

        Keys.onPressed: event => {
            if (nav.navigate(event))
                return;
            switch (event.key) {
            case Qt.Key_Return:
            case Qt.Key_Enter:
            case Qt.Key_Space:
            case Qt.Key_L:
            case Qt.Key_Right:
                run(pickable[nav.index]);
                break;
            case Qt.Key_H:
            case Qt.Key_Left:
            case Qt.Key_Backspace:
                if (!back())
                    return;
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        // ---------- header: the app, and where we are in its menu ----------

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            AppIcon {
                implicitSize: 22
                source: Tray.menuItem?.icon ?? ""
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Txt {
                    Layout.fillWidth: true
                    variant: "title"
                    text: Tray.name(Tray.menuItem)
                    elide: Text.ElideRight
                }

                Txt {
                    Layout.fillWidth: true
                    visible: menu.stack.length > 0
                    variant: "small"
                    color: Theme.dim
                    text: menu.stack.map(s => s.title).join("  ›  ")
                    elide: Text.ElideLeft
                }
            }

            IconButton {
                visible: menu.stack.length > 0
                flat: true
                icon: Icons.chevronLeft
                color: Theme.dim
                onClicked: menu.back()
            }
        }

        Divider {}

        // ---------- the entries ----------

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: menu.entries

                delegate: Loader {
                    id: slot
                    required property var modelData
                    readonly property int pick: menu.pickable.indexOf(modelData)

                    Layout.fillWidth: true
                    sourceComponent: modelData.isSeparator ? separator : row

                    // quieter than Divider: it only groups entries
                    Component {
                        id: separator
                        Item {
                            implicitHeight: 9
                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width - 20
                                height: 1
                                color: Theme.line
                            }
                        }
                    }

                    Component {
                        id: row

                        SelectableCard {
                            id: card
                            readonly property var entry: slot.modelData
                            readonly property bool checkable: entry.buttonType !== QsMenuButtonType.None
                            readonly property bool checked: entry.checkState === Qt.Checked

                            implicitHeight: 34
                            selected: slot.pick >= 0 && slot.pick === nav.index
                            opacity: entry.enabled ? 1 : 0.45

                            RowLayout {
                                anchors {
                                    fill: parent
                                    leftMargin: 10
                                    rightMargin: 10
                                }
                                spacing: 10

                                // a check box / radio button, or the entry's own icon
                                Txt {
                                    visible: card.checkable
                                    Layout.preferredWidth: 16
                                    horizontalAlignment: Text.AlignHCenter
                                    text: card.entry.buttonType === QsMenuButtonType.RadioButton ? (card.checked ? Icons.radioOn : Icons.radioOff) : (card.checked ? Icons.checkboxOn : Icons.checkboxOff)
                                    color: card.checked ? Theme.accent : Theme.dim
                                }

                                AppIcon {
                                    visible: !card.checkable && card.entry.icon !== ""
                                    implicitSize: 16
                                    source: card.entry.icon
                                }

                                Txt {
                                    Layout.fillWidth: true
                                    text: Tray.label(card.entry.text)
                                    font.bold: card.selected
                                    elide: Text.ElideRight
                                }

                                Txt {
                                    visible: card.entry.hasChildren
                                    text: Icons.chevronRight
                                    color: Theme.dim
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: card.entry.enabled
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: if (slot.pick >= 0)
                                    nav.select(slot.pick)
                                onClicked: menu.run(card.entry)
                            }
                        }
                    }
                }
            }
        }

        EmptyState {
            visible: menu.entries.length === 0
            text: "Empty menu"
        }

        Hint {
            text: menu.stack.length > 0 ? "j k select • Enter open • h back • Esc close" : "j k select • Enter open • Esc close"
        }
    }
}
