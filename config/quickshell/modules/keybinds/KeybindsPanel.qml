import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// Keybinds: the Hyprland shortcuts, under the section headers of bindings.lua, filtered as you type (by what
// they do or by their keys: "shift", "tab"). Read from Hyprland each time it opens, so it shows what's
// really bound. Opened from the hub (?).
DropdownPanel {
    id: panel

    name: "keybinds"
    edge: "center"
    cardWidth: 640
    cardHeight: 620
    autoFocus: false            // the search box takes the focus itself

    onOpenChanged: if (open)
        Keybinds.refresh()

    property string filter: ""
    readonly property var shown: {
        const words = filter.trim().toLowerCase().split(/\s+/).filter(w => w !== "");
        if (words.length === 0)
            return Keybinds.binds;
        // every word must be in the description, the section or the keys
        return Keybinds.binds.filter(b => {
            const hay = (b.description + " " + b.section + " " + b.keys.map(k => k.join(" ")).join(" ")).toLowerCase();
            return words.every(w => hay.includes(w));
        });
    }

    ColumnLayout {
        spacing: 8

        PanelHeader {
            icon: Icons.keyboard
            title: "Keybinds"
            subtitle: Keybinds.error !== "" ? Keybinds.error : Keybinds.loading && Keybinds.binds.length === 0 ? "reading…" : Fmt.plural(Keybinds.binds.length, "shortcut")
            subtitleColor: Keybinds.error !== "" ? Theme.urgent : Theme.dim
        }

        SearchBox {
            placeholder: "What it does, or its keys..."

            onTextChanged: {
                panel.filter = text;
                list.positionViewAtBeginning();
            }
            // nothing to run: the arrows scroll
            onMoved: direction => {
                if (direction === "down")
                    list.flick(0, -800);
                else if (direction === "up")
                    list.flick(0, 800);
            }
        }

        EmptyState {
            visible: list.count === 0 && !Keybinds.loading
            text: "No shortcut matches"
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: ScriptModel {
                values: panel.shown
            }

            readonly property real rowWidth: width - (vbar.size < 1 ? vbar.width + 6 : 0)

            ScrollBar.vertical: ScrollBar {
                id: vbar
                policy: ScrollBar.AsNeeded
            }

            // each row, with its section's name above it when it's the first of the section
            delegate: Column {
                id: entry

                required property var modelData
                required property int index

                readonly property bool firstOfSection: index === 0 || panel.shown[index - 1]?.section !== modelData.section

                width: ListView.view.rowWidth

                Txt {
                    visible: entry.firstOfSection
                    width: parent.width
                    topPadding: entry.index === 0 ? 2 : 12
                    bottomPadding: 4
                    leftPadding: 10
                    variant: "small"
                    font.bold: true
                    color: Theme.accent
                    text: entry.modelData.section.toUpperCase()
                }

                ListRow {
                    id: row

                    readonly property var modelData: entry.modelData

                    width: parent.width
                    implicitHeight: 32

                    Txt {
                        Layout.fillWidth: true
                        variant: "row"
                        text: row.modelData.description
                        elide: Text.ElideRight
                    }

                    // each key combination: its keys side by side in small frames; several combos joined by "or"
                    Repeater {
                        model: row.modelData.keys

                        delegate: RowLayout {
                            id: combo

                            required property var modelData
                            required property int index

                            spacing: 4

                            Txt {
                                visible: combo.index > 0
                                Layout.leftMargin: 4
                                Layout.rightMargin: 4
                                variant: "small"
                                text: "or"
                            }

                            Repeater {
                                model: combo.modelData

                                delegate: Rectangle {
                                    required property string modelData

                                    implicitWidth: Math.max(22, keyText.implicitWidth + 12)
                                    implicitHeight: 20
                                    radius: Theme.radiusSmall
                                    color: Theme.surface
                                    border.width: 1
                                    border.color: Theme.border

                                    Txt {
                                        id: keyText
                                        anchors.centerIn: parent
                                        variant: "small"
                                        color: Theme.fg
                                        text: parent.modelData
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Hint {
            text: "Type to filter • ↑ ↓ scroll • Esc close"
        }
    }
}
