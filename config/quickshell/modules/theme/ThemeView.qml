import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The theme picker: the palettes in ~/.config/theme/palettes, each with a strip of its colours, then the fonts
// (the shell's, the terminal's and the apps'). Picking a palette switches the whole desktop live; the panel
// stays open, so you can watch it change and try the next. A font opens the list of installed ones, each
// drawn in itself, and picking one applies it the same way. Last, the dock: always shown or auto-hide.
// Shown in its own panel and as the hub's tab (the theme picker).
ColumnLayout {
    id: menu

    // the font being picked ("ui", "mono" or "app"), or "" on the main page
    property string fontRole: ""
    readonly property var fontRoleInfo: Themes.fontRoles.find(r => r.key === fontRole) ?? null
    readonly property var fontChoices: fontRole === "mono" ? Themes.monoFonts : Themes.fonts
    Component.onCompleted: Themes.refresh()

    spacing: 12

    readonly property int paletteCount: Themes.palettes.length
    // the dock row, after the fonts
    readonly property int dockIndex: paletteCount + Themes.fontRoles.length

    // the main page: the palettes, the fonts, then the dock
    Selection {
        id: nav
        count: menu.dockIndex + 1
    }
    // a font's list
    Selection {
        id: fontNav
        count: menu.fontChoices.length
        view: fontList
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

    // a font's list opens on the font in use
    function openFonts(key) {
        menu.fontRole = key;
        fontNav.select(Math.max(0, menu.fontChoices.indexOf(Theme.fonts[key])));
        Qt.callLater(() => fontList.positionViewAtIndex(fontNav.index, ListView.Center));
    }
    function closeFonts() {
        const i = Themes.fontRoles.findIndex(r => r.key === menu.fontRole);
        menu.fontRole = "";
        nav.select(menu.paletteCount + i);
    }

    // Enter on the main page: a palette applies, a font opens its list, the dock switches mode
    function activate(i) {
        if (i === menu.dockIndex)
            Dock.setAlwaysShow(!Dock.alwaysShow);
        else if (i < menu.paletteCount)
            Themes.set(Themes.palettes[i]?.id ?? "");
        else
            openFonts(Themes.fontRoles[i - menu.paletteCount].key);
    }

    Keys.onPressed: event => {
        if (menu.fontRole !== "") {
            if (fontNav.navigate(event))
                return;
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                Themes.setFont(menu.fontRole, menu.fontChoices[fontNav.index]);
            // back to the main page (Escape too: it only closes the panel from there)
            else if (event.key === Qt.Key_Escape || event.key === Qt.Key_H || event.key === Qt.Key_Left || event.key === Qt.Key_Backspace)
                menu.closeFonts();
            else
                return;
            event.accepted = true;
            return;
        }

        if (nav.navigate(event))
            return;
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || ((event.key === Qt.Key_L || event.key === Qt.Key_Right) && nav.index >= menu.paletteCount))
            menu.activate(nav.index);
        // a font's size, on its row
        else if (nav.index >= menu.paletteCount && nav.index < menu.dockIndex && (event.key === Qt.Key_Minus || event.key === Qt.Key_Plus || event.key === Qt.Key_Equal))
            Themes.changeFontSize(Themes.fontRoles[nav.index - menu.paletteCount], event.key === Qt.Key_Minus ? -1 : 1);
        else {
            // a number picks that palette directly
            const i = parseInt(event.text) - 1;
            if (!(i >= 0 && i < menu.paletteCount))
                return;
            nav.select(i);
            Themes.set(Themes.palettes[i].id);
        }
        event.accepted = true;
    }

    PanelHeader {
        icon: Icons.palette
        title: menu.fontRoleInfo ? menu.fontRoleInfo.label + " font" : "Theme"
        subtitle: menu.fontRoleInfo ? menu.fontRoleInfo.what : (Theme.palette?.name ?? "")
    }

    Divider {}

    // ---------- main page: palettes ----------
    ColumnLayout {
        visible: menu.fontRole === ""
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

    Divider {
        visible: menu.fontRole === ""
    }

    // ---------- main page: fonts ----------
    ColumnLayout {
        visible: menu.fontRole === ""
        Layout.fillWidth: true
        spacing: 4

        Repeater {
            model: Themes.fontRoles

            delegate: SelectableCard {
                id: fontRow

                required property var modelData
                required property int index

                readonly property string family: Theme.fonts[modelData.key] ?? ""

                Layout.fillWidth: true
                implicitHeight: 44
                selected: nav.index === menu.paletteCount + index
                // the card's own click (the size buttons sit above it and keep theirs)
                onSelectRequested: menu.openFonts(modelData.key)

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 12
                        rightMargin: 12
                    }
                    spacing: 12

                    Txt {
                        Layout.preferredWidth: 70
                        text: fontRow.modelData.label
                        font.bold: fontRow.selected
                    }

                    // the font in use, drawn in itself
                    Txt {
                        Layout.fillWidth: true
                        text: fontRow.family
                        font.family: fontRow.family
                        color: Theme.dim
                        elide: Text.ElideRight
                    }

                    // its size, with − and + (or the - and + keys on this row)
                    Row {
                        spacing: 2

                        IconButton {
                            icon: "−"
                            size: Theme.fontSize
                            onClicked: Themes.changeFontSize(fontRow.modelData, -1)
                        }
                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            horizontalAlignment: Text.AlignHCenter
                            variant: "row"
                            text: Themes.fontSize(fontRow.modelData) + " " + fontRow.modelData.unit
                        }
                        IconButton {
                            icon: "+"
                            size: Theme.fontSize
                            onClicked: Themes.changeFontSize(fontRow.modelData, 1)
                        }
                    }

                    Txt {
                        text: Icons.chevronRight
                        color: fontRow.selected ? Theme.accent : Theme.dim
                    }
                }

                // hover only: under the card's click and the size buttons
                MouseArea {
                    anchors.fill: parent
                    z: -1
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    cursorShape: Qt.PointingHandCursor
                    onEntered: nav.select(menu.paletteCount + fontRow.index)
                }
            }
        }
    }

    Divider {
        visible: menu.fontRole === ""
    }

    // ---------- main page: the dock ----------
    SelectableCard {
        id: dockRow

        visible: menu.fontRole === ""
        Layout.fillWidth: true
        implicitHeight: 44
        selected: nav.index === menu.dockIndex
        onSelectRequested: Dock.setAlwaysShow(!Dock.alwaysShow)

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 12
                rightMargin: 12
            }
            spacing: 12

            Txt {
                Layout.preferredWidth: 70
                text: "Dock"
                font.bold: dockRow.selected
            }

            Txt {
                Layout.fillWidth: true
                text: Dock.alwaysShow ? "Always shown" : "Hides, shows at the bottom edge"
                color: Theme.dim
                elide: Text.ElideRight
            }

            Toggle {
                checked: Dock.alwaysShow
                onToggled: Dock.setAlwaysShow(!Dock.alwaysShow)
            }
        }

        MouseArea {
            anchors.fill: parent
            z: -1
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            cursorShape: Qt.PointingHandCursor
            onEntered: nav.select(menu.dockIndex)
        }
    }

    // ---------- a font's list ----------
    ScrollList {
        id: fontList

        visible: menu.fontRole !== ""
        maxHeight: 360
        model: menu.fontChoices

        delegate: SelectableCard {
            id: choice

            required property string modelData
            required property int index

            readonly property bool current: modelData === Theme.fonts[menu.fontRole]
            readonly property bool isDefault: modelData === (Theme.settings.font[menu.fontRole] ?? Theme.settings.font.ui)

            width: fontList.rowWidth
            implicitHeight: 36
            selected: fontNav.index === index

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
                onEntered: fontNav.select(choice.index)
                onClicked: Themes.setFont(menu.fontRole, choice.modelData)
            }
        }
    }

    Hint {
        text: menu.fontRole !== "" ? "j k select • Enter apply • h or Esc back" : "j k select • Enter apply / toggle • - + font size • number palette • Esc close"
    }
}
