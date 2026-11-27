import QtQuick
import QtQuick.Layouts
import qs.config
import qs.services
import qs.components.ui

// The hub's Home tab, one column: the day, what's playing, the toggles, the calendar and its events.
// HubPanel keeps it while another tab shows (hidden, not removed), so the calendar keeps its month and day.
ColumnLayout {
    id: root
    spacing: 12

    // Home's own keys: the calendar and the media. False for a key it doesn't use
    function handleKey(key) {
        switch (key) {
        case Qt.Key_Left:
        case Qt.Key_H:
            calendar.shiftMonth(-1);
            break;
        case Qt.Key_Right:
        case Qt.Key_L:
            calendar.shiftMonth(1);
            break;
        case Qt.Key_J:
        case Qt.Key_Down:
            calendar.moveDay(1);
            break;
        case Qt.Key_K:
        case Qt.Key_Up:
            calendar.moveDay(-1);
            break;
        case Qt.Key_T:
            calendar.goToday();
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
        default:
            return false;
        }
        return true;
    }

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

    // ---------- quick toggles ----------
    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        QuickToggle {
            icon: Net.wifiOn ? Icons.wifi4 : Icons.wifiOff
            label: "Wi-Fi"
            active: Net.wifiOn && Net.wifiDevice !== null
            available: Net.wifiDevice !== null
            onClicked: Net.toggleWifi()
        }

        QuickToggle {
            icon: Bt.connected ? Icons.bluetoothConnected : Bt.powered ? Icons.bluetooth : Icons.bluetoothOff
            label: "Bluetooth"
            active: Bt.powered
            available: Bt.adapter !== null
            onClicked: Bt.togglePower()
        }

        QuickToggle {
            icon: Notifs.dnd ? Icons.bellOff : Icons.bell
            label: "Silent"
            active: Notifs.dnd
            onClicked: Notifs.dnd = !Notifs.dnd
        }

        QuickToggle {
            icon: Icons.keepAwake
            label: "Awake"
            active: Toggles.keepAwake
            onClicked: Toggles.keepAwake = !Toggles.keepAwake
        }
    }

    Divider {}

    // ---------- calendar ----------
    HubCalendar {
        id: calendar
        Layout.fillWidth: true
    }

    Divider {}

    // ---------- events of the selected day ----------
    HubEvents {
        Layout.fillWidth: true
        day: calendar.selected
        today: calendar.today
    }
}
