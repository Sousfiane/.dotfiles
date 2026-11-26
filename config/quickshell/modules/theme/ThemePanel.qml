import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The theme picker: the palettes in ~/.config/theme/palettes, each with a strip of its colours. Picking one
// switches the whole desktop live; the panel stays open, so you can watch it change and try the next.
DropdownPanel {
    id: panel

    name: "theme"
    edge: "center"
    cardWidth: 420

    onOpenChanged: {
        if (open)
            Themes.refresh();
    }

    ColumnLayout {
        id: menu
        spacing: 12

        Selection {
            id: nav
            count: Themes.palettes.length
        }

        // the selection sits on the current palette when the list (re)loads, and follows a switch made
        // elsewhere (the `theme` command)
        function selectCurrent() {
            nav.select(Themes.palettes.findIndex(p => p.id === Themes.current));
        }
        Connections {
            target: Themes
            function onPalettesChanged() {
                menu.selectCurrent();
            }
            function onCurrentChanged() {
                menu.selectCurrent();
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Down || event.key === Qt.Key_J)
                nav.move(1);
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
                nav.move(-1);
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                Themes.set(Themes.palettes[nav.index]?.id ?? "");
            else {
                // a number picks that palette directly
                const i = parseInt(event.text) - 1;
                if (!(i >= 0 && i < Themes.palettes.length))
                    return;
                nav.select(i);
                Themes.set(Themes.palettes[i].id);
            }
            event.accepted = true;
        }

        PanelHeader {
            icon: Icons.palette
            title: "Theme"
            subtitle: Theme.palette?.name ?? ""
        }

        Divider {}

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: Themes.palettes

                delegate: SelectableCard {
                    id: row

                    required property var modelData
                    required property int index

                    readonly property bool current: modelData.id === Themes.current

                    Layout.fillWidth: true
                    implicitHeight: 56
                    selected: nav.index === index

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 12
                            rightMargin: 12
                        }
                        spacing: 12

                        // the current one
                        Txt {
                            Layout.preferredWidth: 18
                            horizontalAlignment: Text.AlignHCenter
                            text: row.current ? Icons.check : ""
                            color: Theme.accent
                            font.pixelSize: Theme.fontSize + 4
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Txt {
                                text: row.modelData.name
                                font.bold: row.selected || row.current
                                elide: Text.ElideRight
                            }

                            // the palette at a glance: its background, then its accents
                            Row {
                                spacing: 4

                                Repeater {
                                    model: ["base", "overlay", "text", "love", "gold", "rose", "pine", "foam", "iris"]

                                    delegate: Rectangle {
                                        required property string modelData

                                        width: 16
                                        height: 10
                                        radius: Theme.radiusSmall
                                        color: row.modelData.colors[modelData] ?? "transparent"
                                        border.width: 1
                                        border.color: Theme.withAlpha(Theme.line, 0.6)
                                    }
                                }
                            }
                        }

                        Txt {
                            text: row.modelData.dark ? "dark" : "light"
                            color: Theme.dim
                            variant: "small"
                        }

                        KeyBadge {
                            text: row.index < 9 ? String(row.index + 1) : ""
                            visible: row.index < 9
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: nav.select(row.index)
                        onClicked: Themes.set(row.modelData.id)
                    }
                }
            }
        }

        Hint {
            text: "j k select • Enter or number apply • Esc close"
        }
    }
}
