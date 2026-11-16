pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.config

// events from the Nextcloud calendar (CalDAV, read-only), fetched by scripts/calendar.py.
// The hub calls show() with the month on screen; a window of a few months around it is loaded.
Singleton {
    id: root

    property var calendars: []              // [{name, color}]
    property var events: []                 // [{calendar, color, title, location, start, end, allDay}]
    property string error: ""               // last failure, "" when fine
    property bool loaded: false             // at least one successful fetch
    readonly property bool loading: proc.running
    property real fetchedAt: 0

    // loaded window: [winStart, winEnd), first days of months
    property date winStart: new Date(0)
    property date winEnd: new Date(0)

    // "YYYY-MM-DD" -> events touching that day, sorted all-day first then by start
    readonly property var byDay: {
        const out = {};
        for (const ev of events) {
            const s = parse(ev.start);
            let e = parse(ev.end);
            if (e <= s)
                e = new Date(s.getTime() + 1);
            // every day the event touches (end is exclusive), capped for very long events
            const d = new Date(s.getFullYear(), s.getMonth(), s.getDate());
            for (let i = 0; i < 62 && d < e; i++) {
                const k = key(d.getFullYear(), d.getMonth(), d.getDate());
                (out[k] = out[k] ?? []).push(ev);
                d.setDate(d.getDate() + 1);
            }
        }
        return out;
    }

    function colorFor(name) {
        return Config.calendarColors[name] ?? Theme.accent;
    }

    function key(y, m, d) {
        return y + "-" + String(m + 1).padStart(2, "0") + "-" + String(d).padStart(2, "0");
    }

    // "2026-11-18" is a local date (new Date() would read it as UTC); full ISO times carry their offset
    function parse(iso) {
        if (iso.length === 10)
            return new Date(+iso.slice(0, 4), +iso.slice(5, 7) - 1, +iso.slice(8, 10));
        return new Date(iso);
    }

    function eventsOn(y, m, d) {
        return byDay[key(y, m, d)] ?? [];
    }

    // make sure the month on screen (and the days of its neighbours shown in the grid) is loaded
    function show(y, m) {
        const first = new Date(y, m, 1);
        if (first >= winStart && new Date(y, m + 1, 1) <= winEnd)
            return;
        winStart = new Date(y, m - 1, 1);
        winEnd = new Date(y, m + 2, 1);
        refresh();
    }

    function refreshIfStale(maxAgeMin) {
        if (Date.now() - fetchedAt > maxAgeMin * 60 * 1000)
            refresh();
    }

    // a fetch asked for while one is running is done right after it
    property bool again: false

    function refresh() {
        if (winEnd <= winStart) {           // nothing shown yet: the months around today
            const t = new Date();
            winStart = new Date(t.getFullYear(), t.getMonth() - 1, 1);
            winEnd = new Date(t.getFullYear(), t.getMonth() + 2, 1);
        }
        if (proc.running) {
            again = true;
            return;
        }
        proc.command = ["python3", "-I", Quickshell.shellDir + "/scripts/calendar.py", isoDate(winStart), isoDate(winEnd)];
        proc.running = true;
    }

    function isoDate(d) {
        return key(d.getFullYear(), d.getMonth(), d.getDate());
    }

    Process {
        id: proc

        stdout: StdioCollector {
            onStreamFinished: {
                let d;
                try {
                    d = JSON.parse(text);
                } catch (e) {
                    root.error = "unreadable answer from the calendar script";
                    return;
                }
                if (d.error) {
                    root.error = d.error;   // keep the last good events
                    return;
                }
                // colors come from the theme (Config.calendarColors), not from Nextcloud
                for (const c of d.calendars)
                    c.color = root.colorFor(c.name);
                for (const ev of d.events)
                    ev.color = root.colorFor(ev.calendar);
                root.calendars = d.calendars;
                root.events = d.events;
                root.error = "";
                root.loaded = true;
                root.fetchedAt = Date.now();
            }
        }

        onExited: if (root.again) {
            root.again = false;
            root.refresh();
        }
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 15 * 60 * 1000            // every 15 minutes
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
