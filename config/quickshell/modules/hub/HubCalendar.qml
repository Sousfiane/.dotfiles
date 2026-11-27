import Quickshell
import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// The hub's month calendar: the month's name with arrows (click it for today), the days in a grid
// from Monday with a dot per event, the selected day outlined. Scroll over it to change month.
// The keys are the hub's: it calls shiftMonth, moveDay and goToday.
ColumnLayout {
    id: cal
    spacing: 12

    // month being displayed (starts on the current month)
    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()

    readonly property date today: clock.date

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // day whose events are listed under the calendar (starts on today)
    property date selected: new Date()

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

    // ---------- calendar header ----------
    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        IconButton {
            icon: "‹"
            size: Theme.fontSize + 6
            onClicked: cal.shiftMonth(-1)
        }

        Txt {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            variant: "heading"
            text: Qt.formatDate(new Date(cal.viewYear, cal.viewMonth, 1), "MMMM yyyy")

            // click the title to jump back to today
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: cal.goToday()
            }
        }

        IconButton {
            icon: "›"
            size: Theme.fontSize + 6
            onClicked: cal.shiftMonth(1)
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
            model: cal.cells

            delegate: Rectangle {
                id: dayCell
                required property var modelData

                readonly property bool inMonth: modelData.month === cal.viewMonth
                readonly property bool isToday: Calendar.sameDay(modelData.date, cal.today)
                readonly property bool isSelected: Calendar.sameDay(modelData.date, cal.selected)
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
                            radius: width / 2
                            color: dayCell.isToday ? Theme.bgSolid : modelData.color
                        }
                    }
                }

                MouseArea {
                    id: dayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: cal.select(dayCell.modelData.year, dayCell.modelData.month, dayCell.modelData.day)
                }
            }
        }

        // scroll over the calendar to change month
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: event => cal.shiftMonth(event.angleDelta.y > 0 ? -1 : 1)
        }
    }
}
