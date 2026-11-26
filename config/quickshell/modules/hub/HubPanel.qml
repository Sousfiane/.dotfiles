import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.panel
import qs.components.ui

// The hub (SUPER + ALT + Space, or the clock): date, weather and what's playing, the calendar with the
// selected day's events, and shortcuts to the other pickers.
DropdownPanel {
    id: panel
    name: "hub"
    edge: "center"
    cardWidth: 720

    ColumnLayout {
        id: hub
        spacing: 12

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        // month being displayed (starts on the current month)
        property int viewYear: new Date().getFullYear()
        property int viewMonth: new Date().getMonth()

        readonly property date today: clock.date

        // day whose events are listed under the calendar (starts on today)
        property date selected: new Date()
        readonly property var selectedEvents: Calendar.eventsOn(selected.getFullYear(), selected.getMonth(), selected.getDate())
        readonly property bool selectedIsToday: sameDay(selected, today)

        function sameDay(a, b) {
            return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
        }

        // select a day, and show its month if it is not the one on screen
        function select(y, m, d) {
            selected = new Date(y, m, d);
            if (y !== viewYear || m !== viewMonth) {
                viewYear = y;
                viewMonth = m;
            }
        }

        function moveDay(n) {
            select(selected.getFullYear(), selected.getMonth(), selected.getDate() + n);
        }

        // load the events of the month on screen (and refresh old data when the hub opens)
        onViewMonthChanged: Calendar.show(viewYear, viewMonth)
        Component.onCompleted: {
            Calendar.show(viewYear, viewMonth);
            Calendar.refreshIfStale(5);
        }

        // 6 weeks of days, starting on Monday
        readonly property var cells: {
            const y = viewYear;
            const m = viewMonth;
            const first = new Date(y, m, 1);
            const offset = (first.getDay() + 6) % 7;
            const out = [];
            for (let i = 0; i < 42; i++) {
                const d = new Date(y, m, 1 - offset + i);
                out.push({
                    date: d,
                    day: d.getDate(),
                    month: d.getMonth(),
                    year: d.getFullYear()
                });
            }
            return out;
        }

        function shiftMonth(d) {
            const next = new Date(viewYear, viewMonth + d, 1);
            viewYear = next.getFullYear();
            viewMonth = next.getMonth();
        }

        function goToday() {
            select(today.getFullYear(), today.getMonth(), today.getDate());
        }

        Keys.onPressed: event => {
            switch (event.key) {
            case Qt.Key_Left:
            case Qt.Key_H:
                shiftMonth(-1);
                break;
            case Qt.Key_Right:
            case Qt.Key_L:
                shiftMonth(1);
                break;
            case Qt.Key_J:
            case Qt.Key_Down:
                moveDay(1);
                break;
            case Qt.Key_K:
            case Qt.Key_Up:
                moveDay(-1);
                break;
            case Qt.Key_T:
                goToday();
                break;
            case Qt.Key_A:
                Hub.openPicker("launcher");
                break;
            case Qt.Key_W:
                Hub.openPicker("wallpaper");
                break;
            case Qt.Key_E:
                Hub.openPicker("theme");
                break;
            case Qt.Key_C:
                Hub.openPicker("clipboard");
                break;
            case Qt.Key_S:
                Hub.openPicker("screenshot");
                break;
            case Qt.Key_I:
                Hub.openPicker("install");
                break;
            case Qt.Key_R:
                Hub.openPicker("remove");
                break;
            case Qt.Key_Question:
                Hub.openPicker("keybinds");
                break;
            case Qt.Key_P:
            case Qt.Key_Space:
                Media.toggle();
                break;
            case Qt.Key_N:
                Media.next();
                break;
            case Qt.Key_B:
                Media.previous();
                break;
            case Qt.Key_Q:
                panel.close();
                break;
            default:
                return;
            }
            event.accepted = true;
        }

        // the calendar's side on the left, the shortcuts on the right
        RowLayout {
            Layout.fillWidth: true
            spacing: 20

            ColumnLayout {
                Layout.preferredWidth: 318        // the calendar grid's width
                Layout.maximumWidth: 318
                Layout.alignment: Qt.AlignTop
                spacing: 12

                // ---------- time and date, weather next to them ----------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // fresh weather whenever the hub opens (the service also refreshes every 30 minutes)
                    Component.onCompleted: Weather.refreshIfStale()

                    DateTimeBlock {
                        Layout.fillWidth: true
                    }

                    // the columns hold only fixed-size text, so this is what lets the row span the card
                    Item {
                        Layout.fillWidth: true
                    }

                    WeatherBlock {
                        Layout.fillWidth: false             // nested layouts fill by default: stay against the right edge
                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    }
                }

                Divider {}

                // ---------- now playing (only while a player has a track) ----------
                NowPlaying {
                    Layout.fillWidth: true
                }

                Divider {
                    visible: Media.active
                }

                // ---------- calendar header ----------
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    IconButton {
                        icon: "‹"
                        size: Theme.fontSize + 6
                        onClicked: hub.shiftMonth(-1)
                    }

                    Txt {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        variant: "heading"
                        text: Qt.formatDate(new Date(hub.viewYear, hub.viewMonth, 1), "MMMM yyyy")

                        // click the title to jump back to today
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: hub.goToday()
                        }
                    }

                    IconButton {
                        icon: "›"
                        size: Theme.fontSize + 6
                        onClicked: hub.shiftMonth(1)
                    }
                }

                // ---------- calendar grid ----------
                Grid {
                    Layout.alignment: Qt.AlignHCenter
                    columns: 7
                    columnSpacing: 4
                    rowSpacing: 2

                    // weekday names
                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                        delegate: Txt {
                            required property string modelData

                            width: 42
                            height: 22
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            variant: "small"
                            font.bold: true
                            text: modelData
                        }
                    }

                    // days
                    Repeater {
                        model: hub.cells

                        delegate: Rectangle {
                            id: dayCell
                            required property var modelData

                            readonly property bool inMonth: modelData.month === hub.viewMonth
                            readonly property bool isToday: hub.sameDay(modelData.date, hub.today)
                            readonly property bool isSelected: hub.sameDay(modelData.date, hub.selected)
                            readonly property var events: Calendar.eventsOn(modelData.year, modelData.month, modelData.day)

                            width: 42
                            height: 30
                            radius: Theme.radius
                            color: isToday ? Theme.accent : dayMouse.containsMouse ? Theme.surface : Theme.surfaceClear
                            border.width: 1
                            border.color: isSelected && !isToday ? Theme.accent : Theme.accentClear
                            Behavior on color {
                                CAnim {}
                            }
                            Behavior on border.color {
                                CAnim {}
                            }

                            Txt {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -2
                                variant: "row"
                                text: dayCell.modelData.day
                                color: dayCell.isToday ? Theme.bgSolid : dayCell.inMonth ? Theme.fg : Theme.dim
                                opacity: dayCell.inMonth || dayCell.isToday ? 1 : 0.5
                                font.bold: dayCell.isToday || dayCell.isSelected
                            }

                            // one dot per event (up to three), in its calendar's color
                            Row {
                                anchors {
                                    horizontalCenter: parent.horizontalCenter
                                    bottom: parent.bottom
                                    bottomMargin: 3
                                }
                                spacing: 2
                                opacity: dayCell.inMonth || dayCell.isToday ? 1 : 0.5

                                Repeater {
                                    model: dayCell.events.slice(0, 3)

                                    delegate: Rectangle {
                                        required property var modelData
                                        width: 4
                                        height: 4
                                        radius: 2
                                        color: dayCell.isToday ? Theme.bgSolid : modelData.color
                                    }
                                }
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: hub.select(dayCell.modelData.year, dayCell.modelData.month, dayCell.modelData.day)
                            }
                        }
                    }

                    // scroll over the calendar to change month
                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: event => hub.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
                    }
                }

                Divider {}

                // ---------- events of the selected day ----------
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true

                        Txt {
                            Layout.fillWidth: true
                            variant: "heading"
                            text: hub.selectedIsToday ? "Today" : Qt.formatDate(hub.selected, "dddd d MMMM")
                        }

                        Txt {
                            variant: "small"
                            text: Calendar.loading ? "syncing…" : hub.selectedEvents.length === 0 ? "" : Fmt.plural(hub.selectedEvents.length, "event")
                        }
                    }

                    Repeater {
                        model: hub.selectedEvents.slice(0, 5)

                        delegate: RowLayout {
                            id: evRow
                            required property var modelData

                            // "All day", "14:00 – 15:00", or the part of a multi-day event that falls on this day
                            readonly property string when: {
                                const ev = modelData;
                                if (ev.allDay)
                                    return "All day";
                                const s = Calendar.parse(ev.start);
                                const e = Calendar.parse(ev.end);
                                const startsHere = hub.sameDay(s, hub.selected);
                                const endsHere = hub.sameDay(e, hub.selected) || (e - s === 0);
                                if (startsHere && endsHere)
                                    return Qt.formatTime(s, "HH:mm") + (e > s ? " – " + Qt.formatTime(e, "HH:mm") : "");
                                if (startsHere)
                                    return "from " + Qt.formatTime(s, "HH:mm");
                                if (endsHere)
                                    return "until " + Qt.formatTime(e, "HH:mm");
                                return "All day";
                            }

                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.fillHeight: true
                                implicitWidth: 3
                                radius: 2
                                color: evRow.modelData.color
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Txt {
                                        Layout.fillWidth: true
                                        variant: "row"
                                        font.bold: true
                                        text: evRow.modelData.title
                                        elide: Text.ElideRight
                                    }

                                    Txt {
                                        variant: "small"
                                        text: evRow.when
                                    }
                                }

                                Txt {
                                    Layout.fillWidth: true
                                    variant: "small"
                                    text: evRow.modelData.calendar + (evRow.modelData.location ? "  ·  " + evRow.modelData.location : "")
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }

                    Txt {
                        visible: hub.selectedEvents.length > 5
                        variant: "small"
                        text: "+ " + (hub.selectedEvents.length - 5) + " more"
                    }

                    Txt {
                        visible: Calendar.loaded && hub.selectedEvents.length === 0
                        variant: "dim"
                        text: "No events"
                    }

                    // the reason, when the calendar cannot be read
                    Txt {
                        visible: Calendar.error !== ""
                        Layout.fillWidth: true
                        variant: "small"
                        color: Theme.urgent
                        wrapMode: Text.Wrap
                        text: "Calendar: " + Calendar.error
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Theme.border
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                spacing: 12

                // ---------- pickers ----------
                Txt {
                    variant: "heading"
                    text: "Open"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: [
                            {
                                label: "Apps",
                                key: "A",
                                icon: Icons.apps,
                                target: "launcher"
                            },
                            {
                                label: "Wallpapers",
                                key: "W",
                                icon: Icons.wallpaper,
                                target: "wallpaper"
                            },
                            {
                                label: "Theme",
                                key: "E",
                                icon: Icons.palette,
                                target: "theme"
                            },
                            {
                                label: "Clipboard",
                                key: "C",
                                icon: Icons.clipboard,
                                target: "clipboard"
                            },
                            {
                                label: "Screenshot",
                                key: "S",
                                icon: Icons.screenshot,
                                target: "screenshot"
                            },
                            {
                                label: "Keybinds",
                                key: "?",
                                icon: Icons.keyboard,
                                target: "keybinds"
                            }
                        ]

                        delegate: ShortcutTile {
                            onActivated: target => Hub.openPicker(target)
                        }
                    }
                }

                Divider {}

                // ---------- packages ----------
                Txt {
                    variant: "heading"
                    text: "Packages"
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: [
                            {
                                label: "Install",
                                key: "I",
                                icon: Icons.packageInstall,
                                target: "install"
                            },
                            {
                                label: "Remove",
                                key: "R",
                                icon: Icons.packageRemove,
                                target: "remove"
                            }
                        ]

                        delegate: ShortcutTile {
                            onActivated: target => Hub.openPicker(target)
                        }
                    }
                }
            }
        }

        Hint {
            text: Media.active ? "h l month • j k day • t today • p/b/n media • a w e c s ? i r open • Esc" : "h l month • j k day • t today • a w e c s ? i r open • Esc close"
        }
    }
}
