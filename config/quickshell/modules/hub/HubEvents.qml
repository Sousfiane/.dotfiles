import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// The hub's list of one day's events under the calendar: up to five, each with its time (or "All day",
// or the part of a multi-day event on that day), calendar and place. Also the calendar's error.
ColumnLayout {
    id: root

    required property date day          // the day whose events are listed
    property date today: new Date()     // the hub's clock, so "Today" moves at midnight
    readonly property var events: Calendar.eventsOn(day.getFullYear(), day.getMonth(), day.getDate())

    spacing: 6

    RowLayout {
        Layout.fillWidth: true

        Txt {
            Layout.fillWidth: true
            variant: "heading"
            text: Calendar.sameDay(root.day, root.today) ? "Today" : Qt.formatDate(root.day, "dddd d MMMM")
        }

        Txt {
            variant: "small"
            text: Calendar.loading ? "syncing…" : root.events.length === 0 ? "" : Fmt.plural(root.events.length, "event")
        }
    }

    Repeater {
        model: root.events.slice(0, 5)

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
                const startsHere = Calendar.sameDay(s, root.day);
                const endsHere = Calendar.sameDay(e, root.day) || (e - s === 0);
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
        visible: root.events.length > 5
        variant: "small"
        text: "+ " + (root.events.length - 5) + " more"
    }

    Txt {
        visible: Calendar.loaded && root.events.length === 0
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
